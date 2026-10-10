import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';

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

Future<void> _start(WidgetTester tester) async {
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
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ruota a ogni turno'));
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
}
