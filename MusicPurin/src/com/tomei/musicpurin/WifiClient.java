
package com.tomei.musicpurin;

import java.io.*;
import java.net.*;
import java.util.*;


public class WifiClient {
    public static void main(String args[]) {//used for testing purpose
        WifiClient client = new WifiClient(args[0], args[1]);
        try {
            client.test();
        } catch (Throwable t) {;}
    }

    public WifiClient(String host, String mediaRoot) {
        mHost = host;
        mMediaRoot = mediaRoot;
    }

    private String mHost;
    private String mMediaRoot;
    private Socket mSock;
    private DataInputStream mSockDataInputStream;
    private DataOutputStream mSockDataOutputStream;

    private void cleanUpServerConnection() {
        Utils.close(mSockDataOutputStream);
        Utils.close(mSockDataInputStream);
        Utils.close(mSock);
    }

    private DataInputStream askServer(String command) throws IOException {
        if (mSock != null) {
            cleanUpServerConnection();
        }

        try {
            mSock = new Socket(mHost, WifiServer.PORT);
            mSockDataInputStream = new DataInputStream(mSock.getInputStream());
            mSockDataOutputStream = new DataOutputStream(mSock.getOutputStream());
            mSockDataOutputStream.writeUTF(command);
        } catch (Throwable t) {
            cleanUpServerConnection();
        }
        return mSockDataInputStream;
    }

    class Song {
        long mSize;
        String mHostPath;
        String mLocalPath;

        Song(long size, String hostPath) {
            mHostPath = hostPath;
            mSize = size;
            mLocalPath = mMediaRoot + hostPath;
        }
    }

    private ArrayList<Song> readAllSyncableFiles() {
        DataInputStream in;
        ArrayList<Song> list = new ArrayList<Song>();

        try {
            in = askServer(WifiServer.CMD_LIST_SYNCABLE_FILES);
            while (true) {
                long size = in.readLong();
                String s = in.readUTF();
                if (s == null || s.equals(WifiServer.INFO_END_FILES)) {
                    break;
                }
                Song song = new Song(size, s);
                list.add(song);
            }
        } catch (Throwable t) {
            cleanUpServerConnection();
        }
        return list;
    }

    private void getFile(Song s) throws IOException {
        FileOutputStream out = null;
        byte buf[] = new byte[4096];

        try {
            DataInputStream in = askServer(WifiServer.CMD_GET_FILE);
            mSockDataOutputStream.writeUTF(s.mHostPath);

            File f = new File(s.mLocalPath);
            f.getParentFile().mkdirs();
            out = new FileOutputStream(f);
            int downloaded = 0;
            while (true) {
                int n = in.read(buf);
                if (n < 0) {
                    break;
                }
                out.write(buf, 0, n);
                downloaded += n;
            }
            System.out.println("Expect: " + s.mSize + ", saved = " + downloaded);
        } finally {
            Utils.close(out);
        }
    }


    public void test() throws IOException {
        ArrayList<Song> list = readAllSyncableFiles();
        for (Song song : list) {
            System.out.println("SYNCABLE: [" + song.mSize + "] "+ song.mLocalPath);
            File f = new File(song.mLocalPath);
            if (!f.exists() || f.length() != song.mSize) {
                getFile(song);
            }
        }

        if (list.size() > 0) {
            Song s = list.get(0);
            getFile(s);
        }
    }
}
