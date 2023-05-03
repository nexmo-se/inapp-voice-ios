package com.vonage.inapp_voice_android.views
import android.Manifest
import android.content.pm.PackageManager
import retrofit2.Callback
import android.os.Bundle
import android.view.View
import android.view.inputmethod.InputMethodManager
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.widget.doOnTextChanged
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.vonage.inapp_voice_android.App
import com.vonage.inapp_voice_android.adaptors.RegionRecyclerAdaptor
import com.vonage.inapp_voice_android.api.APIRetrofit
import com.vonage.inapp_voice_android.api.LoginInformation
import com.vonage.inapp_voice_android.databinding.ActivityLoginBinding
import com.vonage.inapp_voice_android.managers.SharedPrefManager
import com.vonage.inapp_voice_android.models.User
import com.vonage.inapp_voice_android.utils.*
import com.vonage.inapp_voice_android.utils.navigateToCallActivity
import com.vonage.inapp_voice_android.utils.showToast
import retrofit2.Call
import retrofit2.Response

class LoginActivity : AppCompatActivity() {

    companion object {
        private const val PERMISSIONS_REQUEST_CODE = 123
    }

    // Only permission with a 'dangerous' Protection Level
    // need to be requested explicitly
    private val permissions = arrayOf(
        Manifest.permission.RECORD_AUDIO,
        Manifest.permission.READ_PHONE_STATE,
        Manifest.permission.ANSWER_PHONE_CALLS,
        Manifest.permission.MANAGE_OWN_CALLS,
        Manifest.permission.READ_PHONE_NUMBERS,
        Manifest.permission.CALL_PHONE,
    )
    private val arePermissionsGranted : Boolean get() {
        return permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }
    private val coreContext = App.coreContext
    private val clientManager = coreContext.clientManager
    private lateinit var binding: ActivityLoginBinding
    private var layoutManager: RecyclerView.LayoutManager? = null
    private var filteredRegions = ArrayList(Constants.REGIONS)
    private val regionAdaptor = RegionRecyclerAdaptor(filteredRegions)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        checkPermissions()

        // Select Regions
        layoutManager = LinearLayoutManager(this)
        binding.rvRegion.layoutManager = layoutManager
        binding.rvRegion.adapter = regionAdaptor

        regionAdaptor.onRegionClick = {
            // Set value
            binding.etRegion.setText(it)
            binding.etRegion.clearFocus()
            val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
            imm.hideSoftInputFromWindow(binding.etRegion.windowToken, 0)
        }

        binding.etRegion.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) {
                binding.rvRegion.visibility = View.VISIBLE
            }
            else {
                binding.rvRegion.visibility = View.GONE
            }
        }

        binding.etRegion.doOnTextChanged { text, _, _, _ ->
            //filter text
            filteredRegions.clear()


            if (text !== "" && !Constants.REGIONS.contains(text.toString(), true)) {
                val newList = ArrayList(Constants.REGIONS.filter { it ->
                    it.lowercase().contains(text.toString().lowercase())
                })
                filteredRegions.addAll(newList)
            }
            else {
                val newList = ArrayList(Constants.REGIONS)
                filteredRegions.addAll(newList)
            }
            regionAdaptor.notifyDataSetChanged()

        }

        // Submit Form
        binding.btLogin.setOnClickListener {
            val username = binding.etUsername.text.toString()
            val region = binding.etRegion.text.toString()
            val pin = binding.etPin.text.toString()

            if ( username == ""
                ||  pin == ""
                || !Constants.REGIONS.contains(region, true) ) {
                showToast(this, "Missing/Wrong User Information")

                return@setOnClickListener
            }

            APIRetrofit.instance.getCredential(LoginInformation(username, region, pin, null)).enqueue(object: Callback<User> {
                override fun onResponse(call: Call<User>, response: Response<User>) {
                    response.body()?.let { it1 ->
                        clientManager.initClient(it1)
                        clientManager.login(it1) {
                            navigateToCallActivity()
                        }
                    }
                }

                override fun onFailure(call: Call<User>, t: Throwable) {
                    showToast(this@LoginActivity, "Failed to Get Credential")
                }

            })

      }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if(arePermissionsGranted){
            App.coreContext.telecomHelper
        }
    }

    private fun checkPermissions() {
      if (!arePermissionsGranted) {
          // Request permissions
          ActivityCompat.requestPermissions(this, permissions, PERMISSIONS_REQUEST_CODE)
      }
  }

}