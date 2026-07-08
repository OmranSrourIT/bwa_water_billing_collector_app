package com.example.bwa_water_billing_collector_app


import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID



class MainActivity : FlutterFragmentActivity() {


    private val CHANNEL = "minesec/payment"
    private val PRINT_CHANNEL = "printer_channel"


    private lateinit var tpayManager: TPayManager
    private lateinit var methodChannel: MethodChannel



    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {


        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PRINT_CHANNEL
        ).setMethodCallHandler { call, result ->


            when(call.method){


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


                    if(mac == null || image == null){
                        result.error("ERROR","Missing image data",null)
                        return@setMethodCallHandler
                    }


                    try {

                        val bitmap =
                            BitmapFactory.decodeByteArray(
                                image,
                                0,
                                image.size
                            )

                        val printerBytes =
                            bitmapToEscPosBytes(bitmap)

                        sendToPrinter(
                            mac,
                            printerBytes
                        )

                        result.success(true)

                    }catch(e:Exception){
                        result.error("IMAGE_PRINT_FAILED",e.message,null)
                    }

                }



                else -> result.notImplemented()

            }

        }





        super.configureFlutterEngine(flutterEngine)





        // =========================
        // PAYMENT (كما هو بدون تغيير)
        // =========================


        methodChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )



        tpayManager =
            TPayManager(this)



        tpayManager.onResult = { success, data, error ->


            if(success && data != null){


                methodChannel.invokeMethod(
                    "paymentResult",
                    mapOf(
                        "rspCode" to "00",
                        "rspMsg" to "APPROVED",
                        "tranId" to data.tranId,
                        "posMessageId" to data.posMessageId,
                        "totalAmount" to data.totalAmount.toString(),
                        "approvalCode" to data.approvalCode,
                        "rrn" to data.rrn,
                        "paymentMethod" to data.paymentMethod,
                        "maskedAccount" to data.maskedAccount,
                        "createdAt" to data.createdAt,
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


            when(call.method){


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






    // =================================
    // BLUETOOTH PRINT
    // =================================

    private fun sendToPrinter(
        mac:String,
        data:ByteArray
    ){


        val adapter =
            android.bluetooth.BluetoothAdapter.getDefaultAdapter()

        val device =
            adapter.getRemoteDevice(mac)

        val uuid =
            UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")


        val socket =
            device.createRfcommSocketToServiceRecord(uuid)


        socket.connect()


        val output =
            socket.outputStream


        output.write(data)
        output.flush()


        // feed paper
        output.write(byteArrayOf(0x0A,0x0A,0x0A,0x0A,0x0A))
        output.flush()


        Thread.sleep(300)

        socket.close()

    }







    // =================================
    // ESC/POS IMAGE (FIXED)
    // =================================

    private fun bitmapToEscPosBytes(
        bitmap: Bitmap
    ): ByteArray {


        // عرض مناسب لطابعة 80mm
        val targetWidth = 576

        val scaled = Bitmap.createScaledBitmap(
            bitmap,
            targetWidth,
            (bitmap.height * targetWidth) / bitmap.width,
            true
        )


        val width = scaled.width
        val height = scaled.height


        val widthBytes = (width + 7) / 8


        val bytes = ArrayList<Byte>()


        // GS v 0
        bytes.add(0x1D)
        bytes.add(0x76)
        bytes.add(0x30)
        bytes.add(0x00)

        bytes.add((widthBytes % 256).toByte())
        bytes.add((widthBytes / 256).toByte())

        bytes.add((height % 256).toByte())
        bytes.add((height / 256).toByte())


        for (y in 0 until height) {

            for (x in 0 until widthBytes) {

                var value = 0

                for (bit in 0 until 8) {

                    val xx = x * 8 + bit

                    if (xx < width) {

                        val pixel =
                            scaled.getPixel(xx, y)

                        val gray =
                            (Color.red(pixel) +
                                    Color.green(pixel) +
                                    Color.blue(pixel)) / 3

                        if (gray < 160) {
                            value = value or (1 shl (7 - bit))
                        }

                    }

                }

                bytes.add(value.toByte())

            }

        }

        return bytes.toByteArray()

    }

}
