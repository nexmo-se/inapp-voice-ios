package com.vonage.inapp_voice_android.core

import android.content.Context
import com.vonage.inapp_voice_android.managers.SharedPrefManager
import com.vonage.inapp_voice_android.telecom.CallConnection
import com.vonage.inapp_voice_android.telecom.TelecomHelper

/**
 * A singleton class for storing and accessing Core Application Data
 */
class CoreContext private constructor(context: Context) {
    private val applicationContext: Context = context.applicationContext
    val telecomHelper: TelecomHelper by lazy { TelecomHelper(applicationContext) }
    val clientManager: VoiceClientManager by lazy { VoiceClientManager(applicationContext) }
    var activeCall: CallConnection? = null

    /**
     * The Firebase Push Token obtained via PushNotificationService.
     */
    var pushToken: String? get() {
        return SharedPrefManager.getPushToken()
    } set(value) {
        if (value !== null) {
            SharedPrefManager.setPushToken(value)
        }
    }
    /**
     * The Device ID bound to the Push Token once it will be registered.
     * It will be used to unregister the Push Token later on.
     */
    var deviceId: String? get() {
        return SharedPrefManager.getDeviceId()
    } set(value) {
        if (value !== null) {
            SharedPrefManager.setDeviceId(value)
        }
    }

    companion object {
        // Volatile will guarantee a thread-safe & up-to-date version of the instance
        @Volatile
        private var instance: CoreContext? = null

        fun getInstance(context: Context): CoreContext {
            return instance ?: synchronized(this) {
                instance ?: CoreContext(context).also { instance = it }
            }
        }
    }
}