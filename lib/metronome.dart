import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;
import 'package:scoped_model/scoped_model.dart';
import 'app_icons.dart';
import 'asset_cache.dart';
import 'radial_slider.dart';
import 'tempo_graph.dart';
import 'audio_players.dart';
import 'tempo_bottom_sheet.dart';
import 'intl.dart';
import 'model.dart';

const MIN_TEMPO = 30;
const MAX_TEMPO = 240;
const MIN_ANGLE = - math.pi * 0.5;
const MAX_ANGLE = math.pi * 6.5;
const SAMPLE_DIR = 'assets/samples';
const PRESET_SOUNDS = [
  { 'high': 'metronome-high.mp3', 'low': 'metronome-low.mp3' },
  { 'high': 'robot-high.mp3', 'low': 'robot-low.mp3' },
  { 'high': 'tick-high.mp3', 'low': 'tick-low.mp3' },
  { 'high': 'conga-high.mp3', 'low': 'conga-low.mp3' },
  { 'high': 'kit-tom.mp3', 'low': 'kit-snare.mp3' },
];

enum MetronomeState {
  PLAYING, STOPPED,
}

class Metronome extends StatefulWidget {
  Metronome();

  @override
  _MetronomeState createState() => _MetronomeState();
}

class _MetronomeState extends State<Metronome> {
  MetronomeState playerState = MetronomeState.STOPPED;

  // time signature
  int timeSig = 4;
  int timeSigBase = 4;
  // sound effect index
  int soundEffectIdx = 0;
  // in bpm unit
  int tempo = 90;
  // current beat
  int beat = 0;

  GlobalKey tempoBottomSheetKey = GlobalKey(debugLabel: 'TempoBottomSheetKey');

  // move files from assets to doc
  AssetCache assetCache = AssetCache();

  AudioPlayerPool players = new AudioPlayerPool();
  Timer timer;

  /// how long a tick takes in millisecs
  int get beatTime {
    return  (60 * 1000 / tempo * 4 / timeSigBase).floor();
  }

  String get _tempoLabel {
    if (tempo < 40) return 'Grave';
    if (tempo < 60) return 'Largo';
    if (tempo < 76) return 'Adagio';
    if (tempo < 66) return 'Larghetto';
    if (tempo < 92) return 'Andante';
    if (tempo < 112) return 'Andante Moderato';
    if (tempo < 116) return 'Allegretto';
    if (tempo < 120) return 'Allegro Moderato';
    if (tempo < 156) return 'Allegro';
    if (tempo < 172) return 'Vivace';
    if (tempo < 200) return 'Presto';
    return 'Prestissimo';
  }

  @override
  void dispose() {
    players.dispose();
    super.dispose();
  }

  void _play() async {
    if (playerState == MetronomeState.PLAYING) {
      _stop();
    } else {
      await _prepareResource();
      _start();
    }

    setState(() {
      if (playerState == MetronomeState.PLAYING) {
        playerState = MetronomeState.STOPPED;
      } else {
        playerState = MetronomeState.PLAYING;
      }
    });
  }

  void _start() async {
    if (timer != null) {
      timer.cancel();
    }

    timer = Timer(Duration(milliseconds: beatTime), _onTick);
  }

  void _stop() async {
    // no need to stop audioplayer, since we're playing all short notes
    // players.stopAll();
  
    if (timer != null) {
      timer.cancel();
    }

    setState(() {
      beat = 0;
    });
  }

  void _switchSoundEffect() async {
    setState(() {
      soundEffectIdx = (soundEffectIdx + 1) % PRESET_SOUNDS.length;
    });
    await _prepareResource();

    // if it is stopped, play a beat to get a preview of the sample
    if (playerState == MetronomeState.STOPPED) {
      players.get(0).resume();
    }
  }

  Map<String, String> get currentSoundEffect {
    return PRESET_SOUNDS[soundEffectIdx];
  }
  /// put assets from bundle under documents directory, so that audioplayer can read it
  Future<void> _prepareResource() async {
    var fx = currentSoundEffect;
    var files = [
      path.join(SAMPLE_DIR, fx['high']),
      path.join(SAMPLE_DIR, fx['low']),
    ];
    var f = await assetCache.prepareAssets(files);
    
    players
      ..setConfig((i, player) {
        player.setReleaseMode(ReleaseMode.STOP);
        // index 0 is high sound, index 1 is low sound
        player.setUrl(i == 0 ? f[0] : f[1], isLocal: true);
      })
      ..make(2);
  }

  void _onTick() {
    setState(() {
      beat += 1;

      var i = (beat - 1) % timeSig;
      
      AudioPlayer player = players.get(i == 0 ? 0 : 1);
      if (player == null) {
        // player is not ready
        return;
      }
      player.seek(Duration(seconds: 0));
      player.resume();
    });

    timer = Timer(Duration(milliseconds: beatTime), _onTick);
  }

  void _onSetTempo(double v) {
    setState(() {
      tempo = _angle2Tempo(v);
    });
  }

  int _angle2Tempo(double v) {
    return ((MAX_TEMPO - MIN_TEMPO) * (v - MIN_ANGLE) / (MAX_ANGLE - MIN_ANGLE) + MIN_TEMPO).round();
  }

  double _tempo2Angle(int v) {
    return (v - MIN_TEMPO) * (MAX_ANGLE - MIN_ANGLE) / (MAX_TEMPO - MIN_TEMPO) + MIN_ANGLE;
  }
 
  _configTempo() async {
    await showModalBottomSheet<List<int>>(
      context: context, builder: _buildTempoSettings
    );

    // I get the state from bottomsheet using GlobalKey, can I use Navigator?
    setState(() {
      TempoBottomSheetState sheetState = tempoBottomSheetKey.currentState;
      timeSig = sheetState.timeSig;
      timeSigBase = sheetState.timeSigBase;
    });
  }

  Widget _buildTempoSettings(BuildContext context) {
    return TempoBottomSheet(
      key: tempoBottomSheetKey,
      timeSig: timeSig, timeSigBase: timeSigBase,
      onConfig: (int _timeSig, int _timeSigBase) {
        setState(() {
          timeSig = _timeSig;
          timeSigBase = _timeSigBase;
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) {
        ThemeData theme = model.theme;

        List<Color> colors;
        List<double> stops;
        if (theme.brightness == Brightness.dark) {
          colors = <Color>[Colors.transparent, Colors.white10, Colors.white30, Colors.white70];
          stops = [0.5, 0.8, 0.93, 1.0];
        } else {
          colors = <Color>[Colors.transparent, Colors.black12, Colors.black26, Colors.black38];
          stops = [0.5, 0.8, 0.93, 1.0];
        }

        return Material(
          color: Colors.transparent,
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.music_note, size: 14.0,),
                              Text('$timeSig/$timeSigBase'),
                            ],
                          ),
                        ),
                        Text(tempo.toString(), style: TextStyle(fontSize: 50.0)),
                        Text(_tempoLabel.toString()),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.volume_up, size: 14.0,),
                              Text('${soundEffectIdx + 1}'),
                            ],
                          ),
                        ),
                      ],
                    )),
                    Container(
                      child: Stack(
                          children: <Widget>[
                            TempoGraph(beat: beat, timeSig: timeSig, beatTime: beatTime),
                            RadialSlider(
                              color: theme.accentColor,
                              minAngle: MIN_ANGLE,
                              maxAngle: MAX_ANGLE,
                              initialAngle: _tempo2Angle(tempo),
                              onChanging: _onSetTempo,
                              backgroundGradient: RadialGradient(
                                colors: colors,
                                stops: stops,
                              ),
                            ),
                          ]
                      ),
                      margin: EdgeInsets.all(50.0),
                    ),
                  ],
                ),
              ),
              PlayerControl(
                playerState: playerState,
                play: _play,
                configSoundEffect: _switchSoundEffect,
                configTempo: _configTempo,
              ),
            ],
          ),
        );
      }
    );
  }
}


class PlayerControl extends StatelessWidget {
  
  final VoidCallback configTempo;
  final VoidCallback configSoundEffect;
  final VoidCallback play;
  final MetronomeState playerState;
  PlayerControl({this.playerState, this.play, this.configTempo, this.configSoundEffect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: IconButton(
              icon: Icon(Icons.library_music),
              iconSize: 30.0,
              tooltip: AppLocalizations.of(context).tempoSettings,
              onPressed: configTempo
            ),
          ),
          Expanded(
            child: IconButton(
              icon: Icon(playerState == MetronomeState.PLAYING ? Icons.stop : Icons.play_arrow),
              iconSize: 80.0,
              tooltip: AppLocalizations.of(context).startOrStop,
              onPressed: play,
            ),
          ),
          Expanded(
            child: IconButton(
              icon: Icon(AppIcons.sound_wave),
              iconSize: 35.0,
              tooltip: AppLocalizations.of(context).soundSettings,
              onPressed: configSoundEffect
            ),
          ),
        ],
      ),
    );
  }
}