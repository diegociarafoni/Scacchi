import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup.dart';

typedef ShareBackup = Future<void> Function(String text, String fileName);

Future<void> _shareWithSystem(String text, String fileName) async {
  final tmp = await getTemporaryDirectory();
  final file = File('${tmp.path}/$fileName');
  await file.writeAsString(text, flush: true);
  try {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Backup di Rokko'),
    );
  } finally {
    // Copia completa dei dati: non lasciarla nella cartella temporanea.
    if (file.existsSync()) await file.delete();
  }
}

/// Esporta e ripristina tutti i dati locali in un unico file (RF-103).
class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
    this.directory = getApplicationSupportDirectory,
    required this.preferences,
    this.share = _shareWithSystem,
  });

  final Future<Directory> Function() directory;
  final Map<String, Object> Function() preferences;
  final ShareBackup share;

  /// Pagina collegata alle preferenze di sistema, già caricate.
  static Future<BackupPage> system() async {
    final prefs = await SharedPreferences.getInstance();
    return BackupPage(
      preferences: () => {for (final k in prefs.getKeys()) k: prefs.get(k)!},
    );
  }

  @override
  State<BackupPage> createState() => _BackupPageState();
}

/// Sostituisce tutte le preferenze con [preferences].
Future<void> applyPreferencesToSystem(Map<String, Object> preferences) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  for (final e in preferences.entries) {
    final v = e.value;
    switch (v) {
      case bool():
        await prefs.setBool(e.key, v);
      case int():
        await prefs.setInt(e.key, v);
      case double():
        await prefs.setDouble(e.key, v);
      case String():
        await prefs.setString(e.key, v);
      case List<String>():
        await prefs.setStringList(e.key, v);
    }
  }
}

class _BackupPageState extends State<BackupPage> {
  String? _message;

  Future<void> _export() async {
    try {
      final backup = await Backup.collect(
        await widget.directory(),
        widget.preferences(),
      );
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      await widget.share(backup.encode(), 'scacchi-backup-$stamp.json');
      _say('Backup pronto da salvare');
    } on Object catch (e) {
      _say('Backup non riuscito: $e');
    }
  }

  Future<void> _restore() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _PasteDialog(),
    );
    if (text == null) return;
    try {
      final backup = Backup.decode(text);
      await backup.stage(await widget.directory());
      _say('Backup pronto. Chiudi e riapri l\'app per ripristinare i dati.');
    } on BackupException catch (e) {
      _say(e.message);
    } on Object catch (e) {
      _say('Ripristino non riuscito: $e');
    }
  }

  void _say(String text) {
    if (mounted) setState(() => _message = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e ripristino')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Il backup contiene partite, progressi, percorso, tornei, '
            'allenamento e impostazioni. Salvalo in un posto sicuro: senza '
            'rete non esiste una copia online.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.ios_share),
            label: const Text('Condividi il backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restore,
            icon: const Icon(Icons.restore),
            label: const Text('Ripristina da testo'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, key: const Key('backup-message')),
          ],
        ],
      ),
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog();

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ripristina il backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Incolla il contenuto del file di backup. I dati attuali '
            'vengono sostituiti.',
          ),
          TextField(controller: _controller, maxLines: 4),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Ripristina'),
        ),
      ],
    );
  }
}
