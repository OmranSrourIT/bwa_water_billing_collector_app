package com.example.bwa_water_billing_collector_app
 
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.util.UUID
 
class MainActivity : FlutterFragmentActivity() {
 
    private val CHANNEL = "minesec/payment"
    private val PRINT_CHANNEL = "printer_channel"
 
    private lateinit var tpayManager: TPayManager
    private lateinit var methodChannel: MethodChannel
 
    // Cached Bluetooth connection — avoids paying the RFCOMM handshake cost on every print
    private var cachedSocket: android.bluetooth.BluetoothSocket? = null
    private var cachedMac: String? = null
 
    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
 
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PRINT_CHANNEL
        ).setMethodCallHandler { call, result ->
 
            when (call.method) {
 
                "getPairedPrinters" -> {
                    val adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
                    val devices = adapter.bondedDevices
 
                    val resultList = devices.map {
                        mapOf(
                            "name" to it.name,
                            "mac" to it.address
                        )
                    }
 
                    result.success(resultList)
                    return@setMethodCallHandler
                }
 
                "printImage" -> {
 
                    val mac =
                        call.argument<String>("mac")
 
                    val image =
                        call.argument<ByteArray>("image")
 
                    if (mac == null || image == null) {
                        result.error("ERROR", "Missing image data", null)
                        return@setMethodCallHandler
                    }
 
                    try {
                        val t0 = System.currentTimeMillis()
 
                        val bitmap =
                            BitmapFactory.decodeByteArray(
                                image,
                                0,
                                image.size
                            )
 
                        val t1 = System.currentTimeMillis()
 
                        val printerBytes =
                            bitmapToEscPosBytes(bitmap)
 
                        val t2 = System.currentTimeMillis()
 
                        sendToPrinter(
                            mac,
                            printerBytes
                        )
 
                        val t3 = System.currentTimeMillis()
 
                        Log.d(
                            "PrintTiming",
                            "decode=${t1 - t0}ms convert=${t2 - t1}ms send=${t3 - t2}ms total=${t3 - t0}ms"
                        )
 
                        result.success(true)
 
                    } catch (e: Exception) {
                        result.error("IMAGE_PRINT_FAILED", e.message, null)
                    }
 
                }
 
                "closePrinterConnection" -> {
                    closePrinterConnection()
                    result.success(true)
                }
 
                else -> result.notImplemented()
 
            }
 
        }
 
        super.configureFlutterEngine(flutterEngine)
 
        // PAYMENT
 
        methodChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
 
        tpayManager =
            TPayManager(this)
 
        tpayManager.onResult = { success, data, error ->
 
            if (success && data != null) {
 
                methodChannel.invokeMethod(
                    "paymentResult",
                    mapOf(
                        "rspCode" to "00",
                        "rspMsg" to "APPROVED",
                        "tranId" to data.tranId,
                        "trace" to data.trace,
                        "tranStatus" to data.tranStatus,
                        "posMessageId" to data.posMessageId,
                        "totalAmount" to data.totalAmount.toString(),
                        "approvalCode" to data.approvalCode,
                        "rrn" to data.rrn,
                        "paymentMethod" to data.paymentMethod,
                        "maskedAccount" to data.maskedAccount,
                        "cvmPerformed" to data.cvmPerformed,
                        "acqMid" to data.acqMid,
                        "acqTid" to data.acqTid,
                        "mchAddress" to data.mchAddress,
                        "mchName" to data.mchName,
                        "createByName" to data.createByName,
                        "createdAt" to data.createdAt,
                        "updatedAt" to data.updatedAt,
                        "tranType" to data.tranType,
                        "entryMode" to data.entryMode
                    )
                )
 
            } else {
 
                methodChannel.invokeMethod(
                    "paymentResult",
                    mapOf(
                        "rspCode" to "-1",
                        "rspMsg" to (error ?: "FAILED")
                    )
                )
 
            }
 
        }
 
        methodChannel.setMethodCallHandler { call, result ->
 
            when (call.method) {
 
                "startPayment" -> {
 
                    val amount =
                        call.argument<Double>("amount") ?: 0.0
 
                    val referenceId =
                        call.argument<String>("referenceId") ?: ""
 
                    tpayManager.startPayment(amount, referenceId)
 
                    result.success(mapOf("status" to "PAYMENT_STARTED"))
 
                }
 
                else -> result.notImplemented()
 
            }
 
        }
 
    }
 
    override fun onDestroy() {
        closePrinterConnection()
        super.onDestroy()
    }
 
    // =================================
    // BLUETOOTH PRINT (cached connection)
    // =================================
 
    private fun getPrinterOutputStream(mac: String): BufferedOutputStream {
        // Reuse the existing socket if it's the same printer and still connected
        if (cachedSocket?.isConnected == true && cachedMac == mac) {
            return BufferedOutputStream(cachedSocket!!.outputStream, 8192)
        }
 
        // Otherwise close any stale connection and open a fresh one
        try {
            cachedSocket?.close()
        } catch (_: Exception) {
        }
 
        val adapter =
            android.bluetooth.BluetoothAdapter.getDefaultAdapter()
 
        val device =
            adapter.getRemoteDevice(mac)
 
        val uuid =
            UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
 
        val socket =
            device.createRfcommSocketToServiceRecord(uuid)
 
        socket.connect()
 
        cachedSocket = socket
        cachedMac = mac
 
        return BufferedOutputStream(socket.outputStream, 8192)
    }
 
    private fun sendToPrinter(
        mac: String,
        data: ByteArray
    ) {
        val output = getPrinterOutputStream(mac)
 
        output.write(data)
 
        // feed paper
        output.write(byteArrayOf(0x0A, 0x0A, 0x0A, 0x0A, 0x0A))
 
        output.flush() // single flush at the end instead of per-write
 
        // NOTE: removed Thread.sleep(300) and socket.close() — closing after every print
        // forces a full reconnect (and this same 300ms wait) on the very next print.
        // The socket now stays open and is reused. If your printer needs a brief
        // settle time before accepting the next job, only add a short sleep here,
        // and only if you observe dropped/garbled prints without it — test first.
    }
 
    // Call this if you need to explicitly disconnect (e.g. user changes printer,
    // or app is closing) — also wired up above via onDestroy and a "closePrinterConnection" method call
    private fun closePrinterConnection() {
        try {
            cachedSocket?.close()
        } catch (_: Exception) {
        }
        cachedSocket = null
        cachedMac = null
    }
 
    // =================================
    // ESC/POS IMAGE (fast pixel conversion)
    // =================================
 
    private fun bitmapToEscPosBytes(
        bitmap: Bitmap
    ): ByteArray {
 
        // عرض مناسب لطابعة 80mm
        val targetWidth = 576
 
        val scaled = if (bitmap.width == targetWidth) {
            bitmap
        } else {
            Bitmap.createScaledBitmap(
                bitmap,
                targetWidth,
                (bitmap.height * targetWidth) / bitmap.width,
                false // filter=false — faster, and irrelevant once thresholded to 1-bit
            )
        }
 
        val width = scaled.width
        val height = scaled.height
        val widthBytes = (width + 7) / 8
 
        // Pull all pixels in ONE native call instead of one call per pixel
        val pixels = IntArray(width * height)
        scaled.getPixels(pixels, 0, width, 0, 0, width, height)
 
        val output = ByteArrayOutputStream(widthBytes * height + 16)
 
        // GS v 0
        output.write(0x1D)
        output.write(0x76)
        output.write(0x30)
        output.write(0x00)
 
        output.write(widthBytes % 256)
        output.write(widthBytes / 256)
 
        output.write(height % 256)
        output.write(height / 256)
 
        for (y in 0 until height) {
            val rowStart = y * width
            var value = 0
            var bitCount = 0
 
            for (x in 0 until width) {
                val p = pixels[rowStart + x]
                val r = (p shr 16) and 0xFF
                val g = (p shr 8) and 0xFF
                val b = p and 0xFF
                val gray = (r + g + b) / 3
 
                value = (value shl 1) or (if (gray < 160) 1 else 0)
                bitCount++
 
                if (bitCount == 8) {
                    output.write(value)
                    value = 0
                    bitCount = 0
                }
            }
 
            if (bitCount > 0) {
                output.write(value shl (8 - bitCount))
            }
        }
 
        return output.toByteArray()
    }
 
}
