import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import 'qr_code_view.dart';
import 'qr_l10n.dart';
import 'qr_transfer.dart';

/// Mostra i fotogrammi QR di una partita; se sono più d'uno scorrono in
/// ciclo, così chi riceve può leggerli in qualunque ordine.
class QrSendPage extends StatefulWidget {
  const QrSendPage({
    super.key,
    required this.title,
    required this.frames,
    this.hint,
    this.interval = const Duration(milliseconds: 800),
  });

  final String title;
  final List<String> frames;

  /// Istruzioni sotto il QR; di default quelle dello scambio di partite.
  final String? hint;

  /// Tempo di ogni fotogramma: abbastanza per una lettura anche al buio.
  final Duration interval;

  @override
  State<QrSendPage> createState() => _QrSendPageState();
}

class _QrSendPageState extends State<QrSendPage> {
  int _index = 0;
  Timer? _timer;

  int get _count => widget.frames.length;

  // Oltre il limite di chi riceve sarebbe inutile mostrarlo.
  bool get _tooLarge => _count > maxTransferFrames;

  late final _images = _tooLarge
      ? const <QrImage>[]
      : [for (final f in widget.frames) qrImage(f)];

  @override
  void initState() {
    super.initState();
    if (_count > 1 && !_tooLarge) _play();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    _timer = Timer.periodic(widget.interval, (_) => _step(1));
  }

  void _toggle() => setState(() {
    if (_timer == null) {
      _play();
    } else {
      _timer!.cancel();
      _timer = null;
    }
  });

  void _step(int delta) => setState(() => _index = (_index + delta) % _count);

  @override
  Widget build(BuildContext context) {
    final l10n = qrL10n(context);
    final playing = _timer != null;
    if (_tooLarge) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.qrSendTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.qrTooLarge, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrSendTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: QrCodeView(
                  data: widget.frames[_index],
                  image: _images[_index],
                  label: l10n.qrCodeLabel,
                ),
              ),
            ),
            if (_count > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: l10n.qrPrevious,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _step(-1),
                  ),
                  IconButton(
                    tooltip: playing ? l10n.qrPause : l10n.qrResume,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    onPressed: _toggle,
                  ),
                  IconButton(
                    tooltip: l10n.qrNext,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _step(1),
                  ),
                ],
              ),
              Text(
                l10n.qrPart(_index + 1, _count),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Text(widget.hint ?? l10n.qrSendHint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
