import 'package:flutter/material.dart';

import '../engine/computer_player.dart';
import '../tablebase/tablebase_service.dart';
import 'drill.dart';
import 'drill_page.dart';
import 'drills.dart';
import 'endgame_controller.dart';

/// Elenco delle posizioni dell'allenatore dei finali (RF-86): prima quelle
/// da ripetere, poi le altre con le stelle migliori.
class EndgamesPage extends StatelessWidget {
  const EndgamesPage({
    super.key,
    required this.controller,
    required this.createComputer,
    this.simple = false,
    this.tablebase,
  });

  final EndgameController controller;
  final ComputerPlayer Function() createComputer;
  final bool simple;

  /// Finali perfetti (RF-97) per la mossa perfetta nelle posizioni coperte.
  final TablebaseService? tablebase;

  static String _goal(EndgameDrill drill) => switch (drill.goal) {
    DrillGoal.mate => 'Dai scacco matto',
    DrillGoal.promote => 'Promuovi il pedone',
    DrillGoal.hold =>
      drill.fen.split(' ')[1] == 'b'
          ? 'Resisti con il Nero'
          : 'Resisti con il Bianco',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finali')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final progress = controller.progress;
          return ListView(
            children: [
              for (final drill in progress.ordered(endgameDrills))
                ListTile(
                  title: Text(drill.title),
                  subtitle: Text(
                    progress.toRepeat.contains(drill.id)
                        ? 'Da ripetere'
                        : _goal(drill),
                  ),
                  trailing: Text(
                    '${'★' * progress.starsFor(drill.id)}'
                    '${'☆' * (3 - progress.starsFor(drill.id))}',
                    semanticsLabel:
                        '${progress.starsFor(drill.id)} stelle su 3',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DrillPage(
                        drill: drill,
                        controller: controller,
                        createComputer: createComputer,
                        simple: simple,
                        tablebase: tablebase,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
