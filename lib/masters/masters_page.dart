import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'master_game.dart';
import 'master_game_page.dart';
import 'master_games.dart';
import 'masters_controller.dart';

/// Elenco delle partite dei grandi maestri (RF-87) con le stelle migliori di
/// «Indovina la mossa» (RF-88).
class MastersPage extends StatelessWidget {
  const MastersPage({super.key, required this.controller, this.simple = false});

  final MastersController controller;
  final bool simple;

  static String _subtitle(MasterGame game) => [
    if (game.nickname != null) game.nickname!,
    '${game.event}, ${game.year}',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mastersTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final progress = controller.progress;
          return ListView(
            children: [
              for (final game in masterGames)
                ListTile(
                  title: Text('${game.white} – ${game.black}'),
                  subtitle: Text(_subtitle(game)),
                  trailing: Text(
                    '${'★' * progress.starsFor(game.id)}'
                    '${'☆' * (3 - progress.starsFor(game.id))}',
                    semanticsLabel: l10n.mastersStars(
                      progress.starsFor(game.id),
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MasterGamePage(
                        game: game,
                        controller: controller,
                        simple: simple,
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
