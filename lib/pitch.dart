import 'dart:math' as math;
import 'model.dart';

class PitchResult {
  String note;
  int octave;
  double delta; // delta from nearest pit-ch in cent
  PitchResult({this.note, this.delta, this.octave});

  String get naturalNote {
    if (note.length == 2) {
      return note.substring(0, 1);
    }
    return note;
  }

  bool get isNatural {
    return note.lastIndexOf('#') == -1;
  }

  @override
  String toString() {
    return '$note$octave';
  }
}

class PitchFind {
  static Map<int, String> pitchMapping = {
    0: 'A',
    1: 'A#',
    2: 'B',
    3: 'C',
    4: 'C#',
    5: 'D',
    6: 'D#',
    7: 'E',
    8: 'F',
    9: 'F#',
    10: 'G',
    11: 'G#',
  };

  // Temperament table from http://www.instrument-tuner.com/TemperamentTables.html
  static Map<String, double> pythagorean = {
    'A': 0.0,
    'A#': -9.775,
    'B': 3.910,
    'C': -5.865,
    'C#': 7.820,
    'D': -1.955,
    'D#': -11.730,
    'E': 1.955,
    'F': -7.820,
    'F#': 5.865,
    'G': -3.910,
    'G#': 9.775,
  };

  static Map<String, double> justIntonation = {
    'A': 0.0,
    'A#': 33.237,
    'B': 3.910,
    'C': 15.641,
    'C#': -13.686	,
    'D': 19.551,
    'D#': 31.282	,
    'E': 1.955	,
    'F': 13.686	,
    'F#': 5.864	,
    'G': 17.596,
    'G#': 29.327,
  };

  static Map<String, double> meanTone = {
    'A': 0.0,
    'A#': 13.686,
    'B': -5.864,
    'C': 8.798,
    'C#': -9.775,
    'D': 2.933,
    'D#': 15.640,
    'E': -2.932,
    'F': 11.731,
    'F#': -7.819,
    'G': 5.865,
    'G#': -10.752,
  };

  static PitchResult getNearestPitchWithTemperament(double freq, double concertPitch, Temperament t) {
    if (freq < 0) {
      return null;
    }

    var stepsFromA4 = 12 * math.log(freq / concertPitch) / math.log(2);
    var flat = stepsFromA4.floor();
    var sharp = stepsFromA4.ceil();

    var temperamentMap;
    if (t == Temperament.pythagorean) {
      temperamentMap = pythagorean;
    } else if (t == Temperament.just) {
      temperamentMap = justIntonation;
    } else if (t == Temperament.mean) {
      temperamentMap = Temperament.mean;
    }

    var flatT = temperamentMap == null ? 0 : temperamentMap[pitchMapping[flat % 12]];
    var sharpT = temperamentMap == null ? 0 : temperamentMap[pitchMapping[sharp % 12]];
    var distFromFlat = stepsFromA4 * 100 - flat * 100 - flatT;
    var distFromSharp = sharp * 100 - stepsFromA4 * 100 + sharpT;

    int stepsNearest;
    double delta;
    if (distFromFlat > distFromSharp) {
      stepsNearest = sharp;
      delta = -distFromSharp;
    } else {
      stepsNearest = flat;
      delta = distFromFlat;
    }

    String note = pitchMapping[stepsNearest % 12];
    int octave = 4 + ((stepsNearest + 9) / 12).floor();

    return PitchResult(
      note: note,
      delta: delta,
      octave: octave,
    );
  }
}