package com.vonage.inapp_voice_android.views.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.vonage.inapp_voice_android.App
import com.vonage.inapp_voice_android.R
import com.vonage.inapp_voice_android.databinding.FragmentActivecallBinding

class FragmentActiveCall: Fragment(R.layout.fragment_activecall) {
    private var _binding: FragmentActivecallBinding? = null
    private val binding get() = _binding!!

    private val coreContext = App.coreContext
    private val clientManager = coreContext.clientManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentActivecallBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.btHangUp.setOnClickListener {
            onHangup()
        }
    }
    private fun onHangup(){
        coreContext.activeCall?.let { call ->
            clientManager.hangupCall(call)
        }
    }
}