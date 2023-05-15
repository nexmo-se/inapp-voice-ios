package com.vonage.inapp_voice_android.push

import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.vonage.inapp_voice_android.App

class PushNotificationService : FirebaseMessagingService() {
    companion object {
        /**
         * Request FCM Token Explicitly.
         */
        fun requestToken(){
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    task.result?.takeIf { it != App.coreContext.pushToken }?.let { token ->
                        println("FCM Device Push Token: $token")
                        App.coreContext.pushToken = token
                    }
                }
            }
        }
    }
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        println("PUSH TOKEN:  $token")
        // Set new Push Token
        App.coreContext.pushToken = token
    }
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Whenever a Push Notification comes in
        // If there is no active session then
        // Create one using the latest valid Auth Token and notify the ClientManager
        // Else notify the ClientManager directly
        App.coreContext.run {
            if (sessionId == null) {
                val user = user ?: return@run
                clientManager.login(user, onSuccessCallback = {
                    clientManager.processIncomingPush(remoteMessage)
                })

            } else {
                clientManager.processIncomingPush(remoteMessage)
            }
        }
    }
}