import 'package:flutter/material.dart';

import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'activity_recorder.dart';
import 'mode_guide.dart';
import 'puzzle_feed.dart';
import 'puzzle_page.dart';
import 'puzzle_run.dart';
import 'puzzle_run_page.dart';
import 'puzzle_trainer.dart';
import 'themes.dart';

/// Punto di ingresso dei puzzle: punteggio e modalità.
class PuzzleHubPage extends StatefulWidget {
  const PuzzleHubPage({
    super.key,
    required this.trainer,
    this.today,
    this.onActivity,
  });

  final Future<PuzzleTrainer> trainer;
  final ActivityRecorder? onActivity;

  /// Data usata per il puzzle del giorno; di default oggi.
  final DateTime? today;

  @override
  State<PuzzleHubPage> createState() => _PuzzleHubPageState();
}

class _PuzzleHubPageState extends State<PuzzleHubPage> {
  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle')),
      body: FutureBuilder<PuzzleTrainer>(
        future: widget.trainer,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Impossibile caricare i puzzle.'));
          }
          final trainer = snapshot.data;
          if (trainer == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final daily = trainer.library.daily(widget.today ?? DateTime.now());
          final due = trainer.dueReviews().length;
          // Profilo bambino (RP-06): niente punteggio, conteggi e difficoltà;
          // i puzzle risolti diventano stelle.
          final kid = AppSettings.of(context).kidMode;
          // Solo il profilo bambino ha i testi nei file .arb.
          AppLocalizations l() => AppLocalizations.of(context);
          return ListView(
            children: [
              if (kid)
                _KidHeader(solved: trainer.solvedCount)
              else
                ListTile(
                  title: Text(
                    'Punteggio ${trainer.rating.rating.round()}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  subtitle: Text(
                    'Risolti ${trainer.solvedCount} · '
                    'Sbagliati ${trainer.failedCount} · '
                    '${trainer.library.puzzles.length} puzzle disponibili',
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.extension_outlined),
                title: const Text('Allenamento'),
                subtitle: Text(
                  kid
                      ? l().kidPuzzleTraining
                      : 'Puzzle adatti al tuo punteggio',
                ),
                onTap: () => _open(
                  PuzzlePage(
                    trainer: trainer,
                    guide: PuzzleGuide.training,
                    onActivity: widget.onActivity,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.today_outlined),
                title: const Text('Puzzle del giorno'),
                subtitle: Text(
                  kid ? l().kidPuzzleDaily : 'Difficoltà ${daily.rating}',
                ),
                onTap: () => _open(
                  PuzzlePage(
                    trainer: trainer,
                    puzzle: daily,
                    guide: PuzzleGuide.daily,
                    title: 'Puzzle del giorno',
                    onActivity: widget.onActivity,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Per tema'),
                subtitle: const Text('Matti, forchette, finali e altro'),
                onTap: () => _open(
                  _ThemeListPage(
                    trainer: trainer,
                    onActivity: widget.onActivity,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.replay_outlined),
                title: const Text('Ripasso degli errori'),
                subtitle: Text(
                  kid
                      ? (due == 0
                            ? l().kidPuzzleReviewNone
                            : l().kidPuzzleReviewDue)
                      : (due == 0
                            ? 'Nessun puzzle da ripassare oggi'
                            : '$due da ripassare oggi'),
                ),
                enabled: due > 0,
                onTap: () => _open(
                  PuzzlePage(
                    trainer: trainer,
                    feed: ReviewFeed(trainer),
                    guide: PuzzleGuide.review,
                    title: 'Ripasso',
                    onActivity: widget.onActivity,
                  ),
                ),
              ),
              // Le modalità a tempo ruotano attorno a punti, errori e record:
              // nel profilo bambino non compaiono.
              if (!kid) const Divider(),
              if (!kid)
                for (final mode in PuzzleRunMode.values)
                  ListTile(
                    leading: const Icon(Icons.bolt_outlined),
                    title: Text(mode.label),
                    subtitle: Text(mode.description),
                    trailing: Text('Record ${trainer.records.best(mode)}'),
                    onTap: () => _open(
                      PuzzleRunPage(
                        trainer: trainer,
                        mode: mode,
                        onActivity: widget.onActivity,
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Intestazione del profilo bambino: una stella per puzzle risolto, fino a
/// [kidMaxStars], così si vede crescere la raccolta senza contare.
class _KidHeader extends StatelessWidget {
  const _KidHeader({required this.solved});

  final int solved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      title: Text(
        l.kidPuzzleHubTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: KidStars(
        key: const Key('kid-puzzle-stars'),
        count: solved,
        label: l.kidPuzzleStarsLabel,
      ),
    );
  }
}

class _ThemeListPage extends StatelessWidget {
  const _ThemeListPage({required this.trainer, this.onActivity});

  final PuzzleTrainer trainer;
  final ActivityRecorder? onActivity;

  @override
  Widget build(BuildContext context) {
    final kid = AppSettings.of(context).kidMode;
    final themes = [
      for (final e in puzzleThemeLabels.entries)
        if (trainer.library.countFor(e.key) > 0) e,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Temi')),
      body: ListView.builder(
        itemCount: themes.length,
        itemBuilder: (context, i) {
          final t = themes[i];
          return ListTile(
            title: Text(t.value),
            trailing: kid ? null : Text('${trainer.library.countFor(t.key)}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PuzzlePage(
                  trainer: trainer,
                  theme: t.key,
                  guide: PuzzleGuide.theme,
                  title: t.value,
                  onActivity: onActivity,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
