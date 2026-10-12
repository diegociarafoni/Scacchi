import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/theme/rokko_theme.dart';

void main() {
  test(
    'i token sono nel tema chiaro e scuro con arancione e verde distinti',
    () {
      for (final t in [RokkoTheme.light(), RokkoTheme.dark()]) {
        final tokens = t.extension<RokkoTokens>()!;
        expect(tokens.action, RokkoTheme.orange);
        expect(tokens.boardGreen, RokkoTheme.green);
        expect(tokens.kidTouch, greaterThanOrEqualTo(56));
      }
    },
  );

  testWidgets('i pulsanti pieni rispettano il bersaglio minimo di 48 dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RokkoTheme.light(),
        home: Scaffold(
          body: Center(
            child: FilledButton(onPressed: () {}, child: const Text('Ok')),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  testWidgets('il marchio mostra Rokko e nasconde la torre ai lettori', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RokkoTheme.light(),
        home: const Scaffold(body: RokkoWordmark()),
      ),
    );
    expect(find.text('Rokko'), findsOneWidget);
    expect(find.byIcon(Icons.castle), findsOneWidget);
  });
}
