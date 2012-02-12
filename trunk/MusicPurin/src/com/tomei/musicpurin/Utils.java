
package com.tomei.musicpurin;

import java.io.DataInput;
import java.io.DataOutputStream;
import java.io.DataInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import java.util.ArrayList;
import java.net.Socket;
import java.net.ServerSocket;

public class Utils {
    static void close(ServerSocket obj) {
        try {
            obj.close();
        } catch (Throwable t) {}
    }
    static void close(Socket obj) {
        try {
            obj.close();
        } catch (Throwable t) {}
    }
    static void close(InputStream obj) {
        try {
            obj.close();
        } catch (Throwable t) {}
    }
    static void close(OutputStream obj) {
        try {
            obj.close();
        } catch (Throwable t) {}
    }
    static void close(DataInputStream obj) {
        try {
            obj.close();
        } catch (Throwable t) {}
    }
    static void close(DataOutputStream obj) {
        try {
            obj.close();
        } catch (Throwable t) {}
    }
}