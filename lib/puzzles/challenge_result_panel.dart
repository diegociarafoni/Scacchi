import 'package:flutter/material.dart';

import '../exchange/qr_l10n.dart';
import '../exchange/qr_receive_page.dart';
import '../exchange/qr_send_page.dart';
import 'friend_challenge.dart';

/// Confronto a fine prova (RF-95): mostra il QR col proprio punteggio e legge
/// quello dell'amico.
class ChallengeResultPanel extends StatefulWidget {
  const ChallengeResultPanel({
    super.key,
    required this.challenge,
    required this.score,
    required this.scanner,
  });

  final FriendChallenge challenge;
  final int score;
  final QrScannerBuilder scanner;

  @override
  State<ChallengeResultPanel> createState() => _ChallengeResultPanelState();
}

class _ChallengeResultPanelState extends State<ChallengeResultPanel> {
  int? _theirs;
  String? _error;

  Future<void> _show() {
    final l10n = qrL10n(context);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrSendPage(
          title: l10n.challengeResultTitle(widget.score),
          frames: encodeChallenge(
            ChallengeResult(widget.challenge, widget.score),
          ),
          hint: l10n.challengeResultHint,
        ),
      ),
    );
  }

  Future<void> _read() async {
    final l10n = qrL10n(context);
    final text = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrReceivePage(
          scanner: widget.scanner,
          title: l10n.challengeReadResult,
          hint: l10n.challengeReadResultHint,
          foreignMessage: l10n.challengeNotResult,
        ),
      ),
    );
    if (text == null || !mounted) return;
    final message = parseChallenge(text);
    setState(() {
      _theirs = null;
      if (message is! ChallengeResult) {
        _error = l10n.challengeNotResult;
      } else if (!message.answers(widget.challenge)) {
        _error = l10n.challengeOtherChallenge;
      } else {
        _error = null;
        _theirs = message.score;
      }
    });
  }

  String _outcome() {
    final l10n = qrL10n(context);
    final (mine, theirs) = (widget.score, _theirs!);
    return switch (compareScores(mine: mine, theirs: theirs)) {
      ChallengeOutcome.won => l10n.challengeWon(mine, theirs),
      ChallengeOutcome.lost => l10n.challengeLost(mine, theirs),
      ChallengeOutcome.draw => l10n.challengeDraw(mine, theirs),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = qrL10n(context);
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.challengeCompareTitle, style: text.titleMedium),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _show,
          icon: const Icon(Icons.qr_code_2),
          label: Text(l10n.challengeShowResult),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _read,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l10n.challengeReadResult),
        ),
        if (_theirs != null || _error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _theirs != null && _error == null ? _outcome() : _error!,
                textAlign: TextAlign.center,
                style: _error != null
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : text.titleLarge,
              ),
            ),
          ),
      ],
    );
  }
}
