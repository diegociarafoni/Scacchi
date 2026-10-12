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
  /// **'Rokko'**
  String get appTitle;

  /// Titolo della pagina di backup
  ///
  /// In it, this message translates to:
  /// **'Backup e ripristino'**
  String get backupTitle;

  /// No description provided for @backupIntro.
  ///
  /// In it, this message translates to:
  /// **'Il backup contiene partite, progressi, percorso, tornei, allenamento e impostazioni. Salvalo in un posto sicuro: senza rete non esiste una copia online.'**
  String get backupIntro;

  /// Pulsante che esporta il backup con la condivisione di sistema
  ///
  /// In it, this message translates to:
  /// **'Condividi il backup'**
  String get backupShare;

  /// Oggetto proposto dalla condivisione di sistema, per esempio nelle email
  ///
  /// In it, this message translates to:
  /// **'Backup di Rokko'**
  String get backupShareSubject;

  /// Pulsante che apre la finestra per incollare un backup
  ///
  /// In it, this message translates to:
  /// **'Ripristina da testo'**
  String get backupRestoreFromText;

  /// No description provided for @backupExported.
  ///
  /// In it, this message translates to:
  /// **'Backup pronto da salvare'**
  String get backupExported;

  /// Errore tecnico durante l'esportazione
  ///
  /// In it, this message translates to:
  /// **'Backup non riuscito: {error}'**
  String backupExportFailed(String error);

  /// No description provided for @backupRestoreStaged.
  ///
  /// In it, this message translates to:
  /// **'Backup pronto. Chiudi e riapri l\'app per ripristinare i dati.'**
  String get backupRestoreStaged;

  /// Errore tecnico durante il ripristino
  ///
  /// In it, this message translates to:
  /// **'Ripristino non riuscito: {error}'**
  String backupRestoreFailed(String error);

  /// No description provided for @backupErrorNotApp.
  ///
  /// In it, this message translates to:
  /// **'Non è un backup di Rokko'**
  String get backupErrorNotApp;

  /// No description provided for @backupErrorNewerVersion.
  ///
  /// In it, this message translates to:
  /// **'Backup creato da una versione più recente'**
  String get backupErrorNewerVersion;

  /// No description provided for @backupErrorUnexpectedFile.
  ///
  /// In it, this message translates to:
  /// **'File inatteso nel backup: {file}'**
  String backupErrorUnexpectedFile(String file);

  /// No description provided for @backupErrorInvalidFile.
  ///
  /// In it, this message translates to:
  /// **'File non valido nel backup: {file}'**
  String backupErrorInvalidFile(String file);

  /// No description provided for @backupErrorInvalidPreference.
  ///
  /// In it, this message translates to:
  /// **'Preferenza non valida: {name}'**
  String backupErrorInvalidPreference(String name);

  /// No description provided for @backupErrorUnreadable.
  ///
  /// In it, this message translates to:
  /// **'Backup non leggibile'**
  String get backupErrorUnreadable;

  /// No description provided for @backupRestoreDialogTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristina il backup'**
  String get backupRestoreDialogTitle;

  /// No description provided for @backupRestoreDialogBody.
  ///
  /// In it, this message translates to:
  /// **'Incolla il contenuto del file di backup. I dati attuali vengono sostituiti.'**
  String get backupRestoreDialogBody;

  /// No description provided for @backupCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get backupCancel;

  /// Conferma del ripristino
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get backupRestore;

  /// Nome del pezzo con l'articolo, per le frasi di «spiegami perché»
  ///
  /// In it, this message translates to:
  /// **'{role, select, pawn{il pedone} knight{il cavallo} bishop{l\'alfiere} rook{la torre} queen{la donna} other{il re}}'**
  String whyPiece(String role);

  /// Spiegami perché: la mossa dà matto
  ///
  /// In it, this message translates to:
  /// **'Scacco matto!'**
  String get whyMate;

  /// Spiegami perché: arrocco
  ///
  /// In it, this message translates to:
  /// **'Arrocca: mette il re al sicuro.'**
  String get whyCastle;

  /// Spiegami perché: promozione
  ///
  /// In it, this message translates to:
  /// **'Promuove il pedone: diventa {role, select, queen{una donna} rook{una torre} bishop{un alfiere} knight{un cavallo} other{un pezzo}}.'**
  String whyPromote(String role);

  /// Spiegami perché: cattura
  ///
  /// In it, this message translates to:
  /// **'Cattura {victim} con {attacker}.'**
  String whyCapture(String victim, String attacker);

  /// Spiegami perché: scacco
  ///
  /// In it, this message translates to:
  /// **'Dà scacco al tuo re.'**
  String get whyCheck;

  /// Spiegami perché: pezzo salvato
  ///
  /// In it, this message translates to:
  /// **'Mette al sicuro {piece}, che era sotto attacco.'**
  String whySafe(String piece);

  /// Spiegami perché: minaccia di cattura
  ///
  /// In it, this message translates to:
  /// **'Minaccia di catturare {victim} in {square}.'**
  String whyThreatCapture(String victim, String square);

  /// Spiegami perché, profilo bambino: minaccia di cattura senza casa
  ///
  /// In it, this message translates to:
  /// **'Minaccia di catturare {victim}.'**
  String whyThreatCaptureKid(String victim);

  /// Spiegami perché: minaccia di scacco
  ///
  /// In it, this message translates to:
  /// **'Prepara uno scacco al tuo re.'**
  String get whyThreatCheck;

  /// Spiegami perché: minaccia di promozione
  ///
  /// In it, this message translates to:
  /// **'Prepara la promozione di un pedone.'**
  String get whyThreatPromote;

  /// Spiegami perché: sviluppo di un pezzo
  ///
  /// In it, this message translates to:
  /// **'Sviluppa {piece}: entra in gioco.'**
  String whyDevelop(String piece);

  /// Spiegami perché: pedone al centro
  ///
  /// In it, this message translates to:
  /// **'Prende spazio al centro.'**
  String get whyCenter;

  /// Spiegami perché: mossa tranquilla
  ///
  /// In it, this message translates to:
  /// **'Sposta {piece} su una casa più utile.'**
  String whyImprove(String piece);

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
  /// **'Non riesco a usare la fotocamera. Consenti l\'accesso alla fotocamera per Rokko nelle impostazioni del telefono e riprova.'**
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

  /// No description provided for @opponentHintHuman.
  ///
  /// In it, this message translates to:
  /// **'Si gioca in due sullo stesso dispositivo.'**
  String get opponentHintHuman;

  /// No description provided for @opponentHintComputer.
  ///
  /// In it, this message translates to:
  /// **'Scegli il livello o lascia che si adatti a te.'**
  String get opponentHintComputer;

  /// No description provided for @opponentHintBot.
  ///
  /// In it, this message translates to:
  /// **'Avversari con personalità da sbloccare uno a uno.'**
  String get opponentHintBot;

  /// Sotto un bot bloccato: quale bot battere per sbloccarlo
  ///
  /// In it, this message translates to:
  /// **'Si sblocca battendo {name}'**
  String botUnlockHint(String name);

  /// No description provided for @handicapTitle.
  ///
  /// In it, this message translates to:
  /// **'Handicap'**
  String get handicapTitle;

  /// No description provided for @handicapGameTitle.
  ///
  /// In it, this message translates to:
  /// **'Partita a handicap'**
  String get handicapGameTitle;

  /// No description provided for @handicapHint.
  ///
  /// In it, this message translates to:
  /// **'Chi concede il vantaggio gioca senza un pezzo o con meno tempo. La partita non conta per il rating locale.'**
  String get handicapHint;

  /// No description provided for @handicapPieceTitle.
  ///
  /// In it, this message translates to:
  /// **'Pezzo in meno'**
  String get handicapPieceTitle;

  /// No description provided for @handicapNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get handicapNone;

  /// No description provided for @handicapPieceFPawn.
  ///
  /// In it, this message translates to:
  /// **'Pedone f'**
  String get handicapPieceFPawn;

  /// No description provided for @handicapPieceKnight.
  ///
  /// In it, this message translates to:
  /// **'Cavallo'**
  String get handicapPieceKnight;

  /// No description provided for @handicapPieceRook.
  ///
  /// In it, this message translates to:
  /// **'Torre'**
  String get handicapPieceRook;

  /// No description provided for @handicapPieceQueen.
  ///
  /// In it, this message translates to:
  /// **'Donna'**
  String get handicapPieceQueen;

  /// No description provided for @handicapTimeTitle.
  ///
  /// In it, this message translates to:
  /// **'Tempo di chi concede'**
  String get handicapTimeTitle;

  /// No description provided for @handicapTimeEqual.
  ///
  /// In it, this message translates to:
  /// **'Uguale'**
  String get handicapTimeEqual;

  /// No description provided for @handicapTimeHint.
  ///
  /// In it, this message translates to:
  /// **'Vale solo con un orologio e se è inferiore alla cadenza scelta.'**
  String get handicapTimeHint;

  /// No description provided for @handicapGiverTitle.
  ///
  /// In it, this message translates to:
  /// **'Chi concede il vantaggio'**
  String get handicapGiverTitle;

  /// No description provided for @handicapGiverYou.
  ///
  /// In it, this message translates to:
  /// **'Tu'**
  String get handicapGiverYou;

  /// No description provided for @handicapGiverOpponent.
  ///
  /// In it, this message translates to:
  /// **'L\'avversario'**
  String get handicapGiverOpponent;

  /// No description provided for @handicapGiverWhite.
  ///
  /// In it, this message translates to:
  /// **'Il Bianco'**
  String get handicapGiverWhite;

  /// No description provided for @handicapGiverBlack.
  ///
  /// In it, this message translates to:
  /// **'Il Nero'**
  String get handicapGiverBlack;

  /// No description provided for @handicapTimeMinutes.
  ///
  /// In it, this message translates to:
  /// **'{n} min'**
  String handicapTimeMinutes(int n);

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

  /// No description provided for @minigamesTitle.
  ///
  /// In it, this message translates to:
  /// **'Minigiochi'**
  String get minigamesTitle;

  /// Miglior punteggio del minigioco
  ///
  /// In it, this message translates to:
  /// **'Record {score}'**
  String minigamesRecord(int score);

  /// No description provided for @minigamesCoordinatesTitle.
  ///
  /// In it, this message translates to:
  /// **'Coordinate a tempo'**
  String get minigamesCoordinatesTitle;

  /// No description provided for @minigamesCoordinatesDescription.
  ///
  /// In it, this message translates to:
  /// **'Tocca la casa indicata: quante ne trovi in 30 secondi?'**
  String get minigamesCoordinatesDescription;

  /// No description provided for @minigamesCaptureAllTitle.
  ///
  /// In it, this message translates to:
  /// **'Cattura tutto'**
  String get minigamesCaptureAllTitle;

  /// No description provided for @minigamesCaptureAllDescription.
  ///
  /// In it, this message translates to:
  /// **'Un solo pezzo cattura tutti i pedoni con meno mosse possibile.'**
  String get minigamesCaptureAllDescription;

  /// No description provided for @minigamesBlindTitle.
  ///
  /// In it, this message translates to:
  /// **'Alla cieca'**
  String get minigamesBlindTitle;

  /// No description provided for @minigamesBlindDescription.
  ///
  /// In it, this message translates to:
  /// **'Leggi le mosse senza scacchiera e indica cosa c\'è su una casa.'**
  String get minigamesBlindDescription;

  /// No description provided for @minigamesMaterialTitle.
  ///
  /// In it, this message translates to:
  /// **'Conta del materiale'**
  String get minigamesMaterialTitle;

  /// No description provided for @minigamesMaterialDescription.
  ///
  /// In it, this message translates to:
  /// **'Chi è in vantaggio, e di quanto?'**
  String get minigamesMaterialDescription;

  /// Pulsante per giocare un'altra sessione
  ///
  /// In it, this message translates to:
  /// **'Ancora'**
  String get minigamesAgain;

  /// Pulsante per tornare all'elenco dei minigiochi
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get minigamesDone;

  /// No description provided for @minigamesNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get minigamesNext;

  /// Etichetta per la lettura dello schermo della barra di avanzamento
  ///
  /// In it, this message translates to:
  /// **'Scacchiera {board} di {total}'**
  String minigamesCaptureAllProgress(int board, int total);

  /// No description provided for @minigamesCaptureAllSessionOver.
  ///
  /// In it, this message translates to:
  /// **'Sessione finita'**
  String get minigamesCaptureAllSessionOver;

  /// Stelle totali a fine sessione
  ///
  /// In it, this message translates to:
  /// **'{score, plural, one{{score} stella su {max}} other{{score} stelle su {max}}}'**
  String minigamesCaptureAllScore(int score, int max);

  /// No description provided for @minigamesCaptureAllMoves.
  ///
  /// In it, this message translates to:
  /// **'Mosse {moves}, minimo {optimal}'**
  String minigamesCaptureAllMoves(int moves, int optimal);

  /// Etichetta per la lettura dello schermo delle stelle di una scacchiera
  ///
  /// In it, this message translates to:
  /// **'{stars, plural, one{{stars} stella su 3} other{{stars} stelle su 3}}'**
  String minigamesCaptureAllStars(int stars);

  /// No description provided for @minigamesCaptureAllRetry.
  ///
  /// In it, this message translates to:
  /// **'Ricomincia'**
  String get minigamesCaptureAllRetry;

  /// Etichetta per la lettura dello schermo della casa da trovare
  ///
  /// In it, this message translates to:
  /// **'Tocca la casa {square}'**
  String minigamesCoordinatesTarget(String square);

  /// No description provided for @minigamesCoordinatesScore.
  ///
  /// In it, this message translates to:
  /// **'Punteggio {score}'**
  String minigamesCoordinatesScore(int score);

  /// Tempo rimasto
  ///
  /// In it, this message translates to:
  /// **'{seconds, plural, one{{seconds} secondo} other{{seconds} secondi}}'**
  String minigamesCoordinatesSecondsLeft(int seconds);

  /// No description provided for @minigamesCoordinatesTimeUp.
  ///
  /// In it, this message translates to:
  /// **'Tempo scaduto'**
  String get minigamesCoordinatesTimeUp;

  /// Risultato a fine sessione
  ///
  /// In it, this message translates to:
  /// **'Punteggio {score}: {score, plural, one{{score} giusta} other{{score} giuste}}, {mistakes, plural, one{{mistakes} sbagliata} other{{mistakes} sbagliate}}'**
  String minigamesCoordinatesSummary(int score, int mistakes);

  /// No description provided for @minigamesCoordinatesIntro.
  ///
  /// In it, this message translates to:
  /// **'Tocca la casa indicata, senza coordinate sulla scacchiera. Hai 30 secondi.'**
  String get minigamesCoordinatesIntro;

  /// Scacchiera vista dal bianco
  ///
  /// In it, this message translates to:
  /// **'Bianco'**
  String get minigamesCoordinatesWhite;

  /// Scacchiera vista dal nero
  ///
  /// In it, this message translates to:
  /// **'Nero'**
  String get minigamesCoordinatesBlack;

  /// No description provided for @minigamesCoordinatesStart.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get minigamesCoordinatesStart;

  /// No description provided for @minigamesQuizResult.
  ///
  /// In it, this message translates to:
  /// **'{score, plural, one{{score} risposta giusta su {total}} other{{score} risposte giuste su {total}}}'**
  String minigamesQuizResult(int score, int total);

  /// No description provided for @minigamesQuizQuestion.
  ///
  /// In it, this message translates to:
  /// **'Domanda {number} di {total}'**
  String minigamesQuizQuestion(int number, int total);

  /// No description provided for @minigamesQuizCorrect.
  ///
  /// In it, this message translates to:
  /// **'Esatto!'**
  String get minigamesQuizCorrect;

  /// Risposta giusta dopo una scelta sbagliata
  ///
  /// In it, this message translates to:
  /// **'Era: {answer}'**
  String minigamesQuizAnswer(String answer);

  /// Titolo della schermata e voce di menu della partita su due telefoni
  ///
  /// In it, this message translates to:
  /// **'Gioca con un amico'**
  String get multiplayerTitle;

  /// Sottotitolo della voce di menu
  ///
  /// In it, this message translates to:
  /// **'Su due telefoni nella stessa Wi-Fi o hotspot'**
  String get multiplayerEntrySubtitle;

  /// Spiegazione nella schermata iniziale
  ///
  /// In it, this message translates to:
  /// **'Un telefono crea la partita e mostra un QR, l\'altro lo inquadra. Poi le mosse viaggiano da sole sulla stessa Wi-Fi o sull\'hotspot di uno dei due.'**
  String get multiplayerIntro;

  /// Etichetta della scelta del colore di chi crea la partita
  ///
  /// In it, this message translates to:
  /// **'Il tuo colore'**
  String get multiplayerYourColor;

  /// Colore bianco
  ///
  /// In it, this message translates to:
  /// **'Bianco'**
  String get multiplayerWhite;

  /// Colore nero
  ///
  /// In it, this message translates to:
  /// **'Nero'**
  String get multiplayerBlack;

  /// Pulsante che crea l'invito
  ///
  /// In it, this message translates to:
  /// **'Crea la partita'**
  String get multiplayerCreate;

  /// Pulsante che apre la fotocamera per leggere l'invito
  ///
  /// In it, this message translates to:
  /// **'Unisciti con il QR'**
  String get multiplayerJoin;

  /// Errore quando il telefono non è in una rete locale
  ///
  /// In it, this message translates to:
  /// **'Collegati a una Wi-Fi o accendi l\'hotspot, poi riprova.'**
  String get multiplayerNoNetwork;

  /// Istruzioni sotto il QR dell'invito
  ///
  /// In it, this message translates to:
  /// **'Sull\'altro telefono apri Tu › Gioca con un amico › Unisciti con il QR e inquadra questo codice.'**
  String get multiplayerInviteHint;

  /// Descrizione del QR per il lettore di schermo
  ///
  /// In it, this message translates to:
  /// **'Codice QR dell\'invito alla partita'**
  String get multiplayerInviteQrLabel;

  /// Stato mentre chi ospita aspetta l'altro telefono
  ///
  /// In it, this message translates to:
  /// **'In attesa dell\'avversario…'**
  String get multiplayerWaiting;

  /// Stato mentre l'invitato si collega
  ///
  /// In it, this message translates to:
  /// **'Collegamento all\'altro telefono…'**
  String get multiplayerConnecting;

  /// Stato quando tocca a questo telefono
  ///
  /// In it, this message translates to:
  /// **'Tocca a te'**
  String get multiplayerYourTurn;

  /// Stato quando tocca all'altro telefono
  ///
  /// In it, this message translates to:
  /// **'Tocca all\'avversario'**
  String get multiplayerPeerTurn;

  /// Avviso quando la mossa non ha trovato un canale
  ///
  /// In it, this message translates to:
  /// **'Mossa non ancora consegnata: partirà appena l\'altro telefono sarà raggiungibile.'**
  String get multiplayerPending;

  /// Esito della partita
  ///
  /// In it, this message translates to:
  /// **'Vince il Bianco'**
  String get multiplayerWhiteWins;

  /// Esito della partita
  ///
  /// In it, this message translates to:
  /// **'Vince il Nero'**
  String get multiplayerBlackWins;

  /// Esito della partita
  ///
  /// In it, this message translates to:
  /// **'Patta'**
  String get multiplayerDraw;

  /// Titolo della schermata della fotocamera
  ///
  /// In it, this message translates to:
  /// **'Inquadra l\'invito'**
  String get multiplayerScanTitle;

  /// Istruzioni sotto la fotocamera
  ///
  /// In it, this message translates to:
  /// **'Inquadra il QR mostrato dall\'altro telefono.'**
  String get multiplayerScanHint;

  /// Errore per un QR estraneo
  ///
  /// In it, this message translates to:
  /// **'Questo QR non è un invito a una partita.'**
  String get multiplayerNotInvite;

  /// Errore della fotocamera
  ///
  /// In it, this message translates to:
  /// **'Fotocamera non disponibile.'**
  String get multiplayerCameraError;

  /// Titolo della conferma di uscita
  ///
  /// In it, this message translates to:
  /// **'Lasciare la partita?'**
  String get multiplayerLeaveTitle;

  /// Testo della conferma di uscita
  ///
  /// In it, this message translates to:
  /// **'Il collegamento con l\'altro telefono si chiude e la partita non viene salvata.'**
  String get multiplayerLeaveBody;

  /// Conferma l'uscita
  ///
  /// In it, this message translates to:
  /// **'Lascia'**
  String get multiplayerLeave;

  /// Annulla l'uscita
  ///
  /// In it, this message translates to:
  /// **'Resta'**
  String get multiplayerStay;

  /// Errore generico all'avvio della partita in rete locale
  ///
  /// In it, this message translates to:
  /// **'Non è stato possibile avviare la partita: riprova.'**
  String get multiplayerStartError;

  /// Titolo della schermata e della voce nella scheda Aperture
  ///
  /// In it, this message translates to:
  /// **'Le tue aperture'**
  String get personalTitle;

  /// Sottotitolo della voce nella scheda Aperture
  ///
  /// In it, this message translates to:
  /// **'Le mosse che hai giocato, con i risultati'**
  String get personalHubSubtitle;

  /// Errore di lettura dell'archivio
  ///
  /// In it, this message translates to:
  /// **'L\'archivio delle partite non si è potuto leggere: riprova più tardi.'**
  String get personalLoadFailed;

  /// Archivio senza partite utili
  ///
  /// In it, this message translates to:
  /// **'Gioca qualche partita contro il computer per costruire il tuo albero delle aperture.'**
  String get personalEmpty;

  /// Filtri senza partite
  ///
  /// In it, this message translates to:
  /// **'Nessuna partita con questi filtri.'**
  String get personalNoGamesFiltered;

  /// Posizione fuori dall'albero
  ///
  /// In it, this message translates to:
  /// **'Non hai mai giocato da questa posizione.'**
  String get personalNoGamesHere;

  /// Filtro colore: tutte le partite
  ///
  /// In it, this message translates to:
  /// **'Entrambi'**
  String get personalSideAll;

  /// Filtro colore: partite con il bianco
  ///
  /// In it, this message translates to:
  /// **'Bianco'**
  String get personalSideWhite;

  /// Filtro colore: partite con il nero
  ///
  /// In it, this message translates to:
  /// **'Nero'**
  String get personalSideBlack;

  /// Etichetta del filtro per avversario
  ///
  /// In it, this message translates to:
  /// **'Avversario'**
  String get personalOpponent;

  /// Filtro avversario senza restrizioni
  ///
  /// In it, this message translates to:
  /// **'Tutti gli avversari'**
  String get personalAllOpponents;

  /// Partite in cui è stata giocata una mossa
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} partita} other{{count} partite}}'**
  String personalGames(int count);

  /// Partite che rispettano i filtri
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} partita considerata} other{{count} partite considerate}}'**
  String personalGamesTotal(int count);

  /// Vittorie, patte e sconfitte in breve
  ///
  /// In it, this message translates to:
  /// **'{wins}V · {draws}P · {losses}S'**
  String personalScore(int wins, int draws, int losses);

  /// Vittorie, patte e sconfitte per i lettori di schermo
  ///
  /// In it, this message translates to:
  /// **'{wins} vinte, {draws} patte, {losses} perse'**
  String personalScoreSemantics(int wins, int draws, int losses);

  /// Titolo senza mosse
  ///
  /// In it, this message translates to:
  /// **'Posizione iniziale'**
  String get personalStartPosition;

  /// Titolo di una posizione senza nome nel libro
  ///
  /// In it, this message translates to:
  /// **'Apertura senza nome'**
  String get personalNoName;

  /// Torna alla mossa precedente
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get personalBack;

  /// Torna alla posizione iniziale
  ///
  /// In it, this message translates to:
  /// **'Inizio'**
  String get personalStart;

  /// Tooltip del pulsante che gira la scacchiera
  ///
  /// In it, this message translates to:
  /// **'Gira la scacchiera'**
  String get personalFlip;

  /// Tooltip: apre il libro delle aperture nella stessa posizione
  ///
  /// In it, this message translates to:
  /// **'Apri nell\'explorer delle aperture'**
  String get personalOpenInBook;

  /// Tooltip nell'explorer delle aperture: apre l'albero personale
  ///
  /// In it, this message translates to:
  /// **'Le tue partite da questa posizione'**
  String get personalFromHere;

  /// Titolo della scheda Aperture
  ///
  /// In it, this message translates to:
  /// **'Aperture'**
  String get openingsTitle;

  /// Voce e titolo dell'explorer delle aperture
  ///
  /// In it, this message translates to:
  /// **'Esplora aperture'**
  String get openingsExplorer;

  /// Sottotitolo della voce Esplora aperture
  ///
  /// In it, this message translates to:
  /// **'Nomi e continuazioni di oltre 3.000 aperture'**
  String get openingsExplorerSubtitle;

  /// Voce e titolo del repertorio del Bianco
  ///
  /// In it, this message translates to:
  /// **'Repertorio con il Bianco'**
  String get openingsRepertoireWhite;

  /// Voce e titolo del repertorio del Nero
  ///
  /// In it, this message translates to:
  /// **'Repertorio con il Nero'**
  String get openingsRepertoireBlack;

  /// Sottotitolo se il repertorio non si carica
  ///
  /// In it, this message translates to:
  /// **'Repertorio non disponibile'**
  String get openingsRepertoireUnavailable;

  /// Sottotitolo durante il caricamento del repertorio
  ///
  /// In it, this message translates to:
  /// **'Caricamento...'**
  String get openingsLoading;

  /// Sottotitolo del repertorio: linee e mosse in scadenza
  ///
  /// In it, this message translates to:
  /// **'{lines, plural, one{1 linea} other{{lines} linee}} · {due, plural, one{1 mossa da ripassare} other{{due} mosse da ripassare}}'**
  String openingsRepertoireSummary(int lines, int due);

  /// Colore dei pezzi bianchi
  ///
  /// In it, this message translates to:
  /// **'Bianco'**
  String get openingsWhite;

  /// Colore dei pezzi neri
  ///
  /// In it, this message translates to:
  /// **'Nero'**
  String get openingsBlack;

  /// Pulsante che chiude un dialogo senza scegliere
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get openingsCancel;

  /// Toglie l'ultima mossa nell'explorer
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get openingsBack;

  /// Riporta l'explorer alla posizione iniziale
  ///
  /// In it, this message translates to:
  /// **'Inizio'**
  String get openingsReset;

  /// Descrizione dell'icona che cambia il lato della scacchiera
  ///
  /// In it, this message translates to:
  /// **'Gira la scacchiera'**
  String get openingsFlipBoard;

  /// Errore nell'explorer se il libro non si carica
  ///
  /// In it, this message translates to:
  /// **'Impossibile caricare le aperture.'**
  String get openingsLoadFailed;

  /// Nome della posizione senza mosse nell'explorer
  ///
  /// In it, this message translates to:
  /// **'Posizione iniziale'**
  String get openingsStartPosition;

  /// Posizione dell'explorer che non ha un nome nel libro
  ///
  /// In it, this message translates to:
  /// **'Apertura senza nome'**
  String get openingsUnnamed;

  /// Nessuna continuazione nel libro
  ///
  /// In it, this message translates to:
  /// **'Fuori dal libro delle aperture'**
  String get openingsOutOfBook;

  /// Titolo della partita da un'apertura senza nome
  ///
  /// In it, this message translates to:
  /// **'Apertura libera'**
  String get openingsFreeTitle;

  /// Icona e titolo del dialogo per aggiungere la linea corrente
  ///
  /// In it, this message translates to:
  /// **'Aggiungi al repertorio'**
  String get openingsAddToRepertoire;

  /// Conferma l'aggiunta al repertorio
  ///
  /// In it, this message translates to:
  /// **'Aggiungi'**
  String get openingsAdd;

  /// Campo del nome della linea
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get openingsLineName;

  /// Nome proposto per una linea senza apertura riconosciuta
  ///
  /// In it, this message translates to:
  /// **'Linea'**
  String get openingsDefaultLineName;

  /// Nome di una linea importata da PGN
  ///
  /// In it, this message translates to:
  /// **'PGN {n}'**
  String openingsPgnLineName(int n);

  /// Conferma dopo l'aggiunta al repertorio del Bianco
  ///
  /// In it, this message translates to:
  /// **'Linea aggiunta al repertorio del Bianco.'**
  String get openingsLineAddedWhite;

  /// Conferma dopo l'aggiunta al repertorio del Nero
  ///
  /// In it, this message translates to:
  /// **'Linea aggiunta al repertorio del Nero.'**
  String get openingsLineAddedBlack;

  /// Icona dell'explorer che avvia la partita dall'apertura (RF-94)
  ///
  /// In it, this message translates to:
  /// **'Gioca questa apertura'**
  String get openingsPlayOpening;

  /// Icona di una linea del repertorio che avvia la partita (RF-94)
  ///
  /// In it, this message translates to:
  /// **'Gioca la linea'**
  String get openingsPlayLine;

  /// Titolo del dialogo con colore e livello (RF-94)
  ///
  /// In it, this message translates to:
  /// **'Gioca contro il computer'**
  String get openingsPlayDialogTitle;

  /// Campo del livello del computer
  ///
  /// In it, this message translates to:
  /// **'Livello'**
  String get openingsPlayLevel;

  /// Conferma l'avvio della partita
  ///
  /// In it, this message translates to:
  /// **'Gioca'**
  String get openingsPlay;

  /// Avviso in partita (RF-94)
  ///
  /// In it, this message translates to:
  /// **'Il computer è uscito dalla linea del repertorio.'**
  String get openingsLeftByComputer;

  /// Avviso in partita (RF-94)
  ///
  /// In it, this message translates to:
  /// **'Sei uscito dalla linea del repertorio.'**
  String get openingsLeftByUser;

  /// Etichetta per i lettori di schermo del nome dell'apertura in partita
  ///
  /// In it, this message translates to:
  /// **'Apertura: {name} ({eco})'**
  String openingsGameSemantics(String name, String eco);

  /// Icona e titolo del dialogo di importazione
  ///
  /// In it, this message translates to:
  /// **'Importa PGN'**
  String get openingsImportPgn;

  /// Aiuto sotto il campo del PGN
  ///
  /// In it, this message translates to:
  /// **'Ogni variante diventa una linea.'**
  String get openingsImportHelper;

  /// Conferma l'importazione del PGN
  ///
  /// In it, this message translates to:
  /// **'Importa'**
  String get openingsImport;

  /// Esito di un'importazione senza linee
  ///
  /// In it, this message translates to:
  /// **'Nessuna linea valida nel PGN.'**
  String get openingsNoValidLines;

  /// Esito dell'importazione
  ///
  /// In it, this message translates to:
  /// **'Linee aggiunte: {added}'**
  String openingsLinesAdded(int added);

  /// Esito dell'importazione con linee scartate; reason è il primo motivo
  ///
  /// In it, this message translates to:
  /// **'Linee aggiunte: {added}. Scartate: {discarded} ({reason})'**
  String openingsLinesAddedDiscarded(int added, int discarded, String reason);

  /// Repertorio vuoto
  ///
  /// In it, this message translates to:
  /// **'Nessuna linea. Aggiungile da Esplora aperture con il pulsante \"Aggiungi al repertorio\" o importa un PGN.'**
  String get openingsNoLines;

  /// Icona che elimina una linea
  ///
  /// In it, this message translates to:
  /// **'Elimina la linea'**
  String get openingsDeleteLine;

  /// Pulsante di ripasso senza mosse in scadenza
  ///
  /// In it, this message translates to:
  /// **'Nessuna mossa da ripassare'**
  String get openingsNothingToReview;

  /// Pulsante che avvia il ripasso
  ///
  /// In it, this message translates to:
  /// **'Ripassa {due, plural, one{1 mossa} other{{due} mosse}}'**
  String openingsReviewMoves(int due);

  /// Titolo della schermata di ripasso
  ///
  /// In it, this message translates to:
  /// **'Ripasso del repertorio'**
  String get openingsDrillTitle;

  /// Fine del ripasso
  ///
  /// In it, this message translates to:
  /// **'Ripasso completato: {count, plural, one{1 mossa} other{{count} mosse}}.'**
  String openingsDrillDone(int count);

  /// Invito del ripasso per una mossa mai vista
  ///
  /// In it, this message translates to:
  /// **'Nuova mossa: gioca quella indicata dalla freccia.'**
  String get openingsDrillNewMove;

  /// Invito del ripasso
  ///
  /// In it, this message translates to:
  /// **'Linea \"{name}\": qual è la tua mossa?'**
  String openingsDrillPrompt(String name);

  /// Dopo una mossa sbagliata nel ripasso
  ///
  /// In it, this message translates to:
  /// **'Non è la mossa del repertorio: ecco quella giusta.'**
  String get openingsDrillWrong;

  /// Errore: linea senza mosse
  ///
  /// In it, this message translates to:
  /// **'La linea è vuota.'**
  String get openingsErrorEmpty;

  /// Errore: mossa illegale
  ///
  /// In it, this message translates to:
  /// **'La linea contiene una mossa illegale.'**
  String get openingsErrorIllegal;

  /// Errore: nessuna mossa del colore del repertorio
  ///
  /// In it, this message translates to:
  /// **'La linea non contiene mosse del tuo colore.'**
  String get openingsErrorNoOwnMoves;

  /// Errore: un'altra mossa è già prevista
  ///
  /// In it, this message translates to:
  /// **'In questa posizione il repertorio prevede già {san}.'**
  String openingsErrorConflict(String san);

  /// Titolo della schermata e della voce in «Tu»
  ///
  /// In it, this message translates to:
  /// **'Scacchiera fisica'**
  String get physicalTitle;

  /// Sottotitolo della voce in «Tu»
  ///
  /// In it, this message translates to:
  /// **'Orologio e registro per una partita dal vivo'**
  String get physicalEntrySubtitle;

  /// Spiegazione nella schermata iniziale
  ///
  /// In it, this message translates to:
  /// **'Gioca su una scacchiera vera: l\'app fa da orologio e registra la partita. Dopo ogni mossa scrivila o toccala tra quelle legali.'**
  String get physicalIntro;

  /// Nome predefinito e lato del Bianco
  ///
  /// In it, this message translates to:
  /// **'Bianco'**
  String get physicalWhite;

  /// Nome predefinito e lato del Nero
  ///
  /// In it, this message translates to:
  /// **'Nero'**
  String get physicalBlack;

  /// Scelta della partita senza orologio
  ///
  /// In it, this message translates to:
  /// **'Senza tempo'**
  String get physicalUntimed;

  /// Pulsante che avvia la partita
  ///
  /// In it, this message translates to:
  /// **'Inizia la partita'**
  String get physicalStart;

  /// Etichetta del campo mossa quando muove il Bianco
  ///
  /// In it, this message translates to:
  /// **'Mossa del Bianco (es. e4, Cf3)'**
  String get physicalInputWhite;

  /// Etichetta del campo mossa quando muove il Nero
  ///
  /// In it, this message translates to:
  /// **'Mossa del Nero (es. e5, Cc6)'**
  String get physicalInputBlack;

  /// Avviso per una mossa illegale o ambigua
  ///
  /// In it, this message translates to:
  /// **'Mossa non valida: «{text}»'**
  String physicalInvalidMove(String text);

  /// Registro vuoto
  ///
  /// In it, this message translates to:
  /// **'Nessuna mossa'**
  String get physicalNoMoves;

  /// Ferma l'orologio
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get physicalPause;

  /// Riavvia l'orologio
  ///
  /// In it, this message translates to:
  /// **'Riprendi'**
  String get physicalResume;

  /// Toglie l'ultima mossa
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get physicalUndo;

  /// Pulsante patta concordata
  ///
  /// In it, this message translates to:
  /// **'Patta'**
  String get physicalDraw;

  /// Pulsante abbandono
  ///
  /// In it, this message translates to:
  /// **'Abbandona'**
  String get physicalResign;

  /// Domanda di conferma della patta
  ///
  /// In it, this message translates to:
  /// **'Patta concordata?'**
  String get physicalDrawQuestion;

  /// Conferma
  ///
  /// In it, this message translates to:
  /// **'Sì'**
  String get physicalYes;

  /// Rifiuto
  ///
  /// In it, this message translates to:
  /// **'No'**
  String get physicalNo;

  /// Titolo della scelta di chi abbandona
  ///
  /// In it, this message translates to:
  /// **'Chi abbandona?'**
  String get physicalWhoResigns;

  /// Conferma di salvataggio
  ///
  /// In it, this message translates to:
  /// **'Partita salvata nell\'archivio'**
  String get physicalSaved;

  /// Partita finita senza mosse
  ///
  /// In it, this message translates to:
  /// **'Nessuna mossa da salvare'**
  String get physicalNothingToSave;

  /// Errore di salvataggio
  ///
  /// In it, this message translates to:
  /// **'Salvataggio non riuscito'**
  String get physicalSaveFailed;

  /// Torna alla schermata iniziale
  ///
  /// In it, this message translates to:
  /// **'Nuova partita'**
  String get physicalNewGame;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Scacco matto'**
  String get physicalEndCheckmate;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Abbandono'**
  String get physicalEndResignation;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Tempo scaduto'**
  String get physicalEndTimeout;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Patta concordata'**
  String get physicalEndAgreement;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Stallo'**
  String get physicalEndStalemate;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Materiale insufficiente'**
  String get physicalEndInsufficient;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Tripla ripetizione'**
  String get physicalEndRepetition;

  /// Motivo di fine partita
  ///
  /// In it, this message translates to:
  /// **'Regola delle 50 mosse'**
  String get physicalEndFiftyMoves;

  /// Motivo di fine partita non previsto
  ///
  /// In it, this message translates to:
  /// **'Partita finita'**
  String get physicalEndOther;

  /// Motivo e risultato (1-0, 0-1, 1/2-1/2)
  ///
  /// In it, this message translates to:
  /// **'{reason} · {result}'**
  String physicalResultLine(String reason, String result);

  /// Pulsante che apre la fotocamera
  ///
  /// In it, this message translates to:
  /// **'Mossa dalla foto'**
  String get physicalPhoto;

  /// Chiede di nuovo gli angoli della scacchiera
  ///
  /// In it, this message translates to:
  /// **'Riallinea'**
  String get physicalRealign;

  /// Errore della fotocamera
  ///
  /// In it, this message translates to:
  /// **'Fotocamera non disponibile'**
  String get physicalCameraUnavailable;

  /// Errore di decodifica della foto
  ///
  /// In it, this message translates to:
  /// **'Immagine non leggibile'**
  String get physicalImageUnreadable;

  /// Dopo la prima foto
  ///
  /// In it, this message translates to:
  /// **'Foto di riferimento salvata. Dopo la prossima mossa scatta un\'altra foto.'**
  String get physicalReferenceSaved;

  /// Due foto uguali
  ///
  /// In it, this message translates to:
  /// **'Nessuna mossa riconosciuta: la scacchiera è uguale.'**
  String get physicalNoMoveRecognized;

  /// Sopra le mosse proposte
  ///
  /// In it, this message translates to:
  /// **'Mosse più probabili dalla foto: conferma quella giusta.'**
  String get physicalGuessNote;

  /// Titolo della schermata di allineamento
  ///
  /// In it, this message translates to:
  /// **'Allinea la scacchiera'**
  String get physicalAlignTitle;

  /// Istruzione di allineamento
  ///
  /// In it, this message translates to:
  /// **'Trascina i quattro cerchi sugli angoli della scacchiera. Per le foto successive terrai la stessa inquadratura.'**
  String get physicalAlignHelp;

  /// Lato in basso nella foto
  ///
  /// In it, this message translates to:
  /// **'Bianco in basso'**
  String get physicalAlignWhiteBottom;

  /// Lato in basso nella foto
  ///
  /// In it, this message translates to:
  /// **'Nero in basso'**
  String get physicalAlignBlackBottom;

  /// Conferma l'allineamento
  ///
  /// In it, this message translates to:
  /// **'Fatto'**
  String get physicalAlignDone;

  /// Obiettivo del puzzle mostrato sopra la scacchiera e letto dai lettori di schermo
  ///
  /// In it, this message translates to:
  /// **'{goal, select, mateIn1{Obiettivo: matto in 1} mateIn2{Obiettivo: matto in 2} mateIn3{Obiettivo: matto in 3} mateIn4{Obiettivo: matto in 4} mate{Obiettivo: dai matto} crushing{Obiettivo: ottieni un vantaggio decisivo} advantage{Obiettivo: ottieni il vantaggio} equality{Obiettivo: ottieni la parità} other{Obiettivo: trova la mossa migliore}}'**
  String puzzleGoal(String goal);

  /// Voce della scheda Puzzle e titolo della schermata
  ///
  /// In it, this message translates to:
  /// **'Sfida un amico'**
  String get challengeTitle;

  /// Sottotitolo della voce nella scheda Puzzle
  ///
  /// In it, this message translates to:
  /// **'Gli stessi puzzle su due telefoni, senza rete'**
  String get challengeSubtitle;

  /// Spiegazione in cima alla schermata della sfida
  ///
  /// In it, this message translates to:
  /// **'Scegli la prova e mostra il QR all\'amico: giocate gli stessi puzzle. A fine prova vi scambiate i punteggi con un secondo QR.'**
  String get challengeIntro;

  /// Pulsante che crea la sfida
  ///
  /// In it, this message translates to:
  /// **'Prepara la sfida'**
  String get challengePrepare;

  /// Sfida creata, in attesa di mostrare il QR
  ///
  /// In it, this message translates to:
  /// **'Sfida pronta: {mode}'**
  String challengeReady(String mode);

  /// Pulsante che apre il QR della sfida
  ///
  /// In it, this message translates to:
  /// **'Mostra il QR all\'amico'**
  String get challengeShowInvite;

  /// Pulsante che avvia la prova
  ///
  /// In it, this message translates to:
  /// **'Gioca la tua prova'**
  String get challengePlay;

  /// Pulsante che apre la fotocamera
  ///
  /// In it, this message translates to:
  /// **'Ricevi una sfida'**
  String get challengeReceive;

  /// Titolo sopra il QR della sfida
  ///
  /// In it, this message translates to:
  /// **'Sfida: {mode}'**
  String challengeInviteTitle(String mode);

  /// Istruzioni sotto il QR della sfida
  ///
  /// In it, this message translates to:
  /// **'L\'amico apre Puzzle › Sfida un amico › Ricevi una sfida e inquadra il codice.'**
  String get challengeInviteHint;

  /// Istruzioni sotto la fotocamera per la sfida
  ///
  /// In it, this message translates to:
  /// **'Inquadra il QR della sfida mostrato dall\'amico.'**
  String get challengeReceiveHint;

  /// Errore: QR letto di altro tipo
  ///
  /// In it, this message translates to:
  /// **'Questo QR non è una sfida: chiedi all\'amico di mostrare il QR della sfida.'**
  String get challengeNotInvite;

  /// Errore: raccolte di puzzle diverse
  ///
  /// In it, this message translates to:
  /// **'I due telefoni hanno puzzle diversi: aggiornate Rokko su entrambi.'**
  String get challengeLibraryMismatch;

  /// Titolo del confronto a fine prova
  ///
  /// In it, this message translates to:
  /// **'Sfida con l\'amico'**
  String get challengeCompareTitle;

  /// Pulsante che apre il QR del risultato
  ///
  /// In it, this message translates to:
  /// **'Mostra il mio risultato'**
  String get challengeShowResult;

  /// Titolo sopra il QR del risultato
  ///
  /// In it, this message translates to:
  /// **'Il mio risultato: {score}'**
  String challengeResultTitle(int score);

  /// Istruzioni sotto il QR del risultato
  ///
  /// In it, this message translates to:
  /// **'L\'amico inquadra questo codice per vedere il tuo punteggio.'**
  String get challengeResultHint;

  /// Pulsante che apre la fotocamera per il risultato
  ///
  /// In it, this message translates to:
  /// **'Leggi il risultato dell\'amico'**
  String get challengeReadResult;

  /// Istruzioni sotto la fotocamera per il risultato
  ///
  /// In it, this message translates to:
  /// **'Inquadra il QR del risultato mostrato dall\'amico.'**
  String get challengeReadResultHint;

  /// Errore: QR letto di altro tipo
  ///
  /// In it, this message translates to:
  /// **'Questo QR non è un risultato: chiedi all\'amico di mostrare il QR del risultato.'**
  String get challengeNotResult;

  /// Errore: il risultato non appartiene a questa sfida
  ///
  /// In it, this message translates to:
  /// **'Il risultato è di un\'altra sfida.'**
  String get challengeOtherChallenge;

  /// Esito del confronto
  ///
  /// In it, this message translates to:
  /// **'Hai vinto: {mine} a {theirs}'**
  String challengeWon(int mine, int theirs);

  /// Esito del confronto
  ///
  /// In it, this message translates to:
  /// **'Ha vinto l\'amico: {theirs} a {mine}'**
  String challengeLost(int mine, int theirs);

  /// Esito del confronto
  ///
  /// In it, this message translates to:
  /// **'Pareggio: {mine} a {theirs}'**
  String challengeDraw(int mine, int theirs);

  /// Impostazioni: titolo dell'interruttore
  ///
  /// In it, this message translates to:
  /// **'Spiegami perché'**
  String get settingsExplainWhy;

  /// Impostazioni: descrizione
  ///
  /// In it, this message translates to:
  /// **'Dopo ogni mossa del computer, una riga su cosa minaccia o prepara'**
  String get settingsExplainWhyDescription;

  /// Impostazioni: titolo dell'interruttore; in partita è anche l'etichetta del pulsante
  ///
  /// In it, this message translates to:
  /// **'Modalità zen'**
  String get settingsZenMode;

  /// Impostazioni: descrizione
  ///
  /// In it, this message translates to:
  /// **'In partita restano solo scacchiera e mosse: niente Elo, materiale, stato, avvisi dell\'allenatore e commenti'**
  String get settingsZenModeDescription;

  /// shareImageTitle
  ///
  /// In it, this message translates to:
  /// **'Esporta come immagine'**
  String get shareImageTitle;

  /// shareImageAction
  ///
  /// In it, this message translates to:
  /// **'Condividi'**
  String get shareImageAction;

  /// shareImageFlip
  ///
  /// In it, this message translates to:
  /// **'Capovolgi la scacchiera'**
  String get shareImageFlip;

  /// shareImageCoordinates
  ///
  /// In it, this message translates to:
  /// **'Coordinate'**
  String get shareImageCoordinates;

  /// shareImageLastMove
  ///
  /// In it, this message translates to:
  /// **'Ultima mossa'**
  String get shareImageLastMove;

  /// shareImageCaption
  ///
  /// In it, this message translates to:
  /// **'Didascalia (facoltativa)'**
  String get shareImageCaption;

  /// shareImagePreview
  ///
  /// In it, this message translates to:
  /// **'Anteprima della scacchiera'**
  String get shareImagePreview;

  /// shareImageFailed
  ///
  /// In it, this message translates to:
  /// **'Condivisione non riuscita'**
  String get shareImageFailed;

  /// shareImageSubject
  ///
  /// In it, this message translates to:
  /// **'Posizione di scacchi'**
  String get shareImageSubject;

  /// No description provided for @statsTitle.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statsTitle;

  /// No description provided for @statsLoadFailed.
  ///
  /// In it, this message translates to:
  /// **'L\'archivio delle partite non si è potuto leggere: riprova più tardi.'**
  String get statsLoadFailed;

  /// No description provided for @statsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Gioca qualche partita contro il computer per vedere le statistiche.'**
  String get statsEmpty;

  /// Sezione con vittorie, patte e sconfitte
  ///
  /// In it, this message translates to:
  /// **'Bilancio'**
  String get statsRecord;

  /// Tutte le partite
  ///
  /// In it, this message translates to:
  /// **'Tutte'**
  String get statsAllGames;

  /// No description provided for @statsWithWhite.
  ///
  /// In it, this message translates to:
  /// **'Con il bianco'**
  String get statsWithWhite;

  /// No description provided for @statsWithBlack.
  ///
  /// In it, this message translates to:
  /// **'Con il nero'**
  String get statsWithBlack;

  /// No description provided for @statsLocalGames.
  ///
  /// In it, this message translates to:
  /// **'Partite tra due persone'**
  String get statsLocalGames;

  /// No description provided for @statsByTimeControl.
  ///
  /// In it, this message translates to:
  /// **'Per cadenza'**
  String get statsByTimeControl;

  /// No description provided for @statsTopOpenings.
  ///
  /// In it, this message translates to:
  /// **'Aperture più giocate'**
  String get statsTopOpenings;

  /// No description provided for @statsGames.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} partita} other{{count} partite}}'**
  String statsGames(int count);

  /// No description provided for @statsAccuracy.
  ///
  /// In it, this message translates to:
  /// **'Precisione'**
  String get statsAccuracy;

  /// No description provided for @statsAverage.
  ///
  /// In it, this message translates to:
  /// **'Media'**
  String get statsAverage;

  /// No description provided for @statsAccuracyTrend.
  ///
  /// In it, this message translates to:
  /// **'Andamento della precisione'**
  String get statsAccuracyTrend;

  /// No description provided for @statsRating.
  ///
  /// In it, this message translates to:
  /// **'Rating stimato {rating}'**
  String statsRating(int rating);

  /// No description provided for @statsRatingProvisional.
  ///
  /// In it, this message translates to:
  /// **'provvisorio: servono {count} partite contro il computer'**
  String statsRatingProvisional(int count);

  /// No description provided for @statsRatingGames.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{su {count} partita contro il computer} other{su {count} partite contro il computer}}'**
  String statsRatingGames(int count);

  /// No description provided for @statsRatingTrend.
  ///
  /// In it, this message translates to:
  /// **'Andamento del rating'**
  String get statsRatingTrend;

  /// Etichetta per la lettura dello schermo di un bilancio vuoto
  ///
  /// In it, this message translates to:
  /// **'nessuna partita'**
  String get statsNoGames;

  /// Etichetta per la lettura dello schermo della percentuale
  ///
  /// In it, this message translates to:
  /// **'{wins, plural, one{{wins} vittoria} other{{wins} vittorie}}, {draws, plural, one{{draws} patta} other{{draws} patte}}, {losses, plural, one{{losses} sconfitta} other{{losses} sconfitte}}'**
  String statsScoreDetail(int wins, int draws, int losses);

  /// Etichetta per la lettura dello schermo di un grafico
  ///
  /// In it, this message translates to:
  /// **'{label}: da {first} a {last}, minimo {min}, massimo {max}'**
  String statsTrend(
    String label,
    String first,
    String last,
    String min,
    String max,
  );

  /// Titolo della schermata della storia
  ///
  /// In it, this message translates to:
  /// **'Storia'**
  String get storyTitle;

  /// storyEntrySubtitle
  ///
  /// In it, this message translates to:
  /// **'Un viaggio a capitoli: lezioni, puzzle e sfide'**
  String get storyEntrySubtitle;

  /// storyChapterNumber
  ///
  /// In it, this message translates to:
  /// **'Capitolo {n}'**
  String storyChapterNumber(int n);

  /// storyProgress
  ///
  /// In it, this message translates to:
  /// **'{done} capitoli su {total}'**
  String storyProgress(int done, int total);

  /// storyChapterLocked
  ///
  /// In it, this message translates to:
  /// **'Si apre concludendo il capitolo precedente'**
  String get storyChapterLocked;

  /// storyChapterDone
  ///
  /// In it, this message translates to:
  /// **'Capitolo concluso'**
  String get storyChapterDone;

  /// storyContinue
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get storyContinue;

  /// storyFinished
  ///
  /// In it, this message translates to:
  /// **'La storia è finita. Lezioni, puzzle e partite restano disponibili nel resto dell\'app.'**
  String get storyFinished;

  /// storyStepLessons
  ///
  /// In it, this message translates to:
  /// **'Lezioni: {value} su {total}'**
  String storyStepLessons(int value, int total);

  /// storyStepPuzzles
  ///
  /// In it, this message translates to:
  /// **'Puzzle del capitolo: {value} su {total}'**
  String storyStepPuzzles(int value, int total);

  /// storyStepGuardian
  ///
  /// In it, this message translates to:
  /// **'Il guardiano del capitolo'**
  String get storyStepGuardian;

  /// storyStepBoss
  ///
  /// In it, this message translates to:
  /// **'Sfida a {name}'**
  String storyStepBoss(String name);

  /// storyStepDone
  ///
  /// In it, this message translates to:
  /// **'fatto'**
  String get storyStepDone;

  /// storyStepTodo
  ///
  /// In it, this message translates to:
  /// **'da fare'**
  String get storyStepTodo;

  /// storyStepLocked
  ///
  /// In it, this message translates to:
  /// **'bloccato'**
  String get storyStepLocked;

  /// storyStepLockedHint
  ///
  /// In it, this message translates to:
  /// **'Prima concludi il passo precedente.'**
  String get storyStepLockedHint;

  /// storyEngineMissing
  ///
  /// In it, this message translates to:
  /// **'Le sfide si giocano dove gira il computer: Android e iOS, o Windows e Linux con Stockfish installato.'**
  String get storyEngineMissing;

  /// storyBossWon
  ///
  /// In it, this message translates to:
  /// **'Hai battuto {name}!'**
  String storyBossWon(String name);

  /// storyBossLost
  ///
  /// In it, this message translates to:
  /// **'{name} resiste ancora: riprova quando vuoi.'**
  String storyBossLost(String name);

  /// storyPuzzlesNone
  ///
  /// In it, this message translates to:
  /// **'I puzzle non si possono caricare: riprova.'**
  String get storyPuzzlesNone;

  /// storyVillageTitle
  ///
  /// In it, this message translates to:
  /// **'Il villaggio dei pezzi'**
  String get storyVillageTitle;

  /// storyVillageIntro
  ///
  /// In it, this message translates to:
  /// **'Arrivi al villaggio ai piedi della Rocca. Gli abitanti non ricordano più come si muovono i loro pezzi: aiutali con le lezioni, poi dimostra di accorgerti subito di un pezzo lasciato in presa.'**
  String get storyVillageIntro;

  /// storyVillageBoss
  ///
  /// In it, this message translates to:
  /// **'{name}, il custode del villaggio, ti sfida per vedere se hai imparato davvero.'**
  String storyVillageBoss(String name);

  /// storyVillageOutro
  ///
  /// In it, this message translates to:
  /// **'Il villaggio ti saluta con una festa. La strada per le porte della città è aperta.'**
  String get storyVillageOutro;

  /// storyGatesTitle
  ///
  /// In it, this message translates to:
  /// **'Le porte della città'**
  String get storyGatesTitle;

  /// storyGatesIntro
  ///
  /// In it, this message translates to:
  /// **'Le guardie ti fermano alle porte: per entrare devi conoscere le regole, dallo scacco all\'arrocco. Una promozione ben vista apre anche il cancello più alto.'**
  String get storyGatesIntro;

  /// storyGatesBoss
  ///
  /// In it, this message translates to:
  /// **'{name}, capitana delle guardie, vuole una prova prima di lasciarti passare.'**
  String storyGatesBoss(String name);

  /// storyGatesOutro
  ///
  /// In it, this message translates to:
  /// **'Le porte si aprono. Davanti a te si alza la torre del re.'**
  String get storyGatesOutro;

  /// storyTowerTitle
  ///
  /// In it, this message translates to:
  /// **'La torre del re'**
  String get storyTowerTitle;

  /// storyTowerIntro
  ///
  /// In it, this message translates to:
  /// **'In cima alla torre vive il re, e sa difendersi. Impara i matti per metterlo alle strette, anche quando i suoi stessi pezzi gli fanno da muro.'**
  String get storyTowerIntro;

  /// storyTowerBoss
  ///
  /// In it, this message translates to:
  /// **'{name}, il cavaliere che ama i gambetti, ti aspetta in cima alle scale.'**
  String storyTowerBoss(String name);

  /// storyTowerOutro
  ///
  /// In it, this message translates to:
  /// **'Il re della torre è in scacco matto. Resta il bosco, e le sue trappole.'**
  String get storyTowerOutro;

  /// storyForestTitle
  ///
  /// In it, this message translates to:
  /// **'Il bosco delle trappole'**
  String get storyForestTitle;

  /// storyForestIntro
  ///
  /// In it, this message translates to:
  /// **'Nel bosco ogni pezzo nasconde una trappola: forchette, inchiodature, infilate. Impara a vederle prima degli altri.'**
  String get storyForestIntro;

  /// storyForestBoss
  ///
  /// In it, this message translates to:
  /// **'{name}, la guida del bosco, conosce ogni sentiero e ogni insidia.'**
  String storyForestBoss(String name);

  /// storyForestOutro
  ///
  /// In it, this message translates to:
  /// **'Hai attraversato il bosco senza cadere in nessuna trappola. Il castello ti aspetta.'**
  String get storyForestOutro;

  /// storyCastleTitle
  ///
  /// In it, this message translates to:
  /// **'Il castello dei finali'**
  String get storyCastleTitle;

  /// storyCastleIntro
  ///
  /// In it, this message translates to:
  /// **'Nel castello sulla scacchiera restano pochi pezzi e ogni mossa conta. Qui si decide chi sa chiudere una partita.'**
  String get storyCastleIntro;

  /// storyCastleBoss
  ///
  /// In it, this message translates to:
  /// **'{name}, il castellano, difende l\'ingresso della sala della corona.'**
  String storyCastleBoss(String name);

  /// storyCastleOutro
  ///
  /// In it, this message translates to:
  /// **'Il portone si apre: la corona è vicina.'**
  String get storyCastleOutro;

  /// storyCrownTitle
  ///
  /// In it, this message translates to:
  /// **'La corona'**
  String get storyCrownTitle;

  /// storyCrownIntro
  ///
  /// In it, this message translates to:
  /// **'Ultima tappa: la sala della corona. Partire bene è mezza vittoria: il centro, lo sviluppo, l\'arrocco.'**
  String get storyCrownIntro;

  /// storyCrownBoss
  ///
  /// In it, this message translates to:
  /// **'{name}, la guardiana della corona, gioca le aperture come nessun altro.'**
  String storyCrownBoss(String name);

  /// storyCrownOutro
  ///
  /// In it, this message translates to:
  /// **'La corona è tua. Il regno è in pace e ogni nuova partita è una nuova storia.'**
  String get storyCrownOutro;

  /// Voce della scheda Tu
  ///
  /// In it, this message translates to:
  /// **'Riepilogo settimanale'**
  String get weeklyEntryTitle;

  /// Pagina vuota del riepilogo
  ///
  /// In it, this message translates to:
  /// **'Negli ultimi sette giorni non hai ancora fatto nulla. Gioca una partita o risolvi un puzzle: il riepilogo si riempie da solo.'**
  String get weeklyEmpty;

  /// Titolo della sezione progressi
  ///
  /// In it, this message translates to:
  /// **'I tuoi progressi'**
  String get weeklyProgressHeading;

  /// Partite della settimana
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} partita} other{{count} partite}}'**
  String weeklyGames(int count);

  /// Esiti delle partite
  ///
  /// In it, this message translates to:
  /// **'{wins} vinte, {draws} patte, {losses} perse'**
  String weeklyGameResults(int wins, int draws, int losses);

  /// Puzzle della settimana
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} puzzle risolto} other{{count} puzzle risolti}}'**
  String weeklyPuzzles(int count);

  /// Lezioni della settimana
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} lezione completata} other{{count} lezioni completate}}'**
  String weeklyLessons(int count);

  /// Revisioni della settimana
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} partita rivista} other{{count} partite riviste}}'**
  String weeklyReviews(int count);

  /// Minuti di allenamento
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} minuto di allenamento} other{{count} minuti di allenamento}}'**
  String weeklyMinutes(int count);

  /// Precisione media delle revisioni
  ///
  /// In it, this message translates to:
  /// **'Precisione media {percent}%'**
  String weeklyAccuracy(int percent);

  /// Precisione in aumento
  ///
  /// In it, this message translates to:
  /// **'{points, plural, one{{points} punto in più della settimana scorsa} other{{points} punti in più della settimana scorsa}}'**
  String weeklyAccuracyUp(int points);

  /// Precisione in calo
  ///
  /// In it, this message translates to:
  /// **'{points, plural, one{{points} punto in meno della settimana scorsa} other{{points} punti in meno della settimana scorsa}}'**
  String weeklyAccuracyDown(int points);

  /// Titolo della sezione errore
  ///
  /// In it, this message translates to:
  /// **'Errore più frequente'**
  String get weeklyErrorHeading;

  /// Errore ricorrente con il numero di volte
  ///
  /// In it, this message translates to:
  /// **'{error}: {count, plural, one{{count} volta} other{{count} volte}}'**
  String weeklyErrorLine(String error, int count);

  /// Nessun errore ricorrente
  ///
  /// In it, this message translates to:
  /// **'Nessun errore si è ripetuto: ottimo lavoro.'**
  String get weeklyNoError;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'pezzi lasciati in presa'**
  String get weeklyErrorHangingPiece;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'forchette subite'**
  String get weeklyErrorAllowedFork;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'forchette mancate'**
  String get weeklyErrorMissedFork;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'inchiodature subite'**
  String get weeklyErrorAllowedPin;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'attacchi di scoperta mancati'**
  String get weeklyErrorMissedDiscovery;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'re lasciato scoperto'**
  String get weeklyErrorExposedKing;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'matti mancati'**
  String get weeklyErrorMissedMate;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'matti subiti'**
  String get weeklyErrorAllowedMate;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'perdite di materiale'**
  String get weeklyErrorMaterialLoss;

  /// Nome di un errore ricorrente, in minuscolo
  ///
  /// In it, this message translates to:
  /// **'catture mancate'**
  String get weeklyErrorMissedCapture;

  /// Titolo della sezione consiglio
  ///
  /// In it, this message translates to:
  /// **'Il consiglio'**
  String get weeklyAdviceHeading;

  /// Consiglio: lezione
  ///
  /// In it, this message translates to:
  /// **'Ripassa la lezione «{title}» del Percorso.'**
  String weeklyAdviceLesson(String title);

  /// Consiglio: puzzle di un tema
  ///
  /// In it, this message translates to:
  /// **'Allenati con i puzzle «{title}».'**
  String weeklyAdvicePuzzles(String title);

  /// Consiglio: rivedere una partita
  ///
  /// In it, this message translates to:
  /// **'Rivedi una delle tue partite: il coach ti mostra dove migliorare.'**
  String get weeklyAdviceReview;

  /// Consiglio: puzzle
  ///
  /// In it, this message translates to:
  /// **'Risolvi qualche puzzle: bastano pochi minuti al giorno.'**
  String get weeklyAdviceSolvePuzzles;

  /// Consiglio: continuare
  ///
  /// In it, this message translates to:
  /// **'Continua così: allenarti poco ma spesso funziona.'**
  String get weeklyAdviceKeepGoing;

  /// Pulsante che apre la lezione consigliata
  ///
  /// In it, this message translates to:
  /// **'Apri la lezione'**
  String get weeklyOpenLesson;

  /// Pulsante che apre i puzzle consigliati
  ///
  /// In it, this message translates to:
  /// **'Apri i puzzle'**
  String get weeklyOpenPuzzles;

  /// Profilo bambino: frase sui progressi
  ///
  /// In it, this message translates to:
  /// **'Questa settimana ti sei allenato. Bravo!'**
  String get weeklyKidActive;

  /// Profilo bambino: etichetta per i lettori di schermo
  ///
  /// In it, this message translates to:
  /// **'Le stelle sono i giorni in cui ti sei allenato'**
  String get weeklyKidDaysLabel;

  /// Profilo bambino: errore ricorrente
  ///
  /// In it, this message translates to:
  /// **'Fai più attenzione a: {error}.'**
  String weeklyKidError(String error);

  /// Titolo della scheda con il risultato esatto dei finali con pochi pezzi
  ///
  /// In it, this message translates to:
  /// **'Finale perfetto'**
  String get tablebaseTitle;

  /// Attesa mentre l'app genera la tabella dei finali, solo al primo uso
  ///
  /// In it, this message translates to:
  /// **'Calcolo il finale perfetto… succede solo la prima volta'**
  String get tablebaseCalculating;

  /// Risultato esatto: vince il Bianco, con le mosse al matto
  ///
  /// In it, this message translates to:
  /// **'{moves, plural, one{Il Bianco vince: matto in {moves} mossa} other{Il Bianco vince: matto in {moves} mosse}}'**
  String tablebaseWhiteMates(int moves);

  /// Risultato esatto: vince il Nero, con le mosse al matto
  ///
  /// In it, this message translates to:
  /// **'{moves, plural, one{Il Nero vince: matto in {moves} mossa} other{Il Nero vince: matto in {moves} mosse}}'**
  String tablebaseBlackMates(int moves);

  /// Risultato esatto senza numeri, per il profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Il Bianco vince'**
  String get tablebaseWhiteWins;

  /// Risultato esatto senza numeri, per il profilo bambino
  ///
  /// In it, this message translates to:
  /// **'Il Nero vince'**
  String get tablebaseBlackWins;

  /// Risultato esatto: nessuno dei due può vincere
  ///
  /// In it, this message translates to:
  /// **'Patta con il gioco perfetto'**
  String get tablebaseDraw;

  /// Mossa migliore del finale perfetto
  ///
  /// In it, this message translates to:
  /// **'Mossa perfetta: {move}'**
  String tablebaseBestMove(String move);

  /// Descrizione per i lettori di schermo del pulsante con la mossa perfetta
  ///
  /// In it, this message translates to:
  /// **'Gioca la mossa perfetta'**
  String get tablebaseBestMoveHint;

  /// Pulsante dell'allenatore dei finali che disegna la mossa perfetta sulla scacchiera
  ///
  /// In it, this message translates to:
  /// **'Mostra la mossa perfetta'**
  String get tablebaseShowMove;
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
