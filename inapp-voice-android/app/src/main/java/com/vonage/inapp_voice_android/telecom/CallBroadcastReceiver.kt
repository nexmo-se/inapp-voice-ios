package com.vonage.inapp_voice_android.telecom

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log
import com.vonage.inapp_voice_android.utils.notifyCallStartedToCallActivity
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

class CallBroadcastReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if(intent?.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED){ return }
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        if(state != TelephonyManager.EXTRA_STATE_OFFHOOK) {return}
        context?.let {
            runBlocking {
                delay(1000)
                notifyCallStartedToCallActivity(it)
            }
        }
    }
}