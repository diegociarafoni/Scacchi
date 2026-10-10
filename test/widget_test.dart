import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/main.dart';

void main() {
  testWidgets('avvia una nuova partita con il Bianco al tratto', (
    tester,
  ) async {
    await tester.pumpWidget(const ScacchiApp());
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('Nuova'), findsOneWidget);
  });
}
