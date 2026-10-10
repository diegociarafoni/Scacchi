import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'game_archive.dart';
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
  });

  final GameArchive archive;

  /// Chiamata quando si tocca una partita per aprirla.
  final ValueChanged<SavedGame>? onOpen;
  final ShareText share;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  List<SavedGame>? _games;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final games = await widget.archive.list();
    if (mounted) setState(() => _games = games);
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
    final result = await widget.archive.importPgn(text);
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

  Future<void> _delete(SavedGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la partita?'),
        content: Text(_title(game)),
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
      body: games == null
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

enum _Action { share, copy, delete }

String _title(SavedGame g) => '${g.white} – ${g.black}';

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
      title: Text(_title(game)),
      subtitle: Text('${_date(game.updatedAt)} · ${game.mode} · $result'),
      onTap: onTap,
      trailing: PopupMenuButton<_Action>(
        tooltip: 'Azioni per ${_title(game)}',
        onSelected: onAction,
        itemBuilder: (context) => const [
          PopupMenuItem(value: _Action.share, child: Text('Condividi PGN')),
          PopupMenuItem(value: _Action.copy, child: Text('Copia PGN')),
          PopupMenuItem(value: _Action.delete, child: Text('Elimina')),
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
