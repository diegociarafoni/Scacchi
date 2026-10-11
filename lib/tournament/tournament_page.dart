import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'tournament.dart';
import 'tournament_controller.dart';

/// Gioca la partita del torneo e restituisce i punti dell'utente (1, ½, 0),
/// o `null` se la partita non si è conclusa.
typedef PlayTournamentGame = Future<double?> Function(
  BuildContext context,
  UserGame game,
);

/// Tornei offline contro bot (RG-09): preparazione, classifica o tabellone,
/// prossima partita e bacheca dei trofei.
class TournamentPage extends StatelessWidget {
  const TournamentPage({
    super.key,
    required this.controller,
    required this.bots,
    required this.userElo,
    this.userName = 'Tu',
    this.play,
  });

  final TournamentController controller;

  /// Bot disponibili, con il livello del motore che li fa giocare.
  final List<Player> bots;

  /// Forza stimata dell'utente, per scegliere avversari alla sua portata.
  final int userElo;
  final String userName;

  /// Avvia la partita contro il motore; senza, le partite non partono.
  final PlayTournamentGame? play;

  Future<void> _abandon(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abbandonare il torneo?'),
        content: const Text('Il torneo si chiude senza trofeo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continua'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abbandona'),
          ),
        ],
      ),
    );
    if (ok ?? false) await controller.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final t = controller.current;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tornei'),
            actions: [
              if (t != null && !t.finished)
                IconButton(
                  tooltip: 'Abbandona il torneo',
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: () => _abandon(context),
                ),
            ],
          ),
          body: t == null
              ? _Setup(page: this)
              : _Running(page: this, tournament: t),
        );
      },
    );
  }
}

class _Setup extends StatefulWidget {
  const _Setup({required this.page});

  final TournamentPage page;

  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  TournamentFormat _format = TournamentFormat.roundRobin;

  /// Numero di giocatori scelto per ciascuna formula.
  final _sizeByFormat = {
    TournamentFormat.roundRobin: 6,
    TournamentFormat.knockout: 8,
  };

  List<int> get _sizes =>
      _format == TournamentFormat.knockout ? const [4, 8] : const [4, 5, 6, 8];

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final text = Theme.of(context).textTheme;
    final available = [
      for (final s in _sizes)
        if (s - 1 <= page.bots.length) s,
    ];
    // Con pochi bot la scelta ricade sul torneo più grande possibile.
    final chosen = _sizeByFormat[_format]!;
    final size = available.contains(chosen)
        ? chosen
        : available.isEmpty
        ? 0
        : available.last;
    final opponents = chooseBots(
      page.bots,
      userElo: page.userElo,
      count: size - 1,
    );
    final trophies = page.controller.trophies;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Nuovo torneo', style: text.titleLarge),
        const Text(
          'Partite vere contro il motore; tra i bot i risultati si simulano '
          'in base alla forza.',
        ),
        const SizedBox(height: 12),
        SegmentedButton<TournamentFormat>(
          segments: [
            for (final f in TournamentFormat.values)
              ButtonSegment(value: f, label: Text(f.label)),
          ],
          selected: {_format},
          onSelectionChanged: (s) => setState(() => _format = s.first),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final s in available)
              ChoiceChip(
                label: Text('$s giocatori'),
                selected: s == size,
                onSelected: (_) => setState(() => _sizeByFormat[_format] = s),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Avversari', style: text.titleMedium),
        for (final b in opponents)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text('${b.name} · ${b.elo}'),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: available.isEmpty
              ? null
              : () => page.controller.start(
                  format: _format,
                  size: size,
                  userName: page.userName,
                  userElo: page.userElo,
                  bots: page.bots,
                ),
          child: const Text('Inizia il torneo'),
        ),
        if (trophies.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Bacheca', style: text.titleLarge),
          for (final tr in trophies)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                tr.rank == 1 ? '🏆' : '🎖',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text('${tr.rank}° posto su ${tr.players}'),
              subtitle: Text(
                '${tr.format.label} · ${_date(tr.date)}'
                '${tr.rank == 1 ? '' : ' · vinto da ${tr.champion}'}',
              ),
            ),
        ],
      ],
    );
  }
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

class _Running extends StatefulWidget {
  const _Running({required this.page, required this.tournament});

  final TournamentPage page;
  final Tournament tournament;

  @override
  State<_Running> createState() => _RunningState();
}

class _RunningState extends State<_Running> {
  bool _playing = false;

  TournamentPage get page => widget.page;

  Future<void> _play(BuildContext context, UserGame game) async {
    final play = page.play;
    if (play == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le partite del torneo arrivano con la partita contro il '
            'computer.',
          ),
        ),
      );
      return;
    }
    final before = page.controller.current;
    setState(() => _playing = true);
    try {
      final points = await play(context, game);
      // Il risultato vale solo se nel frattempo il torneo non è cambiato.
      if (points != null && identical(page.controller.current, before)) {
        await page.controller.recordUserGame(points);
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final text = Theme.of(context).textTheme;
    final game = t.userGame;
    final totalRounds = t.format == TournamentFormat.roundRobin
        ? t.totalRounds
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${t.format.label} · ${t.players.length} giocatori',
          style: text.titleLarge,
        ),
        const SizedBox(height: 12),
        if (t.finished)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    t.userRank == 1
                        ? 'Hai vinto il torneo!'
                        : 'Hai chiuso al ${t.userRank}° posto',
                    style: text.titleLarge,
                  ),
                  if (t.userRank != 1)
                    Text('Vince ${t.players[t.champion!].name}'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: page.controller.dismiss,
                    child: const Text('Nuovo torneo'),
                  ),
                ],
              ),
            ),
          )
        else if (game != null)
          Card(
            child: ListTile(
              title: Text(
                game.armageddon
                    ? 'Spareggio Armageddon contro ${game.opponent.name}'
                    : 'Turno ${t.currentRound + 1}'
                          '${totalRounds == null ? '' : ' di $totalRounds'}: '
                          'contro ${game.opponent.name}',
              ),
              subtitle: Text(
                '${game.opponent.elo} Elo · '
                'giochi con il ${game.color == Side.white ? 'bianco' : 'nero'}'
                '${game.armageddon ? (game.color == Side.black ? ' · ti basta la patta' : ' · devi vincere') : ''}',
              ),
              trailing: FilledButton(
                onPressed: _playing ? null : () => _play(context, game),
                child: const Text('Gioca'),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (t.format == TournamentFormat.roundRobin)
          _StandingsTable(tournament: t)
        else
          _Bracket(tournament: t),
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final rows = tournament.standings();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Classifica', style: text.titleMedium),
        for (final (i, s) in rows.indexed)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Text('${i + 1}.'),
            title: Text(
              tournament.players[s.player].name,
              style: s.player == 0
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
            trailing: Text(
              '${_points(s.points)} pt · SB ${_points(s.sonnebornBerger)}',
            ),
          ),
      ],
    );
  }
}

String _points(double p) =>
    p == p.truncateToDouble() ? p.toInt().toString() : p.toStringAsFixed(1);

class _Bracket extends StatelessWidget {
  const _Bracket({required this.tournament});

  final Tournament tournament;

  String _roundName(int round, int total) => switch (total - round) {
    1 => 'Finale',
    2 => 'Semifinali',
    _ => 'Quarti di finale',
  };

  String _score(Pairing p) {
    final r = p.result;
    if (r == null) return '–';
    final main = switch (r) {
      1.0 => '1-0',
      0.0 => '0-1',
      _ => '½-½',
    };
    if (r == 0.5 && p.tiebreak != null) return '$main (Armageddon)';
    return main;
  }

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final text = Theme.of(context).textTheme;
    final total = t.totalRounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = total - 1; r >= 0; r--)
          if (r < t.rounds.length) ...[
            Text(_roundName(r, total), style: text.titleMedium),
            for (final p in t.rounds[r])
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${t.players[p.white].name} – ${t.players[p.black!].name}',
                ),
                trailing: Text(_score(p)),
                leading: Icon(
                  p.winner == null
                      ? Icons.hourglass_empty
                      : p.winner == 0 || (!p.includes(0))
                      ? Icons.check
                      : Icons.close,
                  size: 18,
                ),
              ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
