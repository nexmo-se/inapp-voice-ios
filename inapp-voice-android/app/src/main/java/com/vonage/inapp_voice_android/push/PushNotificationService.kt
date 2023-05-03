package com.vonage.inapp_voice_android.push

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.vonage.inapp_voice_android.App

class PushNotificationService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        println("PUSH TOKEN:  $token")
        // Set new Push Token
        App.coreContext.pushToken = token
    }
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // When an incoming call comes in, notify the ClientManager
        App.coreContext.clientManager.processIncomingPush(remoteMessage)
    }
}