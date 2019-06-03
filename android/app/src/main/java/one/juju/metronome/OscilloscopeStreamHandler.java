package one.juju.metronome;

import android.app.Activity;

import java.lang.ref.WeakReference;

import be.tarsos.dsp.AudioEvent;
import be.tarsos.dsp.AudioProcessor;
import be.tarsos.dsp.Oscilloscope;
import io.flutter.plugin.common.EventChannel;

public class OscilloscopeStreamHandler implements EventChannel.StreamHandler, StreamProcessorHandler {
    private static final String LOG_TAG = OscilloscopeStreamHandler.class.getSimpleName();

    Activity activity;
    WeakReference<LineInAudioDispatcher> dispatcher;
    AudioProcessor processor;
    EventChannel.EventSink sink;

    OscilloscopeStreamHandler(Activity act, LineInAudioDispatcher d) {
        activity = act;
        dispatcher = new WeakReference<>(d);
        Oscilloscope.OscilloscopeEventHandler handler = new Oscilloscope.OscilloscopeEventHandler() {
            @Override
            public void handleEvent(float[] floats, AudioEvent audioEvent) {
                final double[] doubles = new double[floats.length];
                // convert to double array, flutter does not support passing float array
                for (int i = 0; i < floats.length; i++) {
                    doubles[i] = floats[i];
                }
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                    if (sink != null) {
                        sink.success(doubles);
                    }
                    }
                });
            }
        };
        processor = new Oscilloscope(handler);
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
