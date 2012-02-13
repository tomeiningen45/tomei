
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
            t.printStackTrace();
            cleanUpServerConnection();
        }
        return mSockDataInputStream;
    }

    class Song {
        long mSize;
        String mHostPath;
        String mLocalPath;
        String mFileDate;

        Song(long size, String hostPath, String fileDate) {
            mHostPath = hostPath;
            mSize = size;
            mLocalPath = mMediaRoot + hostPath;
            mFileDate = fileDate;
        }

        int compare(Song rhs) {
            return mFileDate.compareTo(rhs.mFileDate);
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
                String fileDate = in.readUTF();
                if (s == null || s.equals(WifiServer.INFO_END_FILES)) {
                    break;
                }
                Song song = new Song(size, s, fileDate);
                list.add(song);
            }
        } catch (Throwable t) {
            t.printStackTrace();
            cleanUpServerConnection();
        }

        Collections.sort(list, new Comparator<Song>() {
                public int compare(Song lhs, Song rhs) {
                    return lhs.compare(rhs); // sort ascending (oldest first)
                }
            });
 
        return list;
    }

    private void getFile(Song s, Notifier notifier, int numSongDownloaded, long allSongsDownloaded) throws IOException {
        FileOutputStream out = null;
        byte buf[] = new byte[4096];

        notifier.notifyOneSongStart(s.mLocalPath, s.mSize);

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
                allSongsDownloaded += n;
                notifier.notifyOneSongProgress(numSongDownloaded, s.mSize, downloaded, allSongsDownloaded);
            }
            System.out.println("Expect: " + s.mSize + ", saved = " + downloaded);
        } finally {
            Utils.close(out);
        }
    }


    private void test() throws IOException {
        sync(new Notifier());
    }

    public void sync(Notifier notifier) throws IOException {
        ArrayList<Song> list = readAllSyncableFiles();
        ArrayList<Song> todownload = new ArrayList<Song>();

        long totalBytes = 0;

        for (Song song : list) {
            //System.out.println("SYNCABLE: [" + song.mSize + "] "+ song.mLocalPath);
            File f = new File(song.mLocalPath);
            if (!f.exists() || f.length() != song.mSize) {
                todownload.add(song);
                totalBytes += song.mSize;
            }
        }

        if (todownload.size() <= 0) {
            notifier.notify("Nothing to sync - checked " + list.size() + " songs");
            return;
        }

        notifier.notify("Downloading " + todownload.size() + " songs");
        notifier.notifyTotal(todownload.size(), totalBytes);

        int numSongDownloaded = 0;
        long allSongsDownloaded = 0;

        for (Song song : todownload) {
            System.out.println("Syncing: [" + song.mSize + "] "+ song.mLocalPath);
            getFile(song, notifier, numSongDownloaded, allSongsDownloaded);
            numSongDownloaded ++;
            allSongsDownloaded += song.mSize;
        }

        //if (list.size() > 0) {
        //    Song s = list.get(0);
        //    getFile(s);
        //}
    }

    public static class Notifier {
        public void notifyTotal(int numToSync, long totalBytes) {

        }

        public void notifyOneSongProgress(int numSongDownloaded, long thisSongTotal, long thisSongDownloaded, long allSongsDownloaded) {

        }
        public void notifyOneSongStart(String localFilePath, long thisSongTotal) {

        }
        public void notify(String s) {

        }
    }
}
