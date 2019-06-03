import 'dart:math';
import 'package:flutter/material.dart';

class RadialSlider extends StatefulWidget {
  double radius;
  double minAngle;
  double maxAngle;
  double initialAngle;
  Widget background;
  Color color;
  Color backgroundColor;
  Gradient backgroundGradient;
  ValueChanged<double> onChange;
  ValueChanged<double> onChanging;

  RadialSlider({
    this.radius,
    this.initialAngle,
    this.minAngle = - pi / 2,
    this.maxAngle = pi * 1.5,
    this.background,
    this.color = Colors.orange,
    this.backgroundColor = Colors.purple,
    this.backgroundGradient = const RadialGradient(
      colors: <Color>[Colors.black12, Colors.black26, Colors.black45],
      stops: <double>[0.6, 0.8, 1.0],
    ),
    this.onChange,
    this.onChanging,
  });

  @override
  _RadialSliderState createState() => _RadialSliderState();
}

class _RadialSliderState extends State<RadialSlider> {

  double angle = 0.0;

  @override
  void initState() {
    super.initState();
    angle = widget.initialAngle ?? widget.minAngle;
  }

  _onPointerUp(PointerUpEvent evt) {
    if (widget.onChange != null) {
      widget.onChange(angle);
    }
  }

  _onPointerMove(PointerMoveEvent evt, BuildContext context) {
    var dx = evt.delta.dx,
        dy = evt.delta.dy;
    var dAngle = pi / 2 + angle - atan2(dy, dx);

    // project dx dy onto circle
    var dPos = cos(dAngle) * sqrt(pow(dx, 2) + pow(dy, 2));

    RenderBox box = context.findRenderObject();
    Offset pos = box.globalToLocal(evt.position);
    double r = sqrt(pow(pos.dx - context.size.width / 2, 2) + pow(pos.dy - context.size.height / 2, 2));
    // var r = _RadialLayoutDelegate.getRadius(context.size, widget.radius);
    double newAngle = min(angle + dPos / r, widget.maxAngle);
    newAngle = max(widget.minAngle, newAngle);
    setState(() {
      angle = newAngle;
    });

    if (widget.onChanging != null) {
      widget.onChanging(newAngle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: widget.background != null ? widget.background : Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.backgroundColor,
              gradient: widget.backgroundGradient,
            ),
            width: widget.radius != null ? widget.radius * 2 + 50.0 : null,
            height: widget.radius != null ? widget.radius * 2 + 50.0 : null,
          ),
        ),
        Listener(
          onPointerMove: (evt) {_onPointerMove(evt, context);},
          onPointerUp: _onPointerUp,
          child: CustomSingleChildLayout(
            delegate: _RadialLayoutDelegate(
              angle: angle,
              radius: widget.radius,
            ),
            child: RaisedButton(
              onPressed: () {},
              shape: CircleBorder(),
              color: widget.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadialLayoutDelegate extends SingleChildLayoutDelegate {
  static getRadius(Size size, double radius) {
    if (radius == null && size.width != double.infinity && size.height != double.infinity) {
      return min(size.width, size.height) / 2;
    }
    return radius;
  }
  double radius;
  double angle;

  _RadialLayoutDelegate({this.radius, this.angle});

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var r = getRadius(size, radius);
    var center = Offset(
      (size.width - childSize.width) / 2,
      (size.height - childSize.height) / 2,
    );

    return center.translate(r * cos(angle), r * sin(angle));
  }

  @override
  bool shouldRelayout(_RadialLayoutDelegate oldDelegate) {
    return oldDelegate.angle != angle
    || oldDelegate.radius != radius;
  }
}