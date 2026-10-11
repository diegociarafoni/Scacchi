import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('it'),
    Locale('en'),
  ];

  /// Titolo dell'app nel selettore delle attività; il nome sotto l'icona è in AndroidManifest.xml e Info.plist
  ///
  /// In it, this message translates to:
  /// **'Scacchi'**
  String get appTitle;

  /// Titolo della schermata che mostra il QR della partita e voce di menu
  ///
  /// In it, this message translates to:
  /// **'Passa con QR'**
  String get qrSendTitle;

  /// Istruzioni sotto il QR
  ///
  /// In it, this message translates to:
  /// **'Sull\'altro telefono apri Tu › Archivio › Ricevi con QR e inquadra il codice.'**
  String get qrSendHint;

  /// Fotogramma mostrato di una partita lunga
  ///
  /// In it, this message translates to:
  /// **'Parte {current} di {total}'**
  String qrPart(int current, int total);

  /// Ferma lo scorrimento dei fotogrammi
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get qrPause;

  /// Riprende lo scorrimento dei fotogrammi
  ///
  /// In it, this message translates to:
  /// **'Riprendi'**
  String get qrResume;

  /// Fotogramma successivo
  ///
  /// In it, this message translates to:
  /// **'Parte successiva'**
  String get qrNext;

  /// Fotogramma precedente
  ///
  /// In it, this message translates to:
  /// **'Parte precedente'**
  String get qrPrevious;

  /// Etichetta del QR per il lettore di schermo
  ///
  /// In it, this message translates to:
  /// **'Codice QR della partita'**
  String get qrCodeLabel;

  /// Titolo della schermata con la fotocamera e azione dell'archivio
  ///
  /// In it, this message translates to:
  /// **'Ricevi con QR'**
  String get qrReceiveTitle;

  /// Istruzioni sotto la fotocamera
  ///
  /// In it, this message translates to:
  /// **'Inquadra il codice QR mostrato dall\'altro telefono.'**
  String get qrReceiveHint;

  /// Avanzamento della lettura, annunciato anche al lettore di schermo
  ///
  /// In it, this message translates to:
  /// **'{received} di {total} parti lette'**
  String qrReceived(int received, int total);

  /// QR di altro tipo, per esempio un indirizzo web
  ///
  /// In it, this message translates to:
  /// **'Questo QR non contiene una partita.'**
  String get qrForeign;

  /// Dati non validi
  ///
  /// In it, this message translates to:
  /// **'Il QR è danneggiato: ricomincia la lettura.'**
  String get qrCorrupted;

  /// Oltre i limiti di sicurezza
  ///
  /// In it, this message translates to:
  /// **'La partita è troppo grande per essere ricevuta.'**
  String get qrTooLarge;

  /// Si è inquadrato il QR di un'altra partita
  ///
  /// In it, this message translates to:
  /// **'Nuova partita inquadrata: lettura ricominciata.'**
  String get qrRestarted;

  /// Permesso negato o fotocamera assente
  ///
  /// In it, this message translates to:
  /// **'Non riesco a usare la fotocamera. Consenti l\'accesso alla fotocamera per Scacchi nelle impostazioni del telefono e riprova.'**
  String get qrCameraError;

  /// Riapre la fotocamera
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get qrRetry;

  /// PGN ricevuto ma non importabile
  ///
  /// In it, this message translates to:
  /// **'Il QR non contiene una partita valida.'**
  String get qrInvalidGame;

  /// Una partita finita non si continua: va nell'archivio
  ///
  /// In it, this message translates to:
  /// **'La partita è già conclusa: ricevila da Tu › Archivio › Ricevi con QR.'**
  String get qrFinishedGame;

  /// Un fotogramma rovinato o in conflitto, scartato senza perdere le parti lette
  ///
  /// In it, this message translates to:
  /// **'QR non valido: ignorato.'**
  String get qrMalformed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
