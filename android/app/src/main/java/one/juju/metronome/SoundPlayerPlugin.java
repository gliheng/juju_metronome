package one.juju.metronome;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.AudioManager;
import android.media.SoundPool;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

class SoundPlayerPlugin implements MethodChannel.MethodCallHandler {
    private static final String CHANNEL_NAME = "one.juju.metronome/sound_player";

    /** Plugin registration. */
    public static void registerWith(PluginRegistry.Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(new SoundPlayerPlugin(registrar));
    }

    SoundPlayerPlugin(PluginRegistry.Registrar registrar) {
        this.registrar = registrar;
    }

    PluginRegistry.Registrar registrar;
    private SoundPool pool;
    private List<Integer> sounds;
    private List<AssetFileDescriptor> fds;
    private HashSet<Integer> loaded;

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.method.equals("load")) {
            load((ArrayList<String>)methodCall.arguments, result);
        } else if (methodCall.method.equals("play")) {
            play((Integer)methodCall.arguments);
            result.success(null);
        } else if (methodCall.method.equals("unload")) {
            unload();
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    void load(List<String> files, MethodChannel.Result result) {
        if (pool != null) {
            pool.release();
        }

        AssetManager assetManager = registrar.context().getAssets();
        pool = new SoundPool(10, AudioManager.STREAM_MUSIC, 100);
        pool.setOnLoadCompleteListener(new SoundPool.OnLoadCompleteListener() {
            @Override
            public void onLoadComplete(SoundPool soundPool, int sampleId, int status) {
                if (status == 0) {
                    loaded.add(sampleId);
                    if (loaded.size() == files.size()) {
                        // this notify flutter of complete loading
                        result.success(null);
                    }
                } else {
                    result.error("-1", String.format("soundpool sample load error: %d", sampleId), null);
                }
            }
        });
        sounds = new ArrayList<Integer>() {
            {
                for (int i = 0; i < files.size(); i++) {
                    add(null);
                }
            }
        };
        fds = new ArrayList<AssetFileDescriptor>() {
            {
                for (int i = 0; i < files.size(); i++) {
                    add(null);
                }
            }
        };
        loaded = new HashSet<>();


        for (int i = 0; i < files.size(); i++) {
            String key = registrar.lookupKeyForAsset(files.get(i));
            try {
                AssetFileDescriptor fd = assetManager.openFd(key);
                sounds.set(i, pool.load(fd, 1));
            } catch (IOException e) {
            }
        }
    }

    void unload() {
        if (pool == null) return;

        pool.release();

        for (int i = 0; i < fds.size(); i++) {
            try {
                AssetFileDescriptor fd = fds.get(i);
                if (fd != null) {
                    fd.close();
                }
            } catch (IOException e) {
            }
        }
    }

    void play(int i) {
        Integer id = sounds.get(i);
        if (id != null) {
            pool.play(id, 1f, 1f, 1, 0, 1f);
        }
    }
}