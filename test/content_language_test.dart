import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/content.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_support.dart';

void main() {
  testWidgets('i contenuti si caricano nella lingua scelta', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'french'});
    addTearDown(useContent);
    Content.reset();
    await tester.pumpWidget(const ScacchiApp());
    await tester.runAsync(() async {
      for (var i = 0; i < 100 && Content.language != 'fr'; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();
    expect(Content.language, 'fr');
  });
}
