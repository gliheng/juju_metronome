package one.juju.metronome;

import android.app.Activity;

import java.util.ArrayList;
import java.util.List;

import be.tarsos.dsp.AudioDispatcher;
import be.tarsos.dsp.io.android.AudioDispatcherFactory;


public class LineInAudioDispatcher {
    Activity activity;
    AudioDispatcher dispatcher;
    Thread audioThread;

    List<StreamProcessorHandler> handlers = new ArrayList<>();

    LineInAudioDispatcher(Activity act) {
        activity = act;
    }

    public void addHandler(StreamProcessorHandler handler) {
        startAudioThread();
        handlers.add(handler);
        if (dispatcher != null) {
            dispatcher.addAudioProcessor(handler.getProcessor());
        }
    }

    public void removeHandler(StreamProcessorHandler handler) {
        handlers.remove(handler);
        if (dispatcher != null) {
            dispatcher.removeAudioProcessor(handler.getProcessor());
        }
        // stop audio thread if not used
        if (handlers.size() == 0) {
            stop();
        }
    }

    public void startAudioThread() {
        if (!((MainActivity) activity).ensureMicrophonePermission()) {
            return;
        }
        if (audioThread != null) return;

        dispatcher = AudioDispatcherFactory.fromDefaultMicrophone(22050, 1024, 0);
        audioThread = new Thread(dispatcher, "Audio Capture");
        audioThread.start();
    }

    public void resume() {
        if (this.handlers.size() == 0) return;

        startAudioThread();
        if (audioThread != null) {
            for (int i = 0; i < handlers.size(); i++) {
                dispatcher.addAudioProcessor(handlers.get(i).getProcessor());
            }
        }
    }

    public void stop() {
        if (audioThread != null) {
            dispatcher.stop();
            dispatcher = null;
            audioThread = null;
        }
    }
}
