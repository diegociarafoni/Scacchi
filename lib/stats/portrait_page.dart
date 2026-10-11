import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../archive/game_archive.dart';
import 'portrait.dart';

typedef ShareImage = Future<void> Function(Uint8List png, String fileName);

Future<void> _shareWithSystem(Uint8List png, String fileName) async {
  final tmp = await getTemporaryDirectory();
  final file = File('${tmp.path}/$fileName');
  await file.writeAsBytes(png, flush: true);
  try {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'La mia settimana'),
    );
  } finally {
    if (file.existsSync()) await file.delete();
  }
}

const _weekdays = {
  DateTime.monday: 'lunedì',
  DateTime.tuesday: 'martedì',
  DateTime.wednesday: 'mercoledì',
  DateTime.thursday: 'giovedì',
  DateTime.friday: 'venerdì',
  DateTime.saturday: 'sabato',
  DateTime.sunday: 'domenica',
};

const _roles = {
  Role.king: 'con il re',
  Role.queen: 'con la donna',
  Role.rook: 'con la torre',
  Role.bishop: 'con l\'alfiere',
  Role.knight: 'con il cavallo',
  Role.pawn: 'con il pedone',
};

/// Scheda degli ultimi sette giorni, condivisibile come immagine.
class PortraitPage extends StatefulWidget {
  const PortraitPage({
    super.key,
    required this.archive,
    this.now,
    this.share = _shareWithSystem,
  });

  final GameArchive archive;
  final DateTime Function()? now;
  final ShareImage share;

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
      debugPrint('Lettura dell\'archivio non riuscita: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _share() async {
    final boundary =
        _card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || _sharing) return;
    _sharing = true;
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final to = _portrait!.to;
      String two(int n) => n.toString().padLeft(2, '0');
      await widget.share(
        data.buffer.asUint8List(),
        'scacchi-settimana-${to.year}-${two(to.month)}-${two(to.day)}.png',
      );
      if (mounted) setState(() => _message = null);
    } on Object catch (e) {
      debugPrint('Condivisione non riuscita: $e');
      if (mounted) setState(() => _message = 'Condivisione non riuscita');
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portrait = _portrait;
    return Scaffold(
      appBar: AppBar(title: const Text('La tua settimana')),
      body: _failed
          ? const Center(child: Text('L\'archivio non si è potuto leggere.'))
          : portrait == null
          ? const Center(child: CircularProgressIndicator())
          : portrait.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Nessuna partita negli ultimi sette giorni. Gioca contro il '
                  'computer e qui comparirà il riepilogo.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RepaintBoundary(
                  key: _card,
                  child: _Card(portrait: portrait),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Condividi come immagine'),
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
    final rows = <(String, String)>[
      if (p.openings.isNotEmpty)
        (
          'Aperture preferite',
          p.openings.map((o) => '${o.name} (${o.games})').join(', '),
        ),
      if (p.accuracy case final a?) ('Precisione media', '${a.round()}%'),
      if (p.matingPiece case final r?)
        (
          'Matto preferito',
          '${_roles[r]}, ${p.matingGames} '
              '${p.matingGames == 1 ? 'volta' : 'volte'}',
        ),
      if (p.strongestBeaten case final e?)
        ('Avversario più forte battuto', 'Elo $e'),
      if (p.busiestWeekday case final d?) ('Giorno più attivo', _weekdays[d]!),
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
          Text('La mia settimana a scacchi', style: text.titleLarge),
          Text('${_date(p.from)} – ${_date(p.to)}', style: text.bodySmall),
          const SizedBox(height: 12),
          Text(
            '${s.games} ${s.games == 1 ? 'partita' : 'partite'}',
            key: const Key('portrait-games'),
            style: text.displaySmall,
          ),
          Text(
            '${s.wins} vinte · ${s.draws} patte · ${s.losses} perse',
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
