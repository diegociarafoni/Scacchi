import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/theme/rokko_mascot.dart';
import 'package:rokko/theme/rokko_theme.dart';

void main() {
  testWidgets('la mascotte è solo decorativa: nessun testo per i lettori', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: RokkoTheme.light(),
        home: const Scaffold(body: RokkoMascot(size: 120)),
      ),
    );
    expect(find.byType(RokkoMascot), findsOneWidget);
    expect(tester.getSize(find.byType(RokkoMascot)), const Size(120, 120));
    expect(tester.getSemantics(find.byType(RokkoMascot)).label, isEmpty);
    handle.dispose();
  });

  testWidgets('lo stato vuoto mostra la torre e il testo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RokkoTheme.light(),
        home: const Scaffold(body: EmptyState('Niente qui')),
      ),
    );
    expect(find.byType(RokkoMascot), findsOneWidget);
    expect(find.text('Niente qui'), findsOneWidget);
  });
}
