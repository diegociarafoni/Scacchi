import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/multiplayer/remote_turn_check.dart';
import 'package:scacchi/multiplayer/remote_watch.dart';
import 'package:scacchi/multiplayer/remote_watch_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'RMP-41 il registro degli avvisi ricorda l\'ultima mossa per partita',
    () async {
      SharedPreferences.setMockInitialValues({});
      final log = PrefsNotifiedLog();
      expect(await log.read('a'), 0);
      await log.write('a', 7);
      await log.write('b', 2);
      expect(await log.read('a'), 7);
      expect(await log.read('b'), 2);
    },
  );

  test('RMP-41 senza il lavoro in background il gioco non si ferma', () async {
    // Nei test non c'è WorkManager: l'errore del canale non deve uscire.
    await const BackgroundRemoteWatch().enable();
    await const BackgroundRemoteWatch().disable();
  });

  group('RMP-40 testo dell\'avviso', () {
    test('con la mossa dell\'amico, in italiano e in inglese', () {
      const turn = RemoteTurn(moves: 3, san: 'Nf3', over: false);
      expect(
        turnNotificationText(turn, lookupAppLocalizations(const Locale('it'))),
        ('Tocca a te', 'Il tuo amico ha giocato Nf3.'),
      );
      expect(
        turnNotificationText(turn, lookupAppLocalizations(const Locale('en'))),
        ('Your turn', 'Your friend played Nf3.'),
      );
    });

    test('se la mossa chiude la partita lo dice', () {
      const turn = RemoteTurn(moves: 7, san: 'Qxf7#', over: true);
      expect(
        turnNotificationText(
          turn,
          lookupAppLocalizations(const Locale('it')),
        ).$2,
        'La partita con il tuo amico è finita.',
      );
    });
  });
}
