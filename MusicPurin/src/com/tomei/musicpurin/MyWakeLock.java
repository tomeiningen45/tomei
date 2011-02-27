/*
 * Copyright (C) 2008 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.tomei.musicpurin;

import android.content.Context;
import android.os.PowerManager;

class MyWakeLock {

    private static PowerManager.WakeLock sCpuWakeLock;

    static synchronized void acquireCpuWakeLock(Context context) {
        if (sCpuWakeLock != null) {
            return;
        }

        System.out.println("HOLDING WAKE LOCK");

        PowerManager pm =
                (PowerManager) context.getSystemService(Context.POWER_SERVICE);

        sCpuWakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK, "MusicPurin");
        sCpuWakeLock.acquire();
    }

    static synchronized void releaseCpuWakeLock() {
        if (sCpuWakeLock != null) {
            sCpuWakeLock.release();
            sCpuWakeLock = null;
        }

        System.out.println("RELEASED WAKE LOCK");
    }
}
