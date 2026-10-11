import 'package:flutter/material.dart';

import 'activity_recorder.dart';
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
          return ListView(
            children: [
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
                subtitle: const Text('Puzzle adatti al tuo punteggio'),
                onTap: () => _open(
                  PuzzlePage(trainer: trainer, onActivity: widget.onActivity),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.today_outlined),
                title: const Text('Puzzle del giorno'),
                subtitle: Text('Difficoltà ${daily.rating}'),
                onTap: () => _open(
                  PuzzlePage(
                    trainer: trainer,
                    puzzle: daily,
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
                  due == 0
                      ? 'Nessun puzzle da ripassare oggi'
                      : '$due da ripassare oggi',
                ),
                enabled: due > 0,
                onTap: () => _open(
                  PuzzlePage(
                    trainer: trainer,
                    feed: ReviewFeed(trainer),
                    title: 'Ripasso',
                    onActivity: widget.onActivity,
                  ),
                ),
              ),
              const Divider(),
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

class _ThemeListPage extends StatelessWidget {
  const _ThemeListPage({required this.trainer, this.onActivity});

  final PuzzleTrainer trainer;
  final ActivityRecorder? onActivity;

  @override
  Widget build(BuildContext context) {
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
            trailing: Text('${trainer.library.countFor(t.key)}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PuzzlePage(
                  trainer: trainer,
                  theme: t.key,
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
