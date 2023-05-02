package com.vonage.inapp_voice_android.views

import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.vonage.inapp_voice_android.App
import com.vonage.inapp_voice_android.R
import com.vonage.inapp_voice_android.api.APIRetrofit
import com.vonage.inapp_voice_android.api.DeleteInformation
import com.vonage.inapp_voice_android.api.LoginInformation
import com.vonage.inapp_voice_android.databinding.ActivityCallBinding
import com.vonage.inapp_voice_android.managers.SharedPrefManager
import com.vonage.inapp_voice_android.models.User
import com.vonage.inapp_voice_android.utils.navigateToLoginActivity
import com.vonage.inapp_voice_android.utils.showToast
import com.vonage.inapp_voice_android.views.fragments.FragmentIdleCall
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class CallActivity : AppCompatActivity() {
    private val coreContext = App.coreContext
    private val clientManager = coreContext.clientManager
    private lateinit var binding: ActivityCallBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityCallBinding.inflate(layoutInflater)
        setContentView(binding.root)

        replaceFragment(FragmentIdleCall())

        binding.btLogout.setOnClickListener {
            val user =  SharedPrefManager.getUser()

            if (user == null) {
                navigateToLoginActivity()
            }

            APIRetrofit.instance.deleteUser(DeleteInformation(user!!.dc, user.userId, user.token)).enqueue(object:
                Callback<Void> {
                override fun onResponse(call: Call<Void>, response: Response<Void>) {
                    clientManager.logout {
                        navigateToLoginActivity()
                    }
                }

                override fun onFailure(call: Call<Void>, t: Throwable) {
                    showToast(this@CallActivity, "Failed to Get Credential")
                }

            })
        }
    }

    private fun replaceFragment(fragment: Fragment) {
        val fragmentManager = supportFragmentManager
        val fragmentTransaction = fragmentManager.beginTransaction()
        fragmentTransaction.replace(R.id.fcCallStatus, fragment)
        fragmentTransaction.commit()
    }
}