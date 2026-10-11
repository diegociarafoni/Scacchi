/// Minigiochi di allenamento (RG-10), sul modello di Magnus Trainer e Lichess.
enum Minigame {
  coordinates(
    'coordinate',
    'Coordinate a tempo',
    'Tocca la casa indicata: quante ne trovi in 30 secondi?',
  ),
  captureAll(
    'cattura',
    'Cattura tutto',
    'Un solo pezzo cattura tutti i pedoni con meno mosse possibile.',
  ),
  blind(
    'cieca',
    'Alla cieca',
    'Leggi le mosse senza scacchiera e indica cosa c\'è su una casa.',
  ),
  material(
    'materiale',
    'Conta del materiale',
    'Chi è in vantaggio, e di quanto?',
  );

  const Minigame(this.id, this.title, this.description);

  /// Identificativo stabile, usato nei record.
  final String id;
  final String title;
  final String description;

  static Minigame? byId(String id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}
