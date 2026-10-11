import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

/// Rileva lo scorrimento orizzontale su una scacchiera di lato [size] senza
/// contendere i gesti alla scacchiera: se il dito parte da una casa in cui
/// [canStartAt] è vero (un pezzo da muovere) il gesto è un trascinamento e viene
/// ignorato. [onSwipe] riceve -1 per scorrere a destra (indietro) e 1 per
/// scorrere a sinistra (avanti).
class BoardSwipe extends StatefulWidget {
  const BoardSwipe({
    super.key,
    required this.size,
    required this.orientation,
    required this.canStartAt,
    required this.onSwipe,
    required this.child,
    this.enabled = true,
  });

  final double size;
  final Side orientation;
  final bool Function(Square) canStartAt;
  final ValueChanged<int> onSwipe;
  final Widget child;
  final bool enabled;

  /// Spostamento minimo, in casa, perché il gesto conti come scorrimento.
  static const minTravel = 1.5;

  @override
  State<BoardSwipe> createState() => _BoardSwipeState();
}

class _BoardSwipeState extends State<BoardSwipe> {
  final _pointers = <int>{};
  int? _tracked;
  Offset _start = Offset.zero;

  @override
  void didUpdateWidget(BoardSwipe old) {
    super.didUpdateWidget(old);
    _pointers.clear();
    _tracked = null;
  }

  Square? _squareAt(Offset local) {
    final cell = widget.size / 8;
    final file = (local.dx / cell).floor();
    final row = (local.dy / cell).floor();
    if (file < 0 || file > 7 || row < 0 || row > 7) return null;
    final white = widget.orientation == Side.white;
    return Square.fromCoords(
      File(white ? file : 7 - file),
      Rank(white ? 7 - row : row),
    );
  }

  void _down(PointerDownEvent event) {
    _pointers.add(event.pointer);
    _tracked = null;
    if (!widget.enabled || _pointers.length != 1) return;
    final square = _squareAt(event.localPosition);
    if (square == null || widget.canStartAt(square)) return;
    _tracked = event.pointer;
    _start = event.localPosition;
  }

  void _up(PointerUpEvent event) {
    final tracked = _tracked == event.pointer && _pointers.length == 1;
    _pointers.remove(event.pointer);
    if (!tracked) return;
    _tracked = null;
    final delta = event.localPosition - _start;
    final cell = widget.size / 8;
    if (delta.dx.abs() < cell * BoardSwipe.minTravel ||
        delta.dx.abs() < 2 * delta.dy.abs()) {
      return;
    }
    widget.onSwipe(delta.dx < 0 ? 1 : -1);
  }

  void _cancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (_tracked == event.pointer) _tracked = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );
}
