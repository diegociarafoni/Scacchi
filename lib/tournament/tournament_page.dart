import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

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
    this.userName,
    this.play,
  });

  final TournamentController controller;

  /// Bot disponibili, con il livello del motore che li fa giocare.
  final List<Player> bots;

  /// Forza stimata dell'utente, per scegliere avversari alla sua portata.
  final int userElo;

  /// Nome dell'utente nella classifica; senza, «Tu» nella lingua dell'app.
  final String? userName;

  /// Avvia la partita contro il motore; senza, le partite non partono.
  final PlayTournamentGame? play;

  Future<void> _abandon(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.tournamentAbandonTitle),
          content: Text(l10n.tournamentAbandonBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.tournamentContinue),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.tournamentAbandon),
            ),
          ],
        );
      },
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
            title: Text(AppLocalizations.of(context).tournamentTitle),
            actions: [
              if (t != null && !t.finished)
                IconButton(
                  tooltip: AppLocalizations.of(context)
                      .tournamentAbandonTooltip,
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
    final l10n = AppLocalizations.of(context);
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
        Text(l10n.tournamentNew, style: text.titleLarge),
        Text(l10n.tournamentIntro),
        const SizedBox(height: 12),
        SegmentedButton<TournamentFormat>(
          segments: [
            for (final f in TournamentFormat.values)
              ButtonSegment(value: f, label: Text(_formatLabel(l10n, f))),
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
                label: Text(l10n.tournamentPlayers(s)),
                selected: s == size,
                onSelected: (_) => setState(() => _sizeByFormat[_format] = s),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l10n.tournamentOpponents, style: text.titleMedium),
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
                  userName: page.userName ?? l10n.tournamentYou,
                  userElo: page.userElo,
                  bots: page.bots,
                ),
          child: Text(l10n.tournamentStart),
        ),
        if (trophies.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l10n.tournamentTrophies, style: text.titleLarge),
          for (final tr in trophies)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                tr.rank == 1 ? '🏆' : '🎖',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(l10n.tournamentPlace('${tr.rank}', tr.players)),
              subtitle: Text(
                tr.rank == 1
                    ? l10n.tournamentTrophySubtitle(
                        _formatLabel(l10n, tr.format),
                        _date(l10n, tr.date),
                      )
                    : l10n.tournamentTrophySubtitleChampion(
                        _formatLabel(l10n, tr.format),
                        _date(l10n, tr.date),
                        tr.champion,
                      ),
              ),
            ),
        ],
      ],
    );
  }
}

String _formatLabel(AppLocalizations l10n, TournamentFormat format) =>
    switch (format) {
      TournamentFormat.roundRobin => l10n.tournamentFormatRoundRobin,
      TournamentFormat.knockout => l10n.tournamentFormatKnockout,
    };

String _date(AppLocalizations l10n, DateTime d) =>
    DateFormat(l10n.tournamentDatePattern).format(d);

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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).tournamentGamesUnavailable,
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
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final game = t.userGame;
    final totalRounds = t.format == TournamentFormat.roundRobin
        ? t.totalRounds
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.tournamentHeader(_formatLabel(l10n, t.format), t.players.length),
          style: text.titleLarge,
        ),
        const SizedBox(height: 12),
        if (page.controller.playingBots)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tournamentBotsPlaying),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ),
            ),
          )
        else if (t.finished)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    t.userRank == 1
                        ? l10n.tournamentWon
                        : l10n.tournamentFinishedRank('${t.userRank}'),
                    style: text.titleLarge,
                  ),
                  if (t.userRank != 1)
                    Text(l10n.tournamentChampion(t.players[t.champion!].name)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: page.controller.dismiss,
                    child: Text(l10n.tournamentNew),
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
                    ? l10n.tournamentArmageddonVs(game.opponent.name)
                    : totalRounds == null
                    ? l10n.tournamentRoundVs(
                        t.currentRound + 1,
                        game.opponent.name,
                      )
                    : l10n.tournamentRoundOfVs(
                        t.currentRound + 1,
                        totalRounds,
                        game.opponent.name,
                      ),
              ),
              subtitle: Text(_gameSubtitle(l10n, game)),
              trailing: FilledButton(
                onPressed: _playing || page.controller.playingBots
                    ? null
                    : () => _play(context, game),
                child: Text(l10n.tournamentPlay),
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

String _gameSubtitle(AppLocalizations l10n, UserGame game) {
  final color = game.color.name;
  if (!game.armageddon) {
    return l10n.tournamentGameSubtitle(game.opponent.elo, color);
  }
  return game.color == Side.black
      ? l10n.tournamentGameSubtitleDraw(game.opponent.elo, color)
      : l10n.tournamentGameSubtitleWin(game.opponent.elo, color);
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final rows = tournament.standings();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tournamentStandings, style: text.titleMedium),
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
              l10n.tournamentStandingsPoints(
                _points(s.points),
                _points(s.sonnebornBerger),
              ),
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

  String _roundName(AppLocalizations l10n, int round, int total) =>
      switch (total - round) {
        1 => l10n.tournamentRoundFinal,
        2 => l10n.tournamentRoundSemifinals,
        _ => l10n.tournamentRoundQuarterfinals,
      };

  String _score(AppLocalizations l10n, Pairing p) {
    final r = p.result;
    if (r == null) return '–';
    final main = switch (r) {
      1.0 => '1-0',
      0.0 => '0-1',
      _ => '½-½',
    };
    if (r == 0.5 && p.tiebreak != null) {
      return l10n.tournamentScoreArmageddon(main);
    }
    return main;
  }

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final total = t.totalRounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = total - 1; r >= 0; r--)
          if (r < t.rounds.length) ...[
            Text(_roundName(l10n, r, total), style: text.titleMedium),
            for (final p in t.rounds[r])
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${t.players[p.white].name} – ${t.players[p.black!].name}',
                ),
                trailing: Text(_score(l10n, p)),
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
