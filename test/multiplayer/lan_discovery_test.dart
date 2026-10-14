import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/multiplayer/game_invite.dart';
import 'package:rokko/multiplayer/lan_discovery.dart';

void main() {
  test(
    'RMP-10 il nome del servizio è stabile e non svela l\'id della partita',
    () {
      final id = newGameId();
      expect(lanServiceName(id), lanServiceName(id));
      expect(lanServiceName(id), isNot(lanServiceName(newGameId())));
      expect(lanServiceName(id), matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(lanServiceName(id), isNot(contains(id.substring(0, 8))));
    },
  );

  test('RMP-10 della ricerca si usa solo un indirizzo IPv4', () {
    expect(lanIpv4('192.168.1.7'), '192.168.1.7');
    expect(lanIpv4('fe80::1'), isNull);
    expect(lanIpv4('non un indirizzo'), isNull);
    expect(lanIpv4(null), isNull);
  });
}
