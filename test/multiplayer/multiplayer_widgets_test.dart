import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/multiplayer/multiplayer_widgets.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../localized_app.dart';

Widget _app(Widget child, {double scale = 1}) {
  final app = localizedApp(
    home: Scaffold(body: Center(child: child)),
  );
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Theme(data: RokkoTheme.light(), child: app),
  );
}

void main() {
  testWidgets('RMP-08 l\'indicatore dice lo stato con testo, icona e voce', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const ConnectionIndicator(
          channels: [
            ChannelLink(channel: LinkChannel.wifi, level: LinkLevel.connected),
          ],
        ),
      ),
    );
    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text('Collegato'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.bySemanticsLabel('Wi-Fi: Collegato'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('RMP-08 ogni livello ha una forma diversa, non solo un colore', (
    tester,
  ) async {
    final icons = <IconData>{};
    for (final level in LinkLevel.values) {
      await tester.pumpWidget(
        _app(
          ConnectionIndicator(
            channels: [ChannelLink(channel: LinkChannel.wifi, level: level)],
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon).first).icon!;
      icons.add(icon);
    }
    expect(icons, hasLength(LinkLevel.values.length));
  });

  testWidgets('RMP-08 un nuovo canale è una voce in più della stessa lista', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ConnectionIndicator(
          channels: [
            ChannelLink(channel: LinkChannel.wifi, level: LinkLevel.connected),
            ChannelLink(
              channel: LinkChannel.bluetooth,
              level: LinkLevel.offline,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text('Bluetooth'), findsOneWidget);
    expect(find.text('Non raggiungibile'), findsOneWidget);
  });

  testWidgets('RMP-08 testo al 130% senza overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640) * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const ConnectionIndicator(
          channels: [
            ChannelLink(channel: LinkChannel.wifi, level: LinkLevel.connecting),
          ],
        ),
        scale: 1.3,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RMP-08 il QR sta in una cornice chiara con la didascalia', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Theme(
        data: RokkoTheme.dark(),
        child: localizedApp(
          home: const Scaffold(body: InviteCard(data: 'scacchi://invito')),
        ),
      ),
    );
    expect(find.text('Mostra questo codice al tuo amico'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Codice QR dell.invito alla partita')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
