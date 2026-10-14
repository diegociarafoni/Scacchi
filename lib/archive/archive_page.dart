import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../exchange/qr_l10n.dart';
import '../exchange/qr_receive_page.dart';
import '../exchange/qr_send_page.dart';
import '../exchange/qr_transfer.dart';
import '../l10n/app_localizations.dart';
import 'game_archive.dart';
import 'pgn.dart';
import 'saved_game.dart';

typedef ShareText = Future<void> Function(String text);

/// Storico delle partite salvate con ricerca, import ed export PGN.
class ArchivePage extends StatefulWidget {
  const ArchivePage({
    super.key,
    required this.archive,
    this.onOpen,
    this.onAnalyse,
    this.share,
    this.scanner = zxingScanner,
  });

  final GameArchive archive;

  /// Chiamata quando si tocca una partita per aprirla.
  final ValueChanged<SavedGame>? onOpen;

  /// Chiamata quando si sceglie «Apri nell'analisi» (RF-52); senza, la voce
  /// non compare.
  final ValueChanged<SavedGame>? onAnalyse;

  /// Condivisione del testo; senza, si usa il foglio di condivisione del
  /// sistema.
  final ShareText? share;

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
    final l = AppLocalizations.of(context);
    return (_games ?? const []).where(
      (g) =>
          q.isEmpty ||
          g.titleIn(l).toLowerCase().contains(q) ||
          g.white.toLowerCase().contains(q) ||
          g.black.toLowerCase().contains(q) ||
          _modeLabel(l, g.mode).toLowerCase().contains(q),
    );
  }

  Future<void> _share(String text) {
    final share = widget.share;
    if (share != null) return share(text);
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: AppLocalizations.of(context).archiveShareSubject,
      ),
    );
  }

  /// Esegue [action] avvisando se il disco non risponde (pieno, non scrivibile).
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FileSystemException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).youLoadError)),
      );
    }
  }

  Future<void> _exportAll() => _guard(() async {
    final text = await widget.archive.exportPgn();
    if (mounted) await _share(text);
  });

  Future<void> _import() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportDialog(),
    );
    if (text == null || !mounted) return;
    await _guard(() => _showImport(widget.archive.importPgn(text)));
  }

  Future<void> _showImport(Future<PgnImport> import) async {
    final result = await import;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)
              .archiveImportResult(result.games.length, result.skipped),
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
    await _guard(
      () => _showImport(widget.archive.importRecords(PgnImport(games, 0))),
    );
  }

  Future<void> _sendQr(SavedGame game) {
    final frames = encodeTransfer(game.pgn);
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QrSendPage(
          title: game.titleIn(AppLocalizations.of(context)),
          frames: frames,
        ),
      ),
    );
  }

  Future<void> _delete(SavedGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).archiveDeleteTitle),
        content: Text(game.titleIn(AppLocalizations.of(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).archiveCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).archiveDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _guard(() async {
      await widget.archive.delete(game.id);
      await _reload();
    });
  }

  Future<void> _onAction(SavedGame game, _Action action) async {
    switch (action) {
      case _Action.analyse:
        widget.onAnalyse?.call(game);
      case _Action.share:
        await _share(game.pgn);
      case _Action.copy:
        await Clipboard.setData(ClipboardData(text: game.pgn));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).archivePgnCopied),
            ),
          );
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.archiveTitle),
        actions: [
          IconButton(
            tooltip: qrL10n(context).qrReceiveTitle,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _receive,
          ),
          IconButton(
            tooltip: l.archiveImportPgn,
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _import,
          ),
          IconButton(
            tooltip: l.archiveExportAll,
            icon: const Icon(Icons.ios_share),
            onPressed: games == null || games.isEmpty ? null : _exportAll,
          ),
        ],
      ),
      body: _failed
          ? Center(child: Text(l.archiveUnreadable))
          : games == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.archiveSearchHint,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            games.isEmpty ? l.archiveEmpty : l.archiveNoMatch,
                          ),
                        )
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, i) => _GameTile(
                            game: visible[i],
                            onTap: widget.onOpen == null
                                ? null
                                : () => widget.onOpen!(visible[i]),
                            canAnalyse: widget.onAnalyse != null,
                            onAction: (a) => _onAction(visible[i], a),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

enum _Action { analyse, share, copy, qr, delete }

/// Tipo di partita in parole; un tipo sconosciuto si mostra com'è.
String _modeLabel(AppLocalizations l, String mode) => switch (mode) {
  SavedGame.local => l.archiveModeLocal,
  SavedGame.computer => l.archiveModeComputer,
  SavedGame.imported => l.archiveModeImported,
  SavedGame.physical => l.archiveModePhysical,
  SavedGame.analysis => l.archiveModeAnalysis,
  _ => mode,
};

String _date(BuildContext context, DateTime d) =>
    DateFormat.yMd(Localizations.localeOf(context).toString()).format(d);

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.onTap,
    required this.canAnalyse,
    required this.onAction,
  });

  final SavedGame game;
  final VoidCallback? onTap;
  final bool canAnalyse;
  final ValueChanged<_Action> onAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = game.finished ? game.result : l.archiveInProgress;
    return ListTile(
      title: Text(game.titleIn(l)),
      subtitle: Text(
        '${_date(context, game.updatedAt)} · ${_modeLabel(l, game.mode)} · $result',
      ),
      onTap: onTap,
      trailing: PopupMenuButton<_Action>(
        tooltip: l.archiveActionsFor(game.titleIn(l)),
        onSelected: onAction,
        itemBuilder: (context) => [
          if (canAnalyse)
            PopupMenuItem(
              value: _Action.analyse,
              child: Text(l.archiveOpenAnalysis),
            ),
          PopupMenuItem(value: _Action.share, child: Text(l.archiveSharePgn)),
          PopupMenuItem(value: _Action.copy, child: Text(l.archiveCopyPgn)),
          PopupMenuItem(
            value: _Action.qr,
            child: Text(qrL10n(context).qrSendTitle),
          ),
          PopupMenuItem(value: _Action.delete, child: Text(l.archiveDelete)),
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
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.archiveImportPgn),
      content: TextField(
        key: const Key('pgnInput'),
        controller: _text,
        minLines: 6,
        maxLines: 12,
        decoration: InputDecoration(
          hintText: l.archiveImportHint,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: l.archivePaste,
            icon: const Icon(Icons.content_paste),
            onPressed: _paste,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.archiveCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: Text(l.archiveImport),
        ),
      ],
    );
  }
}
