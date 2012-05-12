
package com.tomei.musicpurin;

import java.io.*;
import java.net.*;
import java.util.*;


public class WifiClient {
    public static void main(String args[]) {//used for testing purpose
        WifiClient client = new WifiClient(args[0], args[1]);
        try {
            if ("test1".equals(args[2])) {
                client.test1();
            } else {
                client.test2();
            }
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

    class PlayList {
        String mName;
        ArrayList<String> mSongNames;

        PlayList(String name) {
            mName = name;
            mSongNames = new ArrayList<String>();
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

    private void test1() throws IOException {
        sync(new Notifier());
    }

    private void test2() throws IOException {
        ArrayList<PlayList> lists = getPlayLists();
        for (PlayList list : lists) {
            System.out.println(list.mName + "=============================");
            for (String localPath: list.mSongNames) {
                System.out.println(list.mName + " +> " + localPath);
            }
        }
    }

    HashMap<String, String> mFilesInRootMap;

    private void findAllFilesInRoot() {
        mFilesInRootMap = new HashMap();
        File dir = new File(mMediaRoot);
        findAllFiles(dir);
    }

    private void findAllFiles(File dir) {
        String children[] = dir.list();
        for (String child : children) {
            File f = new File(dir, child);
            if (f.isDirectory()) {
                findAllFiles(f);
            } else {
                String s = f.getPath();
                mFilesInRootMap.put(s, s);
            }
        }
    }

    private void deleteUnneededFiles(Notifier notifier) {
        int del = 0;
        for (String file : mFilesInRootMap.keySet()) {
            System.out.println("NOT NEEDED: " + file);
            (new File(file)).delete();
            del ++;
        }
        notifier.notify("Deleted " + del + " files");
    }

    public void sync(Notifier notifier) throws IOException {
        ArrayList<Song> list = readAllSyncableFiles();
        ArrayList<Song> todownload = new ArrayList<Song>();

        long totalBytes = 0;

        findAllFilesInRoot();

        for (Song song : list) {
            //System.out.println("SYNCABLE: [" + song.mSize + "] "+ song.mLocalPath);
            File f = new File(song.mLocalPath);
            if (!f.exists() || f.length() != song.mSize) {
                todownload.add(song);
                totalBytes += song.mSize;
            }
            mFilesInRootMap.remove(song.mLocalPath);
        }

        if (list.size() > 0) {
            deleteUnneededFiles(notifier);
        } else {
            // probably because connection to server failed.
        }

        if (todownload.size() <= 0) {
            notifier.notify("Nothing to sync - checked " + list.size() + " songs");
            return;
        }

        notifier.notify("Downloading " + todownload.size() + " songs : " + (totalBytes/1024) + " KB");
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

    public ArrayList<PlayList> getPlayLists() {
        ArrayList<PlayList> lists = new ArrayList<PlayList>();

        DataInputStream in;

        try {
            in = askServer(WifiServer.CMD_GET_PLAYLISTS);
            while (true) {
                String name = in.readUTF();
                if (name == null || name.equals(WifiServer.INFO_END_FILES)) {
                    break;
                }
                PlayList list = new PlayList(name);
                while (true) {
                    String songName = in.readUTF();
                    if (songName == null || songName.equals(WifiServer.INFO_END_LIST)) {
                        break;
                    }
                    list.mSongNames.add(mMediaRoot + songName);
                }
                lists.add(list);
            }
        } catch (Throwable t) {
            t.printStackTrace();
            cleanUpServerConnection();
        }
        return lists;
    }

    public static class Notifier {
        public void notifyTotal(int numToSync, long totalBytes) {
            System.out.println("Need to sync: " + numToSync + " songs for " + totalBytes + " bytes");
        }

        public void notifyOneSongProgress(int numSongDownloaded, long thisSongTotal, long thisSongDownloaded, long allSongsDownloaded) {

        }
        public void notifyOneSongStart(String localFilePath, long thisSongTotal) {

        }
        public void notify(String s) {

        }
    }
}
