import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TempoGraph extends StatelessWidget {

  final int timeSig;
  final int beatTime;
  final int beat;
  TempoGraph({
    this.timeSig,
    this.beat,
    this.beatTime,
  });

  @override
  Widget build(BuildContext context) {
    double sweepAngle = math.pi * 2/timeSig;
    return Stack(
      children: List.generate(timeSig, (i) {
        double startAngle = sweepAngle * i - math.pi / 2;
        Color color = i == 0 ? Colors.red : Colors.blue;
        bool show;
        if (beat == 0) show = false;
        else show = (beat - 1) % timeSig == i;

        return ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: TempoAnimator(
            startAngle: startAngle,
            sweepAngle: sweepAngle,
            color: color,
            show: show,
            beatTime: beatTime,
          )
        );
      })
    );
  }
}

class TempoAnimator extends StatefulWidget {
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final bool show;
  final int beatTime;
  TempoAnimator({this.startAngle, this.sweepAngle, this.color, this.show, this.beatTime});

  @override
  _TempoAnimatorState createState() => _TempoAnimatorState();
}

class _TempoAnimatorState extends State<TempoAnimator> with SingleTickerProviderStateMixin {
  AnimationController controller;
  Tween tween;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.beatTime));
    tween = YoyoTween(begin: 0.0, end: 1.0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TempoAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.duration = Duration(milliseconds: widget.beatTime);
    if (widget.show) controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget child) {
        return Opacity(
          opacity: tween.evaluate(controller),
          child: CustomPaint(
            painter: TempoPainter(
              startAngle: widget.startAngle,
              sweepAngle: widget.sweepAngle,
              color: widget.color
            ),
          )
        );
      }
    ); 
  }
}

/// This tween change value from begin to end then back to begin
class YoyoTween extends Tween<double> {
  YoyoTween({double begin, double end}): super(begin: begin, end: end);

  @override
  double lerp(double t) {
    return super.lerp(math.sin(t * math.pi));
  }

  @override
  double evaluate(Animation<double> animation) {
    return lerp(animation.value);
  }
}

class TempoPainter extends CustomPainter {
  double startAngle;
  double sweepAngle;
  Color color;

  TempoPainter({
    this.startAngle,
    this.sweepAngle,
    this.color,
  });

  @override
  bool shouldRepaint(TempoPainter oldDelegate) {
    return startAngle != oldDelegate.startAngle
      || sweepAngle != oldDelegate.sweepAngle
      || color != oldDelegate.color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double r = math.min(size.width, size.height) / 2;
    double ir = r * 0.85;

    Rect rect = Rect.fromCircle(
      center: Offset.zero,
      radius: r
    );
    Rect irect = Rect.fromCircle(
      center: Offset.zero,
      radius: ir
    );

    Paint paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    Path path = Path();
    if (sweepAngle == math.pi * 2) {
      Path path1 = Path();
      path1.addOval(rect);
      Path path2 = Path();
      path2.addOval(irect);
      path = Path.combine(ui.PathOperation.difference, path1, path2);
    } else {
      path.moveTo(ir * math.cos(startAngle), ir * math.sin(startAngle));
      path.lineTo(r * math.cos(startAngle), r * math.sin(startAngle));
      path.arcTo(rect, startAngle, sweepAngle, false);
      path.lineTo(ir * math.cos(startAngle + sweepAngle), ir * math.sin(startAngle + sweepAngle));
      path.arcTo(irect, startAngle + sweepAngle, -sweepAngle, false);
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }
}