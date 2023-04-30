package com.vonage.inapp_voice_android

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.vonage.inapp_voice_android.databinding.ActivityLoginBinding

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private var layoutManager: RecyclerView.LayoutManager? = null
    private var regionAdaptor: RecyclerView.Adapter<RegionRecyclerAdaptor.ViewHolder> ? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        layoutManager = LinearLayoutManager(this)

        binding.rvRegion.layoutManager = layoutManager

        regionAdaptor = RegionRecyclerAdaptor()
        binding.rvRegion.adapter = regionAdaptor

        binding.svRegion.setOnQueryTextFocusChangeListener {
            // TODO:
        }
        binding.btLogin.setOnClickListener {
        //  TODO: submit form
      }
    }

}