import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'pitch.dart';
import 'model.dart';

class Tuner extends StatefulWidget {
  final TunerSettings settings;

  Tuner({this.settings});

  @override
  _TunerState createState() => _TunerState();
}

class _TunerState extends State<Tuner> {

  static const EventChannel pitchEventChannel = EventChannel('one.juju.metronome/pitch_detect');

  double freq;
  double prob;
  PitchResult nearestPitch;

  StreamSubscription<dynamic> pitchStream;

  @override
  void initState() {
    super.initState();
    pitchStream = pitchEventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(Object data) {
    List<double> d = data;
    double frequency = d[0];
    double probability = d[1];
    if (probability > 0.5) {
      var ret = PitchFind.getNearestPitchWithTemperament(
          frequency,
          widget.settings.concertPitch,
          widget.settings.temperament
      );
      if (ret == null) return;

      setState(() {
        freq = frequency;
        prob = probability;
        nearestPitch = ret;
      });
    }
  }

  void _onError(Object error) {
    print('Pitch stream error $error');
  }

  void showTunerSettings(BuildContext context, AppModel model) async {
    TunerSettings v = await Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (BuildContext context) {
        return TunerSettingsDialog(settings: widget.settings);
      }
    ));

    if (v != null) {
      model.setTunerSettings(v);
    }
  }

  Color get hintColor {
    if (this.nearestPitch == null) {
      return Colors.black26;
    }
    double r = nearestPitch.delta.abs()/50;
    r = r.roundToDouble();
    if (r < 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, r);
    }
    return Color.lerp(Colors.yellow, Colors.red, r);
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) {
        double width = MediaQuery.of(context).size.width;
        var radius = 0.6 * width;
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Positioned(
              top: 20.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FlatButton(
                    child: Text(temperamentLabel(widget.settings.temperament)),
                    color: Colors.black.withOpacity(0.1),
                    onPressed: () {
                      showTunerSettings(context, model);
                    },
                  ),
                  Container(width: 10.0, height: 0.0),
                  FlatButton(
                    child: Text('A4 = ${widget.settings.concertPitch}Hz'),
                    color: Colors.black.withOpacity(0.1),
                    onPressed: () {
                      showTunerSettings(context, model);
                    },
                  ),
                ],
              ),
            ),
            Stack(
                fit: StackFit.expand,
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  Container(
                    child: Center(
                        child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              gradient: RadialGradient(
                                colors: [
                                  model.theme.brightness == Brightness.light ? Colors.white.withAlpha(1) : Colors.transparent,
                                  hintColor
                                ]
                              ),
                              shape: BoxShape.circle,
                            ),
                            width: radius,
                            height: radius,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: DefaultTextStyle(
                                      style: model.theme.textTheme.title.copyWith(fontSize: 50.0),
                                      child: nearestPitch == null? Text('--') : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(left: 10.0),
                                            child: Text(nearestPitch.naturalNote),
                                          ),
                                          Transform.translate(
                                              offset: Offset(0.0, 14.0),
                                              child: Text('${nearestPitch.octave}', style: TextStyle(fontSize: 28.0))
                                          ),
                                          Transform.translate(
                                            offset: Offset(-16.0, -16.0),
                                            child: Text(nearestPitch.isNatural ? '' : '#', style: TextStyle(fontSize: 28.0)),
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                                Text(freq != null ? '${freq.toStringAsFixed(1)}Hz' : ''),
                              ],
                            )
                        )
                    ),
                  ),
                  Positioned(
                      left: 0.0,
                      child: PitchScale(delta: nearestPitch == null ? 0.0 : nearestPitch.delta, hintColor: hintColor)
                  ),
                  Positioned(
                    left: 0.0,
                    bottom: 0.0,
                    right: 0.0,
                    child: Oscilloscope(),
                  )
                ]
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    pitchStream.cancel();
  }
}

const double MIN_PITCH = 430.0;
const double MAX_PITCH = 450.0;

class TunerSettingsDialog extends StatefulWidget {
  final TunerSettings settings;

  TunerSettingsDialog({this.settings});

  @override
  _TunerSettingsDialogState createState() => _TunerSettingsDialogState();
}

class _TunerSettingsDialogState extends State<TunerSettingsDialog> {
  Temperament temperament;
  double concertPitch;

  @override
  void initState() {
    super.initState();
    temperament = widget.settings.temperament;
    concertPitch = widget.settings.concertPitch;
  }

  void onTemperamentSelected(Temperament t) {
    setState(() {
      temperament = t;
    });
  }

  void handleSliderValueChanged(double v) {
    setState(() {
      concertPitch = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuner Settings'),
        actions: <Widget>[
          FlatButton(
            child: Text('Save'),
            onPressed: () {
              Navigator.pop(context, TunerSettings(temperament: temperament, concertPitch: concertPitch));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            ListTile(title: Text('Temperament'), trailing: PopupMenuButton(
              child: Text(temperamentLabel(temperament)),
              onSelected: onTemperamentSelected,
              itemBuilder: (BuildContext context) {
                return Temperament.values.map((Temperament t) {
                  return PopupMenuItem<Temperament>(
                    value: t,
                    child: Text(temperamentLabel(t)),
                  );
                }).toList();
              },
            )),
            ListTile(title: Text('Concert Pitch'), subtitle: Row(
              children: <Widget>[
                Expanded(
                  child: Slider(
                      value: concertPitch,
                      min: MIN_PITCH,
                      max: MAX_PITCH,
                      divisions: (MAX_PITCH - MIN_PITCH).toInt(),
                      onChanged: handleSliderValueChanged,
                      label: concertPitch.toString()
                  ),
                ),
                Text(concertPitch.toString())
              ],
            )),
          ]
        ),
      ),
    );
  }
}


class PitchScale extends StatelessWidget {
  final Color hintColor;
  final double delta;
  static const double MAX_HEIGHT = 150.0;

  PitchScale({this.hintColor, this.delta});

  double cent2Pixel(double v) {
    double d = - MAX_HEIGHT / 50 * v;
    return d.roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    var leftEdge = 2 * MAX_HEIGHT + 20;
    return SizedBox(
      width: 60.0,
      height: leftEdge,
      child: Row(
        children: <Widget>[
          Container(
            width: 20.0,
            height: leftEdge,
            decoration: ShapeDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: WedgeShape(),
            ),
            child: ScaleBar(color: hintColor, height: cent2Pixel(delta)),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.centerLeft,
              children: [-50.0, -20.0, 0.0, 20.0, 50.0].map((v) {
                var c;
                if (v == 0) {
                  c = Center(child: Transform.rotate(angle: math.pi, child: Icon(Icons.play_arrow)));
                } else {
                  c = Text(v.toString(), style: TextStyle(fontSize: 14.0));
                }
                const double boxHeight = 20.0;
                return Positioned(
                  top: leftEdge / 2 + cent2Pixel(v) - boxHeight/2,
                  child: Container(
                    height: boxHeight,
                    child: Center(
                      child: c,
                    )
                  )
                );
              }).toList()
            ),
          )
        ],
      )
    );
  }
}

class ScaleBar extends StatelessWidget {
  final double height;
  final Color color;

  ScaleBar({this.height, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScaleBarPainter(color: color, height: height),
    );
  }
}


class ScaleBarPainter extends CustomPainter {
  Color color;
  double height;

  ScaleBarPainter({this.color, this.height});

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color;
    var rrect;
    if (height < 0) {
      var rect = Rect.fromLTWH(0.0, size.height / 2 + height, size.width, height.abs());
      rrect = RRect.fromRectAndCorners(rect, topLeft: Radius.circular(5.0), topRight: Radius.circular(5.0));
    } else {
      var rect = Rect.fromLTWH(0.0, size.height / 2, size.width, height);
      rrect = RRect.fromRectAndCorners(rect, bottomLeft: Radius.circular(5.0), bottomRight: Radius.circular(5.0));
    }
    canvas.drawRRect(rrect, paint);
  }
}


class WedgeShape extends ShapeBorder {

  @override
  EdgeInsetsGeometry get dimensions {
  return const EdgeInsets.only();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {

  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return new Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top + 10.0)
      ..lineTo(rect.right, rect.bottom - 10.0)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  ShapeBorder scale(double t) {
    return null;
  }
}

class Oscilloscope extends StatefulWidget {
  @override
  _OscilloscopeState createState() => _OscilloscopeState();
}

class _OscilloscopeState extends State<Oscilloscope> {
  static const EventChannel oscEventChannel = EventChannel('one.juju.metronome/oscilloscope');
  StreamSubscription<dynamic> oscStream;
  Float64List data;

  @override
  void initState() {
    super.initState();
    oscStream = oscEventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(Object d) {
    setState(() {
      data = d;
    });
  }

  void _onError(Object error) {
    print('Oscilloscope stream error $error');
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) {
        return Container(
          height: 100.0,
          child: CustomPaint(
            key: ObjectKey(data),
            painter: OscilloscopePainter(
              data: data,
              color: model.theme.primaryTextTheme.title.color,
            ),
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    super.dispose();
    oscStream.cancel();
  }
}

class OscilloscopePainter extends CustomPainter {
  static double scale = 250;

  Color color;
  final Float64List data;
  OscilloscopePainter({this.data, this.color});

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data == null) return;

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..color = color.withOpacity(0.5);

    Path path = Path();
    double offsetY = size.height / 2;
    path.moveTo(0.0, offsetY);
    double lastX = 0.0;

    for (int i = 0; i < data.length~/2; i++) {
      double x = data[i * 2] * size.width;
      double y = data[i * 2 + 1] * scale + offsetY;
      // this remove 0, 0 at the tail
      if (x < lastX) continue;
      path.lineTo(x, y);
      lastX = x;
    }

    canvas.drawPath(path, paint);
  }
}