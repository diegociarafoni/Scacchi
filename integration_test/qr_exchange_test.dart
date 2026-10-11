import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/exchange/qr_code_view.dart';
import 'package:scacchi/exchange/qr_send_page.dart';
import 'package:scacchi/exchange/qr_transfer.dart';
import 'package:scacchi/l10n/app_localizations.dart';
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

/// Legge con zxing-cpp, lo stesso decodificatore del telefono, il QR
/// disegnato sullo schermo.
Future<String?> _scanShownQr(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find
        .descendant(
          of: find.byType(QrCodeView),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final rgba = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData();
    return (data!.buffer.asUint8List(), image.width, image.height);
  });
  final (bytes, width, height) = rgba!;
  final code = zx.readBarcode(
    bytes,
    DecodeParams(
      imageFormat: ImageFormat.rgba,
      format: Format.qrCode,
      width: width,
      height: height,
    ),
  );
  return code.isValid ? code.text : null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cap. 7 scambio QR: il QR della partita in corso si legge e '
      'senza fotocamera si spiega cosa fare', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    for (final uci in ['e2e4', 'e7e5', 'g1f3']) {
      await _tapMove(tester, uci);
    }
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passa con QR'));
    await tester.pumpAndSettle();

    final frame = await _scanShownQr(tester);
    final event = TransferAssembler().add(frame!);
    expect((event as TransferComplete).text, contains('1. e4 e5 2. Nf3 *'));

    final context = tester.element(find.byType(QrSendPage));
    await tester.tap(
      find.byTooltip(MaterialLocalizations.of(context).backButtonTooltip),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ricevi con QR'));
    // Il desktop non ha fotocamera: il lettore deve fallire con garbo.
    for (var i = 0; i < 20 && find.text('Riprova').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(find.textContaining('fotocamera'), findsWidgets);
  });

  testWidgets('Cap. 7 scambio QR: ogni fotogramma di una partita lunga si '
      'legge con la densità reale', (tester) async {
    final text = List.generate(
      300,
      (i) => '${i + 1}. Cf3 Cf6 2. Cg1 Cg8 {Città $i}',
    ).join(' ');
    final frames = encodeTransfer(text);
    expect(frames.length, greaterThan(1));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QrSendPage(
          title: 'Lunga',
          frames: frames,
          interval: const Duration(hours: 1),
        ),
      ),
    );
    final assembler = TransferAssembler();
    TransferEvent? last;
    for (var i = 0; i < frames.length; i++) {
      await tester.pump();
      last = assembler.add((await _scanShownQr(tester))!);
      await tester.tap(find.byTooltip('Parte successiva'));
    }
    expect((last! as TransferComplete).text, text);
  });
}
