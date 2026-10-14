import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
import 'activity_recorder.dart';
import 'mistake_path.dart';
import 'puzzle_page.dart';
import 'puzzle_trainer.dart';
import 'themes.dart';

/// Percorso «dai miei errori»: un capitolo per ogni tema tattico che si
/// sbaglia più spesso, con i puzzle nati dalle proprie partite.
class MistakePathPage extends StatefulWidget {
  const MistakePathPage({super.key, required this.trainer, this.onActivity});

  final PuzzleTrainer trainer;
  final ActivityRecorder? onActivity;

  @override
  State<MistakePathPage> createState() => _MistakePathPageState();
}

class _MistakePathPageState extends State<MistakePathPage> {
  Future<void> _open(MistakeChapter chapter, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzlePage(
          trainer: widget.trainer,
          feed: MistakeChapterFeed(widget.trainer, chapter.theme),
          title: title,
          onActivity: widget.onActivity,
        ),
      ),
    );
    // L'avanzamento è cambiato mentre la pagina era coperta.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final chapters = mistakeChapters(widget.trainer);
    return Scaffold(
      appBar: AppBar(title: Text(l.puzzleMistakePath)),
      body: ListView(
        padding: context.withSystemBottom(
          const EdgeInsets.fromLTRB(16, 8, 16, 24),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              chapters.isEmpty
                  ? l.puzzleMistakePathEmpty
                  : l.puzzleMistakePathIntro,
              style: text.bodyMedium,
            ),
          ),
          for (var i = 0; i < chapters.length; i++)
            if (puzzleThemeLabel(l, chapters[i].theme) case final title?)
              _ChapterCard(
                number: i + 1,
                chapter: chapters[i],
                title: title,
                // Nulla da fare adesso: i puzzle aspettano il loro giorno.
                onTap: chapters[i].available == 0
                    ? null
                    : () => _open(chapters[i], title),
              ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.number,
    required this.chapter,
    required this.title,
    required this.onTap,
  });

  final int number;
  final MistakeChapter chapter;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final status = chapter.done
        ? l.puzzleMistakeChapterDone
        : chapter.available == 0
        ? l.puzzleMistakeChapterRested
        : chapter.practiced == 0
        ? l.puzzleMistakeChapterNew
        : l.puzzleMistakeChapterInProgress;
    final count = l.puzzleMistakeChapterPuzzles(chapter.total);
    final progress = l.puzzleMistakeChapterProgress(
      chapter.practiced,
      chapter.total,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: RokkoTokens.of(context).minTouch,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.puzzleMistakeChapterNumber(number),
                  style: text.labelMedium?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: 2),
                Text(title, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(count, style: text.bodyMedium),
                const SizedBox(height: 10),
                // La barra non basta da sola: a parole c'è anche lo stato.
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: chapter.total == 0
                          ? 0
                          : chapter.practiced / chapter.total,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text(progress, style: text.bodySmall)),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: text.labelLarge?.copyWith(
                        color: chapter.done ? colors.primary : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
