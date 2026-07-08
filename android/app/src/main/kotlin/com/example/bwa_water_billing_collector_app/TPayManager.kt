package com.example.bwa_water_billing_collector_app

import androidx.appcompat.app.AppCompatActivity
import com.theminesec.app.poslib.MsaPosApi
import com.theminesec.app.poslib.model.PosRequest
import com.theminesec.app.poslib.model.PosResponse
import com.theminesec.app.poslib.model.TransactionResponse
import java.math.BigDecimal
import android.util.Log
import androidx.fragment.app.FragmentActivity

class TPayManager(private val activity: FragmentActivity) {

    private val TPAY_PACKAGE = "com.minesec.tabadul"

    private val msaPosApi = MsaPosApi(TPAY_PACKAGE)

    private val transactionLauncher =
        activity.registerForActivityResult(msaPosApi.transactionContract()) { response ->
            handleResponse(response)
        }

    var onResult: ((Boolean, TransactionResponse?, String?) -> Unit)? = null


    // 🚀 تشغيل الدفع
    fun startPayment(amount: Double, referenceId: String) {
       Log.d("TPAY", "Start Payment called")
      Log.d("TPAY", "Amount = $amount")
        val request = PosRequest.Transaction.Sale(
            amount = BigDecimal.valueOf(amount),
            posMessageId = referenceId,
            autoDismissResult = true
        )

        transactionLauncher.launch(request)
    }


    // 📩 معالجة النتيجة
    private fun handleResponse(response: PosResponse<*>) {

        when (response) {

            is PosResponse.Success<*> -> {
                val data = response.data as TransactionResponse

                onResult?.invoke(
                    true,
                    data,
                    null
                )
            }

            is PosResponse.Failed -> {
                onResult?.invoke(
                    false,
                    null,
                    "Error ${response.rspCode}: ${response.rspMsg}"
                )
            }
        }
    }
}
