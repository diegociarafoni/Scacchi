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

  /// Intestazione della sezione del profilo nelle Impostazioni
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get kidProfileSection;

  /// Interruttore del profilo bambino (RP-06) nelle Impostazioni
  ///
  /// In it, this message translates to:
  /// **'Profilo bambino'**
  String get kidProfile;

  /// Spiegazione sotto l'interruttore del profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Interfaccia e testi più semplici, bot amichevoli, niente numeri'**
  String get kidProfileDescription;

  /// Titolo della domanda per uscire dal profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Chiedi a un adulto'**
  String get kidAdultGateTitle;

  /// Moltiplicazione da risolvere per uscire dal profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Per uscire dal profilo bambino: quanto fa {a} × {b}?'**
  String kidAdultGateQuestion(int a, int b);

  /// Errore sotto il campo della risposta
  ///
  /// In it, this message translates to:
  /// **'Risposta sbagliata.'**
  String get kidAdultGateWrong;

  /// Pulsante che controlla la risposta
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get kidAdultGateConfirm;

  /// Notifica dei progressi nel profilo bambino, al posto di «+N XP»
  ///
  /// In it, this message translates to:
  /// **'Bravo, continua così!'**
  String get kidProgressGreat;

  /// Obiettivo giornaliero completato, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Obiettivo di oggi raggiunto!'**
  String get kidProgressGoal;

  /// Nuovo livello, senza il numero, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Sei salito di livello: una stella in più!'**
  String get kidProgressLevelUp;

  /// Sfida completata, nel profilo bambino (il titolo può contenere numeri)
  ///
  /// In it, this message translates to:
  /// **'Sfida completata!'**
  String get kidProgressChallenge;

  /// Traguardo sbloccato, nel profilo bambino (il titolo può contenere numeri)
  ///
  /// In it, this message translates to:
  /// **'Nuovo traguardo!'**
  String get kidProgressAchievement;

  /// Ricompensa sbloccata nel profilo bambino, senza il nome (che è solo in italiano)
  ///
  /// In it, this message translates to:
  /// **'Hai sbloccato una ricompensa!'**
  String get kidProgressReward;

  /// Titolo della scheda del livello nel profilo bambino: una stella per livello
  ///
  /// In it, this message translates to:
  /// **'Le tue stelle'**
  String get kidLevelTitle;

  /// Descrizione per i lettori di schermo delle stelle del livello
  ///
  /// In it, this message translates to:
  /// **'Una stella per ogni livello raggiunto'**
  String get kidLevelStarsLabel;

  /// Testo sotto la barra del livello, senza cifre
  ///
  /// In it, this message translates to:
  /// **'Gioca ancora per guadagnare un\'altra stella!'**
  String get kidLevelProgress;

  /// Descrizione per i lettori di schermo della barra del livello
  ///
  /// In it, this message translates to:
  /// **'Strada verso la prossima stella'**
  String get kidLevelProgressLabel;

  /// Serie di giorni attiva, senza il numero di giorni
  ///
  /// In it, this message translates to:
  /// **'Stai giocando tutti i giorni: la fiamma è accesa!'**
  String get kidStreakOn;

  /// Serie di giorni non ancora iniziata
  ///
  /// In it, this message translates to:
  /// **'Gioca oggi per accendere la fiamma!'**
  String get kidStreakOff;

  /// Etichetta della barra dell'obiettivo giornaliero, senza cifre
  ///
  /// In it, this message translates to:
  /// **'Obiettivo di oggi'**
  String get kidGoalToday;

  /// Descrizione per i lettori di schermo della barra di una sfida
  ///
  /// In it, this message translates to:
  /// **'Strada verso la sfida'**
  String get kidChallengeProgress;

  /// Intestazione dell'hub dei puzzle al posto del punteggio
  ///
  /// In it, this message translates to:
  /// **'Risolvi i puzzle e raccogli stelle!'**
  String get kidPuzzleHubTitle;

  /// Descrizione per i lettori di schermo delle stelle dei puzzle risolti
  ///
  /// In it, this message translates to:
  /// **'Le stelle dei puzzle risolti'**
  String get kidPuzzleStarsLabel;

  /// Sottotitolo di Allenamento senza riferimento al punteggio
  ///
  /// In it, this message translates to:
  /// **'Puzzle scelti per te'**
  String get kidPuzzleTraining;

  /// Sottotitolo del puzzle del giorno senza la difficoltà numerica
  ///
  /// In it, this message translates to:
  /// **'Un puzzle nuovo ogni giorno'**
  String get kidPuzzleDaily;

  /// Ripasso con puzzle in attesa, senza il conteggio
  ///
  /// In it, this message translates to:
  /// **'Ci sono puzzle da ripassare'**
  String get kidPuzzleReviewDue;

  /// Ripasso senza puzzle in attesa
  ///
  /// In it, this message translates to:
  /// **'Niente da ripassare oggi'**
  String get kidPuzzleReviewNone;

  /// Sotto la scacchiera del puzzle, al posto del punteggio
  ///
  /// In it, this message translates to:
  /// **'Forza, ce la puoi fare!'**
  String get kidPuzzleKeepGoing;

  /// Giudizio della precisione con cinque stelle
  ///
  /// In it, this message translates to:
  /// **'Perfetto!'**
  String get kidAccuracy5;

  /// Giudizio della precisione con quattro stelle
  ///
  /// In it, this message translates to:
  /// **'Molto bene'**
  String get kidAccuracy4;

  /// Giudizio della precisione con tre stelle
  ///
  /// In it, this message translates to:
  /// **'Bene'**
  String get kidAccuracy3;

  /// Giudizio della precisione con due stelle
  ///
  /// In it, this message translates to:
  /// **'Così così'**
  String get kidAccuracy2;

  /// Giudizio della precisione con una stella
  ///
  /// In it, this message translates to:
  /// **'Da migliorare'**
  String get kidAccuracy1;

  /// Revisione in corso, senza il conteggio delle posizioni
  ///
  /// In it, this message translates to:
  /// **'Sto guardando la partita…'**
  String get kidReviewAnalysing;

  /// Stato dell'analisi al posto della profondità
  ///
  /// In it, this message translates to:
  /// **'Il computer sta pensando…'**
  String get kidAnalysisThinking;

  /// Barra di valutazione senza cifre, vantaggio del Bianco
  ///
  /// In it, this message translates to:
  /// **'Il Bianco è in vantaggio'**
  String get kidEvalWhite;

  /// Barra di valutazione senza cifre, vantaggio del Nero
  ///
  /// In it, this message translates to:
  /// **'Il Nero è in vantaggio'**
  String get kidEvalBlack;

  /// Barra di valutazione senza cifre, posizione pari
  ///
  /// In it, this message translates to:
  /// **'Partita in equilibrio'**
  String get kidEvalEven;

  /// Requisito di avatar, cornici, temi e pezzi bloccati nel profilo bambino, al posto di «Livello N»
  ///
  /// In it, this message translates to:
  /// **'Si sblocca giocando'**
  String get kidUnlockByPlaying;

  /// Coach nel profilo bambino: perdita di materiale senza il conto dei pedoni
  ///
  /// In it, this message translates to:
  /// **'Attento: con questa mossa perdi dei pezzi.'**
  String get kidCoachMaterialLoss;

  /// Coach nel profilo bambino: matto concesso, senza «matto in N»; move e reply in notazione SAN
  ///
  /// In it, this message translates to:
  /// **'Dopo {move} l\'avversario può dare scacco matto con {reply}.'**
  String kidCoachAllowedMate(String move, String reply);

  /// Coach nel profilo bambino: matto mancato, senza «matto in N»; move in notazione SAN
  ///
  /// In it, this message translates to:
  /// **'Con {move} potevi dare scacco matto!'**
  String kidCoachMissedMate(String move);
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
