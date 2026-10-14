import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../share/share_temp.dart';
import '../theme/sheets.dart';
import 'backup.dart';

typedef ShareBackup = Future<void> Function(String text, String fileName);

Future<void> _shareWithSystem(
  String text,
  String fileName,
  String subject,
) async {
  // Non si elimina subito: il sistema può leggerlo dopo il ritorno di
  // `share()`; lo ripulisce `clearShareTemp` alla prossima esportazione o
  // all'avvio.
  final file = await newShareTempFile(fileName);
  await file.writeAsString(text, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], subject: subject),
  );
}

/// Esporta e ripristina tutti i dati locali in un unico file (RF-103).
class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
    this.directory = getApplicationSupportDirectory,
    required this.preferences,
    this.share,
  });

  final Future<Directory> Function() directory;
  final Map<String, Object> Function() preferences;

  /// Senza, il file passa alla condivisione di sistema.
  final ShareBackup? share;

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
  String Function(AppLocalizations l10n)? _message;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final share =
        widget.share ??
        (text, fileName) =>
            _shareWithSystem(text, fileName, l10n.backupShareSubject);
    try {
      final backup = await Backup.collect(
        await widget.directory(),
        widget.preferences(),
      );
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      await share(backup.encode(), 'rokko-backup-$stamp.json');
      _say((l) => l.backupExported);
    } on Object catch (e) {
      _say((l) => l.backupExportFailed('$e'));
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
      _say((l) => l.backupRestoreStaged);
    } on BackupException catch (e) {
      _say((l) => _problem(l, e));
    } on Object catch (e) {
      _say((l) => l.backupRestoreFailed('$e'));
    }
  }

  static String _problem(AppLocalizations l, BackupException e) {
    final detail = e.detail ?? '';
    return switch (e.problem) {
      BackupProblem.notApp => l.backupErrorNotApp,
      BackupProblem.newerVersion => l.backupErrorNewerVersion,
      BackupProblem.unexpectedFile => l.backupErrorUnexpectedFile(detail),
      BackupProblem.invalidFile => l.backupErrorInvalidFile(detail),
      BackupProblem.invalidPreference => l.backupErrorInvalidPreference(detail),
      BackupProblem.unreadable => l.backupErrorUnreadable,
    };
  }

  void _say(String Function(AppLocalizations l10n) message) {
    if (mounted) setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = _message;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: context.withSystemBottom(const EdgeInsets.all(16)),
        children: [
          Text(l10n.backupIntro),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.ios_share),
            label: Text(l10n.backupShare),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restore,
            icon: const Icon(Icons.restore),
            label: Text(l10n.backupRestoreFromText),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message(l10n), key: const Key('backup-message')),
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.backupRestoreDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.backupRestoreDialogBody),
          TextField(controller: _controller, maxLines: 4),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backupCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.backupRestore),
        ),
      ],
    );
  }
}
