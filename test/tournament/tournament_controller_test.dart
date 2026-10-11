import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/tournament/tournament.dart';
import 'package:scacchi/tournament/tournament_controller.dart';

import 'tournament_test.dart' show bots;

void main() {
  late Directory dir;
  final recorded = <Activity>[];

  TournamentController controller() => TournamentController(
    File('${dir.path}/tornei.json'),
    recordActivity: (a) async => recorded.add(a),
    clock: () => DateTime(2026, 10, 11, 18),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tornei');
    recorded.clear();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('un torneo iniziato si ritrova alla riapertura', () async {
    final c = controller();
    await c.load();
    await c.start(
      format: TournamentFormat.roundRobin,
      size: 4,
      userName: 'Tu',
      userElo: 1000,
      bots: bots,
    );
    await c.recordUserGame(1);
    final again = controller();
    await again.load();
    expect(again.current!.toJson(), c.current!.toJson());
  });

  test('a torneo finito: trofeo nella bacheca e attività registrata', () async {
    final c = controller();
    await c.load();
    await c.start(
      format: TournamentFormat.knockout,
      size: 4,
      userName: 'Tu',
      userElo: 1000,
      bots: bots,
    );
    while (c.current?.userGame != null) {
      await c.recordUserGame(1);
    }
    expect(c.current!.finished, isTrue);
    expect(c.trophies, hasLength(1));
    final trophy = c.trophies.single;
    expect(trophy.rank, 1);
    expect(trophy.players, 4);
    expect(trophy.format, TournamentFormat.knockout);
    expect(recorded.whereType<TournamentFinished>().single.rank, 1);

    await c.dismiss();
    expect(c.current, isNull);
    final again = controller();
    await again.load();
    expect(again.trophies.single.rank, 1);
    expect(again.current, isNull);
  });

  test('abbandonare non lascia trofei né XP', () async {
    final c = controller();
    await c.load();
    await c.start(
      format: TournamentFormat.roundRobin,
      size: 6,
      userName: 'Tu',
      userElo: 1000,
      bots: bots,
    );
    await c.dismiss();
    expect(c.current, isNull);
    expect(c.trophies, isEmpty);
    expect(recorded, isEmpty);
  });
}
