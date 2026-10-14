import 'dart:io';

import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' show Chess, Position;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/physical/photo_source.dart';
import 'package:scacchi/physical/physical_game_page.dart';

import '../game_actions.dart';
import '../localized_app.dart';
import 'board_render.dart';

void main() {
  late Directory dir;
  late GameArchive archive;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('fisica');
    archive = GameArchive(File('${dir.path}/games.json'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> open(
    WidgetTester tester, {
    PhotoSource? photos,
    bool photoMove = true,
  }) async {
    await tester.pumpWidget(
      localizedApp(
        home: PhysicalGamePage(
          archive: () async => archive,
          photos: photos ?? const CameraPhotoSource(),
          photoMove: photoMove,
        ),
      ),
    );
    await tester.tap(find.text('Senza tempo'));
    await tester.tap(find.text('Inizia la partita'));
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String move) async {
    await tester.enterText(find.byKey(const Key('physical-input')), move);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  testWidgets('le mosse scritte compaiono nel registro', (tester) async {
    await open(tester);
    await type(tester, 'e4');
    await type(tester, 'Cc6');
    expect(
      tester.widget<Text>(find.byKey(const Key('physical-moves'))).data,
      '1. e4 Nc6',
    );
  });

  testWidgets('una mossa non valida mostra un avviso e non cambia nulla', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'e5');
    expect(find.textContaining('Mossa non valida'), findsOneWidget);
    expect(find.text('Nessuna mossa'), findsOneWidget);
  });

  testWidgets('toccare un suggerimento gioca la mossa', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('physical-input')), 'Nf');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'Nf3'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('physical-moves'))).data,
      '1. Nf3',
    );
  });

  testWidgets('con l\'orologio parte quello del bianco', (tester) async {
    final fixed = DateTime(2026);
    await tester.pumpWidget(
      localizedApp(
        home: PhysicalGamePage(archive: () async => archive, now: () => fixed),
      ),
    );
    await tester.tap(find.text('3+2'));
    await tester.tap(find.text('Inizia la partita'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('physical-clock-white'))).data,
      '3:00',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a partita finita viene salvata nell\'archivio', (tester) async {
    await open(tester);
    await type(tester, 'e4');
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nero').last);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.byKey(const Key('physical-result')), findsOneWidget);
    expect(find.textContaining('salvata'), findsOneWidget);
    final games = (await tester.runAsync(archive.list))!;
    expect(games, hasLength(1));
    expect(games.single.mode, SavedGame.physical);
    expect(games.single.result, '1-0');
  });

  testWidgets(
    'ogni mossa viene salvata e dopo annulla l\'archivio si aggiorna',
    (tester) async {
      Future<List<SavedGame>> stored() async {
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        return (await tester.runAsync(archive.list))!;
      }

      await open(tester);
      await type(tester, 'e4');
      var games = await stored();
      expect(games.single.result, '*');
      await tapGameAction(tester, 'Abbandona');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nero').last);
      await tester.pump();
      expect((await stored()).single.result, '1-0');
      await tapGameAction(tester, 'Annulla');
      await tester.pump();
      games = await stored();
      expect(games.single.result, '*');
      await tapGameAction(tester, 'Annulla');
      await tester.pump();
      expect(await stored(), isEmpty);
    },
  );

  testWidgets('in inglese i testi della schermata sono tradotti', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: PhysicalGamePage(archive: () async => archive, photoMove: true),
      ),
    );
    expect(find.text('Physical board'), findsOneWidget);
    expect(find.text('Untimed'), findsOneWidget);
    await tester.tap(find.text('Untimed'));
    await tester.tap(find.text('Start the game'));
    await tester.pump();
    expect(find.text('No moves'), findsOneWidget);
    expect(find.text('Move from photo'), findsOneWidget);
    await type(tester, 'e5');
    expect(find.textContaining('Invalid move'), findsOneWidget);
    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();
    expect(find.text('Draw agreed?'), findsOneWidget);
  });

  testWidgets('in inglese anche abbandono, foto e allineamento', (
    tester,
  ) async {
    final png = (await tester.runAsync(() => toPng(render(Chess.initial))))!;
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: PhysicalGamePage(
          archive: () async => archive,
          photos: _Shots([png]),
          photoMove: true,
        ),
      ),
    );
    await tester.tap(find.text('Untimed'));
    await tester.tap(find.text('Start the game'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('physical-photo')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Align the board'), findsOneWidget);
    expect(find.text('White at the bottom'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reference photo saved'), findsOneWidget);
    expect(find.text('Realign'), findsOneWidget);
    await tester.tap(find.text('Resign'));
    await tester.pumpAndSettle();
    expect(find.text('Who resigns?'), findsOneWidget);
    await tester.tap(find.text('Black').last);
    await tester.pump();
    expect(find.textContaining('Resignation'), findsOneWidget);
    expect(find.textContaining('Resignation · 1-0'), findsOneWidget);
    expect(find.text('New game'), findsOneWidget);
  });

  testWidgets('senza il flag la mossa dalla foto non compare', (tester) async {
    await open(tester, photoMove: false);
    expect(find.byKey(const Key('physical-photo')), findsNothing);
    expect(find.text('Mossa dalla foto'), findsNothing);
  });

  group('mossa dalla foto', () {
    late List<Uint8List> shots;

    setUp(() => shots = []);

    Future<void> prepare(WidgetTester tester, List<Position> positions) async {
      final all = await tester.runAsync(
        () => Future.wait([for (final p in positions) toPng(render(p))]),
      );
      shots = all!;
    }

    Future<void> shoot(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('physical-photo')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> align(WidgetTester tester) async {
      await tester.tap(find.text('Fatto'));
      await tester.pumpAndSettle();
    }

    Position e4() => Chess.initial.play(Chess.initial.parseSan('e4')!);

    testWidgets('la prima foto allinea e diventa il riferimento', (
      tester,
    ) async {
      await prepare(tester, [Chess.initial]);
      await open(tester, photos: _Shots(shots));
      await shoot(tester);
      expect(find.text('Allinea la scacchiera'), findsOneWidget);
      await align(tester);
      expect(find.textContaining('Foto di riferimento'), findsOneWidget);
    });

    testWidgets('la foto dopo la mossa propone la mossa giusta per prima', (
      tester,
    ) async {
      await prepare(tester, [Chess.initial, e4()]);
      await open(tester, photos: _Shots(shots));
      await shoot(tester);
      await align(tester);
      await shoot(tester);
      expect(find.text('Allinea la scacchiera'), findsNothing);
      final chips = find.byKey(const Key('photo-guess'));
      expect(chips, findsWidgets);
      expect(
        find.descendant(of: chips.first, matching: find.text('e4')),
        findsOneWidget,
      );
      await tester.tap(chips.first);
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('physical-moves'))).data,
        '1. e4',
      );
      expect(chips, findsNothing);
    });

    testWidgets('dopo una mossa scritta la vecchia foto non vale più', (
      tester,
    ) async {
      await prepare(tester, [Chess.initial, e4()]);
      await open(tester, photos: _Shots(shots));
      await shoot(tester);
      await align(tester);
      await type(tester, 'e4');
      await shoot(tester);
      expect(find.byKey(const Key('photo-guess')), findsNothing);
      expect(find.textContaining('Foto di riferimento'), findsOneWidget);
    });

    testWidgets('due foto uguali non propongono nulla', (tester) async {
      await prepare(tester, [Chess.initial, Chess.initial]);
      await open(tester, photos: _Shots(shots));
      await shoot(tester);
      await align(tester);
      await shoot(tester);
      expect(find.byKey(const Key('photo-guess')), findsNothing);
      expect(find.textContaining('Nessuna mossa riconosciuta'), findsOneWidget);
    });

    testWidgets('una fotocamera che fallisce mostra un avviso', (tester) async {
      await open(tester, photos: _Broken());
      await shoot(tester);
      expect(find.textContaining('Fotocamera non disponibile'), findsOneWidget);
    });

    testWidgets('il testo sulla foto sparisce dopo la mossa', (tester) async {
      await prepare(tester, [Chess.initial, e4()]);
      await open(tester, photos: _Shots(shots));
      await shoot(tester);
      await align(tester);
      await shoot(tester);
      expect(find.textContaining('conferma quella giusta'), findsOneWidget);
      await tester.tap(find.byKey(const Key('photo-guess')).first);
      await tester.pump();
      expect(find.textContaining('conferma quella giusta'), findsNothing);
    });

    testWidgets('Riallinea chiede di nuovo gli angoli', (tester) async {
      await prepare(tester, [Chess.initial, Chess.initial]);
      await open(tester, photos: _Shots(shots));
      await shoot(tester);
      await align(tester);
      await tester.tap(find.byKey(const Key('physical-realign')));
      await tester.pump();
      expect(find.text('Allinea la scacchiera'), findsNothing);
      await shoot(tester);
      expect(find.text('Allinea la scacchiera'), findsOneWidget);
    });

    testWidgets('una foto annullata non cambia nulla', (tester) async {
      await open(tester, photos: _Shots(const []));
      await shoot(tester);
      expect(find.text('Allinea la scacchiera'), findsNothing);
      expect(find.textContaining('Foto di riferimento'), findsNothing);
    });
  });
}

class _Broken implements PhotoSource {
  @override
  Future<Uint8List?> take() async => throw StateError('nessuna fotocamera');
}

class _Shots implements PhotoSource {
  _Shots(this.queue);

  final List<Uint8List> queue;
  int _next = 0;

  @override
  Future<Uint8List?> take() async =>
      _next < queue.length ? queue[_next++] : null;
}
