// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Rokko';

  @override
  String get kidProfileSection => 'Profilo';

  @override
  String get kidProfile => 'Profilo bambino';

  @override
  String get kidProfileDescription =>
      'Interfaccia e testi più semplici, bot amichevoli, niente numeri';

  @override
  String get kidAdultGateTitle => 'Chiedi a un adulto';

  @override
  String kidAdultGateQuestion(int a, int b) {
    return 'Per uscire dal profilo bambino: quanto fa $a × $b?';
  }

  @override
  String get kidAdultGateWrong => 'Risposta sbagliata.';

  @override
  String get kidAdultGateConfirm => 'Conferma';

  @override
  String get kidBotPinoDescription => 'Un pulcino allegro che ama attaccare';

  @override
  String get kidBotChiaraDescription =>
      'Gioca con calma e aspetta le tue mosse';

  @override
  String get kidBotRoccoDescription => 'Una volpe furba piena di sorprese';

  @override
  String get kidBotUnavailable =>
      'Su questo dispositivo i bot non sono disponibili.';

  @override
  String get kidGameYourTurn => 'Tocca a te!';

  @override
  String kidGameTurnSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Tocca al Bianco!',
      'other': 'Tocca al Nero!',
    });
    return '$_temp0';
  }

  @override
  String kidGameTurnName(String name) {
    return '$name, tocca a te!';
  }

  @override
  String kidGameOpponentTurn(String name) {
    return '$name sta per muovere';
  }

  @override
  String kidGameThinking(String name) {
    return '$name ci sta pensando…';
  }

  @override
  String kidGameDrawThinking(String name) {
    return '$name ci pensa un attimo…';
  }

  @override
  String get kidGameCheckYou => 'Scacco! Il tuo re è in pericolo';

  @override
  String get kidGameCheckOpponent => 'Scacco! Il re avversario è in pericolo';

  @override
  String kidGameCheckSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Scacco! Il re bianco è in pericolo',
      'other': 'Scacco! Il re nero è in pericolo',
    });
    return '$_temp0';
  }

  @override
  String kidGameCheckName(String name) {
    return 'Scacco! $name, il tuo re è in pericolo';
  }

  @override
  String get kidGameCheckmate => 'Scacco matto!';

  @override
  String get kidGameTimeUp => 'Tempo finito!';

  @override
  String get kidGameKingOfTheHill => 'Il re è arrivato al centro!';

  @override
  String get kidGameThirdCheck => 'Terzo scacco!';

  @override
  String get kidGameOver => 'Partita finita!';

  @override
  String get kidGameYouResigned => 'Ti sei arreso.';

  @override
  String kidGameResignedSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Il Bianco si arrende.',
      'other': 'Il Nero si arrende.',
    });
    return '$_temp0';
  }

  @override
  String kidGameResignedName(String name) {
    return '$name si arrende.';
  }

  @override
  String get kidGameYouWon => 'Hai vinto!';

  @override
  String kidGameOpponentWon(String name) {
    return '$name ha vinto. Riprova!';
  }

  @override
  String kidGameWinnerSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Ha vinto il Bianco!',
      'other': 'Ha vinto il Nero!',
    });
    return '$_temp0';
  }

  @override
  String kidGameWinnerName(String name) {
    return 'Ha vinto $name!';
  }

  @override
  String get kidGameStalemate =>
      'Stallo: il re non può muoversi ma non è sotto scacco. Pareggio!';

  @override
  String get kidGameInsufficientMaterial =>
      'Sono rimasti troppo pochi pezzi per dare scacco matto. Pareggio!';

  @override
  String get kidGameRepetition =>
      'La stessa posizione è tornata tre volte. Pareggio!';

  @override
  String get kidGameFiftyMoves =>
      'Tante mosse senza catture né mosse di pedone. Pareggio!';

  @override
  String get kidGameAgreedDraw => 'Pareggio deciso insieme!';

  @override
  String get kidGameTimeUpDraw =>
      'Tempo finito, ma con questi pezzi nessuno può vincere. Pareggio!';

  @override
  String get kidGameComputer => 'Il computer';

  @override
  String get kidGameNew => 'Nuova partita';

  @override
  String get kidGameDraw => 'Pareggio?';

  @override
  String get kidGameResign => 'Mi arrendo';

  @override
  String get kidGameResignTitle => 'Vuoi arrenderti?';

  @override
  String kidGameResignTitleSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Bianco, vuoi arrenderti?',
      'other': 'Nero, vuoi arrenderti?',
    });
    return '$_temp0';
  }

  @override
  String kidGameResignTitleName(String name) {
    return '$name, vuoi arrenderti?';
  }

  @override
  String get kidGameResignBody => 'Se ti arrendi, la partita finisce.';

  @override
  String get kidGameResignNo => 'No, continuo';

  @override
  String get kidGameResignYes => 'Sì, mi arrendo';

  @override
  String kidGameDrawOfferSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Bianco, vuoi fare pareggio?',
      'other': 'Nero, vuoi fare pareggio?',
    });
    return '$_temp0';
  }

  @override
  String kidGameDrawOfferName(String name) {
    return '$name, vuoi fare pareggio?';
  }

  @override
  String get kidGameDrawNo => 'No, giochiamo';

  @override
  String get kidGameDrawYes => 'Sì, pareggio';

  @override
  String kidGameDrawAccepted(String name) {
    return '$name accetta il pareggio!';
  }

  @override
  String kidGameDrawRefused(String name) {
    return '$name vuole continuare a giocare.';
  }

  @override
  String get kidGameTimeTitle => 'Quanto tempo?';

  @override
  String get kidGameSlowClock => 'Con l\'orologio, con calma';

  @override
  String get kidGameUndo => 'Annulla';

  @override
  String get kidGameFlip => 'Gira';

  @override
  String get kidGameWhiteName => 'Nome del Bianco';

  @override
  String get kidGameBlackName => 'Nome del Nero';

  @override
  String get kidGameNameHint => 'Facoltativo';

  @override
  String get kidGameNoClock => 'Senza tempo';

  @override
  String get kidGameCoach => 'Allenatore';

  @override
  String get kidGameHint => 'Aiuto';

  @override
  String get kidProgressGreat => 'Bravo, continua così!';

  @override
  String get kidProgressGoal => 'Obiettivo di oggi raggiunto!';

  @override
  String get kidProgressLevelUp => 'Sei salito di livello: una stella in più!';

  @override
  String get kidProgressChallenge => 'Sfida completata!';

  @override
  String get kidProgressAchievement => 'Nuovo traguardo!';

  @override
  String get kidProgressReward => 'Hai sbloccato una ricompensa!';

  @override
  String get kidLevelTitle => 'Le tue stelle';

  @override
  String get kidLevelStarsLabel => 'Una stella per ogni livello raggiunto';

  @override
  String get kidLevelProgress =>
      'Gioca ancora per guadagnare un\'altra stella!';

  @override
  String get kidLevelProgressLabel => 'Strada verso la prossima stella';

  @override
  String get kidStreakOn => 'Stai giocando tutti i giorni: la fiamma è accesa!';

  @override
  String get kidStreakOff => 'Gioca oggi per accendere la fiamma!';

  @override
  String get kidGoalToday => 'Obiettivo di oggi';

  @override
  String get kidChallengeProgress => 'Strada verso la sfida';

  @override
  String get kidPuzzleHubTitle => 'Risolvi i puzzle e raccogli stelle!';

  @override
  String get kidPuzzleStarsLabel => 'Le stelle dei puzzle risolti';

  @override
  String get kidPuzzleTraining => 'Puzzle scelti per te';

  @override
  String get kidPuzzleDaily => 'Un puzzle nuovo ogni giorno';

  @override
  String get kidPuzzleReviewDue => 'Ci sono puzzle da ripassare';

  @override
  String get kidPuzzleReviewNone => 'Niente da ripassare oggi';

  @override
  String get kidPuzzleKeepGoing => 'Forza, ce la puoi fare!';

  @override
  String puzzleGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'mateIn1': 'Obiettivo: matto in 1',
      'mateIn2': 'Obiettivo: matto in 2',
      'mateIn3': 'Obiettivo: matto in 3',
      'mateIn4': 'Obiettivo: matto in 4',
      'mate': 'Obiettivo: dai matto',
      'crushing': 'Obiettivo: ottieni un vantaggio decisivo',
      'advantage': 'Obiettivo: ottieni il vantaggio',
      'equality': 'Obiettivo: ottieni la parità',
      'other': 'Obiettivo: trova la mossa migliore',
    });
    return '$_temp0';
  }

  @override
  String get kidAccuracy5 => 'Perfetto!';

  @override
  String get kidAccuracy4 => 'Molto bene';

  @override
  String get kidAccuracy3 => 'Bene';

  @override
  String get kidAccuracy2 => 'Così così';

  @override
  String get kidAccuracy1 => 'Da migliorare';

  @override
  String get kidReviewAnalysing => 'Sto guardando la partita…';

  @override
  String get kidAnalysisThinking => 'Il computer sta pensando…';

  @override
  String get kidEvalWhite => 'Il Bianco è in vantaggio';

  @override
  String get kidEvalBlack => 'Il Nero è in vantaggio';

  @override
  String get kidEvalEven => 'Partita in equilibrio';

  @override
  String get kidUnlockByPlaying => 'Si sblocca giocando';

  @override
  String get kidCoachMaterialLoss =>
      'Attento: con questa mossa perdi dei pezzi.';

  @override
  String kidCoachAllowedMate(String move, String reply) {
    return 'Dopo $move l\'avversario può dare scacco matto con $reply.';
  }

  @override
  String kidCoachMissedMate(String move) {
    return 'Con $move potevi dare scacco matto!';
  }

  @override
  String get qrSendTitle => 'Passa con QR';

  @override
  String get qrSendHint =>
      'Sull\'altro telefono apri Tu › Archivio › Ricevi con QR e inquadra il codice.';

  @override
  String qrPart(int current, int total) {
    return 'Parte $current di $total';
  }

  @override
  String get qrPause => 'Pausa';

  @override
  String get qrResume => 'Riprendi';

  @override
  String get qrNext => 'Parte successiva';

  @override
  String get qrPrevious => 'Parte precedente';

  @override
  String get qrCodeLabel => 'Codice QR della partita';

  @override
  String get qrReceiveTitle => 'Ricevi con QR';

  @override
  String get qrReceiveHint =>
      'Inquadra il codice QR mostrato dall\'altro telefono.';

  @override
  String qrReceived(int received, int total) {
    return '$received di $total parti lette';
  }

  @override
  String get qrForeign => 'Questo QR non contiene una partita.';

  @override
  String get qrCorrupted => 'Il QR è danneggiato: ricomincia la lettura.';

  @override
  String get qrTooLarge => 'La partita è troppo grande per essere ricevuta.';

  @override
  String get qrRestarted => 'Nuova partita inquadrata: lettura ricominciata.';

  @override
  String get qrCameraError =>
      'Non riesco a usare la fotocamera. Consenti l\'accesso alla fotocamera per Rokko nelle impostazioni del telefono e riprova.';

  @override
  String get qrRetry => 'Riprova';

  @override
  String get qrInvalidGame => 'Il QR non contiene una partita valida.';

  @override
  String get qrFinishedGame =>
      'La partita è già conclusa: ricevila da Tu › Archivio › Ricevi con QR.';

  @override
  String get qrMalformed => 'QR non valido: ignorato.';

  @override
  String get editorFenTitle => 'Posizione (FEN)';

  @override
  String get editorFenHelpTooltip => 'Che cos\'è il FEN?';

  @override
  String get editorFenHelpBody =>
      'Il FEN è una riga di testo che descrive una posizione: i pezzi sulla scacchiera, di chi è il turno, l\'arrocco e le mosse. Serve per copiare la posizione in altre app e per incollarne una ricevuta da altrove: usa «Copia FEN» e «Incolla FEN».';

  @override
  String get editorFenHelpClose => 'Ho capito';

  @override
  String get backupTitle => 'Backup e ripristino';

  @override
  String get backupIntro =>
      'Il backup contiene partite, progressi, percorso, tornei, allenamento e impostazioni. Salvalo in un posto sicuro: senza rete non esiste una copia online.';

  @override
  String get backupShare => 'Condividi il backup';

  @override
  String get backupShareSubject => 'Backup di Rokko';

  @override
  String get backupRestoreFromText => 'Ripristina da testo';

  @override
  String get backupExported => 'Backup pronto da salvare';

  @override
  String backupExportFailed(String error) {
    return 'Backup non riuscito: $error';
  }

  @override
  String get backupRestoreStaged =>
      'Backup pronto. Chiudi e riapri l\'app per ripristinare i dati.';

  @override
  String backupRestoreFailed(String error) {
    return 'Ripristino non riuscito: $error';
  }

  @override
  String get backupErrorNotApp => 'Non è un backup di Rokko';

  @override
  String get backupErrorNewerVersion =>
      'Backup creato da una versione più recente';

  @override
  String backupErrorUnexpectedFile(String file) {
    return 'File inatteso nel backup: $file';
  }

  @override
  String backupErrorInvalidFile(String file) {
    return 'File non valido nel backup: $file';
  }

  @override
  String backupErrorInvalidPreference(String name) {
    return 'Preferenza non valida: $name';
  }

  @override
  String get backupErrorUnreadable => 'Backup non leggibile';

  @override
  String get backupRestoreDialogTitle => 'Ripristina il backup';

  @override
  String get backupRestoreDialogBody =>
      'Incolla il contenuto del file di backup. I dati attuali vengono sostituiti.';

  @override
  String get backupCancel => 'Annulla';

  @override
  String get backupRestore => 'Ripristina';

  @override
  String get minigamesTitle => 'Minigiochi';

  @override
  String minigamesRecord(int score) {
    return 'Record $score';
  }

  @override
  String get minigamesCoordinatesTitle => 'Coordinate a tempo';

  @override
  String get minigamesCoordinatesDescription =>
      'Tocca la casa indicata: quante ne trovi in 30 secondi?';

  @override
  String get minigamesCaptureAllTitle => 'Cattura tutto';

  @override
  String get minigamesCaptureAllDescription =>
      'Un solo pezzo cattura tutti i pedoni con meno mosse possibile.';

  @override
  String get minigamesBlindTitle => 'Alla cieca';

  @override
  String get minigamesBlindDescription =>
      'Leggi le mosse senza scacchiera e indica cosa c\'è su una casa.';

  @override
  String get minigamesMaterialTitle => 'Conta del materiale';

  @override
  String get minigamesMaterialDescription => 'Chi è in vantaggio, e di quanto?';

  @override
  String get minigamesAgain => 'Ancora';

  @override
  String get minigamesDone => 'Fine';

  @override
  String get minigamesNext => 'Avanti';

  @override
  String minigamesCaptureAllProgress(int board, int total) {
    return 'Scacchiera $board di $total';
  }

  @override
  String get minigamesCaptureAllSessionOver => 'Sessione finita';

  @override
  String minigamesCaptureAllScore(int score, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score stelle su $max',
      one: '$score stella su $max',
    );
    return '$_temp0';
  }

  @override
  String minigamesCaptureAllMoves(int moves, int optimal) {
    return 'Mosse $moves, minimo $optimal';
  }

  @override
  String minigamesCaptureAllStars(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stelle su 3',
      one: '$stars stella su 3',
    );
    return '$_temp0';
  }

  @override
  String get minigamesCaptureAllRetry => 'Ricomincia';

  @override
  String minigamesCoordinatesTarget(String square) {
    return 'Tocca la casa $square';
  }

  @override
  String minigamesCoordinatesScore(int score) {
    return 'Punteggio $score';
  }

  @override
  String minigamesCoordinatesSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds secondi',
      one: '$seconds secondo',
    );
    return '$_temp0';
  }

  @override
  String get minigamesCoordinatesTimeUp => 'Tempo scaduto';

  @override
  String minigamesCoordinatesSummary(int score, int mistakes) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score giuste',
      one: '$score giusta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      mistakes,
      locale: localeName,
      other: '$mistakes sbagliate',
      one: '$mistakes sbagliata',
    );
    return 'Punteggio $score: $_temp0, $_temp1';
  }

  @override
  String get minigamesCoordinatesIntro =>
      'Tocca la casa indicata, senza coordinate sulla scacchiera. Hai 30 secondi.';

  @override
  String get minigamesCoordinatesWhite => 'Bianco';

  @override
  String get minigamesCoordinatesBlack => 'Nero';

  @override
  String get minigamesCoordinatesStart => 'Inizia';

  @override
  String minigamesQuizResult(int score, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score risposte giuste su $total',
      one: '$score risposta giusta su $total',
    );
    return '$_temp0';
  }

  @override
  String minigamesQuizQuestion(int number, int total) {
    return 'Domanda $number di $total';
  }

  @override
  String get minigamesQuizCorrect => 'Esatto!';

  @override
  String minigamesQuizAnswer(String answer) {
    return 'Era: $answer';
  }

  @override
  String get statsTitle => 'Statistiche';

  @override
  String get statsLoadFailed =>
      'L\'archivio delle partite non si è potuto leggere: riprova più tardi.';

  @override
  String get statsEmpty =>
      'Gioca qualche partita contro il computer per vedere le statistiche.';

  @override
  String get statsRecord => 'Bilancio';

  @override
  String get statsAllGames => 'Tutte';

  @override
  String get statsWithWhite => 'Con il bianco';

  @override
  String get statsWithBlack => 'Con il nero';

  @override
  String get statsLocalGames => 'Partite tra due persone';

  @override
  String get statsByTimeControl => 'Per cadenza';

  @override
  String get statsTopOpenings => 'Aperture più giocate';

  @override
  String statsGames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite',
      one: '$count partita',
    );
    return '$_temp0';
  }

  @override
  String get statsAccuracy => 'Precisione';

  @override
  String get statsAverage => 'Media';

  @override
  String get statsAccuracyTrend => 'Andamento della precisione';

  @override
  String statsRating(int rating) {
    return 'Rating stimato $rating';
  }

  @override
  String statsRatingProvisional(int count) {
    return 'provvisorio: servono $count partite contro il computer';
  }

  @override
  String statsRatingGames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'su $count partite contro il computer',
      one: 'su $count partita contro il computer',
    );
    return '$_temp0';
  }

  @override
  String get statsRatingTrend => 'Andamento del rating';

  @override
  String get statsNoGames => 'nessuna partita';

  @override
  String statsScoreDetail(int wins, int draws, int losses) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins vittorie',
      one: '$wins vittoria',
    );
    String _temp1 = intl.Intl.pluralLogic(
      draws,
      locale: localeName,
      other: '$draws patte',
      one: '$draws patta',
    );
    String _temp2 = intl.Intl.pluralLogic(
      losses,
      locale: localeName,
      other: '$losses sconfitte',
      one: '$losses sconfitta',
    );
    return '$_temp0, $_temp1, $_temp2';
  }

  @override
  String statsTrend(
    String label,
    String first,
    String last,
    String min,
    String max,
  ) {
    return '$label: da $first a $last, minimo $min, massimo $max';
  }

  @override
  String get opponentHintHuman => 'Si gioca in due sullo stesso dispositivo.';

  @override
  String get opponentHintComputer =>
      'Scegli il livello o lascia che si adatti a te.';

  @override
  String get opponentHintBot =>
      'Avversari con personalità da sbloccare uno a uno.';

  @override
  String botUnlockHint(String name) {
    return 'Si sblocca battendo $name';
  }

  @override
  String get handicapTitle => 'Handicap';

  @override
  String get handicapGameTitle => 'Partita a handicap';

  @override
  String get handicapHint =>
      'Chi concede il vantaggio gioca senza un pezzo o con meno tempo. La partita non conta per il rating locale.';

  @override
  String get handicapPieceTitle => 'Pezzo in meno';

  @override
  String get handicapNone => 'Nessuno';

  @override
  String get handicapPieceFPawn => 'Pedone f';

  @override
  String get handicapPieceKnight => 'Cavallo';

  @override
  String get handicapPieceRook => 'Torre';

  @override
  String get handicapPieceQueen => 'Donna';

  @override
  String get handicapTimeTitle => 'Tempo di chi concede';

  @override
  String get handicapTimeEqual => 'Uguale';

  @override
  String get handicapTimeHint =>
      'Vale solo con un orologio e se è inferiore alla cadenza scelta.';

  @override
  String get handicapGiverTitle => 'Chi concede il vantaggio';

  @override
  String get handicapGiverYou => 'Tu';

  @override
  String get handicapGiverOpponent => 'L\'avversario';

  @override
  String get handicapGiverWhite => 'Il Bianco';

  @override
  String get handicapGiverBlack => 'Il Nero';

  @override
  String handicapTimeMinutes(int n) {
    return '$n min';
  }

  @override
  String whyPiece(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'pawn': 'il pedone',
      'knight': 'il cavallo',
      'bishop': 'l\'alfiere',
      'rook': 'la torre',
      'queen': 'la donna',
      'other': 'il re',
    });
    return '$_temp0';
  }

  @override
  String get whyMate => 'Scacco matto!';

  @override
  String get whyCastle => 'Arrocca: mette il re al sicuro.';

  @override
  String whyPromote(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'queen': 'una donna',
      'rook': 'una torre',
      'bishop': 'un alfiere',
      'knight': 'un cavallo',
      'other': 'un pezzo',
    });
    return 'Promuove il pedone: diventa $_temp0.';
  }

  @override
  String whyCapture(String victim, String attacker) {
    return 'Cattura $victim con $attacker.';
  }

  @override
  String get whyCheck => 'Dà scacco al tuo re.';

  @override
  String whySafe(String piece) {
    return 'Mette al sicuro $piece, che era sotto attacco.';
  }

  @override
  String whyThreatCapture(String victim, String square) {
    return 'Minaccia di catturare $victim in $square.';
  }

  @override
  String whyThreatCaptureKid(String victim) {
    return 'Minaccia di catturare $victim.';
  }

  @override
  String get whyThreatCheck => 'Prepara uno scacco al tuo re.';

  @override
  String get whyThreatPromote => 'Prepara la promozione di un pedone.';

  @override
  String whyDevelop(String piece) {
    return 'Sviluppa $piece: entra in gioco.';
  }

  @override
  String get whyCenter => 'Prende spazio al centro.';

  @override
  String whyImprove(String piece) {
    return 'Sposta $piece su una casa più utile.';
  }

  @override
  String get settingsExplainWhy => 'Spiegami perché';

  @override
  String get settingsExplainWhyDescription =>
      'Dopo ogni mossa del computer, una riga su cosa minaccia o prepara';

  @override
  String get settingsZenMode => 'Modalità zen';

  @override
  String get settingsZenModeDescription =>
      'In partita restano solo scacchiera e mosse: niente Elo, materiale, stato, avvisi dell\'allenatore e commenti';

  @override
  String get challengeTitle => 'Sfida un amico';

  @override
  String get challengeSubtitle =>
      'Gli stessi puzzle su due telefoni, senza rete';

  @override
  String get challengeIntro =>
      'Scegli la prova e mostra il QR all\'amico: giocate gli stessi puzzle. A fine prova vi scambiate i punteggi con un secondo QR.';

  @override
  String get challengePrepare => 'Prepara la sfida';

  @override
  String challengeReady(String mode) {
    return 'Sfida pronta: $mode';
  }

  @override
  String get challengeShowInvite => 'Mostra il QR all\'amico';

  @override
  String get challengePlay => 'Gioca la tua prova';

  @override
  String get challengeReceive => 'Ricevi una sfida';

  @override
  String challengeInviteTitle(String mode) {
    return 'Sfida: $mode';
  }

  @override
  String get challengeInviteHint =>
      'L\'amico apre Puzzle › Sfida un amico › Ricevi una sfida e inquadra il codice.';

  @override
  String get challengeReceiveHint =>
      'Inquadra il QR della sfida mostrato dall\'amico.';

  @override
  String get challengeNotInvite =>
      'Questo QR non è una sfida: chiedi all\'amico di mostrare il QR della sfida.';

  @override
  String get challengeLibraryMismatch =>
      'I due telefoni hanno puzzle diversi: aggiornate Rokko su entrambi.';

  @override
  String get challengeCompareTitle => 'Sfida con l\'amico';

  @override
  String get challengeShowResult => 'Mostra il mio risultato';

  @override
  String challengeResultTitle(int score) {
    return 'Il mio risultato: $score';
  }

  @override
  String get challengeResultHint =>
      'L\'amico inquadra questo codice per vedere il tuo punteggio.';

  @override
  String get challengeReadResult => 'Leggi il risultato dell\'amico';

  @override
  String get challengeReadResultHint =>
      'Inquadra il QR del risultato mostrato dall\'amico.';

  @override
  String get challengeNotResult =>
      'Questo QR non è un risultato: chiedi all\'amico di mostrare il QR del risultato.';

  @override
  String get challengeOtherChallenge => 'Il risultato è di un\'altra sfida.';

  @override
  String challengeWon(int mine, int theirs) {
    return 'Hai vinto: $mine a $theirs';
  }

  @override
  String challengeLost(int mine, int theirs) {
    return 'Ha vinto l\'amico: $theirs a $mine';
  }

  @override
  String challengeDraw(int mine, int theirs) {
    return 'Pareggio: $mine a $theirs';
  }

  @override
  String get storyTitle => 'Storia';

  @override
  String get storyEntrySubtitle =>
      'Un viaggio a capitoli: lezioni, puzzle e sfide';

  @override
  String storyChapterNumber(int n) {
    return 'Capitolo $n';
  }

  @override
  String storyProgress(int done, int total) {
    return '$done capitoli su $total';
  }

  @override
  String get storyChapterLocked => 'Si apre concludendo il capitolo precedente';

  @override
  String get storyChapterDone => 'Capitolo concluso';

  @override
  String get storyContinue => 'Continua';

  @override
  String get storyFinished =>
      'La storia è finita. Lezioni, puzzle e partite restano disponibili nel resto dell\'app.';

  @override
  String storyStepLessons(int value, int total) {
    return 'Lezioni: $value su $total';
  }

  @override
  String storyStepPuzzles(int value, int total) {
    return 'Puzzle del capitolo: $value su $total';
  }

  @override
  String get storyStepGuardian => 'Il guardiano del capitolo';

  @override
  String storyStepBoss(String name) {
    return 'Sfida a $name';
  }

  @override
  String get storyStepDone => 'fatto';

  @override
  String get storyStepTodo => 'da fare';

  @override
  String get storyStepLocked => 'bloccato';

  @override
  String get storyStepLockedHint => 'Prima concludi il passo precedente.';

  @override
  String get storyEngineMissing =>
      'Le sfide si giocano dove gira il computer: Android e iOS, o Windows e Linux con Stockfish installato.';

  @override
  String storyBossWon(String name) {
    return 'Hai battuto $name!';
  }

  @override
  String storyBossLost(String name) {
    return '$name resiste ancora: riprova quando vuoi.';
  }

  @override
  String get storyPuzzlesNone => 'I puzzle non si possono caricare: riprova.';

  @override
  String get storyVillageTitle => 'Il villaggio dei pezzi';

  @override
  String get storyVillageIntro =>
      'Arrivi al villaggio ai piedi della Rocca. Gli abitanti non ricordano più come si muovono i loro pezzi: aiutali con le lezioni, poi dimostra di accorgerti subito di un pezzo lasciato in presa.';

  @override
  String storyVillageBoss(String name) {
    return '$name, il custode del villaggio, ti sfida per vedere se hai imparato davvero.';
  }

  @override
  String get storyVillageOutro =>
      'Il villaggio ti saluta con una festa. La strada per le porte della città è aperta.';

  @override
  String get storyGatesTitle => 'Le porte della città';

  @override
  String get storyGatesIntro =>
      'Le guardie ti fermano alle porte: per entrare devi conoscere le regole, dallo scacco all\'arrocco. Una promozione ben vista apre anche il cancello più alto.';

  @override
  String storyGatesBoss(String name) {
    return '$name, capitana delle guardie, vuole una prova prima di lasciarti passare.';
  }

  @override
  String get storyGatesOutro =>
      'Le porte si aprono. Davanti a te si alza la torre del re.';

  @override
  String get storyTowerTitle => 'La torre del re';

  @override
  String get storyTowerIntro =>
      'In cima alla torre vive il re, e sa difendersi. Impara i matti per metterlo alle strette, anche quando i suoi stessi pezzi gli fanno da muro.';

  @override
  String storyTowerBoss(String name) {
    return '$name, il cavaliere che ama i gambetti, ti aspetta in cima alle scale.';
  }

  @override
  String get storyTowerOutro =>
      'Il re della torre è in scacco matto. Resta il bosco, e le sue trappole.';

  @override
  String get storyForestTitle => 'Il bosco delle trappole';

  @override
  String get storyForestIntro =>
      'Nel bosco ogni pezzo nasconde una trappola: forchette, inchiodature, infilate. Impara a vederle prima degli altri.';

  @override
  String storyForestBoss(String name) {
    return '$name, la guida del bosco, conosce ogni sentiero e ogni insidia.';
  }

  @override
  String get storyForestOutro =>
      'Hai attraversato il bosco senza cadere in nessuna trappola. Il castello ti aspetta.';

  @override
  String get storyCastleTitle => 'Il castello dei finali';

  @override
  String get storyCastleIntro =>
      'Nel castello sulla scacchiera restano pochi pezzi e ogni mossa conta. Qui si decide chi sa chiudere una partita.';

  @override
  String storyCastleBoss(String name) {
    return '$name, il castellano, difende l\'ingresso della sala della corona.';
  }

  @override
  String get storyCastleOutro => 'Il portone si apre: la corona è vicina.';

  @override
  String get storyCrownTitle => 'La corona';

  @override
  String get storyCrownIntro =>
      'Ultima tappa: la sala della corona. Partire bene è mezza vittoria: il centro, lo sviluppo, l\'arrocco.';

  @override
  String storyCrownBoss(String name) {
    return '$name, la guardiana della corona, gioca le aperture come nessun altro.';
  }

  @override
  String get storyCrownOutro =>
      'La corona è tua. Il regno è in pace e ogni nuova partita è una nuova storia.';
}
