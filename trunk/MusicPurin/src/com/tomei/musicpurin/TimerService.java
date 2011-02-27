package com.tomei.musicpurin;

import android.app.AlarmManager;
import android.app.KeyguardManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.PowerManager;
import android.os.RemoteException;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Process;
import android.os.RemoteCallbackList;
import android.preference.PreferenceManager;
import java.util.*;
import java.io.*;

public class TimerService extends Service {
    //private static final int FIRE_PERIOD = 12; // TEST
    private static final int FIRE_PERIOD = 3600; // REAL

    @Override
    public void onCreate() {
        MyWakeLock.acquireCpuWakeLock(this);
        if (rescheduleTimer(FIRE_PERIOD)) {
            Thread t = new Thread() {
                    public void run() {
                        checkNewFiles();
                    }
                };
            t.start();
        } else {
            terminate();
        }
    }

    private void checkNewFiles() {
        try {
            System.out.println("CHECKING NEW FILES .....");

            System.out.println("DONE CHECKING NEW FILES .....");
        } catch (Throwable t) {
            t.printStackTrace();
        } finally {
            try {
                // Just in case the download took longer than PERIOD!
                rescheduleTimer(FIRE_PERIOD);
            } catch (Throwable t) {
                t.printStackTrace();
            } 
            terminate();
        }
    }

    public IBinder onBind(Intent intent) {
        return mTimerBinder;
    }

    private final ITimerService.Stub mTimerBinder = new ITimerService.Stub() {
            public void dummy() {
            }
        };

    @Override
    public void onDestroy() {
        System.out.println("TimerService onDestroy()");
        MyWakeLock.releaseCpuWakeLock();
    }

    public boolean rescheduleTimer(int secs) {
        Context context = this;
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        String key = "last.check.seconds";

        long nowSeconds = System.currentTimeMillis() / 1000;
        long lastCheckSeconds = prefs.getLong(key, 0);
        boolean checkNow = false;

        int remain = (int)(lastCheckSeconds + secs - nowSeconds);

        if (remain < 5) {
            checkNow = true;
            SharedPreferences.Editor editor = prefs.edit();
            editor.putLong(key, nowSeconds);
            editor.commit();
        } else {
            secs = remain;
        }

        System.out.println("Reschedule TimerService after " + secs + " seconds");
        AlarmManager alarmMgr = (AlarmManager)context.getSystemService(Context.ALARM_SERVICE);
        PendingIntent pi = createAlarmIntent(context);

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeInMillis(System.currentTimeMillis());
        calendar.add(Calendar.SECOND, secs);

        System.out.println("RTC_WAKEUP = " + calendar);

        alarmMgr.set(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), pi);

        return checkNow;
    }

    private static PendingIntent createAlarmIntent(Context context) {
        Intent i = new Intent("com.tomei.musicpurin.TIMER");
        PendingIntent pi = PendingIntent.getBroadcast(context, 0, i, PendingIntent.FLAG_UPDATE_CURRENT);
        return pi;
    }

    public static void startService(Context context) {
        Intent i = new Intent();
        i.setClassName(context.getPackageName(), context.getPackageName() + ".TimerService");
        context.startService(i);
    }

    private void terminate() {
        stopSelf();
    }
}
