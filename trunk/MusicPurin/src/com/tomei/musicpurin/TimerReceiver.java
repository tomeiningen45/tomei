package com.tomei.musicpurin;

import android.app.KeyguardManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ContentUris;
import android.content.Context;
import android.content.Intent;
import android.content.BroadcastReceiver;
import android.database.Cursor;
import android.os.Parcel;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * See http://groups.google.com/group/android-developers/browse_thread/thread/f0303a539de3a74a
 */
public class TimerReceiver extends BroadcastReceiver {
    public TimerReceiver() {

    }

    // This is called for two cases:
    // - android.intent.action.BOOT_COMPLETED
    // - com.tomei.musicpurin.TIMER

    @Override
    public void onReceive(Context context, Intent intent) {
        // Maintain a cpu wake lock until the TimerService can
        // pick it up.
        System.out.println("com.tomei.musicpurin.TimerReceiver.onReceive()");
        MyWakeLock.acquireCpuWakeLock(context);
        TimerService.startService(context);
    }
}
