package com.tomei.musicpurin;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.database.sqlite.SQLiteStatement;
import java.util.ArrayList;
import java.util.List;

/*
 * FIXME -- IDs are never removed from the DB ... so if you have a huge music collection you may have
 * a problem.
 */
public class HistoryDB {
    protected SQLiteDatabase mDB;
    private static final String DATABASE_NAME = "history.db";
    private static final int DATABASE_VERSION = 1;
    private static final String MAIN_TABLE_NAME = "maintable";

    private SQLiteStatement mInsertMainStmt;
    private static final String INSERT_MAIN = "insert into " 
        + MAIN_TABLE_NAME + "(_id, seconds) values (?, ?)";

    private HistoryDB(Context context) {
        System.out.println("Opening HistoryDB");
        OpenHelper openHelper = new OpenHelper(context, DATABASE_NAME);
        mDB = openHelper.getWritableDatabase();
        mInsertMainStmt = mDB.compileStatement(INSERT_MAIN);
    }

    public synchronized void insertMain(int id, int seconds) {
        System.out.println("inserting id = " + id + ", seconds = " + seconds);
        mInsertMainStmt.bindLong(1, id);
        mInsertMainStmt.bindLong(2, seconds);

        mDB.beginTransaction();
        try {
            mDB.delete(MAIN_TABLE_NAME, "_id=" + id, null);
            mInsertMainStmt.executeInsert();
            mDB.setTransactionSuccessful();
        } finally {
            mDB.endTransaction();
        }
    }

    static String[] PROJECTION = {"seconds"};

    public synchronized int getSeconds(int id) {
        Cursor c =
            mDB.query(MAIN_TABLE_NAME, PROJECTION, "_id=" + id, null, null, null, null);
        try {
            if (c.getCount() > 0) {
                c.moveToFirst();
                return (int) c.getLong(0);
            } else {
                return 0;
            }
        } finally {
            if (c != null) {
                c.close();
            }
        }
    }

    private synchronized void close() {
        System.out.println("Closing HistoryDB");
        mDB.close();
    }

    private static HistoryDB sInstance;
    private static int sRefCount;

    public synchronized static HistoryDB obtain(Context context) {
        if (sInstance == null) {
            sInstance = new HistoryDB(context);
        }
        sRefCount ++;

        return sInstance;
    } 

    public synchronized static void release(HistoryDB db) {
        sRefCount --;
        if (sRefCount <= 0) {
            db.close();
            sInstance = null;
        }
    }

    private static class OpenHelper extends SQLiteOpenHelper {
        OpenHelper(Context context, String dbName) {
            super(context, dbName, null, DATABASE_VERSION);
        }

        @Override
        public void onCreate(SQLiteDatabase db) {
            db.execSQL("CREATE TABLE " + MAIN_TABLE_NAME + "(_id INTEGER PRIMARY KEY, seconds INTEGER)");
        }

        @Override
        public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
            db.execSQL("DROP TABLE IF EXISTS " + MAIN_TABLE_NAME);
            onCreate(db);
        }
    }
}
