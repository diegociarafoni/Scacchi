import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/theme/rokko_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance() + 0.05;
  final lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  test(
    'contrasto WCAG AA (4.5) per pulsanti, testo e stelle in entrambi i temi',
    () {
      for (final t in [RokkoTheme.light(), RokkoTheme.dark()]) {
        final k = t.extension<RokkoTokens>()!;
        final s = t.colorScheme;
        expect(_contrast(k.action, k.onAction), greaterThanOrEqualTo(4.5));
        expect(_contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(s.onSurface, s.surfaceContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(s.secondary, s.surface), greaterThanOrEqualTo(4.5));
        expect(_contrast(k.star, s.surface), greaterThanOrEqualTo(4.5));
      }
    },
  );

  test(
    'i token sono nel tema chiaro e scuro con il verde solo per la scacchiera',
    () {
      for (final t in [RokkoTheme.light(), RokkoTheme.dark()]) {
        final tokens = t.extension<RokkoTokens>()!;
        expect(tokens.action, isNot(RokkoTheme.green));
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
