import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/messages_all.dart';

class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name = locale.languageCode != null ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get title {
    return Intl.message(
      'Juju Metronome',
      name: 'title',
      desc: 'Title for the application',
    );
  }

  String get metronome {
    return Intl.message(
      'Metronome',
      name: 'metronome',
    );
  }

  String get tuner {
    return Intl.message(
      'Tuner',
      name: 'tuner',
    );
  }

  String get tempoSettings {
    return Intl.message(
      'Tempo Settings',
      name: 'tempoSettings',
    );
  }

  String get startOrStop {
    return Intl.message(
      'Start/Stop',
      name: 'startOrStop',
    );
  }

  String get soundSettings {
    return Intl.message(
      'Sound Settings',
      name: 'soundSettings',
    );
  }

  String get tempo {
    return Intl.message(
      'Tempo',
      name: 'tempo',
    );
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}