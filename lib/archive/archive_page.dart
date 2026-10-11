import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../exchange/qr_l10n.dart';
import '../exchange/qr_receive_page.dart';
import '../exchange/qr_send_page.dart';
import '../exchange/qr_transfer.dart';
import 'game_archive.dart';
import 'pgn.dart';
import 'saved_game.dart';

typedef ShareText = Future<void> Function(String text);

Future<void> _shareWithSystem(String text) =>
    SharePlus.instance.share(ShareParams(text: text, subject: 'Partite PGN'));

/// Storico delle partite salvate con ricerca, import ed export PGN.
class ArchivePage extends StatefulWidget {
  const ArchivePage({
    super.key,
    required this.archive,
    this.onOpen,
    this.share = _shareWithSystem,
    this.scanner = zxingScanner,
  });

  final GameArchive archive;

  /// Chiamata quando si tocca una partita per aprirla.
  final ValueChanged<SavedGame>? onOpen;
  final ShareText share;

  /// Lettore QR per ricevere una partita da un altro telefono.
  final QrScannerBuilder scanner;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  List<SavedGame>? _games;
  String _query = '';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final games = await widget.archive.list();
      if (mounted) setState(() => _games = games);
    } on FileSystemException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Iterable<SavedGame> get _visible {
    final q = _query.trim().toLowerCase();
    return (_games ?? const []).where(
      (g) =>
          q.isEmpty ||
          g.white.toLowerCase().contains(q) ||
          g.black.toLowerCase().contains(q) ||
          g.mode.toLowerCase().contains(q),
    );
  }

  Future<void> _exportAll() async =>
      widget.share(await widget.archive.exportPgn());

  Future<void> _import() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportDialog(),
    );
    if (text == null || !mounted) return;
    await _showImport(widget.archive.importPgn(text));
  }

  Future<void> _showImport(Future<PgnImport> import) async {
    final result = await import;
    await _reload();
    if (!mounted) return;
    final n = result.games.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          [
            n == 1 ? '1 partita importata' : '$n partite importate',
            if (result.skipped > 0) '${result.skipped} non valide',
          ].join(', '),
        ),
      ),
    );
  }

  Future<void> _receive() async {
    final text = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => QrReceivePage(scanner: widget.scanner)),
    );
    if (text == null || !mounted) return;
    final games = receivedGames(text);
    if (games.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(qrL10n(context).qrInvalidGame)));
      return;
    }
    await _showImport(widget.archive.importRecords(PgnImport(games, 0)));
  }

  Future<void> _sendQr(SavedGame game) {
    final frames = encodeTransfer(game.pgn);
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QrSendPage(title: game.title, frames: frames),
      ),
    );
  }

  Future<void> _delete(SavedGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la partita?'),
        content: Text(game.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.archive.delete(game.id);
    await _reload();
  }

  Future<void> _onAction(SavedGame game, _Action action) async {
    switch (action) {
      case _Action.share:
        await widget.share(game.pgn);
      case _Action.copy:
        await Clipboard.setData(ClipboardData(text: game.pgn));
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('PGN copiato')));
        }
      case _Action.qr:
        await _sendQr(game);
      case _Action.delete:
        await _delete(game);
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _games;
    final visible = _visible.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partite'),
        actions: [
          IconButton(
            tooltip: qrL10n(context).qrReceiveTitle,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _receive,
          ),
          IconButton(
            tooltip: 'Importa PGN',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _import,
          ),
          IconButton(
            tooltip: 'Esporta tutto in PGN',
            icon: const Icon(Icons.ios_share),
            onPressed: games == null || games.isEmpty ? null : _exportAll,
          ),
        ],
      ),
      body: _failed
          ? const Center(child: Text('Impossibile leggere l\'archivio.'))
          : games == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cerca per giocatore o tipo',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            games.isEmpty
                                ? 'Nessuna partita salvata.'
                                : 'Nessuna partita trovata.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, i) => _GameTile(
                            game: visible[i],
                            onTap: widget.onOpen == null
                                ? null
                                : () => widget.onOpen!(visible[i]),
                            onAction: (a) => _onAction(visible[i], a),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

enum _Action { share, copy, qr, delete }

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.onTap,
    required this.onAction,
  });

  final SavedGame game;
  final VoidCallback? onTap;
  final ValueChanged<_Action> onAction;

  @override
  Widget build(BuildContext context) {
    final result = game.finished ? game.result : 'In corso';
    return ListTile(
      title: Text(game.title),
      subtitle: Text('${_date(game.updatedAt)} · ${game.mode} · $result'),
      onTap: onTap,
      trailing: PopupMenuButton<_Action>(
        tooltip: 'Azioni per ${game.title}',
        onSelected: onAction,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _Action.share,
            child: Text('Condividi PGN'),
          ),
          const PopupMenuItem(value: _Action.copy, child: Text('Copia PGN')),
          PopupMenuItem(
            value: _Action.qr,
            child: Text(qrL10n(context).qrSendTitle),
          ),
          const PopupMenuItem(value: _Action.delete, child: Text('Elimina')),
        ],
      ),
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _text.text = data!.text!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importa PGN'),
      content: TextField(
        key: const Key('pgnInput'),
        controller: _text,
        minLines: 6,
        maxLines: 12,
        decoration: InputDecoration(
          hintText: 'Incolla qui una o più partite in PGN',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Incolla',
            icon: const Icon(Icons.content_paste),
            onPressed: _paste,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: const Text('Importa'),
        ),
      ],
    );
  }
}
