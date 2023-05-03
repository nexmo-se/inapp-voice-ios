package com.vonage.inapp_voice_android.utils

import android.content.Context
import android.content.DialogInterface
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.core.content.ContextCompat.startActivity
import com.vonage.inapp_voice_android.views.LoginActivity


fun ArrayList<String>.contains(s: String, ignoreCase: Boolean = false): Boolean {

    return any { it.equals(s, ignoreCase) }
}

internal fun showToast(context: Context, text: String, duration: Int = Toast.LENGTH_LONG){
    Handler(Looper.getMainLooper()).post {
        Toast.makeText(context, text, duration).show()
    }
}

internal fun showAlert(context: Context, text: String, forceExit: Boolean){
    Handler(Looper.getMainLooper()).post {
        val builder: AlertDialog.Builder = AlertDialog.Builder(context)

        // Set Alert Title
        builder.setTitle(text);
        builder.setCancelable(false);

        // Set the positive button with yes name Lambda OnClickListener method is use of DialogInterface interface.
        builder.setPositiveButton("Ok",
            DialogInterface.OnClickListener { dialog: DialogInterface?, which: Int ->
                // When the user click yes button then app will close
                if (dialog !== null) {
                    dialog.cancel();
                }
                if (forceExit) {
                    val intent = Intent(context, LoginActivity::class.java)
                    intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                    context.startActivity (intent);
                }

            } as DialogInterface.OnClickListener)
        val alertDialog = builder.create()
        alertDialog.show()

    }
}
