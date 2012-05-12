/*
 * Copyright (C) 2007 The Android Open Source Project
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

import com.tomei.musicpurin.R;
import com.tomei.musicpurin.QueryBrowserActivity.QueryListAdapter.QueryHandler;

import android.app.ExpandableListActivity;
import android.app.SearchManager;
import android.app.Activity;
import android.content.AsyncQueryHandler;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.res.Resources;
import android.database.Cursor;
import android.database.CursorWrapper;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.media.AudioManager;
import com.tomei.utils.MediaFile;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Parcel;
import android.os.Parcelable;
import android.provider.MediaStore;
import android.util.Log;
import android.util.SparseArray;
import android.view.ContextMenu;
import android.view.Menu;
import android.view.MenuItem;
import android.view.SubMenu;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.ContextMenu.ContextMenuInfo;
import android.widget.ExpandableListView;
import android.widget.ImageView;
import android.widget.SectionIndexer;
import android.widget.SimpleCursorTreeAdapter;
import android.widget.TextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.ExpandableListView.ExpandableListContextMenuInfo;

import java.text.Collator;

import java.io.File;
import java.io.DataInput;
import java.io.DataOutputStream;
import java.io.DataInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;

import java.util.ArrayList;
import java.net.Socket;
import com.tomei.musicpurin.WifiClient.PlayList;
import com.tomei.musicpurin.WifiClient.Song;

public class WifiSyncActivity extends Activity
{
    String mHost;

    ProgressBar mOneProgress;
    ProgressBar mAllProgress;
    EditText mSyncStatus;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.wifisync);

        final Button button = (Button) findViewById(R.id.start_sync);
        button.setOnClickListener(new View.OnClickListener() {
             public void onClick(View v) {
                 Thread t = new Thread() {
                         public void run() {
                             sync();
                         }
                     };
                 t.start();
             }
         });

        mOneProgress = (ProgressBar) findViewById(R.id.one_progress);
        mAllProgress = (ProgressBar) findViewById(R.id.all_progress);
        mSyncStatus = (EditText)  findViewById(R.id.sync_status);
    }

    boolean syncing;

    void updatePlayLists(ArrayList<PlayList> lists, String root) {
        for (PlayList list : lists) {
            FileOutputStream out = null;
            OutputStreamWriter writer = null;

            try {
                out = new FileOutputStream(root + "/" + list.mName + ".m3u");
                writer = new OutputStreamWriter(out, "UTF-8");
                for (String songName : list.mSongNames) {
                    writer.write(songName + "\n");
                }
                writer.flush();
            } catch (Throwable t) {
                t.printStackTrace();
            }
            Utils.close(out);
        }
    }

    void sync() {
        synchronized (this) {
            if (syncing) {
                return;
            }
            syncing = true;
        }

        long started = System.currentTimeMillis();
        mTotalBytes = 0;
        String root = "/sdcard/musicpurin";

        mNotifier.notify("\nstart");

        MyWakeLock.acquireCpuWakeLock(this);
        try {
            WifiClient client = new WifiClient("192.168.2.80", root);
            try {
                client.sync(mNotifier);
            } catch (Throwable t) {
                t.printStackTrace();
            }

            ArrayList<PlayList> lists = null;
            try {
                lists = client.getPlayLists();
                updatePlayLists(lists, root);
            } catch (Throwable t) {
                t.printStackTrace();
            }

            long elapsed = System.currentTimeMillis() - started;
        
            mNotifier.notify("Elapsed: " + (elapsed) + "ms");
            if (mTotalBytes > 0) {
                mNotifier.notify("Speed: " + (int)(mTotalBytes / ((double)elapsed)) + " KB/Sec");
            }

            refreshDB();
        } finally {
            MyWakeLock.releaseCpuWakeLock();
        }

        synchronized (this) {
            syncing = false;
        }
    }

    private void refreshDB() {
        sendBroadcast(new Intent(Intent.ACTION_MEDIA_MOUNTED,
                                 Uri.parse("file://" + Environment.getExternalStorageDirectory())));
    }

    private long mTotalBytes;

    private void post(Runnable r) {
        runOnUiThread(r);
    }

    WifiClient.Notifier mNotifier = new WifiClient.Notifier() {

            public void notifyTotal(int numToSync, long totalBytes) {
                mTotalBytes = totalBytes;
            }

            public void notifyOneSongProgress(final int numSongDownloaded, 
                                              final long thisSongTotal,
                                              final long thisSongDownloaded,
                                              final long allSongsDownloaded) {
                post(new Runnable() {
                        public void run() {
                            if (thisSongTotal > 0) {
                                mOneProgress.setProgress((int)(100.0 * ((double)thisSongDownloaded) / ((double)thisSongTotal)));
                            }
                            if (mTotalBytes > 0) {
                                mAllProgress.setProgress((int)(100.0 * ((double)allSongsDownloaded) / ((double)mTotalBytes)));
                            }
                        }
                    });
            }

            public void notifyOneSongStart(String localFilePath, long thisSongTotal) {
                int i = localFilePath.lastIndexOf('/');
                notify(localFilePath.substring(i + 1));
            }
            public void notify(final String s) {
                post(new Runnable() {
                        public void run() {
                            mSyncStatus.append(s + '\n');
                            mSyncStatus.postDelayed(new Runnable() {
                                    public void run() {
                                        //mSyncStatus.scrollTo(0, 100000);
                                    }
                                }, 200);
                        }
                    });
            }
        };
}

