import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:screen/screen.dart';
import 'app_icons.dart';
import 'metronome.dart';
import 'tuner.dart';
import 'theme.dart';
import 'dart:async';
import 'model.dart';
import 'intl.dart';

void main() async {

  Screen.keepOn(true);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  SharedPreferences prefs = await _prefs;

  AppModel model = AppModel(prefs: prefs);
  runApp(new MyApp(model));
}

class MyApp extends StatelessWidget {
  final AppModel model;
  MyApp(this.model);

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppModel>(
      model: model,
      child: ScopedModelDescendant<AppModel>(builder: (context, child, model) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en'), // English
            const Locale('zh'), // Chinese
          ],
          theme: model.theme,
          onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).title,
          home: AppContainer(),
        );
      }),
    );
  }
}

class AppContainer extends StatefulWidget {
  @override
  _AppContainerState createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> with SingleTickerProviderStateMixin {
  double titleHeight = 130.0;
  GlobalKey key = GlobalKey(debugLabel: '_MetronomeHomeState > Stack');

  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  bool get panelVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed || status == AnimationStatus.forward;
  }

  double get panelHeight {
    final RenderBox renderBox = key.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  _toggleVisibility() {
    _controller.fling(velocity: panelVisible? -2.0 : 2.0);
  }

  Widget _buildSettings(BuildContext context) {
    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) {
        TextStyle activeStyle = model.theme.primaryTextTheme.button;
        TextStyle normalStyle = activeStyle.copyWith(color: activeStyle.color.withOpacity(0.4));
        return SizedBox(
          height: titleHeight,
          child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(THEMES.length, (i) {
                        var theme = THEMES[i];
                        var onPressed = () {
                          model.setTheme(i);
                        };

                        Widget btn = InkWell(
                          child: Container(
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.all(Radius.circular(4.0)),
                            ),
                          ),
                          onTap: onPressed,
                        );

                        if (model.currentTheme == i) {
                          btn = DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                                  border: Border.all(color: Colors.grey.shade400, width: 2.0)
                              ),
                              child: btn
                          );
                        }
                        return Expanded(
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: btn
                          ),
                        );
                      }).toList()
                  ),
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget> [
                      FlatButton(
                        child: Text(
                          AppLocalizations.of(context).metronome,
                          style: model.appMode == AppMode.METRONOME ? activeStyle : normalStyle,
                        ),
                        onPressed: () {
                          model.setMode(AppMode.METRONOME);
                        },
                      ),
                      FlatButton(
                        child: Text(
                          AppLocalizations.of(context).tuner,
                          style: model.appMode == AppMode.TUNER ? activeStyle : normalStyle,
                        ),
                        onPressed: () {
                          model.setMode(AppMode.TUNER);
                        },
                      )
                    ]
                )
              ]
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints) {

    return ScopedModelDescendant<AppModel>(
      builder: (context, child, model) {
        final Animation<RelativeRect> rectAnimation = new RelativeRectTween(
          begin: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
          end: RelativeRect.fromLTRB(0.0, titleHeight, 0.0, -titleHeight),
        ).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut
        ));

        ThemeData theme = model.theme;
        String img = getBgImage(model.currentTheme);
        Widget background;
        if (img != null) {
          background = Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage(img),
                  )
              )
          );
        } else {
          background = Container(
            color: theme.backgroundColor,
          );
        }

        var app = model.appMode == AppMode.METRONOME ? Metronome(model.metronomeSettings) : Tuner(settings: model.tunerSettings);
        return Stack(
            key: key,
            fit: StackFit.expand,
            children: <Widget>[
              Visibility(
                visible: _controller.status != AnimationStatus.dismissed,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildSettings(context),
                ),
              ),
              PositionedTransition(
                  rect: rectAnimation,
                  child: Container(
                      child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            background,
                            app,
                          ]
                      )
                  )
              )
            ]
        );
      }
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(AppIcons.metronome)
            ),
            Text(AppLocalizations.of(context).title)
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _controller.view,
            ),
            onPressed: _toggleVisibility,
          )
        ],
      ),
      body: LayoutBuilder(builder: _buildBody),
    );
  }
}