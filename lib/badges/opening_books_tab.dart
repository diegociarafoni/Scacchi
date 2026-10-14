import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';

import '../progress/progress_state.dart';
import 'badges_l10n.dart';
import 'badges_page.dart';
import 'opening_volumes.dart';

const _covers = [
  Color(0xFF4F46E5),
  Color(0xFF9333EA),
  Color(0xFFBE123C),
  Color(0xFF0F766E),
  Color(0xFFB45309),
  Color(0xFF1D4ED8),
];

/// Dorso (13) e margine destro (8) della copertina, tolti dalla larghezza
/// della cella per ottenere il lato della scacchiera.
const bookInset = 21.0;

/// Colore della copertina di un libro, fisso per ogni libro.
Color volumeColor(OpeningVolume v) =>
    _covers[v.id.codeUnits.fold(0, (a, c) => a + c) % _covers.length];

/// Collezione dei libri delle aperture: uno per ogni apertura giocata, con la
/// posizione in copertina.
class OpeningBooksTab extends StatelessWidget {
  const OpeningBooksTab({super.key, required this.state});

  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    final unlocked = unlockedVolumes(state).map((v) => v.id).toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GalleryCounter(
          earned: unlocked.length,
          total: openingVolumes.length,
          hint: l.booksHint,
        ),
        const SizedBox(height: 16),
        GalleryGrid(
          count: openingVolumes.length,
          itemBuilder: (context, i, width) => BookCard(
            volume: openingVolumes[i],
            plays: state.tally[volumeKey(openingVolumes[i].id)] ?? 0,
            boardSize: width - bookInset,
          ),
        ),
      ],
    );
  }
}

/// Un libro: copertina colorata con la posizione dell'apertura, grigia con il
/// lucchetto finché non l'hai giocata.
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.volume,
    required this.plays,
    required this.boardSize,
  });

  final OpeningVolume volume;
  final int plays;
  final double boardSize;

  bool get _unlocked => plays > 0;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = volume.localName;
    return Semantics(
      button: true,
      label: _unlocked
          ? l.booksSemanticsUnlocked(name)
          : l.booksSemanticsLocked(name),
      excludeSemantics: true,
      child: Material(
        color: _unlocked ? volumeColor(volume) : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(6),
            right: Radius.circular(14),
          ),
          side: BorderSide(
            color: _unlocked ? Colors.transparent : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => unawaited(
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => BookDetail(volume: volume, plays: plays),
            ),
          ),
          child: Stack(
            children: [
              // Il dorso del libro.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 7,
                child: ColoredBox(color: Colors.black.withAlpha(60)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(bookInset - 8, 8, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BookCoverBoard(
                      volume: volume,
                      unlocked: _unlocked,
                      size: boardSize,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _unlocked
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La posizione in copertina; spenta e col lucchetto se il libro è bloccato.
class BookCoverBoard extends StatelessWidget {
  const BookCoverBoard({
    super.key,
    required this.volume,
    required this.unlocked,
    required this.size,
  });

  final OpeningVolume volume;
  final bool unlocked;

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget board(double side) {
      final b = StaticChessboard(
        size: side,
        fen: volume.coverFen,
        orientation: Side.white,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: unlocked
            ? b
            : Stack(
                alignment: Alignment.center,
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.45, 0,
                    ]),
                    child: b,
                  ),
                  Icon(
                    Icons.lock_rounded,
                    size: side * 0.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
      );
    }

    return board(size);
  }
}

/// Scheda di un libro: posizione, nome e quante volte l'hai giocato.
class BookDetail extends StatelessWidget {
  const BookDetail({super.key, required this.volume, required this.plays});

  final OpeningVolume volume;
  final int plays;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    final theme = Theme.of(context);
    final unlocked = plays > 0;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BookCoverBoard(volume: volume, unlocked: unlocked, size: 200),
            const SizedBox(height: 16),
            Text(
              volume.localName,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              unlocked ? l.booksPlayed(plays) : l.booksHowTo,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
