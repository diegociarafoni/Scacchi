import 'dart:io';

/// Rigenera `third_party/chessground`, la copia di chessground senza le
/// immagini delle scacchiere e con i soli set di pezzi dell'app.
/// Uso (dalla radice, dopo `flutter pub get` con la versione originale nella
/// cache di pub): `dart tool/vendor_chessground.dart <cartella-di-chessground>`.
const _sets = [
  'cburnett',
  'celtic',
  'chessnut',
  'fantasy',
  'firi',
  'kiwen-suwi',
  'merida',
  'mpchess',
  'rhosgfx',
  'shapes',
  'spatial',
  'totoy',
];

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'uso: dart tool/vendor_chessground.dart <chessground-x.y.z>',
    );
    exit(2);
  }
  final src = Directory(args.single);
  final out = Directory('third_party/chessground');
  if (out.existsSync()) out.deleteSync(recursive: true);
  _copy(Directory('${src.path}/lib'), Directory('${out.path}/lib'));
  File('${src.path}/LICENSE').copySync(_make('${out.path}/LICENSE'));
  for (final s in _sets) {
    _copy(
      Directory('${src.path}/assets/piece_sets/$s'),
      Directory('${out.path}/assets/piece_sets/$s'),
    );
  }
  final pubspec = File('${src.path}/pubspec.yaml').readAsStringSync();
  var head = pubspec.substring(0, pubspec.indexOf('flutter:\n  assets:'));
  head = head.substring(0, head.indexOf('dev_dependencies:'));
  File('${out.path}/pubspec.yaml').writeAsStringSync(
    '${head.replaceFirst(RegExp(r'^repository:.*\n', multiLine: true), '')}'
    'flutter:\n  assets:\n'
    '${_sets.map((s) => '    - assets/piece_sets/$s/\n').join()}',
  );
}

String _make(String path) {
  File(path).parent.createSync(recursive: true);
  return path;
}

void _copy(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final e in from.listSync()) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is Directory) {
      _copy(e, Directory('${to.path}/$name'));
    } else if (e is File) {
      e.copySync('${to.path}/$name');
    }
  }
}
