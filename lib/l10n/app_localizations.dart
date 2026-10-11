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

  /// Descrizione amichevole del bot Pino nel profilo bambino (RP-06), al posto di Elo, stile e apertura
  ///
  /// In it, this message translates to:
  /// **'Un pulcino allegro che ama attaccare'**
  String get kidBotPinoDescription;

  /// Descrizione amichevole del bot Chiara nel profilo bambino (RP-06), al posto di Elo, stile e apertura
  ///
  /// In it, this message translates to:
  /// **'Gioca con calma e aspetta le tue mosse'**
  String get kidBotChiaraDescription;

  /// Descrizione amichevole del bot Rocco nel profilo bambino (RP-06), al posto di Elo, stile e apertura
  ///
  /// In it, this message translates to:
  /// **'Una volpe furba piena di sorprese'**
  String get kidBotRoccoDescription;

  /// Nel profilo bambino, al posto dell'avviso su Stockfish quando il motore non è disponibile
  ///
  /// In it, this message translates to:
  /// **'Su questo dispositivo i bot non sono disponibili.'**
  String get kidBotUnavailable;

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

  /// Pulsante della barra dei comandi che annulla l'ultima mossa, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get kidGameUndo;

  /// Pulsante della barra dei comandi che capovolge la scacchiera, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Gira'**
  String get kidGameFlip;

  /// Campo del nome del giocatore col Bianco nel pannello Nuova partita, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Nome del Bianco'**
  String get kidGameWhiteName;

  /// Campo del nome del giocatore col Nero nel pannello Nuova partita, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Nome del Nero'**
  String get kidGameBlackName;

  /// Suggerimento nei campi dei nomi: si possono lasciare vuoti
  ///
  /// In it, this message translates to:
  /// **'Facoltativo'**
  String get kidGameNameHint;

  /// Cadenza senza orologio nel pannello Nuova partita, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Senza tempo'**
  String get kidGameNoClock;

  /// Pulsante della barra dei comandi che accende l'allenatore, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Allenatore'**
  String get kidGameCoach;

  /// Pulsante della barra dei comandi che chiede un suggerimento, nel profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Aiuto'**
  String get kidGameHint;

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

  /// Titolo sopra la stringa FEN nell'editor di posizione
  ///
  /// In it, this message translates to:
  /// **'Posizione (FEN)'**
  String get editorFenTitle;

  /// Etichetta e suggerimento dell'icona di aiuto accanto al titolo FEN
  ///
  /// In it, this message translates to:
  /// **'Che cos\'è il FEN?'**
  String get editorFenHelpTooltip;

  /// Spiegazione del FEN nella finestra di aiuto dell'editor
  ///
  /// In it, this message translates to:
  /// **'Il FEN è una riga di testo che descrive una posizione: i pezzi sulla scacchiera, di chi è il turno, l\'arrocco e le mosse. Serve per copiare la posizione in altre app e per incollarne una ricevuta da altrove: usa «Copia FEN» e «Incolla FEN».'**
  String get editorFenHelpBody;

  /// Pulsante per chiudere la finestra di aiuto sul FEN
  ///
  /// In it, this message translates to:
  /// **'Ho capito'**
  String get editorFenHelpClose;
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
