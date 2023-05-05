package com.vonage.inapp_voice_android.views

import android.R.attr.label
import android.content.*
import android.opengl.Visibility
import android.os.Bundle
import android.telecom.Connection
import android.util.Log
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.google.firebase.messaging.FirebaseMessaging
import com.vonage.inapp_voice_android.App
import com.vonage.inapp_voice_android.R
import com.vonage.inapp_voice_android.api.APIRetrofit
import com.vonage.inapp_voice_android.api.DeleteInformation
import com.vonage.inapp_voice_android.databinding.ActivityCallBinding
import com.vonage.inapp_voice_android.managers.SharedPrefManager
import com.vonage.inapp_voice_android.models.CallData
import com.vonage.inapp_voice_android.utils.navigateToLoginActivity
import com.vonage.inapp_voice_android.utils.showToast
import com.vonage.inapp_voice_android.views.fragments.FragmentActiveCall
import com.vonage.inapp_voice_android.views.fragments.FragmentIdleCall
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response


class CallActivity : AppCompatActivity() {
    private val coreContext = App.coreContext
    private val clientManager = coreContext.clientManager
    private lateinit var binding: ActivityCallBinding

    private var fallbackState: Int? = null
    private var isMuteToggled = false

    /**
     * This Local BroadcastReceiver will be used
     * to receive messages from other activities
     */
    private val messageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            // Handle the messages here

            // Call Is Muted Update
            intent?.getBooleanExtra(IS_MUTED, false)?.let {
                if(isMuteToggled != it){
                    // TODO: mute
//                    toggleMute()
                }
            }
            // Call Remotely Disconnected
            intent?.getBooleanExtra(IS_REMOTE_DISCONNECT, false)?.let {
                fallbackState = if(it) Connection.STATE_DISCONNECTED else null
            }
            // Call State Updated
            intent?.getStringExtra(CALL_STATE)?.let {
                if(it == CALL_DISCONNECTED){
                    replaceFragment(FragmentIdleCall(), true)
                }
                else if (it == CALL_STARTED) {
                    replaceFragment(FragmentIdleCall(), false)
                }
                else if (it == CALL_ANSWERED) {
                    replaceFragment(FragmentActiveCall(), true)
                    updateCallData()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityCallBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val user =  SharedPrefManager.getUser()
        if (user == null) {
            navigateToLoginActivity()
            return
        }

        registerFirebaseTokens()
        replaceFragment(FragmentIdleCall(), true)

        binding.btLogout.setOnClickListener {
            APIRetrofit.instance.deleteUser(DeleteInformation(user!!.dc, user.userId, user.token)).enqueue(object:
                Callback<Void> {
                override fun onResponse(call: Call<Void>, response: Response<Void>) {
                    SharedPrefManager.removeUser()
                    navigateToLoginActivity()
                }

                override fun onFailure(call: Call<Void>, t: Throwable) {
                    showToast(this@CallActivity, "Failed to Get Credential")
                }

            })
        }

        binding.btCopyData.setOnClickListener {
            val clipboard: ClipboardManager =
                getSystemService(CLIPBOARD_SERVICE) as ClipboardManager

            val copyText = "myLegId - ${CallData.username} : ${CallData.callId}, memberLegId - ${CallData.memberName.toString()} : ${CallData.memberLegId.toString()}, region : ${CallData.region}"
            val clip = ClipData.newPlainText("copyData", copyText)
            clipboard.setPrimaryClip(clip)
            showToast(this@CallActivity, "Copied")
        }

        registerReceiver(messageReceiver, IntentFilter(MESSAGE_ACTION))
    }

    override fun onResume() {
        super.onResume()
        coreContext.activeCall?.let {
            replaceFragment(FragmentActiveCall(), true)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(messageReceiver)
        clientManager.unregisterDevicePushToken()
        clientManager.logout()
    }

    private fun replaceFragment(fragment: Fragment, isEnable: Boolean) {

        if (fragment.tag == "fragmentActiveCall" || !isEnable) {
            binding.btLogout.visibility = View.GONE
        }
        else {
            binding.btLogout.visibility = View.VISIBLE
        }

        val bundle = Bundle()
        bundle.putBoolean("isEnable", isEnable)
        fragment.arguments = bundle
        val fragmentManager = supportFragmentManager
        val fragmentTransaction = fragmentManager.beginTransaction()
        fragmentTransaction.replace(R.id.fcCallStatus, fragment)
        fragmentTransaction.commitAllowingStateLoss()
    }

    private fun registerFirebaseTokens() {
        // FCM Device Token
        if (coreContext.pushToken !== null) {
            clientManager.registerDevicePushToken()
        }
        else {
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    task.result?.let { token ->
                        App.coreContext.pushToken = token
                        println("FCM Device Token: $token")
                        clientManager.registerDevicePushToken()
                    }
                }
            }
        }
    }

    private fun updateCallData() {
        binding.clCallData.visibility = View.VISIBLE
        binding.tvMyLegIdTitle.text = "myLegId - ${CallData.username}"
        binding.tvMyLegIdData.text = CallData.callId

        if (CallData.memberName !== null && CallData.memberLegId !== null ) {
            binding.tvMemberLegIdTitle.text = "memberLegId - ${CallData.memberName}"
            binding.tvMemberLegIdData.text = CallData.memberLegId
            binding.tvMemberLegIdTitle.visibility = View.VISIBLE
            binding.tvMemberLegIdData.visibility = View.VISIBLE
        }
        else {
            binding.tvMemberLegIdTitle.visibility = View.GONE
            binding.tvMemberLegIdData.visibility = View.GONE
        }

        binding.tvCallDataRegionData.text = CallData.region

    }
//    private fun toggleMute() : Boolean{
//        isMuteToggled = binding.btnMute.toggleButton(isMuteToggled)
//        return isMuteToggled
//    }

    companion object {
        const val MESSAGE_ACTION = "com.vonage.inapp_voice_android.MESSAGE_TO_CALL_ACTIVITY"
        const val IS_MUTED = "isMuted"
        const val CALL_STATE = "callState"
        const val CALL_ANSWERED = "answered"
        const val CALL_STARTED = "started"
        const val CALL_DISCONNECTED = "disconnected"
        const val IS_REMOTE_DISCONNECT = "isRemoteDisconnect"
    }
}