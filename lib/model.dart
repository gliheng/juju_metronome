import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'theme.dart';


enum AppMode {
  METRONOME, TUNER,
}

class AppModel extends Model {
  SharedPreferences prefs;

  AppMode appMode = AppMode.METRONOME;

  int currentTheme;

  TunerSettings tunerSettings;
  MetronomeSettings metronomeSettings;

  AppModel({this.prefs})
      : currentTheme = prefs.getInt('themeId') ?? 0,
        metronomeSettings = MetronomeSettings.fromPrefs(prefs),
        tunerSettings = TunerSettings.fromPrefs(prefs);

  ThemeData get theme {
    return THEMES[currentTheme];
  }

  setMode(AppMode mode) {
    appMode = mode;
    notifyListeners();
  }

  Future<bool> setTheme(int i ) async {
    currentTheme = i;
    notifyListeners();
    return await prefs.setInt('themeId', i);
  }

  Future<bool> setMetronomeSettings(MetronomeSettings v) async {
    metronomeSettings = v;
    notifyListeners();
    return await v.toPrefs(prefs);
  }

  Future<bool> setTunerSettings(TunerSettings v) async {
    tunerSettings = v;
    notifyListeners();
    return await v.toPrefs(prefs);
  }
}

class MetronomeSettings {
  // time signature
  int timeSig = 4;
  int timeSigBase = 4;
  // sound effect index
  int soundEffectIdx = 0;
  // in bpm unit
  int tempo = 90;

  MetronomeSettings({this.timeSig, this.timeSigBase, this.soundEffectIdx, this.tempo});

  MetronomeSettings updateTimeSig(int timeSig, int timeSigBase) {
    return MetronomeSettings(
      timeSig: timeSig,
      timeSigBase: timeSigBase,
      soundEffectIdx: soundEffectIdx,
      tempo: tempo,
    );
  }

  MetronomeSettings updateSoundEffectIdx(int soundEffectIdx) {
    return MetronomeSettings(
      timeSig: timeSig,
      timeSigBase: timeSigBase,
      soundEffectIdx: soundEffectIdx,
      tempo: tempo,
    );
  }

  MetronomeSettings updateTempo(int tempo) {
    return MetronomeSettings(
      timeSig: timeSig,
      timeSigBase: timeSigBase,
      soundEffectIdx: soundEffectIdx,
      tempo: tempo,
    );
  }

  factory MetronomeSettings.fromPrefs(SharedPreferences prefs) {
    var timeSig = prefs.getInt('timeSig') ?? 4;
    var timeSigBase = prefs.getInt('timeSigBase') ?? 4;
    var soundEffectIdx = prefs.getInt('soundEffectIdx') ?? 0;
    var tempo = prefs.getInt('tempo') ?? 90;
    return MetronomeSettings(
        timeSig: timeSig, timeSigBase: timeSigBase,
        soundEffectIdx: soundEffectIdx, tempo: tempo
    );
  }

  Future<bool> toPrefs(SharedPreferences prefs) async {
    var ret1 = await prefs.setInt('timeSig', timeSig ?? 4);
    var ret2 = await prefs.setInt('timeSigBase', timeSigBase ?? 4);
    var ret3 = await prefs.setInt('soundEffectIdx', timeSigBase ?? 0);
    var ret4 = await prefs.setInt('tempo', timeSigBase ?? 90);
    return Future.value(ret1 && ret2 && ret3 && ret4);
  }
}

class TunerSettings {
  final Temperament temperament;
  final double concertPitch;

  TunerSettings({this.temperament, this.concertPitch});

  factory TunerSettings.fromPrefs(SharedPreferences prefs) {
    var concertPitch = prefs.getDouble('concertPitch') ?? 440.0;
    var temperament = Temperament.values[prefs.getInt('temperament') ?? 0];
    return TunerSettings(temperament: temperament, concertPitch: concertPitch);
  }

  Future<bool> toPrefs(SharedPreferences prefs) async {
    var ret = await prefs.setDouble('concertPitch', concertPitch ?? 440.0);
    var ret2 = await prefs.setInt('temperament', temperament.index ?? 0);
    return Future.value(ret && ret2);
  }
}

enum Temperament {
  equal, pythagorean, just, mean
}

String temperamentLabel(Temperament t) {
  String v;
  switch (t) {
    case Temperament.pythagorean:
      v = 'Pythagorean';
      break;
    case Temperament.just:
      v = 'Just';
      break;
    case Temperament.equal:
      v = 'Equal';
      break;
    case Temperament.mean:
      v = 'MeanTone';
      break;
  }
  return v;
}