/// Tipi ammessi dalla convenzione Angular.
const angularTypes = {
  'build',
  'ci',
  'docs',
  'feat',
  'fix',
  'perf',
  'refactor',
  'revert',
  'style',
  'test',
};

const _maxHeaderLength = 100;

final _header = RegExp(
  r'^(?<type>[a-z]+)(?:\((?<scope>[^)]*)\))?(?<breaking>!)?: (?<subject>.*)$',
);
final _scope = RegExp(r'^[a-z0-9][a-z0-9._/-]*$');

// Messaggi generati da git o dagli strumenti di rilascio.
final _gitGenerated = RegExp(r'^(Merge |Revert ")');
final _releaseCommit = RegExp(r'^chore\(main\): release \S+$');

/// Errori del messaggio di commit secondo la convenzione Angular; vuoto se valido.
List<String> validateCommitMessage(String message) {
  final lines = message
      .split('\n')
      .where((l) => !l.startsWith('#'))
      .map((l) => l.trimRight())
      .toList();
  while (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  if (lines.isEmpty) return ['messaggio vuoto'];

  final header = lines.first;
  if (_gitGenerated.hasMatch(header) || _releaseCommit.hasMatch(header)) {
    return const [];
  }

  final errors = <String>[];
  if (header.length > _maxHeaderLength) {
    errors.add('intestazione oltre $_maxHeaderLength caratteri');
  }
  if (lines.length > 1 && lines[1].isNotEmpty) {
    errors.add('serve una riga vuota tra intestazione e corpo');
  }

  final match = _header.firstMatch(header);
  if (match == null) {
    errors.add(
      'formato atteso "tipo(ambito): descrizione", '
      'tipi: ${angularTypes.join(', ')}',
    );
    return errors;
  }
  final type = match.namedGroup('type')!;
  final scope = match.namedGroup('scope');
  final subject = match.namedGroup('subject')!;
  if (!angularTypes.contains(type)) {
    errors.add('tipo "$type" non ammesso; tipi: ${angularTypes.join(', ')}');
  }
  if (scope != null && !_scope.hasMatch(scope)) {
    errors.add('ambito "$scope" non valido: minuscole, cifre, . _ / -');
  }
  if (subject.trim().isEmpty) {
    errors.add('descrizione mancante');
  } else {
    final first = subject[0];
    if (first != first.toLowerCase()) {
      errors.add('la descrizione inizia con la minuscola');
    }
    if (subject.endsWith('.')) {
      errors.add('la descrizione non termina con il punto');
    }
  }
  return errors;
}
