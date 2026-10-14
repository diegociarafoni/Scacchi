import 'dart:async';

import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../l10n/app_localizations.dart';
import '../share/image_sharing.dart';
import '../theme/sheets.dart';
import 'portrait.dart';

export '../share/image_sharing.dart' show ShareImage;

String _weekday(AppLocalizations l, int day) => switch (day) {
  DateTime.monday => l.portraitWeekdayMonday,
  DateTime.tuesday => l.portraitWeekdayTuesday,
  DateTime.wednesday => l.portraitWeekdayWednesday,
  DateTime.thursday => l.portraitWeekdayThursday,
  DateTime.friday => l.portraitWeekdayFriday,
  DateTime.saturday => l.portraitWeekdaySaturday,
  _ => l.portraitWeekdaySunday,
};

/// Scheda degli ultimi sette giorni, condivisibile come immagine.
class PortraitPage extends StatefulWidget {
  const PortraitPage({super.key, required this.archive, this.now, this.share});

  final GameArchive archive;
  final DateTime Function()? now;

  /// Consegna dell'immagine; senza, si usa il menu di condivisione del sistema.
  final ShareImage? share;

  @override
  State<PortraitPage> createState() => _PortraitPageState();
}

class _PortraitPageState extends State<PortraitPage> {
  final _card = GlobalKey();
  PlayerPortrait? _portrait;
  bool _failed = false;
  bool _sharing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final games = await widget.archive.list();
      final now = (widget.now ?? DateTime.now)();
      if (mounted) {
        setState(() => _portrait = PlayerPortrait.from(games, now: now));
      }
    } on Object catch (e) {
      debugPrint('Lettura dell\'archivio non riuscita: $e'); // l10n-ok
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    _sharing = true;
    try {
      final png = await capturePng(_card, pixelRatio: 3);
      if (png == null) return;
      final to = _portrait!.to;
      String two(int n) => n.toString().padLeft(2, '0');
      final fileName =
          'rokko-settimana-${to.year}-${two(to.month)}-${two(to.day)}.png'; // l10n-ok
      if (widget.share case final share?) {
        await share(png, fileName);
      } else if (mounted) {
        await shareImageWithSystem(
          png,
          fileName,
          subject: AppLocalizations.of(context).portraitShareSubject,
        );
      }
      if (mounted) setState(() => _message = null);
    } on Object catch (e) {
      debugPrint('Condivisione non riuscita: $e'); // l10n-ok
      if (mounted) {
        setState(
          () => _message = AppLocalizations.of(context).portraitShareFailed,
        );
      }
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portrait = _portrait;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.portraitTitle)),
      body: _failed
          ? Center(child: Text(l.portraitUnreadable))
          : portrait == null
          ? const Center(child: CircularProgressIndicator())
          : portrait.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(l.portraitEmpty, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: context.withSystemBottom(const EdgeInsets.all(16)),
              children: [
                RepaintBoundary(
                  key: _card,
                  child: _Card(portrait: portrait),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share),
                  label: Text(l.portraitShare),
                ),
                if (_message != null) Text(_message!),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.portrait});

  final PlayerPortrait portrait;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final p = portrait;
    final s = p.score;
    final l = AppLocalizations.of(context);
    final rows = <(String, String)>[
      if (p.openings.isNotEmpty)
        (
          l.portraitOpenings,
          p.openings.map((o) => '${o.name} (${o.games})').join(', '),
        ),
      if (p.accuracy case final a?) (l.portraitAccuracy, '${a.round()}%'),
      if (p.matingPiece case final r?)
        (l.portraitMate, l.portraitMateValue(r.name, p.matingGames)),
      if (p.strongestBeaten case final e?)
        (l.portraitStrongest, l.portraitStrongestValue(e)),
      if (p.busiestWeekday case final d?)
        (l.portraitBusiestDay, _weekday(l, d)),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.portraitCardTitle, style: text.titleLarge),
          Text('${_date(p.from)} – ${_date(p.to)}', style: text.bodySmall),
          const SizedBox(height: 12),
          Text(
            l.portraitGames(s.games),
            key: const Key('portrait-games'),
            style: text.displaySmall,
          ),
          Text(
            l.portraitScore(s.wins, s.draws, s.losses),
            key: const Key('portrait-score'),
            style: text.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.labelMedium),
                  Text(value, style: text.bodyLarge),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
