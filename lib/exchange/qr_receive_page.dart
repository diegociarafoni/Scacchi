import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../archive/pgn.dart';
import 'qr_l10n.dart';
import 'qr_transfer.dart';

/// Costruisce il lettore QR: [onCode] riceve il testo di ogni QR letto,
/// [onError] l'impossibilità di usare la fotocamera.
typedef QrScannerBuilder = Widget Function(
  BuildContext context, {
  required ValueChanged<String> onCode,
  required ValueChanged<Object> onError,
});

/// Partite contenute in un testo ricevuto. Un nostro QR senza mosse né
/// posizione di partenza non è una partita (per esempio un testo qualunque).
List<PgnRecord> receivedGames(String text) => [
  for (final g in importPgn(text).games)
    if (g.game.moves.isNotEmpty || g.headers.containsKey('FEN')) g,
];

/// Lettore basato su zxing-cpp, tutto sul dispositivo e senza servizi Google.
Widget zxingScanner(
  BuildContext context, {
  required ValueChanged<String> onCode,
  required ValueChanged<Object> onError,
}) => ReaderWidget(
  codeFormat: Format.qrCode,
  onScan: (code) {
    final text = code.text;
    if (code.isValid && text != null) onCode(text);
  },
  onControllerCreated: (_, error) {
    if (error != null) onError(error);
  },
  // Fotogrammi ravvicinati: una partita lunga scorre più QR al secondo.
  scanDelay: const Duration(milliseconds: 100),
  scanDelaySuccess: const Duration(milliseconds: 100),
  cropPercent: 0.8,
  showToggleCamera: false,
);

/// Legge con la fotocamera i QR di una partita e restituisce con `pop` il
/// testo ricomposto.
class QrReceivePage extends StatefulWidget {
  const QrReceivePage({super.key, this.scanner = zxingScanner});

  final QrScannerBuilder scanner;

  @override
  State<QrReceivePage> createState() => _QrReceivePageState();
}

class _QrReceivePageState extends State<QrReceivePage> {
  final _assembler = TransferAssembler();
  String? _progress;
  String? _notice;
  bool _cameraFailed = false;
  bool _done = false;

  void _onCode(String frame) {
    if (_done || !mounted) return;
    final l10n = qrL10n(context);
    final event = _assembler.add(frame);
    switch (event) {
      case FrameAccepted(:final received, :final total):
        HapticFeedback.selectionClick().ignore();
        _show(l10n.qrReceived(received, total), null, announce: true);
      case TransferRestarted(:final received, :final total):
        _show(l10n.qrReceived(received, total), l10n.qrRestarted);
      case FrameDuplicate():
        break;
      case FrameRejected(:final reason):
        // Dopo un errore sull'intera partita il ricompositore riparte da zero.
        final restarted = _assembler.received == 0;
        _show(restarted ? null : _progress, switch (reason) {
          RejectReason.foreign => l10n.qrForeign,
          RejectReason.tooLarge => l10n.qrTooLarge,
          RejectReason.malformed => l10n.qrMalformed,
          RejectReason.corrupted => l10n.qrCorrupted,
        });
      case TransferComplete(:final text):
        _done = true;
        HapticFeedback.mediumImpact().ignore();
        Navigator.of(context).pop(text);
    }
  }

  void _show(String? progress, String? notice, {bool announce = false}) {
    setState(() {
      _progress = progress;
      _notice = notice;
    });
    if (announce && progress != null) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        progress,
        Directionality.of(context),
      ).ignore();
    }
  }

  void _onError(Object error) {
    debugPrint('Fotocamera non disponibile: $error');
    if (mounted) setState(() => _cameraFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = qrL10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrReceiveTitle)),
      body: SafeArea(
        child: _cameraFailed
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(l10n.qrCameraError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _cameraFailed = false),
                      child: Text(l10n.qrRetry),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: widget.scanner(
                      context,
                      onCode: _onCode,
                      onError: _onError,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _progress ?? l10n.qrReceiveHint,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_notice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _notice!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
