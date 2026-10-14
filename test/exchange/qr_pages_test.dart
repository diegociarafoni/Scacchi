import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/exchange/qr_code_view.dart';
import 'package:rokko/exchange/qr_receive_page.dart';
import 'package:rokko/exchange/qr_send_page.dart';
import 'package:rokko/exchange/qr_transfer.dart';
import 'package:rokko/l10n/app_localizations.dart';

const _pgn = '[White "Anna"]\n[Black "Bruno"]\n\n1. f3 e5 2. g4 Qh4# 0-1\n';

String _longText() =>
    List.generate(120, (i) => 'Mossa $i: Città ${i * 7919}').join('\n');

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// Lettore finto: espone le callback che il lettore vero chiamerebbe.
class _FakeScanner {
  ValueChanged<String>? onCode;
  ValueChanged<Object>? onError;

  Widget build(
    BuildContext context, {
    required ValueChanged<String> onCode,
    required ValueChanged<Object> onError,
  }) {
    this.onCode = onCode;
    this.onError = onError;
    return const SizedBox(key: Key('fakeScanner'), width: 200, height: 200);
  }
}

void main() {
  group('Invia', () {
    testWidgets('Cap. 7 scambio QR: una partita breve sta in un solo QR', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(QrSendPage(title: 'Anna – Bruno', frames: encodeTransfer(_pgn))),
      );
      expect(find.byType(QrCodeView), findsOneWidget);
      expect(find.textContaining('Parte'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Codice QR')), findsOneWidget);
    });

    testWidgets('Cap. 7 scambio QR: una partita lunga scorre a fotogrammi', (
      tester,
    ) async {
      final frames = encodeTransfer(_longText(), maxDataLength: 100);
      expect(frames.length, greaterThan(2));
      await tester.pumpWidget(
        _app(
          QrSendPage(
            title: 'Lunga',
            frames: frames,
            interval: const Duration(milliseconds: 500),
          ),
        ),
      );
      expect(find.text('Parte 1 di ${frames.length}'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Parte 2 di ${frames.length}'), findsOneWidget);
      for (var i = 2; i <= frames.length; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Parte 1 di ${frames.length}'), findsOneWidget);
    });

    testWidgets('Cap. 7 scambio QR: pausa e avanzamento a mano', (
      tester,
    ) async {
      final frames = encodeTransfer(_longText(), maxDataLength: 100);
      await tester.pumpWidget(
        _app(
          QrSendPage(
            title: 'Lunga',
            frames: frames,
            interval: const Duration(milliseconds: 500),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Pausa'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Parte 1 di ${frames.length}'), findsOneWidget);
      await tester.tap(find.byTooltip('Parte successiva'));
      await tester.pump();
      expect(find.text('Parte 2 di ${frames.length}'), findsOneWidget);
      await tester.tap(find.byTooltip('Parte precedente'));
      await tester.tap(find.byTooltip('Parte precedente'));
      await tester.pump();
      expect(
        find.text('Parte ${frames.length} di ${frames.length}'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Riprendi'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Parte 1 di ${frames.length}'), findsOneWidget);
    });

    testWidgets(
      'Cap. 7 scambio QR: oltre il limite di parti non mostra il QR',
      (tester) async {
        await tester.pumpWidget(
          _app(
            QrSendPage(
              title: 'Enorme',
              frames: List.filled(maxTransferFrames + 1, 'SC1/x'),
            ),
          ),
        );
        expect(find.byType(QrCodeView), findsNothing);
        expect(
          find.text('La partita è troppo grande per essere ricevuta.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Cap. 7 scambio QR: il QR resta nero su bianco anche col '
        'tema scuro', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QrSendPage(title: 'x', frames: encodeTransfer(_pgn)),
        ),
      );
      final view = tester.widget<QrCodeView>(find.byType(QrCodeView));
      expect(view.data, encodeTransfer(_pgn).single);
      final box = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(QrCodeView),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(box.color, Colors.white);
    });
  });

  group('Ricevi', () {
    Future<_FakeScanner> show(
      WidgetTester tester,
      List<String?> results,
    ) async {
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async => results.add(
                    await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => QrReceivePage(scanner: scanner.build),
                      ),
                    ),
                  ),
                  child: const Text('apri'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      return scanner;
    }

    testWidgets('Cap. 7 scambio QR: riceve in qualunque ordine e mostra le '
        'parti lette', (tester) async {
      final results = <String?>[];
      final scanner = await show(tester, results);
      final frames = encodeTransfer(_longText(), maxDataLength: 100);
      final n = frames.length;
      expect(find.byKey(const Key('fakeScanner')), findsOneWidget);

      scanner.onCode!(frames.last);
      await tester.pump();
      expect(find.text('1 di $n parti lette'), findsOneWidget);
      scanner.onCode!(frames.last);
      await tester.pump();
      expect(find.text('1 di $n parti lette'), findsOneWidget);

      for (final f in frames.reversed.skip(1)) {
        scanner.onCode!(f);
      }
      await tester.pumpAndSettle();
      expect(results, [_longText()]);
    });

    testWidgets('Cap. 7 scambio QR: un QR estraneo viene segnalato', (
      tester,
    ) async {
      final scanner = await show(tester, []);
      scanner.onCode!('https://example.com');
      await tester.pump();
      expect(find.text('Questo QR non contiene una partita.'), findsOneWidget);
    });

    testWidgets('Cap. 7 scambio QR: dati danneggiati, si ricomincia', (
      tester,
    ) async {
      final scanner = await show(tester, []);
      final frame = encodeTransfer(_pgn).single;
      final parts = frame.split('/');
      final data = parts.last;
      // Si cambia il primo carattere: l'ultimo può contenere solo bit di
      // riempimento.
      final first = data.startsWith('A') ? 'B' : 'A';
      final tampered = [
        ...parts.take(4),
        '$first${data.substring(1)}',
      ].join('/');
      scanner.onCode!(tampered);
      await tester.pump();
      expect(
        find.text('Il QR è danneggiato: ricomincia la lettura.'),
        findsOneWidget,
      );
    });

    testWidgets('Cap. 7 scambio QR: dopo un errore finale l\'avanzamento '
        'riparte da zero', (tester) async {
      final scanner = await show(tester, []);
      final frames = encodeTransfer(_longText(), maxDataLength: 100);
      for (final f in frames.skip(1)) {
        scanner.onCode!(f);
      }
      await tester.pump();
      expect(
        find.text('${frames.length - 1} di ${frames.length} parti lette'),
        findsOneWidget,
      );
      final parts = frames.first.split('/');
      final data = parts.last;
      final first = data.startsWith('A') ? 'B' : 'A';
      scanner.onCode!(
        [...parts.take(4), '$first${data.substring(1)}'].join('/'),
      );
      await tester.pump();
      expect(find.textContaining('parti lette'), findsNothing);
      expect(
        find.text('Inquadra il codice QR mostrato dall\'altro telefono.'),
        findsOneWidget,
      );
    });

    testWidgets('Cap. 7 scambio QR: fotocamera negata, spiega cosa fare', (
      tester,
    ) async {
      final scanner = await show(tester, []);
      scanner.onError!(Exception('CameraAccessDenied'));
      await tester.pump();
      expect(find.textContaining('fotocamera'), findsWidgets);
      expect(find.byKey(const Key('fakeScanner')), findsNothing);
    });

    testWidgets('Cap. 7 scambio QR: annuncia le parti al lettore di schermo', (
      tester,
    ) async {
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            final data = (message as Map)['data'];
            // Anche i tocchi passano da qui: si tengono solo gli annunci.
            if (data is Map && data['message'] is String) {
              announced.add(data['message'] as String);
            }
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final scanner = await show(tester, []);
      final frames = encodeTransfer(_longText(), maxDataLength: 100);
      scanner.onCode!(frames.first);
      await tester.pump();
      expect(announced, contains('1 di ${frames.length} parti lette'));
    });
  });
}
