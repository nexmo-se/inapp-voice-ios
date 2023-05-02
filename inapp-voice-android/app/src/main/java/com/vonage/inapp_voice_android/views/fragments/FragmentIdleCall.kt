package com.vonage.inapp_voice_android.views.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.vonage.inapp_voice_android.R
import com.vonage.inapp_voice_android.databinding.FragmentIdlecallBinding
import com.vonage.inapp_voice_android.managers.SharedPrefManager

class FragmentIdleCall: Fragment(R.layout.fragment_idlecall) {
    private var _binding: FragmentIdlecallBinding? = null
    // This property is only valid between onCreateView and
// onDestroyView.
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentIdlecallBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val user = SharedPrefManager.getUser()
        binding.tvLoggedUsername.text =   "${user?.username} (${user?.region})"
        // TODO: if user = null, return to login page

//        val itemRecyclerView = view.findViewById<RecyclerView>(R.id.rvConversationContainer)
//        itemRecyclerView.adapter = itemAdaptor
//        itemAdaptor.onItemClick = {
//            // TODO: set edit text
//        }
    }
}