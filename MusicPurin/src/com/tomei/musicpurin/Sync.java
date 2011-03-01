package com.tomei.musicpurin;


import java.io.*;
import java.util.*;
import java.net.*;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.widget.Toast;
import android.net.Uri;

public class Sync implements Runnable {
    private static Thread syncThread;
    private static Context sContext;

    public synchronized static void sync(Context context) {
        sContext = context;
        if (syncThread == null) {
            syncThread = new Thread(new Sync());
            syncThread.start();
        } else {
            toast("Already syncing");
        }
    }

    public void run() {
        try {
            String host = readAsString(new File("/sdcard/synchost.txt")).trim(); // e.g., foobar.com
            if (host.equals("")) {
                toast("cannot read /sdcard/synchost.txt");
                return;
            }
            String root = "http://" + host + "/";
            int numSynced = 0;
            numSynced += syncFiles(root + "/pod/nhknews/");
            numSynced += syncFiles(root + "/pod/nhkpod/");

            System.out.println("host = " + host);

            if (numSynced > 0) {
                sendBroadcast();                
            }
        } finally {
            syncThread = null;
        }
    }

    private int syncFiles(String root) {
        String files[] = splitURL(root + "list.txt");
        if (files == null) {
            toast("no such root " + root);
            return 0;
        }
        int numSynced = 0;
        for (int i=0; i<files.length; i++) {
            String file = root + files[i];
            if (file.endsWith(".mp3")) {
                String dst = "/sdcard/Music/" + files[i];
                File dstFile = new File(dst);
                if (!dstFile.exists()) {
                    System.out.println("New File = " + file);
                    numSynced += syncFile(file, dst);
                } else {
                    System.out.println("Old File = " + file);
                }
            }
        }
        return numSynced;
    }

    private int syncFile(String urlStr, String dst) {
        URLConnection uconn = null;
        InputStream in = null;
        OutputStream out = null;
        File dstTmp = new File(dst + ".tmp");

        int total = 0;
        toast("Downloading " + urlStr);
        try {
            URL url = new URL(urlStr);
            uconn = url.openConnection();
            in = uconn.getInputStream();
            out = new FileOutputStream(dstTmp);
            byte data[] = new byte[4096];
            int n;
            long started = System.currentTimeMillis();
            while ((n = in.read(data)) > 0) {
                total += n;
                out.write(data, 0, n);
            }
            long secs = (System.currentTimeMillis() - started) / 1000;
            out.close(); out = null;
            dstTmp.renameTo(new File(dst));
            toast("Saved + " + dst + ": " + total + " bytes in " + secs + " secs");
            sendBroadcast();
            return 1;
        }  catch (Throwable t) {
            toast("Error: " + urlStr + ", " + total + ", bytes");
            t.printStackTrace();
            return 0;
        } finally {
            close(in);
            close(out);
            close(uconn);
            if (dstTmp.exists()) {
                dstTmp.delete();
            }
        }
    }

    private void sendBroadcast() {
        ((Activity)sContext).runOnUiThread(new Runnable() {
                public void run() {
                    Intent intent = new Intent();
                    intent.setAction("android.intent.action.MEDIA_MOUNTED");
                    intent.putExtra("read-only", false);
                    intent.setData(Uri.fromFile(new File("/sdcard")));

                    sContext.sendBroadcast(intent);
                }
            });
    }

    public static String[] splitURL(String urlStr) {
        URLConnection uconn = null;
        InputStream in = null;
        try {
            URL url = new URL(urlStr);
            uconn = url.openConnection();
            in = uconn.getInputStream();
            return splitInputStream(in);
        } catch (Throwable t) {
            //t.printStackTrace();
            return null;
        } finally {
            close(in);
            close(uconn);
        }
    }


    private static String[] splitInputStream(InputStream in) throws IOException {
        ArrayList<String> v = new ArrayList<String>();
        BufferedReader reader = new BufferedReader(new InputStreamReader(in, "UTF-8"), 8192);

        String s;
        while ((s = reader.readLine()) != null) {
            v.add(s);
        }
        String array[] = new String[v.size()];
        v.toArray(array);
        return array;
    }


    public static String readAsString(File file) {
        try {
            return readAsString(file, "UTF-8");
        } catch (Throwable t) {
            return "";
        }
    }

    public static String readAsString(File file, String encoding)  throws IOException {
        InputStream in = null;

        try {
            in = new FileInputStream(file);
            StringBuffer sbuf = new StringBuffer();
            BufferedReader reader = new BufferedReader(new InputStreamReader(in, encoding), 1024);
            String line;
            String prefix = "";
            while ((line = reader.readLine()) != null) {
                sbuf.append(prefix);
                sbuf.append(line);
                prefix = "\n";
            }
            return sbuf.toString();
        } finally {
            close(in);
        }
    }

    static void close(InputStream in) {
        if (in != null) {
            try {
                in.close();
            } catch (Throwable t) {;}
        }
    }

    static void close(OutputStream out) {
        if (out != null) {
            try {
                out.close();
            } catch (Throwable t) {;}
        }
    }

    static void close(Writer w) {
        if (w != null) {
            try {
                w.close();
            } catch (Throwable t) {;}
        }
    }

    static void close(ServerSocket s) {
        if (s != null) {
            try {
                s.close();
            } catch (Throwable t) {;}
        }
    }

    static void close(Socket s) {
        if (s != null) {
            try {
                s.close();
            } catch (Throwable t) {;}
        }
    }

    static void close(URLConnection uconn) {
        if (uconn != null) {
            try {
                ((HttpURLConnection)uconn).disconnect();
            } catch (Throwable t) {;}
        }
    }

    static void toast(final String text) {
        System.out.println("TOAST: " + text);
        ((Activity)sContext).runOnUiThread(new Runnable() {
                public void run() {
                    Toast.makeText(sContext, text, Toast.LENGTH_LONG).show();
                }
            });
    }
}
