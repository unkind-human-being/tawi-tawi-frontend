package com.rhyn.reach.core.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.example.tawi_tawi_frontend.MainActivity
import com.example.tawi_tawi_frontend.R

object NotificationHelper {

    fun showNotification(context: Context, title: String, message: String, threadId: String? = null) {
        val channelId = "reach_messages"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create the channel (Required for Android 8+)
        val channel = NotificationChannel(channelId, "Chat Messages", NotificationManager.IMPORTANCE_HIGH)
        notificationManager.createNotificationChannel(channel)

        // Open app when clicked
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            // We can pass the threadId so the app knows which chat to open later!
            if (threadId != null) {
                putExtra("OPEN_THREAD_ID", threadId)
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(com.example.tawi_tawi_frontend.R.mipmap.ic_launcher)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        // Use a unique ID based on the thread so multiple messages from the same person stack up
        val notificationId = threadId?.hashCode() ?: System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notification)
    }
}