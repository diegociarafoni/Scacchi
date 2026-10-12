import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../exchange/qr_code_view.dart';
import '../exchange/qr_receive_page.dart';
import '../game/move_speech.dart';
import '../l10n/app_localizations.dart';
import '../training/training_board.dart';
import 'ble_link.dart';
import 'game_invite.dart';
import 'multiplayer_controller.dart';
import 'saved_game.dart';

/// Testi del multigiocatore, in italiano anche senza i delegate.
AppLocalizations multiplayerL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Come ci si collega all'altro telefono.
enum _Channel { wifi, bluetooth }

/// Partita con un amico su un altro telefono (RMP-08): chi crea mostra il QR
/// dell'invito, l'altro lo inquadra, poi si gioca sulla stessa rete locale.
class MultiplayerPage extends StatefulWidget {
  const MultiplayerPage({
    super.key,
    this.openHost = openLanHost,
    this.openGuest = openLanGuest,
    this.bluetoothCheck = checkBluetooth,
    this.openResumeHost = openLanHostAt,
    this.scanner = zxingScanner,
    this.store,
  });

  final OpenHost openHost;
  final ResumeHost openResumeHost;

  /// Dove sta la partita salvata; per default il file dell'app.
  final SavedGameStore? store;
  final OpenGuest openGuest;

  /// Permessi e Bluetooth acceso, controllati prima di una partita Bluetooth.
  final Future<void> Function({required bool isHost}) bluetoothCheck;
  final QrScannerBuilder scanner;

  @override
  State<MultiplayerPage> createState() => _MultiplayerPageState();
}

class _MultiplayerPageState extends State<MultiplayerPage> {
  Side _side = Side.white;
  _Channel _channel = _Channel.wifi;
  bool _busy = false;
  SavedGameStore? _store;
  SavedGame? _saved;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final store = _store = widget.store ?? await SavedGameStore.open();
      final saved = await store.load();
      if (mounted) setState(() => _saved = saved);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Partita salvata non letta: $e');
    }
  }

  Future<void> _resume(SavedGame saved) => _start(() async {
    if (saved.invite.ble) await widget.bluetoothCheck(isHost: saved.isHost);
    return MultiplayerController.resume(
      saved,
      openHost: widget.openResumeHost,
      openGuest: widget.openGuest,
      store: _store,
    );
  });

  Future<bool> _confirmDiscard() async {
    final l10n = multiplayerL10n(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.multiplayerDiscardTitle),
        content: Text(l10n.multiplayerDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.multiplayerStay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.multiplayerDiscard),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _discard() async {
    if (!await _confirmDiscard()) return;
    await _store?.clear();
    if (mounted) setState(() => _saved = null);
  }

  // Una partita nuova prenderebbe il posto di quella salvata: si chiede prima.
  Future<void> _startNew(Future<MultiplayerController> Function() open) async {
    if (_saved != null) {
      if (!await _confirmDiscard()) return;
      await _store?.clear();
      if (mounted) setState(() => _saved = null);
    }
    await _start(open);
  }

  Future<void> _start(Future<MultiplayerController> Function() open) async {
    setState(() => _busy = true);

    final l10n = multiplayerL10n(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final controller = await open();
      // Chi è partito prima che il file fosse pronto comincia a salvare ora.
      unawaited(_ready.then((_) => controller.useStore(_store)));
      if (!mounted) {
        await controller.close();
        return;
      }
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MultiplayerGamePage(controller: controller),
        ),
      );
    } on NoLocalNetwork {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.multiplayerNoNetwork)),
      );
    } on BluetoothUnavailable catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (e.problem) {
            BluetoothProblem.off => l10n.multiplayerBluetoothOff,
            BluetoothProblem.denied => l10n.multiplayerBluetoothDenied,
            BluetoothProblem.unsupported =>
              l10n.multiplayerBluetoothUnsupported,
          }),
        ),
      );
    } on Object catch (e) {
      // Porta occupata, rete locale negata su iOS e simili.
      if (kDebugMode) debugPrint('Partita con un amico non avviata: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.multiplayerStartError)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final invite = await Navigator.of(context).push<GameInvite>(
      MaterialPageRoute(builder: (_) => _ScanPage(scanner: widget.scanner)),
    );
    if (invite == null || !mounted) return;
    await _startNew(() async {
      if (invite.ble) await widget.bluetoothCheck(isHost: false);
      return MultiplayerController.join(
        invite,
        openGuest: widget.openGuest,
        store: _store,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = multiplayerL10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.multiplayerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_saved case final saved?) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.multiplayerResumeBody(saved.moves.length)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: _busy ? null : () => _resume(saved),
                          child: Text(l10n.multiplayerResume),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _busy ? null : _discard,
                          child: Text(l10n.multiplayerDiscard),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(l10n.multiplayerIntro),
          const SizedBox(height: 24),
          Text(
            l10n.multiplayerYourColor,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<Side>(
            segments: [
              ButtonSegment(
                value: Side.white,
                label: Text(l10n.multiplayerWhite),
              ),
              ButtonSegment(
                value: Side.black,
                label: Text(l10n.multiplayerBlack),
              ),
            ],
            selected: {_side},
            onSelectionChanged: (s) => setState(() => _side = s.first),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.multiplayerChannelLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<_Channel>(
            segments: [
              ButtonSegment(
                value: _Channel.wifi,
                icon: const Icon(Icons.wifi),
                label: Text(l10n.multiplayerChannelWifi),
              ),
              ButtonSegment(
                value: _Channel.bluetooth,
                icon: const Icon(Icons.bluetooth),
                label: Text(l10n.multiplayerChannelBluetooth),
              ),
            ],
            selected: {_channel},
            onSelectionChanged: (s) => setState(() => _channel = s.first),
          ),
          if (_channel == _Channel.bluetooth) ...[
            const SizedBox(height: 8),
            Text(l10n.multiplayerBluetoothHint),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_2),
            label: Text(l10n.multiplayerCreate),
            onPressed: _busy
                ? null
                : () => _startNew(() async {
                    final bluetooth = _channel == _Channel.bluetooth;
                    if (bluetooth) await widget.bluetoothCheck(isHost: true);
                    return MultiplayerController.host(
                      side: _side,
                      bluetooth: bluetooth,
                      openHost: widget.openHost,
                      store: _store,
                    );
                  }),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.multiplayerJoin),
            onPressed: _busy ? null : _join,
          ),
        ],
      ),
    );
  }
}

/// Fotocamera che restituisce il primo invito valido inquadrato.
class _ScanPage extends StatefulWidget {
  const _ScanPage({required this.scanner});

  final QrScannerBuilder scanner;

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  String? _error;
  bool _done = false;

  void _onCode(String code) {
    if (_done) return;
    final invite = GameInvite.parse(code);
    if (invite == null) {
      setState(() => _error = multiplayerL10n(context).multiplayerNotInvite);
      return;
    }
    _done = true;
    Navigator.of(context).pop(invite);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = multiplayerL10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.multiplayerScanTitle)),
      body: Column(
        children: [
          Expanded(
            child: widget.scanner(
              context,
              onCode: _onCode,
              onError: (_) {
                if (mounted) {
                  setState(() => _error = l10n.multiplayerCameraError);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              liveRegion: true,
              child: Text(_error ?? l10n.multiplayerScanHint),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scacchiera della partita a due; finché l'avversario non arriva mostra il
/// QR dell'invito.
class MultiplayerGamePage extends StatefulWidget {
  const MultiplayerGamePage({super.key, required this.controller});

  final MultiplayerController controller;

  @override
  State<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends State<MultiplayerGamePage> {
  MultiplayerController get _c => widget.controller;
  int _moves = 0;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _moves = _c.session.sync.moves.length;
    _c.addListener(_onChange);
  }

  void _onChange() {
    final moves = _c.session.sync.moves.length;
    if (moves > _moves) {
      final mover = moves.isOdd ? Side.white : Side.black;
      final san = _c.lastSan;
      if (mover != _c.mySide && san != null) {
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            describeSan(san, mover),
            Directionality.of(context),
          ),
        );
      }
      _moves = moves;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  Future<void> _onMove(Move move) async {
    if (!await _c.play(move) && mounted) setState(() => _revision++);
  }

  Future<bool> _confirmLeave() async {
    if (_c.status == MultiplayerStatus.finished) return true;
    final l10n = multiplayerL10n(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.multiplayerLeaveTitle),
        content: Text(
          _c.status == MultiplayerStatus.waitingPeer
              ? l10n.multiplayerLeaveBodyWaiting
              : l10n.multiplayerLeaveBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.multiplayerStay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.multiplayerLeave),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  String _statusText(AppLocalizations l10n) => switch (_c.status) {
    MultiplayerStatus.waitingPeer => l10n.multiplayerWaiting,
    MultiplayerStatus.connecting => l10n.multiplayerConnecting,
    MultiplayerStatus.myTurn => l10n.multiplayerYourTurn,
    MultiplayerStatus.peerTurn => l10n.multiplayerPeerTurn,
    MultiplayerStatus.finished => switch (_c.outcome?.winner) {
      Side.white => l10n.multiplayerWhiteWins,
      Side.black => l10n.multiplayerBlackWins,
      null => l10n.multiplayerDraw,
    },
  };

  @override
  Widget build(BuildContext context) {
    final l10n = multiplayerL10n(context);
    final status = _c.status;
    final waiting = status == MultiplayerStatus.waitingPeer;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.multiplayerTitle)),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final size = min(box.maxWidth, box.maxHeight * 0.75) - 32;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _statusText(l10n),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (waiting) ...[
                    Center(
                      child: SizedBox(
                        width: min(size, 320),
                        child: QrCodeView(
                          data: _c.inviteLink,
                          label: l10n.multiplayerInviteQrLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.multiplayerInviteHint,
                      textAlign: TextAlign.center,
                    ),
                    if (_c.session.invite.ble) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.multiplayerBluetoothInviteHint,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else
                    Center(
                      child: TrainingBoard(
                        size: size,
                        position: _c.position,
                        player: _c.mySide,
                        orientation: _c.mySide,
                        lastMove: _c.lastMove,
                        enabled: status == MultiplayerStatus.myTurn,
                        revision: _revision,
                        onMove: _onMove,
                      ),
                    ),
                  if (_c.pendingDelivery) ...[
                    const SizedBox(height: 12),
                    Text(l10n.multiplayerPending, textAlign: TextAlign.center),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
