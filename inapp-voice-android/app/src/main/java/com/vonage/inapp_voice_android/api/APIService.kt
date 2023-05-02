package com.vonage.inapp_voice_android.api

import com.vonage.inapp_voice_android.models.User
import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.HTTP
import retrofit2.http.POST

interface APIService {
    @POST("getCredential")
    fun getCredential(
        @Body loginInformation: LoginInformation
    ): Call<User>

    @HTTP(method = "DELETE", path = "deleteUser", hasBody = true)
    fun deleteUser(
        @Body deleteInformation: DeleteInformation
    ): Call<Void>
}