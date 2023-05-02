package com.vonage.inapp_voice_android.utils

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.widget.Toast

fun ArrayList<String>.contains(s: String, ignoreCase: Boolean = false): Boolean {

    return any { it.equals(s, ignoreCase) }
}

internal fun showToast(context: Context, text: String, duration: Int = Toast.LENGTH_LONG){
    Handler(Looper.getMainLooper()).post {
        Toast.makeText(context, text, duration).show()
    }
}
