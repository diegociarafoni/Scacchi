import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/game_invite.dart';

Uint8List bytes(int n, int fill) => Uint8List.fromList(List.filled(n, fill));

GameInvite sample({String? lan}) => GameInvite(
  gameId: '0f8e2c1a-3b4d-4e5f-8a9b-1c2d3e4f5a6b',
  secret: bytes(32, 7),
  hostKey: bytes(32, 9),
  hostSide: Side.white,
  lanAddress: lan,
);

void main() {
  test('RMP-01 l\'identificativo della partita è un UUID v4 casuale', () {
    final a = newGameId();
    final b = newGameId();
    expect(
      a,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(a, isNot(b));
  });

  test('RMP-01 l\'invito va e torna dal link senza perdere nulla', () {
    final invite = sample(lan: '192.168.1.20:47100');
    final link = invite.toLink();
    expect(link, startsWith('scacchi://partita?'));
    final back = GameInvite.parse(link)!;
    expect(back.gameId, invite.gameId);
    expect(back.secret, invite.secret);
    expect(back.hostKey, invite.hostKey);
    expect(back.hostSide, Side.white);
    expect(back.lanAddress, '192.168.1.20:47100');
  });

  test('RMP-01 l\'indirizzo locale è facoltativo', () {
    final back = GameInvite.parse(sample().toLink())!;
    expect(back.lanAddress, isNull);
  });

  test('RMP-32 l\'invito a distanza va e torna dal link', () {
    final inv = GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: Uint8List(32),
      hostSide: Side.black,
      remote: true,
    );
    final back = GameInvite.parse(inv.toLink())!;
    expect(back.remote, isTrue);
    expect(back.lanAddress, isNull);
    expect(inv.toLink(), contains('r=1'));
  });

  test('RMP-32 senza il segno r l\'invito è solo in rete locale', () {
    expect(GameInvite.parse(sample().toLink())!.remote, isFalse);
    expect(sample().toLink(), isNot(contains('r=')));
  });

  test('RMP-32 un valore di r sconosciuto rende l\'invito non valido', () {
    final good = GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: Uint8List(32),
      hostSide: Side.white,
      remote: true,
    ).toLink();
    expect(GameInvite.parse(good.replaceFirst('r=1', 'r=2')), isNull);
    expect(GameInvite.parse(good.replaceFirst('r=1', 'r=')), isNull);
  });

  group('RMP-01 un invito non valido viene scartato', () {
    final good = sample().toLink();
    final cases = {
      'testo qualunque': 'ciao',
      'altro schema': good.replaceFirst('scacchi://', 'http://'),
      'link web di un sito qualunque': good.replaceFirst(
        'scacchi://partita',
        'https://esempio.it/partita',
      ),
      'versione sconosciuta': good.replaceFirst('v=1', 'v=9'),
      'UUID non valido': good.replaceFirst(sample().gameId, 'xyz'),
      'segreto corto': good.replaceFirst(RegExp('s=[^&]+'), 's=AAAA'),
      'chiave non Base64': good.replaceFirst(RegExp('k=[^&]+'), 'k=%%%'),
      'colore sconosciuto': good.replaceFirst('c=w', 'c=x'),
      'indirizzo non valido': sample(lan: 'host:99999').toLink(),
      'troppo lungo': '$good&x=${'a' * 3000}',
    };
    cases.forEach((name, text) {
      test(name, () => expect(GameInvite.parse(text), isNull));
    });
  });
}
