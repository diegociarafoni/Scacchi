import 'package:chessground/chessground.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('licenze dei set di pezzi', () {
    // Licenze che permettono la distribuzione commerciale insieme a codice GPL-3.0.
    const permitted = {
      'GPL-2.0+',
      'GPL-3.0+',
      'Apache-2.0',
      'MIT',
      'CC BY 4.0',
      'CC BY-SA 4.0',
      'CC0',
      'OFL-1.1',
    };

    test('ogni set ha autore e licenza compatibile', () {
      for (final p in PieceStyle.values) {
        expect(p.author, isNotEmpty, reason: p.name);
        expect(permitted, contains(p.license), reason: p.name);
      }
    });

    test('nessun set con licenza non commerciale', () {
      final names = PieceStyle.values.map((p) => p.pieceSet).nonNulls.toSet();
      expect(
        names.intersection({
          PieceSet.california,
          PieceSet.cardinal,
          PieceSet.maestro,
        }),
        isEmpty,
      );
    });
  });

  test('un set non più disponibile torna a quello predefinito', () async {
    SharedPreferences.setMockInitialValues({
      'pieceSet': 'california',
      'boardTheme': 'grey',
    });
    final c = await SettingsController.load();
    expect(c.value.pieceSet, PieceStyle.cburnett);
    expect(c.value.boardTheme, BoardTheme.grey);
  });
}
