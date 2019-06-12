import 'package:flutter/services.dart';

class AudioPlayer {
  MethodChannel channel = new MethodChannel('one.juju.metronome/sound_player');

  load(List<String> files) async {
    await channel.invokeMethod('load', files);
  }
  play(int n) async {
    await channel.invokeMethod('play', n);
  }
  unload() async {
    await channel.invokeMethod('unload');
  }
}