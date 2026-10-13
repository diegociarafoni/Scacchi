import 'package:dartchess/dartchess.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Corregge il secondo tocco di una mossa a due tocchi (RM-02): se cade sul
/// bordo di una casa che non è una destinazione e la casa vicina verso cui è
/// caduto lo è, e lo è una sola, gioca quella. Non contende i gesti alla
/// scacchiera: la selezione del primo tocco la ricostruisce da sé.
class TapAssist extends StatefulWidget {
  const TapAssist({
    super.key,
    required this.size,
    required this.orientation,
    required this.destinations,
    required this.onMove,
    required this.child,
    this.enabled = true,
    this.resetKey,
  });

  final double size;
  final Side orientation;

  /// Case dove può andare il pezzo che sta su [from]; vuoto se non si muove.
  final Set<Square> Function(Square from) destinations;
  final void Function(Square from, Square to) onMove;
  final Widget child;
  final bool enabled;

  /// Al cambio la scelta del pezzo si azzera (di solito la posizione).
  final Object? resetKey;

  /// Fascia del bordo, come frazione della casa, in cui il tocco è dubbio.
  static const edge = 0.2;

  @override
  State<TapAssist> createState() => _TapAssistState();
}

class _TapAssistState extends State<TapAssist> {
  final _pointers = <int>{};
  int? _tracked;
  Offset _down = Offset.zero;
  Square? _selected;

  @override
  void didUpdateWidget(TapAssist old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey ||
        old.size != widget.size ||
        old.orientation != widget.orientation ||
        old.enabled != widget.enabled) {
      _selected = null;
      _tracked = null;
    }
  }

  /// Casa sotto [local] e, in coordinate della scacchiera, la sua posizione.
  Square? _squareAt(int file, int row) {
    if (file < 0 || file > 7 || row < 0 || row > 7) return null;
    final white = widget.orientation == Side.white;
    return Square.fromCoords(
      File(white ? file : 7 - file),
      Rank(white ? 7 - row : row),
    );
  }

  void _pressed(PointerDownEvent event) {
    _pointers.add(event.pointer);
    // Con più dita giù non è un tocco.
    _tracked = _pointers.length == 1 ? event.pointer : null;
    _down = event.localPosition;
  }

  void _up(PointerUpEvent event) {
    final tracked = _tracked == event.pointer;
    _pointers.remove(event.pointer);
    _tracked = null;
    if (!tracked || !widget.enabled) return;
    if ((event.localPosition - _down).distance > kTouchSlop) return;
    _tap(event.localPosition);
  }

  void _tap(Offset p) {
    final cell = widget.size / 8;
    final file = (p.dx / cell).floor();
    final row = (p.dy / cell).floor();
    final square = _squareAt(file, row);
    if (square == null) return;
    if (widget.destinations(square).isNotEmpty) {
      // Toccare di nuovo lo stesso pezzo lo deseleziona, come fa la scacchiera.
      _selected = _selected == square ? null : square;
      return;
    }
    final from = _selected;
    if (from == null) return;
    final dests = widget.destinations(from);
    _selected = null;
    if (dests.contains(square)) return;
    final fx = p.dx / cell - file;
    final fy = p.dy / cell - row;
    final dx = fx < TapAssist.edge ? -1 : (fx > 1 - TapAssist.edge ? 1 : 0);
    final dy = fy < TapAssist.edge ? -1 : (fy > 1 - TapAssist.edge ? 1 : 0);
    if (dx == 0 && dy == 0) return;
    final hits = {
      for (final (cx, cy) in [
        if (dx != 0) (dx, 0),
        if (dy != 0) (0, dy),
        if (dx != 0 && dy != 0) (dx, dy),
      ])
        ?_squareAt(file + cx, row + cy),
    }.where(dests.contains).toList();
    if (hits.length == 1) widget.onMove(from, hits.single);
  }

  void _cancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (_tracked == event.pointer) _tracked = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _pressed,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );
}
