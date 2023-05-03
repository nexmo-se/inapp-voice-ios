package com.vonage.inapp_voice_android.managers

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

import com.vonage.inapp_voice_android.models.User


object SharedPrefManager {
    private  lateinit var sharedPreference: SharedPreferences
    const val PUSH_TOKEN = "PUSH_TOKEN"
    const val DEVICE_ID = "DEVICE_ID"
    const val NAME = "ACCOUNT"

    fun init(context: Context) {
        sharedPreference = context.getSharedPreferences( NAME, Context.MODE_PRIVATE)
    }

    fun saveUser(user: User) {
        val editor = sharedPreference.edit()
        editor.putString("username", user.username)
        editor.putString("userId", user.userId)
        editor.putString("region", user.region)
        editor.putString("dc", user.dc)
        editor.putString("ws", user.ws)
        editor.putString("token", user.token)

        editor.apply()
    }

    fun getUser(): User? {
        return User(
            sharedPreference.getString("username", null)!!,
            sharedPreference.getString("userId", null)!!,
            sharedPreference.getString("region", null)!!,
            sharedPreference.getString("dc", null)!!,
            sharedPreference.getString("ws", null)!!,
            sharedPreference.getString("token", null)!!
        )
    }

    fun removeUser() {
        sharedPreference
            .edit()
            .clear()
            .apply()
    }

    fun setPushToken(token: String) {
        sharedPreference.edit().putString(PUSH_TOKEN, token).apply()
    }

    fun getPushToken(): String? {
        return  sharedPreference.getString(PUSH_TOKEN, null)!!
    }

    fun setDeviceId(deviceId: String) {
        sharedPreference.edit().putString(DEVICE_ID, deviceId).apply()
    }

    fun getDeviceId(): String? {
        return  sharedPreference.getString(DEVICE_ID, null)!!
    }
}