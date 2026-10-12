import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'board_photo.dart';
import 'physical_l10n.dart';

/// Riquadro scelto e lato che sta in basso nella foto.
typedef AlignResult = ({BoardQuad quad, Side view});

enum _Corner { topLeft, topRight, bottomRight, bottomLeft }

/// Si trascinano i quattro angoli sulla scacchiera della foto: serve a
/// sapere dove sta ogni casella.
class BoardAlignPage extends StatefulWidget {
  const BoardAlignPage({
    super.key,
    required this.image,
    required this.aspect,
    required this.initial,
    this.view = Side.white,
  });

  final Uint8List image;

  /// Larghezza divisa altezza della foto.
  final double aspect;
  final BoardQuad initial;
  final Side view;

  @override
  State<BoardAlignPage> createState() => _BoardAlignPageState();
}

class _BoardAlignPageState extends State<BoardAlignPage> {
  late BoardQuad _quad = widget.initial;
  late Side _view = widget.view;

  PhotoPoint _get(_Corner c) => switch (c) {
    _Corner.topLeft => _quad.topLeft,
    _Corner.topRight => _quad.topRight,
    _Corner.bottomRight => _quad.bottomRight,
    _Corner.bottomLeft => _quad.bottomLeft,
  };

  void _move(_Corner c, Offset delta, Size size) {
    final p = _get(c);
    final moved = PhotoPoint(
      (p.x + delta.dx / size.width).clamp(0.0, 1.0),
      (p.y + delta.dy / size.height).clamp(0.0, 1.0),
    );
    setState(() {
      _quad = switch (c) {
        _Corner.topLeft => _quad.copyWith(topLeft: moved),
        _Corner.topRight => _quad.copyWith(topRight: moved),
        _Corner.bottomRight => _quad.copyWith(bottomRight: moved),
        _Corner.bottomLeft => _quad.copyWith(bottomLeft: moved),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = physicalL10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.physicalAlignTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l10n.physicalAlignHelp),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: widget.aspect,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final size = box.biggest;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.memory(widget.image, fit: BoxFit.fill),
                          ),
                          Positioned.fill(
                            child: CustomPaint(painter: _GridPainter(_quad)),
                          ),
                          for (final c in _Corner.values)
                            Positioned(
                              left: _get(c).x * size.width - 24,
                              top: _get(c).y * size.height - 24,
                              child: GestureDetector(
                                key: Key('align-${c.name}'),
                                onPanUpdate: (d) => _move(c, d.delta, size),
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<Side>(
                segments: [
                  ButtonSegment(
                    value: Side.white,
                    label: Text(l10n.physicalAlignWhiteBottom),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: Side.black,
                    label: Text(
                      l10n.physicalAlignBlackBottom,
                      key: const Key('align-black'),
                    ),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton(
                onPressed: () => Navigator.pop<AlignResult>(context, (
                  quad: _quad,
                  view: _view,
                )),
                child: Text(l10n.physicalAlignDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.quad);

  final BoardQuad quad;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withValues(alpha: .8)
      ..strokeWidth = 1;
    Offset at(double u, double v) {
      final p = quad.at(u, v);
      return Offset(p.x * size.width, p.y * size.height);
    }

    for (var i = 0; i <= 8; i++) {
      canvas.drawLine(at(i / 8, 0), at(i / 8, 1), paint);
      canvas.drawLine(at(0, i / 8), at(1, i / 8), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => true;
}
