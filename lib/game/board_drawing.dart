import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../settings/settings.dart';

/// Frecce e cerchi sulla scacchiera (RF-05) senza contendere i gesti alla
/// scacchiera: su touch si tiene premuto un dito fermo su una casa e poi si
/// trascina (cerchio se si rilascia lì, freccia altrimenti); col mouse basta il
/// tasto destro, con Maiusc, Ctrl o Alt per gli altri colori. Un tocco, o il
/// cambio di [resetKey], toglie tutte le forme.
class BoardDrawing extends StatefulWidget {
  const BoardDrawing({
    super.key,
    required this.size,
    required this.orientation,
    required this.color,
    required this.canStartAt,
    required this.builder,
    this.enabled = true,
    this.resetKey,
    this.drawing,
    this.shapeOf = plainShape,
  });

  final double size;
  final Side orientation;

  /// Colore delle forme senza modificatori.
  final Color color;

  /// Case da cui il tocco prolungato non disegna, perché sposta un pezzo.
  final bool Function(Square) canStartAt;
  final bool enabled;

  /// Al cambio le forme spariscono (di solito la posizione).
  final Object? resetKey;

  /// Vero mentre si disegna, per sospendere altri gesti come lo scorrimento.
  final ValueNotifier<bool>? drawing;

  /// Come si disegna una forma: [dest] nullo è un cerchio.
  final Set<Shape> Function(Color color, Square orig, Square? dest) shapeOf;

  static Set<Shape> plainShape(Color color, Square orig, Square? dest) => {
    dest == null
        ? Circle(color: color, orig: orig)
        : Arrow(color: color, orig: orig, dest: dest),
  };

  /// Costruisce la scacchiera con le forme da mostrare.
  final Widget Function(Set<Shape> marks) builder;

  /// Pressione necessaria perché il tocco diventi un disegno.
  static const holdTime = Duration(milliseconds: 400);

  static final red = MarkColor.red.color;
  static final blue = MarkColor.blue.color;
  static final yellow = MarkColor.yellow.color;

  @override
  State<BoardDrawing> createState() => _BoardDrawingState();
}

class _BoardDrawingState extends State<BoardDrawing> {
  var _marks = <_Mark>{};
  final _pointers = <int>{};
  int? _tracked;
  bool _active = false;
  bool _mouse = false;
  Offset _start = Offset.zero;
  Square? _origin;
  Square? _dest;
  Color _color = const Color(0x00000000);
  Timer? _hold;

  @override
  void didUpdateWidget(BoardDrawing old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey && _marks.isNotEmpty) {
      _marks = {};
    }
    if (old.size != widget.size ||
        old.orientation != widget.orientation ||
        (old.enabled && !widget.enabled)) {
      _stop();
      _pointers.clear();
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
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

  Color _colorForKeys() {
    final keys = HardwareKeyboard.instance;
    if (keys.isShiftPressed) return BoardDrawing.red;
    if (keys.isControlPressed) return BoardDrawing.blue;
    if (keys.isAltPressed) return BoardDrawing.yellow;
    return widget.color;
  }

  void _stop() {
    _hold?.cancel();
    _hold = null;
    _tracked = null;
    _origin = null;
    _dest = null;
    if (_active) {
      _active = false;
      widget.drawing?.value = false;
    }
  }

  void _begin(Square square) {
    _origin = square;
    _dest = square;
    _active = true;
    widget.drawing?.value = true;
    unawaited(HapticFeedback.selectionClick());
    setState(() {});
  }

  void _down(PointerDownEvent event) {
    _pointers.add(event.pointer);
    if (_pointers.length > 1) {
      // Con due dita decide la scacchiera (frecce a due dita).
      _stop();
      setState(() {});
      return;
    }
    _stop();
    if (!widget.enabled) return;
    final square = _squareAt(event.localPosition);
    if (square == null) return;
    _tracked = event.pointer;
    _start = event.localPosition;
    _mouse = event.kind == PointerDeviceKind.mouse;
    _color = _colorForKeys();
    if (_mouse) {
      if (event.buttons == kSecondaryMouseButton) _begin(square);
    } else if (!widget.canStartAt(square)) {
      _hold = Timer(BoardDrawing.holdTime, () {
        _hold = null;
        _begin(square);
      });
    }
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _tracked) return;
    if (!_active) {
      if (_hold != null &&
          (event.localPosition - _start).distance > kTouchSlop) {
        _hold!.cancel();
        _hold = null;
      }
      return;
    }
    final square = _squareAt(event.localPosition);
    if (square != null && square != _dest) setState(() => _dest = square);
  }

  void _up(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (event.pointer != _tracked) return;
    final origin = _origin;
    final dest = _dest;
    final drew = _active && origin != null;
    _stop();
    if (drew) {
      final mark = _mark(origin, dest ?? origin);
      setState(() {
        _marks = _marks.contains(mark)
            ? ({..._marks}..remove(mark))
            : {..._marks, mark};
      });
    } else if (_marks.isNotEmpty) {
      setState(() => _marks = {});
    }
  }

  void _cancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (event.pointer != _tracked) return;
    _stop();
    setState(() {});
  }

  _Mark _mark(Square origin, Square dest) =>
      (_color, origin, dest == origin ? null : dest);

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    final preview = _active && origin != null
        ? _mark(origin, _dest ?? origin)
        : null;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: widget.builder({
        for (final (color, orig, dest) in [..._marks, ?preview])
          ...widget.shapeOf(color, orig, dest),
      }),
    );
  }
}

/// Colore, casa di partenza e, per una freccia, di arrivo.
typedef _Mark = (Color, Square, Square?);
