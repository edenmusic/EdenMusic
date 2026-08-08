package com.edenmusic.app;

import android.Manifest;
import android.content.pm.PackageManager;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.ValueCallback;
import android.webkit.WebView;
import android.webkit.WebChromeClient.FileChooserParams;
import android.content.Intent;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

    private static final int MEDIA_PERMISSION_REQUEST = 1001;
    private PermissionRequest pendingPermissionRequest;
    private ValueCallback<android.net.Uri[]> pendingFilePathCallback;

    @Override
    public void onCreate(android.os.Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        getBridge().getWebView().setWebChromeClient(new WebChromeClient() {
        
        public boolean onShowFileChooser(WebView webView, ValueCallback<android.net.Uri[]> filePathCallback, FileChooserParams fileChooserParams) {
        if (pendingFilePathCallback != null) {
            pendingFilePathCallback.onReceiveValue(null);
        }

        pendingFilePathCallback = filePathCallback;

        Intent intent = fileChooserParams.createIntent();
        try {
            startActivityForResult(intent, 2001);
        } catch (Exception e) {
            pendingFilePathCallback.onReceiveValue(null);
            pendingFilePathCallback = null;
            return false;
        }

        return true;
    }

            @Override
            public void onPermissionRequest(final PermissionRequest request) {
                runOnUiThread(() -> {
                    pendingPermissionRequest = request;

                    boolean cameraGranted =
                        ContextCompat.checkSelfPermission(MainActivity.this, Manifest.permission.CAMERA)
                            == PackageManager.PERMISSION_GRANTED;

                    boolean audioGranted =
                        ContextCompat.checkSelfPermission(MainActivity.this, Manifest.permission.RECORD_AUDIO)
                            == PackageManager.PERMISSION_GRANTED;

                    if (cameraGranted && audioGranted) {
                        request.grant(request.getResources());
                        pendingPermissionRequest = null;
                        return;
                    }

                    ActivityCompat.requestPermissions(
                        MainActivity.this,
                        new String[] {
                            Manifest.permission.CAMERA,
                            Manifest.permission.RECORD_AUDIO
                        },
                        MEDIA_PERMISSION_REQUEST
                    );
                });
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == 2001 && pendingFilePathCallback != null) {
            android.net.Uri[] results = null;
            if (resultCode == RESULT_OK && data != null) {
                results = FileChooserParams.parseResult(resultCode, data);
            }
            pendingFilePathCallback.onReceiveValue(results);
            pendingFilePathCallback = null;
        }
    }

    public void onRequestPermissionsResult(
        int requestCode,
        @NonNull String[] permissions,
        @NonNull int[] grantResults
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode != MEDIA_PERMISSION_REQUEST || pendingPermissionRequest == null) {
            return;
        }

        boolean cameraGranted =
            ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED;

        boolean audioGranted =
            ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
                == PackageManager.PERMISSION_GRANTED;

        if (cameraGranted && audioGranted) {
            pendingPermissionRequest.grant(pendingPermissionRequest.getResources());
        } else {
            pendingPermissionRequest.deny();
        }

        pendingPermissionRequest = null;
    }
}
