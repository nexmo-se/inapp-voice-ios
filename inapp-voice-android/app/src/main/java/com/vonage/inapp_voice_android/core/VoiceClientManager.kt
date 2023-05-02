package com.vonage.inapp_voice_android.core

import android.content.Context
import android.telecom.DisconnectCause
import android.util.Log
import android.widget.Toast
import com.google.firebase.messaging.RemoteMessage
import com.vonage.android_core.PushType
import com.vonage.android_core.VGClientConfig
import com.vonage.clientcore.core.api.*
import com.vonage.inapp_voice_android.managers.SharedPrefManager
import com.vonage.inapp_voice_android.models.User
import com.vonage.inapp_voice_android.telecom.CallConnection
import com.vonage.inapp_voice_android.App
import com.vonage.inapp_voice_android.utils.showToast
import com.vonage.voice.api.VoiceClient

/**
 * This Class will act as an interface
 * between the App and the Voice Client SDK
 */
class VoiceClientManager(private val context: Context) {
    private lateinit var client : VoiceClient
    private val coreContext = App.coreContext
    init {
        SharedPrefManager.init(context)
    }

    fun initClient(user: User){
        setDefaultLoggingLevel(LoggingLevel.Info)

        var config = VGClientConfig()
        if (user.dc.contains("-us-")) {
            config = VGClientConfig(ClientConfigRegion.US)
        }
        else if (user.dc.contains("-eu-")) {
            config = VGClientConfig(ClientConfigRegion.EU)

        }
        else if (user.dc.contains("-ap-")) {
            config = VGClientConfig(ClientConfigRegion.AP)
        }

        client = VoiceClient(context)
        client.setConfig(config)
        setClientListeners()
    }

    private fun setClientListeners(){

        client.setSessionErrorListener { err ->
            when(err){
                SessionErrorReason.TransportClosed -> TODO()
                SessionErrorReason.TokenExpired -> TODO()
                SessionErrorReason.PingTimeout -> TODO()
            }
        }

        client.setCallInviteListener { callId, from, type ->
            // Temp Push notification bug:
            // reject incoming calls when there is an active one
//            coreContext.activeCall?.let { return@setCallInviteListener }
//            coreContext.telecomHelper.startIncomingCall(callId, from, type)
        }

        client.setOnLegStatusUpdate { callId, legId, status ->
            println("Call $callId has received status update $status for leg $legId")
            takeIfActive(callId)?.apply {
                if(status == LegStatus.answered){
//                    setActive()
//                    notifyCallAnsweredToCallActivity(context)
                }
            }
        }

        client.setOnCallHangupListener { callId, callQuality, isRemote ->
//            println("Call $callId has been ${if(isRemote) "remotely" else "locally"} hung up with quality: $callQuality")
            takeIfActive(callId)?.apply {
//                val cause = if(isRemote) DisconnectCause(DisconnectCause.REMOTE) else DisconnectCause(
//                    DisconnectCause.LOCAL)
//                setDisconnected(cause)
//                clearActiveCall()
//                notifyCallDisconnectedToCallActivity(context, isRemote)
            }
        }

        client.setCallInviteCancelListener { callId, reason ->
            println("Invite to Call $callId has been canceled with reason: ${reason.name}")
            takeIfActive(callId)?.apply {
                val cause = when(reason){
                    VoiceInviteCancelReason.AnsweredElsewhere -> DisconnectCause(DisconnectCause.ANSWERED_ELSEWHERE)
                    VoiceInviteCancelReason.RejectedElsewhere -> DisconnectCause(DisconnectCause.REMOTE)
                    VoiceInviteCancelReason.RemoteCancel -> DisconnectCause(DisconnectCause.CANCELED)
                    VoiceInviteCancelReason.RemoteTimeout -> DisconnectCause(DisconnectCause.MISSED)

                }
//                setDisconnected(cause)
//                clearActiveCall()
//                notifyCallDisconnectedToCallActivity(context, true)
            }
        }

        client.setCallTransferListener { callId, conversationId ->
            println("Call $callId has been transferred to conversation $conversationId")
        }

        client.setOnMutedListener { callId, legId, isMuted ->
            println("LegId $legId for Call $callId has been ${if(isMuted) "muted" else "unmuted"}")
            takeIf { callId == legId } ?: return@setOnMutedListener
            // Update Active Call Mute State
//            takeIfActive(callId)?.isMuted = isMuted
            // Notify Call Activity
//            notifyIsMutedToCallActivity(context, isMuted)
        }

        client.setOnDTMFListener { callId, legId, digits ->
            println("LegId $legId has sent DTMF digits '$digits' to Call $callId")
        }
    }
    fun login(user: User, onSuccessCallback: (() -> Unit)? = null){
        client.createSession(user.token){ error, sessionId ->
            sessionId?.let {
                showToast(context, "Connected")
                // save to shared preference
                SharedPrefManager.saveUser(user)
                onSuccessCallback?.invoke()
            } ?: error?.let {
                showToast(context, "Login Failed: ${error.message}")
            }
        }
    }

    fun logout(onSuccessCallback: (() -> Unit)? = null){
        client.deleteSession { error ->
            error?.let {
                showToast(context, "Error Logging Out: ${error.message}")
            } ?: run {
                SharedPrefManager.removeUser()
                onSuccessCallback?.invoke()
            }
        }
    }

    fun startOutboundCall(callContext: Map<String, String>? = null){
        client.serverCall(callContext) { err, callId ->
            err?.let {
                println("Error starting outbound call: $it")
            } ?: callId?.let {
                println("Outbound Call successfully started with Call ID: $it")
//                val to = callContext?.get(Constants.CONTEXT_KEY_RECIPIENT) ?: Constants.DEFAULT_DIALED_NUMBER
//                coreContext.telecomHelper.startOutgoingCall(it, to)
            }
        }
    }

    fun registerDevicePushToken(){
        coreContext.pushToken?.let {
            client.registerDevicePushToken(it) { err, deviceId ->
                err?.let {
                    println("Error in registering Device Push Token: $err")
                } ?: deviceId?.let {
                    coreContext.deviceId = deviceId
                    println("Device Push Token successfully registered with Device ID: $deviceId")
                }
            }
        }
    }

    fun unregisterDevicePushToken(){
        coreContext.deviceId?.let {
            client.unregisterDevicePushToken(it) { err ->
                err?.let {
                    println("Error in unregistering Device Push Token: $err")
                }
            }
        }
    }

    fun processIncomingPush(remoteMessage: RemoteMessage) {
        val dataString = remoteMessage.data.toString()
        val type: PushType? = VoiceClient.getPushNotificationType(dataString)
        if (type == PushType.INCOMING_CALL) {
            // This method will trigger the Client's Call Invite Listener
            client.processPushCallInvite(dataString)
        }
    }

    fun answerCall(call: CallConnection){
        call.takeIfActive()?.apply {
            client.answer(callId) { err ->
                if (err != null) {
                    println("Error Answering Call: $err")
                    setDisconnected(DisconnectCause(DisconnectCause.ERROR))
                    clearActiveCall()
                } else {
                    println("Answered call with id: $callId")
                    setActive()
                }
            }
        } ?: call.selfDestroy()
    }

    fun rejectCall(call: CallConnection){
        call.takeIfActive()?.apply {
            client.reject(callId){ err ->
                if (err != null) {
                    println("Error Rejecting Call: $err")
                    setDisconnected(DisconnectCause(DisconnectCause.ERROR))
                } else {
                    println("Rejected call with id: $callId")
                    setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
                }
            }
        } ?: call.selfDestroy()
    }

    fun hangupCall(call: CallConnection){
        call.takeIfActive()?.apply {
            client.hangup(callId) { err ->
                if (err != null) {
                    println("Error Hanging Up Call: $err")
                } else {
                    println("Hung up call with id: $callId")
                }
            }
        } ?: call.selfDestroy()
    }

    fun muteCall(call: CallConnection){
        call.takeIfActive()?.apply {
            client.mute(callId) { err ->
                if (err != null) {
                    println("Error Muting Call: $err")
                } else {
                    println("Muted call with id: $callId")
                }
            }
        }
    }

    fun unmuteCall(call: CallConnection){
        call.takeIfActive()?.apply {
            client.unmute(callId) { err ->
                if (err != null) {
                    println("Error Un-muting Call: $err")
                } else {
                    println("Un-muted call with id: $callId")
                }
            }
        }
    }

    fun sendDtmf(call: CallConnection, digit: String){
        call.takeIfActive()?.apply {
            client.sendDTMF(callId, digit){ err ->
                if (err != null) {
                    println("Error in Sending DTMF '$digit': $err")
                } else {
                    println("Sent DTMF '$digit' on call with id: $callId")
                }
            }
        }
    }

    // Utilities to filter active calls
    private fun takeIfActive(callId: CallId) : CallConnection? {
      return coreContext.activeCall?.takeIf { it.callId == callId }
    }
    private fun CallConnection.takeIfActive() : CallConnection? {
        return takeIfActive(callId)
    }
}