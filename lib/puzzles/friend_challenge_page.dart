import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../exchange/qr_l10n.dart';
import '../exchange/qr_receive_page.dart';
import '../exchange/qr_send_page.dart';
import 'activity_recorder.dart';
import 'friend_challenge.dart';
import 'puzzle_run.dart';
import 'puzzle_run_page.dart';
import 'puzzle_trainer.dart';

/// Sfida a tempo tra due telefoni senza rete (RF-95): un QR lancia la stessa
/// prova su entrambi, a fine prova un secondo QR confronta i punteggi.
class FriendChallengePage extends StatefulWidget {
  const FriendChallengePage({
    super.key,
    required this.trainer,
    this.onActivity,
    this.scanner = zxingScanner,
    this.newSeed,
  });

  final PuzzleTrainer trainer;
  final ActivityRecorder? onActivity;
  final QrScannerBuilder scanner;

  /// Sorgente del seme, sostituibile nei test.
  final int Function()? newSeed;

  @override
  State<FriendChallengePage> createState() => _FriendChallengePageState();
}

class _FriendChallengePageState extends State<FriendChallengePage> {
  PuzzleRunMode _mode = PuzzleRunMode.rush3;
  FriendChallenge? _challenge;
  String? _error;

  late final String _library = libraryFingerprint(widget.trainer.library);

  void _prepare() => setState(() {
    _error = null;
    _challenge = FriendChallenge(
      mode: _mode,
      seed: widget.newSeed?.call() ?? math.Random.secure().nextInt(1 << 32),
      library: _library,
    );
  });

  Future<void> _showInvite(FriendChallenge c) {
    final l10n = qrL10n(context);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrSendPage(
          title: l10n.challengeInviteTitle(c.mode.label),
          frames: encodeChallenge(ChallengeInvite(c)),
          hint: l10n.challengeInviteHint,
        ),
      ),
    );
  }

  Future<void> _play(FriendChallenge c) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PuzzleRunPage(
        trainer: widget.trainer,
        mode: c.mode,
        challenge: c,
        onActivity: widget.onActivity,
        scanner: widget.scanner,
      ),
    ),
  );

  Future<void> _receive() async {
    final l10n = qrL10n(context);
    final text = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrReceivePage(
          scanner: widget.scanner,
          title: l10n.challengeReceive,
          hint: l10n.challengeReceiveHint,
          foreignMessage: l10n.challengeNotInvite,
        ),
      ),
    );
    if (text == null || !mounted) return;
    final message = parseChallenge(text);
    if (message is! ChallengeInvite) {
      setState(() => _error = l10n.challengeNotInvite);
    } else if (message.challenge.library != _library) {
      setState(() => _error = l10n.challengeLibraryMismatch);
    } else {
      setState(() => _error = null);
      await _play(message.challenge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = qrL10n(context);
    final challenge = _challenge;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.challengeIntro, style: text.bodyLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in friendChallengeModes)
                  ChoiceChip(
                    label: Text(mode.label),
                    selected: mode == _mode,
                    onSelected: (_) => setState(() {
                      _mode = mode;
                      _challenge = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_mode.description, style: text.bodyMedium),
            const SizedBox(height: 16),
            if (challenge == null)
              FilledButton.icon(
                onPressed: _prepare,
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n.challengePrepare),
              )
            else ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.challengeReady(challenge.mode.label),
                  style: text.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _showInvite(challenge),
                icon: const Icon(Icons.qr_code_2),
                label: Text(l10n.challengeShowInvite),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _play(challenge),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.challengePlay),
              ),
            ],
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: _receive,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.challengeReceive),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
