package one.juju.metronome;

import android.app.Activity;

import java.lang.ref.WeakReference;

import be.tarsos.dsp.AudioProcessor;
import be.tarsos.dsp.AudioEvent;
import be.tarsos.dsp.pitch.PitchDetectionHandler;
import be.tarsos.dsp.pitch.PitchDetectionResult;
import be.tarsos.dsp.pitch.PitchProcessor;
import io.flutter.plugin.common.EventChannel;

public class PitchStreamHandler implements EventChannel.StreamHandler, StreamProcessorHandler {
  private static final String LOG_TAG = PitchStreamHandler.class.getSimpleName();

  Activity activity;
  WeakReference<LineInAudioDispatcher> dispatcher;
  AudioProcessor processor;
  EventChannel.EventSink sink;

  PitchStreamHandler(Activity act, LineInAudioDispatcher p) {
    activity = act;
    dispatcher = new WeakReference<>(p);
    PitchDetectionHandler handler = new PitchDetectionHandler() {
      @Override
      public void handlePitch(PitchDetectionResult ret, AudioEvent e) {
      final double[] data = {
              ret.getPitch(), ret.getProbability()
      };

      activity.runOnUiThread(new Runnable() {
        @Override
        public void run() {
        // eventSink.error("UNAVAILABLE", "Charging status unavailable", null);
        // eventSink.success("charging");
        if (sink != null) {
          sink.success(data);
        }
        }
      });
      }
    };
    processor = new PitchProcessor(PitchProcessor.PitchEstimationAlgorithm.FFT_YIN, 22050, 1024, handler);
  }

  @Override
  public void onListen(Object o, final EventChannel.EventSink eventSink) {
    sink = eventSink;
    LineInAudioDispatcher d = dispatcher.get();
    if (d != null) {
      d.addHandler(this);
    }
  }

  @Override
  public void onCancel(Object o) {
    sink = null;
    LineInAudioDispatcher d = dispatcher.get();
    if (d != null) {
      d.removeHandler(this);
    }
  }

  @Override
  public AudioProcessor getProcessor() {
    return processor;
  }
}
