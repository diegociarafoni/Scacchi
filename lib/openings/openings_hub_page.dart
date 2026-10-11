import 'package:flutter/material.dart';

import 'explorer_page.dart';

/// Punto di ingresso delle aperture.
class OpeningsHubPage extends StatelessWidget {
  const OpeningsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aperture')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text('Explorer'),
            subtitle: const Text(
              'Nomi e continuazioni di oltre 3.000 aperture',
            ),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ExplorerPage())),
          ),
        ],
      ),
    );
  }
}
