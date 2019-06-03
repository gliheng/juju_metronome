import 'package:audioplayers/audioplayers.dart';

typedef _ConfigCallback = void Function(int i, AudioPlayer player);

class AudioPlayerPool {
  Map<int, AudioPlayer> pool = {};
  _ConfigCallback configurator;

  AudioPlayerPool() {
    AudioPlayer.logEnabled = false;
  }

  AudioPlayer get(int key) {
    if (!pool.containsKey(key)) {
      var player = new AudioPlayer();
      if (configurator != null) {
        configurator(key, player);
      }
      pool[key] = player;
    }
    return pool[key];
  }

  setConfig(_ConfigCallback callback) {
    for (var entry in pool.entries) {
      callback(entry.key, entry.value);
    }
    configurator = callback;
  }

  void make(int n) {
    for (var i = 0; i < n; i++) {
      get(i);
    }
  }

  void dispose() {
    for (AudioPlayer player in pool.values) {
      player.release();
    }
  }
}