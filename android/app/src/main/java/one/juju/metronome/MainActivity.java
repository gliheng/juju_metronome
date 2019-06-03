package one.juju.metronome;


import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterActivity {
  private static final int REQUEST_RECORD_AUDIO = 13;

  private static final String PITCH_DETECT_CHANNEL = "one.juju.metronome/pitch_detect";
  private static final String OSCILLOSCOPE_CHANNEL = "one.juju.metronome/oscilloscope";

  LineInAudioDispatcher dispatcher;
  PitchStreamHandler pitchStreamHandler;
  OscilloscopeStreamHandler oscilloscopeStreamHandler;

  AlertDialog requestPermissionDialog;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    dispatcher = new LineInAudioDispatcher(this);
    pitchStreamHandler = new PitchStreamHandler(this, dispatcher);
    oscilloscopeStreamHandler = new OscilloscopeStreamHandler(this, dispatcher);
    new EventChannel(getFlutterView(), PITCH_DETECT_CHANNEL).setStreamHandler(pitchStreamHandler);
    new EventChannel(getFlutterView(), OSCILLOSCOPE_CHANNEL).setStreamHandler(oscilloscopeStreamHandler);
    // dispatcher.startAudioThread();
  }

  @Override
  protected void onResume() {
    super.onResume();
    dispatcher.resume();
  }

  @Override
  protected void onPause() {
    super.onPause();
    dispatcher.stop();
  }

  // check if permission is satisfied, ask for it if not
  public boolean ensureMicrophonePermission() {
    if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
      requestMicrophonePermission();
      return false;
    } else {
      return true;
    }
  }

  public void requestMicrophonePermission() {
    if (ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.RECORD_AUDIO)) {
      if (requestPermissionDialog != null) return;
      // Show dialog explaining why we need record audio
      AlertDialog.Builder builder = new AlertDialog.Builder(this);
      builder.setMessage(R.string.needPermission);
      builder.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
        @Override
        public void onClick(DialogInterface dialog, int which) {
          ActivityCompat.requestPermissions(MainActivity.this, new String[] {
                  android.Manifest.permission.RECORD_AUDIO}, REQUEST_RECORD_AUDIO);
          requestPermissionDialog = null;
        }
      });
      builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
        @Override
        public void onClick(DialogInterface dialog, int which) {
          requestPermissionDialog = null;
        }
      });
      requestPermissionDialog = builder.create();
      requestPermissionDialog.show();
    } else {
      // In this case, user select never to ask for permission again
      // This function is disabled!
    }
  }

  @Override
  public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                         @NonNull int[] grantResults) {
    if (requestCode == REQUEST_RECORD_AUDIO) {
      if (grantResults.length > 0 &&
              grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          dispatcher.resume();
      } else {
        // requestMicrophonePermission();
      }
    }
  }
}
