package com.vonage.inapp_voice_android

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.recyclerview.widget.RecyclerView

class RegionRecyclerAdaptor: RecyclerView.Adapter<RegionRecyclerAdaptor.ViewHolder>(){
    private var countries = arrayOf("chatp1", "chap2")

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RegionRecyclerAdaptor.ViewHolder {
        val v = LayoutInflater.from(parent.context).inflate(R.layout.item_region, parent, false)
        return ViewHolder(v)
    }

    override fun onBindViewHolder(holder: RegionRecyclerAdaptor.ViewHolder, position: Int) {
        holder.item.text = countries[position]
    }

    override fun getItemCount(): Int {
        return countries.size
    }

    inner class ViewHolder(itemView: View): RecyclerView.ViewHolder(itemView) {
        var item: TextView

        init {
            item = itemView.findViewById(R.id.tvRegionOption)

            item.setOnClickListener {
                val position: Int = absoluteAdapterPosition
                Toast.makeText(item.context, "you clicked ${countries[position]}", Toast.LENGTH_LONG).show()
            }
        }
    }


}