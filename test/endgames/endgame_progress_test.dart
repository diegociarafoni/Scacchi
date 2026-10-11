import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/endgames/drills.dart';
import 'package:scacchi/endgames/endgame_controller.dart';
import 'package:scacchi/endgames/endgame_progress.dart';
import 'package:scacchi/progress/activity.dart';

void main() {
  final first = endgameDrills.first;
  final second = endgameDrills[1];

  test('RF-86 si tengono le stelle migliori', () {
    final p = const EndgameProgress()
        .complete(first.id, 3)
        .complete(first.id, 1);
    expect(p.starsFor(first.id), 3);
  });

  test('RF-86 le posizioni fallite si ripropongono per prime', () {
    final p = const EndgameProgress().fail(second.id);
    expect(p.toRepeat, contains(second.id));
    expect(p.ordered(endgameDrills).first.id, second.id);
    final done = p.complete(second.id, 2);
    expect(done.toRepeat, isEmpty);
    expect(done.ordered(endgameDrills).first.id, first.id);
  });

  test('una posizione già riuscita non torna da ripetere', () {
    final p = const EndgameProgress().complete(first.id, 3).fail(first.id);
    expect(p.toRepeat, isEmpty);
    expect(p.starsFor(first.id), 3);
  });

  test('JSON andata e ritorno', () {
    final p = const EndgameProgress().complete(first.id, 2).fail(second.id);
    final back = EndgameProgress.fromJson(p.toJson());
    expect(back.starsFor(first.id), 2);
    expect(back.toRepeat, {second.id});
  });

  test('il controller salva e registra la prima riuscita', () async {
    final dir = Directory.systemTemp.createTempSync('finali');
    addTearDown(() => dir.deleteSync(recursive: true));
    final recorded = <Activity>[];
    final file = File('${dir.path}/endgames.json');
    final c = EndgameController(
      file,
      recordActivity: (a) async => recorded.add(a),
    );
    await c.load();
    await c.finish(first, 2, const Duration(minutes: 3));
    await c.finish(first, 3, const Duration(minutes: 3));
    await c.finish(second, 0, const Duration(minutes: 1));
    expect(recorded, hasLength(1));
    final again = EndgameController(file);
    await again.load();
    expect(again.progress.starsFor(first.id), 3);
    expect(again.progress.toRepeat, {second.id});
  });
}
