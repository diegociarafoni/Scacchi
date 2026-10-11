import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> _tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(_square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(_square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

Future<void> _dragMove(WidgetTester tester, String uci) async {
  final from = _square(tester, uci.substring(0, 2));
  final to = _square(tester, uci.substring(2, 4));
  final gesture = await tester.startGesture(from);
  await tester.pump();
  await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Impostazioni'));
  await tester.pumpAndSettle();
}

Future<void> _start(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ScacchiApp());
  await tester.pumpAndSettle();
}

const _scholarsMate = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RF-01 muove con due tocchi e con trascinamento', (tester) async {
    await _start(tester);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    await _tapMove(tester, 'e2e4');
    expect(find.text('Muove il Nero.'), findsOneWidget);
    await _dragMove(tester, 'e7e5');
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
  });

  testWidgets('RF-01 ignora una mossa illegale', (tester) async {
    await _start(tester);
    await _tapMove(tester, 'e2e5');
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('1. e5'), findsNothing);
  });

  testWidgets('RF-25 scacco matto, poi annullamento', (tester) async {
    await _start(tester);
    for (final m in _scholarsMate) {
      await _tapMove(tester, m);
    }
    expect(find.text('Scacco matto. Vince il Bianco.'), findsOneWidget);
    expect(find.text('4. Qxf7#'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('4. Qxf7#'), findsNothing);
  });

  testWidgets('RF-25 abbandono con conferma', (tester) async {
    await _start(tester);
    await _tapMove(tester, 'e2e4');
    await tester.tap(find.text('Abbandona'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abbandona'));
    await tester.pumpAndSettle();
    expect(find.text('Abbandono. Vince il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-32 patta concordata', (tester) async {
    await _start(tester);
    await _tapMove(tester, 'e2e4');
    await tester.tap(find.text('Patta'));
    await tester.pumpAndSettle();
    expect(find.text('Il Bianco accetta la patta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Accetta'));
    await tester.pumpAndSettle();
    expect(find.text('Patta concordata.'), findsOneWidget);
  });

  testWidgets('RF-06 gira la scacchiera', (tester) async {
    await _start(tester);
    Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
    expect(board().orientation.name, 'white');
    await tester.tap(find.text('Gira'));
    await tester.pumpAndSettle();
    expect(board().orientation.name, 'black');
  });

  testWidgets('RF-31 rotazione automatica a ogni turno', (tester) async {
    await _start(tester);
    Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
    await _openSettings(tester);
    await tester.tap(find.text('Ruota a ogni turno'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapMove(tester, 'e2e4');
    expect(board().orientation.name, 'black');
  });

  testWidgets('Annulla chiude il selettore di promozione', (tester) async {
    await _start(tester);
    for (final m in [
      'b2b4',
      'a7a5',
      'b4a5',
      'b7b6',
      'a5b6',
      'c7c6',
      'b6b7',
      'h7h6',
    ]) {
      await _tapMove(tester, m);
    }
    final selector = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'PromotionSelector',
    );
    await _tapMove(tester, 'b7a8');
    expect(selector, findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(selector, findsNothing);
  });

  testWidgets('RF-11 mostra i pezzi catturati e il vantaggio', (tester) async {
    await _start(tester);
    expect(find.byKey(const ValueKey('advantage-white')), findsNothing);
    for (final m in ['e2e4', 'd7d5', 'e4d5']) {
      await _tapMove(tester, m);
    }
    expect(find.byKey(const ValueKey('advantage-black')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('advantage-white'))).data,
      '+1',
    );
    expect(find.byKey(const ValueKey('captured-black-pawn-0')), findsOneWidget);
  });

  testWidgets('RP-04 impostazioni della scacchiera', (tester) async {
    await _start(tester);
    ChessboardSettings board() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).settings;
    expect(board().enableCoordinates, isTrue);
    expect(board().showValidMoves, isTrue);

    await _openSettings(tester);
    await tester.tap(find.text('Coordinate'));
    await tester.tap(find.text('Mostra le mosse legali'));
    await tester.tap(find.text('Promuovi sempre a donna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blu'));
    await tester.tap(find.text('Merida'));
    await tester.scrollUntilVisible(find.text('Nessuna'), 100);
    await tester.tap(find.text('Nessuna'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(board().enableCoordinates, isFalse);
    expect(board().showValidMoves, isFalse);
    expect(board().autoQueenPromotion, isTrue);
    expect(board().colorScheme, ChessboardColorScheme.blue);
    expect(board().pieceAssets, PieceSet.meridaAssets);
    expect(board().animationDuration, Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('showCoordinates'), isFalse);
    expect(prefs.getString('boardTheme'), 'blue');
  });

  testWidgets('RF-06 cambiare il tema non annulla il capovolgimento', (
    tester,
  ) async {
    await _start(tester);
    Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
    await _openSettings(tester);
    await tester.tap(find.text('Ruota a ogni turno'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gira'));
    await tester.pumpAndSettle();
    expect(board().orientation.name, 'black');
    await _openSettings(tester);
    await tester.tap(find.text('Blu'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(board().orientation.name, 'black');
  });

  testWidgets('RF-40 nuova partita con orologio', (tester) async {
    await _start(tester);
    expect(find.byKey(const ValueKey('clock-white')), findsNothing);
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    expect(find.text('Senza tempo'), findsOneWidget);
    await tester.tap(find.text('3+2'));
    await tester.pumpAndSettle();
    Text clock(Side side) =>
        tester.widget<Text>(find.byKey(ValueKey('clock-${side.name}')));
    expect(clock(Side.white).data, '3:00');
    expect(clock(Side.black).data, '3:00');
    expect(find.byKey(const ValueKey('clock-active')), findsNothing);

    await _tapMove(tester, 'e2e4');
    final active = find.byKey(const ValueKey('clock-active'));
    expect(
      find.descendant(
        of: active,
        matching: find.byKey(const ValueKey('clock-black')),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('clock-white')), findsNothing);
  });

  testWidgets('RF-120 una nuova partita Chess960 mescola la prima traversa', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chess960'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chess960 n. '), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });
}
