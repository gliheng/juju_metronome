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

  AppModel({this.prefs})
      : currentTheme = prefs.getInt('themeId') ?? 0,
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

  Future<bool> setTunerSettings(TunerSettings v) async {
    tunerSettings = v;
    notifyListeners();
    return await v.toPrefs(prefs);
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