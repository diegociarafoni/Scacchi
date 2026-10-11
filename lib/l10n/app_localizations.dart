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

  /// Riga di stato nel profilo bambino: tocca al giocatore contro il computer
  ///
  /// In it, this message translates to:
  /// **'Tocca a te!'**
  String get kidGameYourTurn;

  /// Riga di stato nel profilo bambino: tocca a un colore, tra due persone
  ///
  /// In it, this message translates to:
  /// **'{side, select, white{Tocca al Bianco!} other{Tocca al Nero!}}'**
  String kidGameTurnSide(String side);

  /// Riga di stato nel profilo bambino: tocca a un giocatore con nome
  ///
  /// In it, this message translates to:
  /// **'{name}, tocca a te!'**
  String kidGameTurnName(String name);

  /// Riga di stato nel profilo bambino: tocca al computer o al bot; name è a inizio frase
  ///
  /// In it, this message translates to:
  /// **'{name} sta per muovere'**
  String kidGameOpponentTurn(String name);

  /// Riga di stato nel profilo bambino mentre il computer o il bot sceglie la mossa
  ///
  /// In it, this message translates to:
  /// **'{name} ci sta pensando…'**
  String kidGameThinking(String name);

  /// Riga di stato nel profilo bambino mentre il computer valuta il pareggio
  ///
  /// In it, this message translates to:
  /// **'{name} ci pensa un attimo…'**
  String kidGameDrawThinking(String name);

  /// Riga di stato nel profilo bambino: il re del giocatore è sotto scacco
  ///
  /// In it, this message translates to:
  /// **'Scacco! Il tuo re è in pericolo'**
  String get kidGameCheckYou;

  /// Riga di stato nel profilo bambino: il giocatore dà scacco al computer
  ///
  /// In it, this message translates to:
  /// **'Scacco! Il re avversario è in pericolo'**
  String get kidGameCheckOpponent;

  /// Riga di stato nel profilo bambino: scacco tra due persone
  ///
  /// In it, this message translates to:
  /// **'{side, select, white{Scacco! Il re bianco è in pericolo} other{Scacco! Il re nero è in pericolo}}'**
  String kidGameCheckSide(String side);

  /// Riga di stato nel profilo bambino: scacco a un giocatore con nome
  ///
  /// In it, this message translates to:
  /// **'Scacco! {name}, il tuo re è in pericolo'**
  String kidGameCheckName(String name);

  /// Inizio della frase di fine partita per scacco matto, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Scacco matto!'**
  String get kidGameCheckmate;

  /// Inizio della frase di fine partita per tempo scaduto, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Tempo finito!'**
  String get kidGameTimeUp;

  /// Inizio della frase di fine partita a Re della collina, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Il re è arrivato al centro!'**
  String get kidGameKingOfTheHill;

  /// Inizio della frase di fine partita a Tre scacchi, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Terzo scacco!'**
  String get kidGameThirdCheck;

  /// Inizio generico della frase di fine partita, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Partita finita!'**
  String get kidGameOver;

  /// Inizio della frase di fine partita quando il giocatore si arrende al computer
  ///
  /// In it, this message translates to:
  /// **'Ti sei arreso.'**
  String get kidGameYouResigned;

  /// Inizio della frase di fine partita per resa, tra due persone
  ///
  /// In it, this message translates to:
  /// **'{side, select, white{Il Bianco si arrende.} other{Il Nero si arrende.}}'**
  String kidGameResignedSide(String side);

  /// Inizio della frase di fine partita per resa di un giocatore con nome
  ///
  /// In it, this message translates to:
  /// **'{name} si arrende.'**
  String kidGameResignedName(String name);

  /// Esito nel profilo bambino: ha vinto il giocatore contro il computer
  ///
  /// In it, this message translates to:
  /// **'Hai vinto!'**
  String get kidGameYouWon;

  /// Esito nel profilo bambino: ha vinto il computer o il bot; name è a inizio frase
  ///
  /// In it, this message translates to:
  /// **'{name} ha vinto. Riprova!'**
  String kidGameOpponentWon(String name);

  /// Esito nel profilo bambino: vincitore tra due persone
  ///
  /// In it, this message translates to:
  /// **'{side, select, white{Ha vinto il Bianco!} other{Ha vinto il Nero!}}'**
  String kidGameWinnerSide(String side);

  /// Esito nel profilo bambino: vincitore con nome
  ///
  /// In it, this message translates to:
  /// **'Ha vinto {name}!'**
  String kidGameWinnerName(String name);

  /// Fine partita per stallo, spiegata in parole semplici
  ///
  /// In it, this message translates to:
  /// **'Stallo: il re non può muoversi ma non è sotto scacco. Pareggio!'**
  String get kidGameStalemate;

  /// Fine partita per materiale insufficiente, in parole semplici
  ///
  /// In it, this message translates to:
  /// **'Sono rimasti troppo pochi pezzi per dare scacco matto. Pareggio!'**
  String get kidGameInsufficientMaterial;

  /// Fine partita per triplice ripetizione, in parole semplici
  ///
  /// In it, this message translates to:
  /// **'La stessa posizione è tornata tre volte. Pareggio!'**
  String get kidGameRepetition;

  /// Fine partita per la regola delle 50 mosse, in parole semplici
  ///
  /// In it, this message translates to:
  /// **'Tante mosse senza catture né mosse di pedone. Pareggio!'**
  String get kidGameFiftyMoves;

  /// Fine partita per patta concordata, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Pareggio deciso insieme!'**
  String get kidGameAgreedDraw;

  /// Fine partita per tempo scaduto senza materiale per vincere
  ///
  /// In it, this message translates to:
  /// **'Tempo finito, ma con questi pezzi nessuno può vincere. Pareggio!'**
  String get kidGameTimeUpDraw;

  /// Nome del computer a inizio frase nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Il computer'**
  String get kidGameComputer;

  /// Pulsante della barra dei comandi per una nuova partita, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Nuova partita'**
  String get kidGameNew;

  /// Pulsante della barra dei comandi per proporre il pareggio, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Pareggio?'**
  String get kidGameDraw;

  /// Pulsante della barra dei comandi per arrendersi, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Mi arrendo'**
  String get kidGameResign;

  /// Titolo del dialogo di resa contro il computer, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Vuoi arrenderti?'**
  String get kidGameResignTitle;

  /// Titolo del dialogo di resa tra due persone, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'{side, select, white{Bianco, vuoi arrenderti?} other{Nero, vuoi arrenderti?}}'**
  String kidGameResignTitleSide(String side);

  /// Titolo del dialogo di resa per un giocatore con nome
  ///
  /// In it, this message translates to:
  /// **'{name}, vuoi arrenderti?'**
  String kidGameResignTitleName(String name);

  /// Testo del dialogo di resa, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Se ti arrendi, la partita finisce.'**
  String get kidGameResignBody;

  /// Pulsante che chiude il dialogo di resa senza arrendersi
  ///
  /// In it, this message translates to:
  /// **'No, continuo'**
  String get kidGameResignNo;

  /// Pulsante che conferma la resa, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Sì, mi arrendo'**
  String get kidGameResignYes;

  /// Titolo del dialogo di pareggio tra due persone: chiede all'avversario
  ///
  /// In it, this message translates to:
  /// **'{side, select, white{Bianco, vuoi fare pareggio?} other{Nero, vuoi fare pareggio?}}'**
  String kidGameDrawOfferSide(String side);

  /// Titolo del dialogo di pareggio per un giocatore con nome
  ///
  /// In it, this message translates to:
  /// **'{name}, vuoi fare pareggio?'**
  String kidGameDrawOfferName(String name);

  /// Pulsante che rifiuta il pareggio, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'No, giochiamo'**
  String get kidGameDrawNo;

  /// Pulsante che accetta il pareggio, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Sì, pareggio'**
  String get kidGameDrawYes;

  /// Messaggio quando il computer o il bot accetta il pareggio; name è a inizio frase
  ///
  /// In it, this message translates to:
  /// **'{name} accetta il pareggio!'**
  String kidGameDrawAccepted(String name);

  /// Messaggio quando il computer o il bot rifiuta il pareggio
  ///
  /// In it, this message translates to:
  /// **'{name} vuole continuare a giocare.'**
  String kidGameDrawRefused(String name);

  /// Titolo della scelta della cadenza nel pannello Nuova partita, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Quanto tempo?'**
  String get kidGameTimeTitle;

  /// Cadenza lenta con orologio (15 minuti più 10 secondi a mossa), nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Con l\'orologio, con calma'**
  String get kidGameSlowClock;
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
