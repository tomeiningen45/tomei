
package com.tomei.musicpurin;

import java.io.*;
import java.net.*;
import java.util.*;


public class WifiServer {
    public static final String CMD_LIST_SYNCABLE_FILES = "ListSyncableFiles";

    public static final String INFO_END_FILES = ":://info/EndFiles";

    public static final int PORT = 3938;

    private static String mITunesRoot;
    private static long mLastLoadTime;
    private static ArrayList mSongs;

    public static void main(String args[]) {
        //Locale.setDefault(new Locale("en_US", "UTF8")
        //System.out.println(Locale.getDefault()); 
        mITunesRoot = args[0];
        loadLib();
        test1();
    }

    private static void test1() {
        // print latest 30 songs

    }

    private static void loadLib() {
        File file = new File(mITunesRoot + "/iTunes Music Library.xml");
        long modtime = file.lastModified();
        if (mLastLoadTime >= modtime) {
            return;
        }
        mSongs = new ArrayList();
        mLastLoadTime = modtime;
        FileInputStream in = null;
        BufferedReader reader = null;
        int count = 0;
        long start = now();

        try {
            in = new FileInputStream(file);
            reader = new BufferedReader(new InputStreamReader(in, "UTF-8"));

            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                int songNum = -1000;
                if ((songNum = isSongStart(line)) > -1000)  {
                    //System.out.println(line + "=" + songNum);
                    loadOneSong(reader, songNum);
                }
                count ++;
            }
        } catch (Throwable t) {
            t.printStackTrace();
        } finally {
            Utils.close(in);
        }

        System.out.println("Loaded " + count + " lines in " + (now() - start) + " ms, " + mSongs.size() + " songs");
    }

    static class Song {
        int mID;
        String mGenre;
        String mKind;
        long mSize;
        long mTotalTime;
        String mDateMod;
        String mDateAdded;
        String mDateRelease;
        String mPersistentID;
        String mTrackType;
        boolean mIsPodcast;
        String mLocation;
        String mComments;

        Song() {
            mSize = -1;
            mTotalTime = -1;
            mID = -1000;
        }
    }

    private static int isSongStart(String line) {
        if (!line.startsWith("<key>")) {
            return -1000;
        }
        if (!line.endsWith("</key>")) {
            return -1000;
        }
        line = line.substring(5);
        line = line.substring(0, line.length() - 6);
        try {
            return Integer.parseInt(line);
        } catch (Throwable t) {
            return -1000;
        }
    }

    private static String mTempKey;
    private static String mTempString;

    private static void loadOneSong(BufferedReader reader, int id) throws IOException {
        String line = reader.readLine();
        if (line == null) {
            return;
        }
        if (!line.trim().equals("<dict>")) {
            return;
        }
        Song song = new Song();
        song.mID = id;
        while ((line = reader.readLine()) != null) {
            line = line.trim();
            if (line.equals("</dict>")) {
                break;
            }
            song.mGenre        = check(line, song.mGenre,        "<key>Genre</key><string>", "</string>");
            song.mKind         = check(line, song.mKind,         "<key>Kind</key><string>", "</string>");
            song.mSize         = check(line, song.mSize,         "<key>Size</key><integer>", "</integer>");
            song.mTotalTime    = check(line, song.mTotalTime,    "<key>TotalTime</key><integer>", "</integer>");
            song.mDateMod      = check(line, song.mDateMod,      "<key>Date Modified</key><date>", "</date>");
            song.mDateAdded    = check(line, song.mDateAdded,    "<key>Date Added</key><date>", "</date>");
            song.mDateRelease  = check(line, song.mDateRelease,  "<key>Release Date</key><date>", "</date>");
            song.mPersistentID = check(line, song.mPersistentID, "<key>Persistent ID</key><string>", "</string>");
            song.mTrackType    = check(line, song.mTrackType,    "<key>Track Type</key><string>", "</string>");
            song.mIsPodcast    = check(line, song.mIsPodcast,    "<key>Podcast</key>", "<true/>");
            song.mLocation     = check(line, song.mLocation,     "<key>Location</key><string>", "</string>");
            song.mComments     = check(line, song.mComments,     "<key>Comments</key><string>", "</string>");
        }
        
        if (song.mLocation != null && song.mIsPodcast) {
            String s;
            //s = "/Volumes/USB/Music/Bonchicast/051202-tin25000-kudotin_vol7_051117.mp3";
            //s = "/Users/ioilam/Music/iTunes/iTunes Media/Podcasts/NHKラシオニュース";
            s = song.mLocation;
            if ((new File(s)).exists()) {
                mSongs.add(song);
            } else {
                System.out.println("missing = " + s);
            }
        }

        //System.out.println("siz = " + song.mSize);
        //System.out.println("pod = " + song.mIsPodcast);
        //System.out.println("loc = " + song.mLocation);
    }

    private static String check(String line, String def, String prefix, String suffix) {
        if (!line.startsWith(prefix)) {
            return def;
        }
        if (!line.endsWith(suffix)) {
            return def;
        }
        line = line.substring(prefix.length());
        line = line.substring(0, line.length() - suffix.length());

        if (line.indexOf('%') >= 0 || line.indexOf('&') >= 0) {
            line = unescape(line);
        }

        if (line.startsWith("file://localhost/")) {
            line = line.substring("file://localhost/".length() - 1);
        }

        return line;
    }

    private static String unescape(String s) {
        if (true) {
            s = s.replaceAll("[+]", "@@ADD@@");
            s = s.replace("&#38;", "&");
            try {
                s = URLDecoder.decode(s);
            } catch (Throwable t) {
                //System.out.println("DECODE: " + s);
            }
            s = s.replaceAll("@@ADD@@", "+");
            return s;
        }

        StringBuffer sbuf = new StringBuffer();
        int i, length = s.length();
        for (i=0; i<length; i++) {
            char c0 = s.charAt(i);
            if (c0 == '%' && i <= length - 6) {
                char c1 = s.charAt(i+1);
                char c2 = s.charAt(i+2);
                char c3 = s.charAt(i+3);
                char c4 = s.charAt(i+4);
                char c5 = s.charAt(i+5);

                if ((c3 == '%') &&
                    (('0' <= c1 && c1 <= '9') || ('A' <= c1 && c1 <= 'F')) &&
                    (('0' <= c2 && c2 <= '9') || ('A' <= c2 && c2 <= 'F')) &&
                    (('0' <= c4 && c4 <= '9') || ('A' <= c4 && c4 <= 'F')) &&
                    (('0' <= c5 && c5 <= '9') || ('A' <= c5 && c5 <= 'F'))) {
                    try {
                        char c = (char)(Integer.parseInt("0x" + c1 + c2 + c4 + c5));
                        i+= 5;
                        sbuf.append(c);
                        continue;
                    } catch (Throwable t) {/*should not reach*/}
                }
            }
            sbuf.append(c0);
        }
        return sbuf.toString();
    }

    private static long check(String line, long def, String prefix, String suffix) {
        if ((line = check(line, null, prefix, suffix)) == null) {
            return def;
        }
        try {
            return Long.parseLong(line);
        } catch (Throwable t) {
            return def;
        }
    }

    private static boolean check(String line, boolean def, String prefix, String suffix) {
        if ((line = check(line, null, prefix, suffix)) == null) {
            return def;
        }
        return true;
    }

    private static long now() {
        return System.currentTimeMillis();
    }

    private void uploadFile(InputStream in, int total, int checksum, String fileName) throws IOException {
        FileOutputStream out = null;
        byte buf[] = new byte[4096];

        try {
            out = new FileOutputStream(fileName);
            int downloaded = 0;
            while (downloaded < total) {
                int toread = total - downloaded;
                if (toread > buf.length) {
                    toread = buf.length;
                }
                int n = in.read(buf, 0, toread);
                if (n < 0) {
                    break;
                }
                out.write(buf, 0, n);
                downloaded += n;
            }
        } finally {
            if (out != null) {
                out.close();
            }
        }
    }
}
