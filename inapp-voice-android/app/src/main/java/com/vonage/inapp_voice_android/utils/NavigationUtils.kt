package com.vonage.inapp_voice_android.utils

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.vonage.inapp_voice_android.views.CallActivity
import com.vonage.inapp_voice_android.views.LoginActivity


internal fun LoginActivity.navigateToCallActivity(extras: Bundle? = null){
    val intent = Intent(this, CallActivity::class.java)
    extras?.let {
        intent.putExtras(it)
    }
    startActivity(intent)
    finish()
}

internal fun CallActivity.navigateToLoginActivity(extras: Bundle? = null){
    val intent = Intent(this, LoginActivity::class.java)
    extras?.let {
        intent.putExtras(it)
    }
    startActivity(intent)
    finish()
}

//internal fun sendMessageToCallActivity(context: Context, extras: Bundle? = null){
//    val intent = Intent(CallActivity.MESSAGE_ACTION)
//    extras?.let {
//        intent.putExtras(it)
//    }
//    context.sendBroadcast(intent)
//}

//internal fun notifyIsMutedToCallActivity(context: Context, isMuted: Boolean){
//    val extras = Bundle()
//    extras.putBoolean(CallActivity.IS_MUTED, isMuted)
//    sendMessageToCallActivity(context, extras)
//}
//
//internal fun notifyCallAnsweredToCallActivity(context: Context) {
//    val extras = Bundle()
//    extras.putString(CallActivity.CALL_STATE, CallActivity.CALL_ANSWERED)
//    sendMessageToCallActivity(context, extras)
//}
//
//internal fun notifyCallDisconnectedToCallActivity(context: Context, isRemote:Boolean) {
//    val extras = Bundle()
//    extras.putString(CallActivity.CALL_STATE, CallActivity.CALL_DISCONNECTED)
//    extras.putBoolean(CallActivity.IS_REMOTE_DISCONNECT, isRemote)
//    sendMessageToCallActivity(context, extras)
//}