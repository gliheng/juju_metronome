import 'package:test/test.dart';
import 'package:juju_metronome/pitch.dart';
import 'package:juju_metronome/model.dart';

void main() {
  // test table based on https://pages.mtu.edu/~suits/notefreqs.html
  test('test equal temperament 440', () {
    testPitch(16.35, 'C0', 440.0);
    testPitch(220.0, 'A3', 440.0);
    testPitch(233.08, 'A#3', 440.0);
    testPitch(246.94, 'B3', 440.0);
    testPitch(261.63, 'C4', 440.0);
    testPitch(277.18, 'C#4', 440.0);
    testPitch(293.66, 'D4', 440.0);
    testPitch(311.13, 'D#4', 440.0);
    testPitch(329.63, 'E4', 440.0);
    testPitch(349.23, 'F4', 440.0);
    testPitch(369.99, 'F#4', 440.0);
    testPitch(392.0, 'G4', 440.0);
    testPitch(415.3, 'G#4', 440.0);
    testPitch(440.0, 'A4', 440.0);
  });

  test('test equal temperament 446', () {
    var base = 446.0;
    testPitch(16.57, 'C0', base);
    testPitch(223.00, 'A3', base);
    testPitch(236.26, 'A#3', base);
    testPitch(250.31, 'B3', base);
    testPitch(265.19, 'C4', base);
    testPitch(280.96, 'C#4', base);
    testPitch(297.67, 'D4', base);
    testPitch(315.37, 'D#4', base);
    testPitch(334.12, 'E4', base);
    testPitch(353.99, 'F4', base);
    testPitch(375.04, 'F#4', base);
    testPitch(397.34, 'G4', base);
    testPitch(420.97, 'G#4', base);
    testPitch(446.00, 'A4', base);
  });

  test('test pythagorean temperament', () {
    testPitchWithTemperament(329.63, 440.0, PitchFind.pythagorean['E'], Temperament.pythagorean);
    testPitchWithTemperament(261.63, 440.0, PitchFind.pythagorean['C'], Temperament.pythagorean);
  });
}

void testPitch(double freq, String note, double ref) {
  var pitch = PitchFind.getNearestPitchWithTemperament(freq, ref, Temperament.equal);
  expect(pitch.delta, lessThan(0.1));
  expect(pitch.toString(), note);
}

void testPitchWithTemperament(freq, ref, double delta, Temperament t) {
  var pitch = PitchFind.getNearestPitchWithTemperament(freq, ref, t);
  var pitch1 = PitchFind.getNearestPitchWithTemperament(freq, ref, Temperament.equal);
  var d = pitch1.delta - pitch.delta;
  expect(d.toStringAsFixed(2), equals(delta.toStringAsFixed(2)));
}