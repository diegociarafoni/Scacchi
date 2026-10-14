import 'dart:io';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/home/review_invite.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localized_app.dart';

SavedGame _game(
  String id,
  int day, {
  String result = '1-0',
  String mode = SavedGame.computer,
  double? accuracy,
}) => SavedGame(
  id: id,
  createdAt: DateTime(2026, 10, day),
  updatedAt: DateTime(2026, 10, day),
  white: 'Tu',
  black: 'Bot',
  mode: mode,
  result: result,
  pgn: '1. e4 e5 *',
  playerSide: Side.white,
  accuracy: accuracy,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('U10 invito a rivedere la prima partita', () {
    late Directory dir;
    late GameArchive archive;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('invite');
      archive = GameArchive(File('${dir.path}/games.json'));
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('propone la prima partita conclusa tra quelle giocate', () async {
      await archive.save(_game('b', 5));
      await archive.save(_game('a', 3));
      expect((await reviewInviteGame(archive))?.id, 'a');
    });

    test('la prima è quella iniziata prima, anche se risalvata dopo', () async {
      await archive.save(_game('a', 3));
      await archive.save(_game('b', 5));
      await archive.save(
        _game('a', 3).copyWith(updatedAt: DateTime(2026, 10, 9)),
      );
      expect((await reviewInviteGame(archive))?.id, 'a');
    });

    test('non propone partite in corso, importate o di analisi', () async {
      await archive.save(_game('live', 1, result: '*'));
      await archive.save(_game('imp', 2, mode: SavedGame.imported));
      await archive.save(_game('ana', 3, mode: SavedGame.analysis));
      expect(await reviewInviteGame(archive), isNull);
    });

    test('non propone nulla se una partita è già stata rivista', () async {
      await archive.save(_game('a', 3));
      await archive.save(_game('b', 4, accuracy: 80));
      expect(await reviewInviteGame(archive), isNull);
    });

    test('dopo «Non ora» l\'invito non torna', () async {
      await archive.save(_game('a', 3));
      await dismissReviewInvite();
      expect(await reviewInviteGame(archive), isNull);
    });
  });

  group('U10 scheda dell\'invito', () {
    final it = lookupAppLocalizations(const Locale('it'));

    Future<void> show(WidgetTester tester, Widget card) =>
        tester.pumpWidget(localizedApp(home: Scaffold(body: card)));

    testWidgets('«Rivedi» apre la partita', (tester) async {
      SavedGame? opened;
      await show(
        tester,
        ReviewInviteCard(
          game: _game('a', 3),
          onReview: (g) => opened = g,
          onDismiss: () {},
        ),
      );
      expect(find.text(it.reviewInviteTitle), findsOneWidget);
      await tester.tap(find.text(it.reviewInviteAction));
      expect(opened?.id, 'a');
    });

    testWidgets('«Non ora» chiude l\'invito', (tester) async {
      var dismissed = false;
      await show(
        tester,
        ReviewInviteCard(
          game: _game('a', 3),
          onReview: (_) {},
          onDismiss: () => dismissed = true,
        ),
      );
      await tester.tap(find.text(it.reviewInviteDismiss));
      expect(dismissed, isTrue);
    });
  });
}
