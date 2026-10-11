import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/game_message.dart';
import 'package:scacchi/multiplayer/game_sync.dart';

final hostKey = Uint8List.fromList(List.filled(32, 1));
final guestKey = Uint8List.fromList(List.filled(32, 2));
final strangerKey = Uint8List.fromList(List.filled(32, 3));

GameSync host() => GameSync(mySide: Side.white, myKey: hostKey);
GameSync guest() =>
    GameSync(mySide: Side.black, myKey: guestKey, peerKey: hostKey);

/// Fa giocare [uci] a [from] e consegna la mossa a [to].
SyncResult relay(GameSync from, GameSync to, String uci) =>
    to.receive(from.playLocal(uci), from.myKey);

void main() {
  test(
    'RMP-03 l\'ospite fissa la chiave dell\'avversario al primo ingresso',
    () {
      final h = host();
      expect(h.peerKey, isNull);
      expect(h.receive(const JoinMessage(), guestKey), isA<PeerJoined>());
      expect(h.peerKey, guestKey);
      expect(h.receive(const JoinMessage(), strangerKey), isA<Rejected>());
      expect(h.receive(const JoinMessage(), guestKey), isA<Duplicate>());
    },
  );

  test('RMP-02 le mosse si alternano e restano identiche sui due telefoni', () {
    final h = host()..receive(const JoinMessage(), guestKey);
    final g = guest();
    expect(relay(h, g, 'e2e4'), isA<MoveAccepted>());
    expect(relay(g, h, 'e7e5'), isA<MoveAccepted>());
    expect(relay(h, g, 'g1f3'), isA<MoveAccepted>());
    expect(h.moves, ['e2e4', 'e7e5', 'g1f3']);
    expect(g.moves, h.moves);
    expect(g.position.fen, h.position.fen);
    expect(g.turn, Side.black);
  });

  test('RMP-02 non si muove fuori turno né con mosse illegali', () {
    final h = host()..receive(const JoinMessage(), guestKey);
    final g = guest();
    expect(() => g.playLocal('e7e5'), throwsStateError);
    expect(() => h.playLocal('e2e5'), throwsArgumentError);
    expect(() => h.playLocal('zz'), throwsArgumentError);
  });

  test('RMP-02 una mossa ricevuta due volte viene ignorata', () {
    final h = host()..receive(const JoinMessage(), guestKey);
    final g = guest();
    final m = h.playLocal('e2e4');
    expect(g.receive(m, hostKey), isA<MoveAccepted>());
    expect(g.receive(m, hostKey), isA<Duplicate>());
    expect(g.moves, ['e2e4']);
  });

  test('RMP-06 chi ha perso mosse le chiede e si rimette in pari', () {
    final h = host()..receive(const JoinMessage(), guestKey);
    final g = guest();
    relay(h, g, 'e2e4');
    relay(g, h, 'e7e5');
    final third = h.playLocal('g1f3');
    // Telefono dell'ospite ripristinato da un backup vecchio.
    final restored = guest();
    final result = restored.receive(third, hostKey);
    expect(result, isA<Gap>().having((r) => r.fromSeq, 'fromSeq', 1));
    for (final m in h.movesFrom(1)) {
      restored.receive(m, hostKey);
    }
    expect(restored.moves, ['e2e4', 'e7e5', 'g1f3']);
    // Finito il recupero l'avversario non può più muovere al suo posto.
    final forged = MoveMessage(
      seq: 4,
      uci: 'b8c6',
      positionHash: positionHash(restored.position.play(Move.parse('b8c6')!)),
    );
    expect(restored.receive(forged, hostKey), isA<Rejected>());
  });

  test('RMP-06 la partita riprende dalle mosse salvate', () {
    final g = GameSync(
      mySide: Side.black,
      myKey: guestKey,
      peerKey: hostKey,
      moves: const ['e2e4', 'e7e5'],
    );
    expect(g.moves.length, 2);
    expect(g.turn, Side.white);
    expect(
      () =>
          GameSync(mySide: Side.black, myKey: guestKey, moves: const ['e2e5']),
      throwsArgumentError,
    );
  });

  group('RMP-02 RMP-03 mosse non valide vengono rifiutate', () {
    late GameSync h;
    late GameSync g;
    setUp(() {
      h = host()..receive(const JoinMessage(), guestKey);
      g = guest();
    });

    test('da un estraneo', () {
      expect(g.receive(h.playLocal('e2e4'), strangerKey), isA<Rejected>());
      expect(g.moves, isEmpty);
    });

    test('prima che l\'avversario sia entrato', () {
      final lonely = host();
      const m = MoveMessage(seq: 1, uci: 'e7e5', positionHash: '00');
      expect(lonely.receive(m, guestKey), isA<Rejected>());
    });

    test('con il colore sbagliato', () {
      final m = h.playLocal('e2e4');
      // L'ospite si rimanda la propria mossa come se fosse dell'avversario.
      expect(h.receive(m, guestKey), isA<Rejected>());
    });

    test('illegale', () {
      final m = MoveMessage(
        seq: 1,
        uci: 'e2e5',
        positionHash: h.playLocal('e2e4').positionHash,
      );
      expect(g.receive(m, hostKey), isA<Rejected>());
    });

    test('con la posizione che non corrisponde', () {
      final m = h.playLocal('e2e4');
      final bad = MoveMessage(seq: m.seq, uci: m.uci, positionHash: 'beef');
      expect(g.receive(bad, hostKey), isA<Rejected>());
      expect(g.moves, isEmpty);
    });

    test('in contrasto con una mossa già ricevuta', () {
      g.receive(h.playLocal('e2e4'), hostKey);
      final other = GameSync(mySide: Side.white, myKey: hostKey)
        ..receive(const JoinMessage(), guestKey);
      final conflicting = other.playLocal('d2d4');
      expect(g.receive(conflicting, hostKey), isA<Rejected>());
      expect(g.moves, ['e2e4']);
    });
  });

  test('RMP-02 a partita finita non si muove più', () {
    final h = host()..receive(const JoinMessage(), guestKey);
    final g = guest();
    relay(h, g, 'f2f3');
    relay(g, h, 'e7e5');
    relay(h, g, 'g2g4');
    relay(g, h, 'd8h4');
    expect(h.position.isCheckmate, isTrue);
    expect(h.isGameOver, isTrue);
    expect(() => h.playLocal('a2a3'), throwsStateError);
  });

  test('RMP-02 l\'impronta della posizione è stabile e breve', () {
    final a = positionHash(Chess.initial);
    expect(a, positionHash(Chess.initial));
    expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    final after = Chess.initial.play(Move.parse('e2e4')!);
    expect(positionHash(after), isNot(a));
  });
}
