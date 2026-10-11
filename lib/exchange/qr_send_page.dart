import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'qr_code_view.dart';

/// Mostra i fotogrammi QR di una partita; se sono più d'uno scorrono in
/// ciclo, così chi riceve può leggerli in qualunque ordine.
class QrSendPage extends StatefulWidget {
  const QrSendPage({
    super.key,
    required this.title,
    required this.frames,
    this.interval = const Duration(milliseconds: 800),
  });

  final String title;
  final List<String> frames;

  /// Tempo di ogni fotogramma: abbastanza per una lettura anche al buio.
  final Duration interval;

  @override
  State<QrSendPage> createState() => _QrSendPageState();
}

class _QrSendPageState extends State<QrSendPage> {
  int _index = 0;
  Timer? _timer;

  int get _count => widget.frames.length;

  @override
  void initState() {
    super.initState();
    if (_count > 1) _play();
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
    final l10n = AppLocalizations.of(context);
    final playing = _timer != null;
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
            Text(l10n.qrSendHint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
