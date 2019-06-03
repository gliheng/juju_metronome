import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'intl.dart';

typedef ConfigCallback = void Function(int timeSig, int timeSigBase);

class TempoBottomSheet extends StatefulWidget {
  final int timeSig;
  final int timeSigBase;
  final ConfigCallback onConfig;
  final Key key;

  TempoBottomSheet({this.key, this.timeSig, this.timeSigBase, this.onConfig})
    : super(key: key);

  @override
  TempoBottomSheetState createState() => TempoBottomSheetState();
}

class TempoBottomSheetState extends State<TempoBottomSheet> {
  int timeSig;
  int timeSigBase;

  @override
  void initState() {
      timeSig = widget.timeSig;
      timeSigBase = widget.timeSigBase;
      super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var textStyle = TextStyle(
      color: Theme.of(context).primaryColor,
      fontSize: 30.0,
    );
    return Container(
      height: 200.0,
      color: Colors.black12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(AppLocalizations.of(context).tempo, style: TextStyle(fontSize: 16.0)),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: CupertinoPicker(
                    looping: false,
                    itemExtent: 36.0,
                    offAxisFraction: -0.4,
                    scrollController: FixedExtentScrollController(
                      initialItem: widget.timeSig,
                    ),
                    children: List.generate(17, (i) {
                      var label = i.toString();
                      return Container(
                        padding: EdgeInsets.only(right: 20.0),
                        alignment: Alignment.centerRight,
                        child: Text(label, style: textStyle),
                      );
                    }),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        timeSig = i;
                      });
                    }
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    looping: false,
                    itemExtent: 36.0,
                    offAxisFraction: 0.4,
                    scrollController: FixedExtentScrollController(
                      initialItem: timeSigBase - 1
                    ),
                    children: List.generate(16, (i) {
                      return Container(
                        padding: EdgeInsets.only(left: 20.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                            '${i + 1}', style: textStyle
                        )
                      );
                    }),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        timeSigBase = i + 1;
                      });
                    },
                  ),
                )
              ],
            )
          )
        ],
      )
    );
  }
}