import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'settings.dart';

/// Posizione di prova: l'alfiere in b5 è selezionato e può prendere in c6.
const _fenBefore =
    'r1bqkbnr/1ppp1ppp/p1n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 4';
const _selected = Square.b5;
const _move = NormalMove(from: Square.b5, to: Square.c6);

final _before = Chess.fromSetup(Setup.parseFen(_fenBefore));
final _after = _before.play(_move);

/// Mini-scacchiera che mostra la posizione di prova con tema, pezzi,
/// evidenziazioni e animazioni delle [settings]; un tocco gioca la mossa.
class BoardPreview extends StatefulWidget {
  const BoardPreview({super.key, required this.settings, this.size = 128});

  final AppSettings settings;
  final double size;

  @override
  State<BoardPreview> createState() => _BoardPreviewState();
}

class _BoardPreviewState extends State<BoardPreview> {
  bool _played = false;
  bool _focused = false;

  @override
  void didUpdateWidget(BoardPreview old) {
    super.didUpdateWidget(old);
    if (_look(old.settings) != _look(widget.settings)) _played = false;
  }

  /// Le sole impostazioni che cambiano ciò che si vede nell'anteprima.
  static Object _look(AppSettings s) => (
    s.boardTheme,
    s.pieceSet,
    s.showCoordinates,
    s.showLegalMoves,
    s.colorBlind,
    s.animation,
    s.tableMode,
  );

  void _toggle() => setState(() => _played = !_played);

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final scheme = s.board.colorScheme;
    final position = _played ? _after : _before;
    final size = widget.size;
    return Semantics(
      label:
          'Anteprima della scacchiera. Tocca per ${_played ? 'ripristinare' : 'giocare'} la mossa di prova',
      button: true,
      excludeSemantics: true,
      onTap: _toggle,
      child: FocusableActionDetector(
        key: const Key('board-preview'),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: _toggle,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: _focused
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    )
                  : null,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  StaticChessboard(
                    size: size,
                    orientation: Side.white,
                    fen: position.fen,
                    lastMove: _played ? _move : null,
                    settings: StaticChessboardSettings.fromBoardSettings(
                      s.board,
                    ),
                    squareHighlights: {
                      if (!_played)
                        _selected: SquareHighlight(details: scheme.selected),
                    },
                  ),
                  if (!_played && s.showLegalMoves)
                    IgnorePointer(
                      child: CustomPaint(
                        key: const Key('preview-dots'),
                        size: Size.square(size),
                        painter: _DotsPainter(
                          position: _before,
                          from: _selected,
                          color: scheme.validMoves,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puntini sulle case libere raggiungibili e anelli sulle catture.
class _DotsPainter extends CustomPainter {
  _DotsPainter({
    required this.position,
    required this.from,
    required this.color,
  });

  final Chess position;
  final Square from;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final square = size.width / 8;
    final dots = Paint()..color = color;
    final rings = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = square * 0.1;
    for (final to in (position.legalMoves[from] ?? SquareSet.empty).squares) {
      final center = Offset(
        (to.file + 0.5) * square,
        (7 - to.rank + 0.5) * square,
      );
      if (position.board.pieceAt(to) != null) {
        canvas.drawCircle(center, square * 0.45, rings);
      } else {
        canvas.drawCircle(center, square * 0.16, dots);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.position != position || old.from != from || old.color != color;
}
