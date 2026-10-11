import 'commit_message.dart';

final _feature = RegExp(
  '^(${angularTypes.join('|')})/[a-z0-9][a-z0-9._-]*'
  r'(/[a-z0-9][a-z0-9._-]*)*$',
);

// Rami creati da strumenti automatici.
const _automationPrefixes = ['dependabot/', 'release-please--', 'claude/'];

/// Errore sul nome del ramo, oppure `null` se valido.
String? validateBranchName(String name) {
  if (name == 'main' || name == 'master') {
    return 'non si lavora direttamente su $name: crea un ramo tipo/descrizione';
  }
  if (_automationPrefixes.any(name.startsWith)) return null;
  if (_feature.hasMatch(name)) return null;
  return 'il ramo "$name" non segue il formato tipo/descrizione-in-minuscolo '
      '(tipi: ${angularTypes.join(', ')})';
}

/// Rami di destinazione letti dall'input del hook pre-push di git
/// (`<ref locale> <sha locale> <ref remoto> <sha remoto>` per riga),
/// esclusi tag e cancellazioni.
List<String> pushedBranches(String prePushInput) {
  const zero = '0000000000000000000000000000000000000000';
  return [
    for (final line in prePushInput.split('\n'))
      if (line.trim().split(RegExp(r'\s+'))
          case [_, final localSha, final remoteRef, _]
          when localSha != zero && remoteRef.startsWith('refs/heads/'))
        remoteRef.substring('refs/heads/'.length),
  ];
}
