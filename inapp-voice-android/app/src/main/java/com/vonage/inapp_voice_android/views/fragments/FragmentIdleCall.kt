package com.vonage.inapp_voice_android.views.fragments

import android.app.Activity
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import androidx.core.widget.doOnTextChanged
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.vonage.inapp_voice_android.App
import com.vonage.inapp_voice_android.R
import com.vonage.inapp_voice_android.adaptors.MembersRecyclerAdaptor
import com.vonage.inapp_voice_android.api.APIRetrofit
import com.vonage.inapp_voice_android.api.MemberInformation
import com.vonage.inapp_voice_android.databinding.FragmentIdlecallBinding
import com.vonage.inapp_voice_android.managers.SharedPrefManager
import com.vonage.inapp_voice_android.models.Members
import com.vonage.inapp_voice_android.models.User
import com.vonage.inapp_voice_android.utils.Constants
import com.vonage.inapp_voice_android.utils.contains
import com.vonage.inapp_voice_android.utils.showToast
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class FragmentIdleCall: Fragment(R.layout.fragment_idlecall) {
    private var _binding: FragmentIdlecallBinding? = null
    private val binding get() = _binding!!

    private var isEnable = false
    private val clientManager = App.coreContext.clientManager
    private var members = ArrayList<String>()
    private var filteredMembers = ArrayList<String>()
    private val membersAdaptor = MembersRecyclerAdaptor(filteredMembers);

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
        isEnable = arguments?.getBoolean("isEnable") ?: true

        val user = SharedPrefManager.getUser()
        binding.tvLoggedUsername.text =   "${user!!.username} (${user!!.region})"

        // Focus button at the start
        binding.btCallAUser.isFocusableInTouchMode = true;
        binding.btCallAUser.requestFocus()

        // Set members adaptors
        val membersRecyclerView = binding.rvCallUser
        membersRecyclerView.layoutManager = LinearLayoutManager(context)
        membersRecyclerView.adapter = membersAdaptor

        membersAdaptor.onMemberClick = {
            binding.etCallUser.setText(it)
            binding.etCallUser.clearFocus()
            binding.btCallAUser.isFocusableInTouchMode = true;
            binding.btCallAUser.requestFocus()

            val imm = activity?.getSystemService(Activity.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.hideSoftInputFromWindow(binding.etCallUser.windowToken, 0)
        }

        binding.etCallUser.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) {
                loadMembers(user)
                binding.rvCallUser.visibility = View.VISIBLE
            }
            else {
                binding.rvCallUser.visibility = View.GONE
            }
        }

        //Filter members
        binding.etCallUser.doOnTextChanged { text, _, _, _ ->
            filteredMembers.clear()

            if (text !== "" && !members.contains(text.toString(), true)) {
                val newList = ArrayList(members.filter { it ->
                    it.lowercase().contains(text.toString().lowercase())
                })
                filteredMembers.addAll(newList)
            }
            else {
                val newList = members
                filteredMembers.addAll(newList)
            }
            membersAdaptor.notifyDataSetChanged()
        }

        // Call Button
        binding.btCallAUser.isEnabled = isEnable
        binding.btCallAUser.setOnClickListener {
            val member = binding.etCallUser.text.toString()
            if (!members.contains(member)) {
                showToast(context!!, "Invalid Member")
                return@setOnClickListener
            }
            call(member)
        }

    }

    private fun loadMembers(user: User) {
        // Get members from backend
        APIRetrofit.instance.getMembers(MemberInformation(user.dc, user.username, user.token)).enqueue(object:
            Callback<Members> {
            override fun onResponse(call: Call<Members>, response: Response<Members>) {
                response.body()?.let { it1 ->
                    filteredMembers.clear()
                    members.addAll(it1.members)
                    filteredMembers.addAll(it1.members)
                    membersAdaptor.notifyDataSetChanged()
                }
            }

            override fun onFailure(call: Call<Members>, t: Throwable) {
                if (context !== null) {
                    showToast(context!!, "Failed to Get Members")
                }
            }

        })
    }

    private fun call(member: String) {
        val callContext = mapOf(
            Constants.CONTEXT_KEY_RECIPIENT to member,
            Constants.CONTEXT_KEY_TYPE to Constants.APP_TYPE
        )
        clientManager.startOutboundCall(callContext)
    }
}