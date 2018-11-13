package com.nedb;

import android.net.Uri;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class NeDBManager extends ReactContextBaseJavaModule {

    static private String private_header_path = "nedb";
    private ReactApplicationContext reactContext;

    public NeDBManager(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "NeDBManager";
    }

    @ReactMethod
    public void exists(String filepath, Promise promise) {
        try {
            File file = new File(getPrivatePath(filepath));
            promise.resolve(file.exists());
        } catch (Exception ex) {
            ex.printStackTrace();
            reject(promise, getPrivatePath(filepath), ex);
        }
    }

    @ReactMethod
    public void writeFile(String filepath, String contents, ReadableMap options, Promise promise) {
        try {
            byte[] bytes = contents.getBytes("utf-8");

            OutputStream outputStream = getOutputStream(getPrivatePath(filepath), false);
            outputStream.write(bytes);
            outputStream.close();

            promise.resolve(null);
        } catch (Exception ex) {
            ex.printStackTrace();
            reject(promise, getPrivatePath(filepath), ex);
        }
    }

    @ReactMethod
    public void unlink(String filepath, Promise promise) {
        try {
            File file = new File(getPrivatePath(filepath));

            if (!file.exists()) throw new Exception("File does not exist");

            DeleteRecursive(file);

            promise.resolve(null);
        } catch (Exception ex) {
            ex.printStackTrace();
            reject(promise, getPrivatePath(filepath), ex);
        }
    }

    @ReactMethod
    public void appendFile(String filepath, String contents, Promise promise) {
        try {
            byte[] bytes = contents.getBytes("utf-8");

            OutputStream outputStream = getOutputStream(getPrivatePath(filepath), true);
            outputStream.write(bytes);
            outputStream.close();

            promise.resolve(null);
        } catch (Exception ex) {
            ex.printStackTrace();
            reject(promise, getPrivatePath(filepath), ex);
        }
    }

    @ReactMethod
    public void readFile(String filepath, Promise promise) {
        try {
            InputStream inputStream = getInputStream(getPrivatePath(filepath));
            byte[] inputData = getInputStreamBytes(inputStream);
            String contents = new String(inputData);

            promise.resolve(contents);
        } catch (Exception ex) {
            ex.printStackTrace();
            reject(promise, getPrivatePath(filepath), ex);
        }
    }

    @ReactMethod
    public void mkdir(String filepath, ReadableMap options, Promise promise) {
        try {
            File file = new File(getPrivatePath(filepath));

            file.mkdirs();

            boolean exists = file.exists();

            if (!exists) throw new Exception("Directory could not be created");

            promise.resolve(null);
        } catch (Exception ex) {
            ex.printStackTrace();
            reject(promise, getPrivatePath(filepath), ex);
        }
    }

    @ReactMethod
    public void rename(String filepath, String destPath, ReadableMap options, Promise promise) {
        try {
            File inFile = new File(getPrivatePath(filepath));

            if (!inFile.renameTo(new File(getPrivatePath(destPath)))) {
                copyFile(getPrivatePath(filepath), destPath);

                inFile.delete();
            }

            promise.resolve(true);
        } catch (Exception ex) {
            ex.printStackTrace();
            reject(promise, getPrivatePath(filepath), ex);
        }
    }



    private void copyFile(String filepath, String destPath) throws IOException, IORejectionException {
        InputStream in = getInputStream(filepath);
        OutputStream out = getOutputStream(destPath, false);

        byte[] buffer = new byte[1024];
        int length;
        while ((length = in.read(buffer)) > 0) {
            out.write(buffer, 0, length);
        }
        in.close();
        out.close();
    }

    private static byte[] getInputStreamBytes(InputStream inputStream) throws IOException {
        byte[] bytesResult;
        ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();
        int bufferSize = 1024;
        byte[] buffer = new byte[bufferSize];
        try {
            int len;
            while ((len = inputStream.read(buffer)) != -1) {
                byteBuffer.write(buffer, 0, len);
            }
            bytesResult = byteBuffer.toByteArray();
        } finally {
            try {
                byteBuffer.close();
            } catch (IOException ignored) {
            }
        }
        return bytesResult;
    }

    private InputStream getInputStream(String filepath) throws IORejectionException {
        Uri uri = getFileUri(filepath);
        InputStream stream;
        try {
            stream = reactContext.getContentResolver().openInputStream(uri);
        } catch (FileNotFoundException ex) {
            throw new IORejectionException("ENOENT", "ENOENT: no such file or directory, open '" + filepath + "'");
        }
        if (stream == null) {
            throw new IORejectionException("ENOENT", "ENOENT: could not open an input stream for '" + filepath + "'");
        }
        return stream;
    }

    private void reject(Promise promise, String filepath, Exception ex) {
        if (ex instanceof FileNotFoundException) {
            rejectFileNotFound(promise, filepath);
            return;
        }
        if (ex instanceof IORejectionException) {
            IORejectionException ioRejectionException = (IORejectionException) ex;
            promise.reject(ioRejectionException.getCode(), ioRejectionException.getMessage());
            return;
        }

        promise.reject(null, ex.getMessage());
    }

    private void rejectFileNotFound(Promise promise, String filepath) {
        promise.reject("ENOENT", "ENOENT: no such file or directory, open '" + filepath + "'");
    }

    private OutputStream getOutputStream(String filepath, boolean append) throws IORejectionException {
        Uri uri = getFileUri(filepath);
        OutputStream stream;
        try {
            stream = reactContext.getContentResolver().openOutputStream(uri, append ? "wa" : "w");
        } catch (FileNotFoundException ex) {
            throw new IORejectionException("ENOENT", "ENOENT: no such file or directory, open '" + filepath + "'");
        }
        if (stream == null) {
            throw new IORejectionException("ENOENT", "ENOENT: could not open an output stream for '" + filepath + "'");
        }
        return stream;
    }

    private Uri getFileUri(String filepath) throws IORejectionException {
        Uri uri = Uri.parse(filepath);
        if (uri.getScheme() == null) {
            // No prefix, assuming that provided path is absolute path to file
            File file = new File(filepath);
            if (file.isDirectory()) {
                throw new IORejectionException("EISDIR", "EISDIR: illegal operation on a directory, read '" + filepath + "'");
            }
            uri = Uri.parse("file://" + filepath);
        }
        return uri;
    }

    private void DeleteRecursive(File fileOrDirectory) {
        if (fileOrDirectory.isDirectory()) {
            for (File child : fileOrDirectory.listFiles()) {
                DeleteRecursive(child);
            }
        }

        fileOrDirectory.delete();
    }

    private String getPrivatePath(String path) {
        String docPath = this.getReactApplicationContext().getFilesDir().getAbsolutePath() + '/' + private_header_path + '/' + path;
        return docPath;
    }
}
