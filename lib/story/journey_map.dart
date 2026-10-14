import 'package:flutter/material.dart';

import '../theme/rokko_mascot.dart';
import '../theme/rokko_theme.dart';
import 'story.dart';
import 'story_l10n.dart';

/// Mappa del viaggio (S3): i luoghi della Storia lungo un sentiero a
/// serpentina, con i capitoli conclusi, il luogo dove si è e quelli ancora
/// chiusi. Un tocco su un luogo porta al suo capitolo.
class JourneyMap extends StatelessWidget {
  const JourneyMap({
    super.key,
    required this.progress,
    required this.current,
    required this.onSelect,
  });

  final StoryProgress progress;

  /// Capitolo dove ci si è fermati; `null` a storia finita.
  final int? current;
  final ValueChanged<int> onSelect;

  static const columns = 3;
  static const _rowHeight = 116.0;

  /// Altezza di una riga: con testi più grandi i nomi occupano più spazio.
  static double rowHeightFor(double textScale) =>
      _rowHeight + (textScale - 1).clamp(0.0, 2.0) * 40;
  static const _node = 56.0;
  static const _maxWidth = 420.0;

  /// Colonna del luogo [i]: le righe dispari si percorrono da destra.
  static int columnOf(int i) {
    final c = i % columns;
    return (i ~/ columns).isOdd ? columns - 1 - c : c;
  }

  @override
  Widget build(BuildContext context) {
    final rows = (storyChapters.length / columns).ceil();
    final rowHeight = rowHeightFor(MediaQuery.textScalerOf(context).scale(1));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            Offset center(int i) => Offset(
              width * (2 * columnOf(i) + 1) / (2 * columns),
              rowHeight * (i ~/ columns) + _node / 2 + 4,
            );
            final scheme = Theme.of(context).colorScheme;
            return SizedBox(
              key: const ValueKey('journey-map'),
              height: rowHeight * rows,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrailPainter(
                        centers: [
                          for (var i = 0; i < storyChapters.length; i++)
                            center(i),
                        ],
                        done: [
                          for (final c in storyChapters)
                            progress.isChapterDone(c),
                        ],
                        solid: scheme.primary,
                        dashed: scheme.outlineVariant,
                      ),
                    ),
                  ),
                  for (final (i, chapter) in storyChapters.indexed)
                    Positioned(
                      left: center(i).dx - width / (2 * columns),
                      top: center(i).dy - _node / 2,
                      width: width / columns,
                      child: _Place(
                        key: ValueKey('journey-${chapter.id}'),
                        chapter: chapter,
                        done: progress.isChapterDone(chapter),
                        here: current == i,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({
    super.key,
    required this.chapter,
    required this.done,
    required this.here,
    required this.onTap,
  });

  final StoryChapter chapter;
  final bool done;
  final bool here;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = RokkoTokens.of(context);
    final title = l10n.chapterTitle(chapter);
    final status = done
        ? l10n.storyChapterDone
        : here
        ? l10n.storyChapterCurrent
        : l10n.storyChapterLocked;
    return Semantics(
      button: true,
      label: '$title. $status',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 48,
        child: Column(
          children: [
            Container(
              width: JourneyMap._node,
              height: JourneyMap._node,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? scheme.primary : scheme.surface,
                border: Border.all(
                  color: here ? tokens.action : scheme.outlineVariant,
                  width: here ? 3 : 2,
                ),
              ),
              child: done
                  ? Icon(Icons.check, color: scheme.onPrimary)
                  : here
                  ? const RokkoMascot(size: 40)
                  : Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            // Sul colore della scheda: il sentiero passa dietro al nome.
            ColoredBox(
              color: theme.cardTheme.color ?? scheme.surfaceContainerLow,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: here ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sentiero che unisce i luoghi: pieno dove il capitolo è concluso,
/// tratteggiato oltre.
class _TrailPainter extends CustomPainter {
  const _TrailPainter({
    required this.centers,
    required this.done,
    required this.solid,
    required this.dashed,
  });

  final List<Offset> centers;
  final List<bool> done;
  final Color solid;
  final Color dashed;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i + 1 < centers.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = done[i] ? solid : dashed;
      final a = centers[i];
      final b = centers[i + 1];
      if (done[i]) {
        canvas.drawLine(a, b, paint);
        continue;
      }
      final length = (b - a).distance;
      final step = (b - a) / length;
      for (var d = 0.0; d < length; d += 13) {
        canvas.drawLine(
          a + step * d,
          a + step * (d + 7 > length ? length : d + 7),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.solid != solid || old.dashed != dashed || !_same(old);

  bool _same(_TrailPainter old) {
    if (old.centers.length != centers.length) return false;
    for (var i = 0; i < centers.length; i++) {
      if (old.centers[i] != centers[i] || old.done[i] != done[i]) return false;
    }
    return true;
  }
}
