import 'puzzle_run.dart';

/// Spiegazione breve di una modalità dei puzzle: cosa fare, come si vince o si
/// perde, tempo o vite e come si calcola il punteggio.
class PuzzleGuide {
  const PuzzleGuide({
    required this.id,
    required this.title,
    required this.goal,
    required this.rules,
  });

  /// Chiave stabile, usata per ricordare che la spiegazione è già stata letta.
  final String id;
  final String title;

  /// Una frase: cosa bisogna ottenere.
  final String goal;

  /// Regole in ordine: come si gioca, quando finisce, come si segna.
  final List<String> rules;

  static const training = PuzzleGuide(
    id: 'training',
    title: 'Allenamento',
    goal: 'Trova la mossa giusta in ogni puzzle, uno dopo l\'altro.',
    rules: [
      'I puzzle sono scelti in base al tuo punteggio: se vai bene diventano più difficili.',
      'Muovi il pezzo giusto: se la mossa è corretta l\'avversario risponde e tocca a te, se è sbagliata viene annullata.',
      'Su un puzzle nuovo, risolto al primo tentativo il punteggio sale; se sbagli o guardi la soluzione conta come fallito, il punteggio scende e il puzzle torna nel ripasso. I puzzle già visti non cambiano il punteggio.',
      'Il suggerimento non toglie nulla: cerchia il pezzo da muovere.',
      'Non c\'è tempo né limite di errori: puoi fermarti quando vuoi.',
    ],
  );

  static const theme = PuzzleGuide(
    id: 'theme',
    title: 'Puzzle per tema',
    goal: 'Allena un solo schema tattico: tutti i puzzle hanno lo stesso tema.',
    rules: [
      'Muovi il pezzo giusto: se la mossa è corretta l\'avversario risponde, se è sbagliata viene annullata.',
      'Su un puzzle nuovo, risolto al primo tentativo il punteggio sale; con errori o soluzione mostrata conta come fallito, il punteggio scende e il puzzle torna nel ripasso.',
      'Non c\'è tempo né limite di errori.',
    ],
  );

  static const daily = PuzzleGuide(
    id: 'daily',
    title: 'Puzzle del giorno',
    goal: 'Risolvi il puzzle di oggi: è lo stesso per tutta la giornata.',
    rules: [
      'Trova la sequenza di mosse giusta: se sbagli la mossa viene annullata e puoi riprovare.',
      'Con "Riprova" ricominci dalla posizione iniziale, con "Soluzione" vedi le mosse.',
      'Conta come risolto solo se non sbagli e non guardi la soluzione; altrimenti conta come fallito.',
      'Domani ne arriva uno nuovo.',
    ],
  );

  static const review = PuzzleGuide(
    id: 'review',
    title: 'Ripasso degli errori',
    goal: 'Ritrova la soluzione dei puzzle che hai sbagliato.',
    rules: [
      'Ogni puzzle torna a scadenze crescenti (1, 3, 7, 14 e 30 giorni): oggi trovi solo quelli in scadenza.',
      'Se lo risolvi senza errori l\'intervallo si allunga, se sbagli ricomincia da un giorno.',
      'Il ripasso non cambia il punteggio dell\'allenamento.',
      'Finiti i puzzle di oggi non c\'è altro da fare.',
    ],
  );

  /// Spiegazione di una modalità a serie, ricavata da tempo ed errori.
  static PuzzleGuide forRun(PuzzleRunMode mode) {
    final minutes = mode.limit?.inMinutes;
    final base = [
      'I puzzle diventano via via più difficili.',
      'Ogni puzzle risolto vale 1 punto.',
    ];
    const tail = [
      'Il record personale è salvato per ogni modalità.',
      'Puoi uscire quando vuoi: punti e XP guadagnati valgono comunque.',
    ];
    return switch (mode) {
      PuzzleRunMode.storm => PuzzleGuide(
        id: mode.name,
        title: mode.label,
        goal: 'Risolvi più puzzle che puoi in $minutes minuti.',
        rules: [
          ...base,
          'Un errore costa ${PuzzleRun.wrongPenalty.inSeconds} secondi, azzera la combo e passa al puzzle successivo.',
          'Con 5, 12, 20 e 30 puzzle di fila guadagni 3, 5, 7 e 10 secondi (poi 10 ogni 10 puzzle).',
          'Non ci sono vite: la serie finisce quando il tempo scade.',
          ...tail,
        ],
      ),
      PuzzleRunMode.rush3 || PuzzleRunMode.rush5 => PuzzleGuide(
        id: mode.name,
        title: mode.label,
        goal: 'Risolvi più puzzle che puoi in $minutes minuti, con tre vite.',
        rules: [
          ...base,
          'Un errore ti toglie una vita e passa al puzzle successivo.',
          'La serie finisce quando il tempo scade o quando perdi la terza vita.',
          ...tail,
        ],
      ),
      PuzzleRunMode.survival => PuzzleGuide(
        id: mode.name,
        title: mode.label,
        goal: 'Risolvi più puzzle che puoi, con tre vite e senza limite di tempo.',
        rules: [
          ...base,
          'Un errore ti toglie una vita e passa al puzzle successivo.',
          'La serie finisce quando perdi la terza vita.',
          ...tail,
        ],
      ),
      PuzzleRunMode.streak => PuzzleGuide(
        id: mode.name,
        title: mode.label,
        goal: 'Risolvi più puzzle di fila: il primo errore chiude la serie.',
        rules: [
          ...base,
          'Non c\'è limite di tempo e non ci sono vite.',
          'Puoi saltare un solo puzzle per serie, con "Salta".',
          ...tail,
        ],
      ),
    };
  }
}
