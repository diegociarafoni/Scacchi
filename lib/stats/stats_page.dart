import 'dart:async';
import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../l10n/app_localizations.dart';
import '../review/game_phase.dart';
import '../review/review_l10n.dart';
import 'local_rating.dart';
import 'stats.dart';

/// Statistiche e rating locale calcolati dall'archivio delle partite.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.archive});

  final GameArchive archive;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  GameStats? _stats;
  LocalRating? _rating;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final List<SavedGame> games;
    try {
      games = await widget.archive.list();
    } on FileSystemException catch (e) {
      debugPrint('Lettura dell\'archivio non riuscita: $e'); // l10n-ok
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    setState(() {
      _stats = GameStats.from(games);
      _rating = LocalRating.from(games);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final rating = _rating;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: _failed
          ? _Message(l10n.statsLoadFailed)
          : stats == null || rating == null
          ? const Center(child: CircularProgressIndicator())
          : stats.all.games == 0 &&
                rating.history.isEmpty &&
                stats.localGames == 0
          ? _Message(l10n.statsEmpty)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RatingCard(rating: rating),
                const SizedBox(height: 16),
                _Section(l10n.statsRecord, [
                  _ScoreRow(l10n.statsAllGames, stats.all),
                  for (final side in Side.values)
                    if (stats.byColor[side] case final s?)
                      _ScoreRow(
                        side == Side.white
                            ? l10n.statsWithWhite
                            : l10n.statsWithBlack,
                        s,
                      ),
                  if (stats.localGames > 0)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.statsLocalGames),
                      trailing: Text('${stats.localGames}'),
                    ),
                ]),
                if (stats.byTimeControl.isNotEmpty)
                  _Section(l10n.statsByTimeControl, [
                    for (final e in stats.byTimeControl.entries)
                      _ScoreRow(
                        e.key == noClock ? l10n.gameNoClock : e.key,
                        e.value,
                      ),
                  ]),
                if (stats.openings.isNotEmpty)
                  _Section(l10n.statsTopOpenings, [
                    for (final o in stats.openings.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(o.name),
                        trailing: Text(l10n.statsGames(o.games)),
                      ),
                  ]),
                if (stats.averageAccuracy case final avg?)
                  _Section(l10n.statsAccuracy, [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.statsAverage),
                      trailing: Text('${avg.toStringAsFixed(1)}%'),
                    ),
                    _Sparkline(
                      values: [for (final p in stats.accuracyTrend) p.$2],
                      label: l10n.statsAccuracyTrend,
                    ),
                  ]),
                if (GamePhase.values.any((p) => stats.phaseAverage(p) != null))
                  _Section(l10n.reviewAccuracyByPhase, [
                    for (final phase in GamePhase.values)
                      if (stats.phaseAverage(phase) case final avg?) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(phaseLabel(l10n, phase)),
                          trailing: Text('${avg.toStringAsFixed(1)}%'),
                        ),
                        if (stats.phaseTrend(phase).length > 1)
                          _Sparkline(
                            values: [
                              for (final p in stats.phaseTrend(phase)) p.$2,
                            ],
                            label: phaseLabel(l10n, phase),
                          ),
                      ],
                  ]),
              ],
            ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final LocalRating rating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statsRating(rating.rating),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              rating.provisional
                  ? l10n.statsRatingProvisional(LocalRating.provisionalGames)
                  : l10n.statsRatingGames(rating.history.length),
            ),
            if (rating.history.length > 1) ...[
              const SizedBox(height: 12),
              _Sparkline(
                values: [for (final p in rating.history) p.$2.toDouble()],
                label: l10n.statsRatingTrend,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          ...children,
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.score);

  final String label;
  final Score score;

  @override
  Widget build(BuildContext context) {
    final percent = score.percent;
    final l10n = AppLocalizations.of(context);
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(score.toString()),
        trailing: Text(
          percent == null ? '–' : '${percent.toStringAsFixed(0)}%',
          semanticsLabel: percent == null
              ? l10n.statsNoGames
              : l10n.statsScoreDetail(score.wins, score.draws, score.losses),
        ),
      ),
    );
  }
}

/// Andamento compatto di una serie di valori.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.label});

  final List<double> values;
  final String label;

  @override
  Widget build(BuildContext context) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return Semantics(
      label: AppLocalizations.of(context).statsTrend(
        label,
        values.first.toStringAsFixed(0),
        values.last.toStringAsFixed(0),
        min.toStringAsFixed(0),
        max.toStringAsFixed(0),
      ),
      child: SizedBox(
        height: 64,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(
            values,
            min,
            max,
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.min, this.max, this.color);

  final List<double> values;
  final double min;
  final double max;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final span = max - min == 0 ? 1 : max - min;
    final path = Path();
    for (final (i, v) in values.indexed) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - (v - min) / span);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      !listEquals(old.values, values) || old.color != color;
}
