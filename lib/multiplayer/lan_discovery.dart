import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Tipo del servizio mDNS con cui l'ospite si annuncia in rete locale.
const lanServiceType = '_rokko-chess._tcp';

/// Nome del servizio di una partita: un'impronta dell'id, così chi è sulla
/// stessa rete non legge l'id e solo chi ha l'invito riconosce la partita.
String lanServiceName(String gameId) =>
    sha256.convert(gameId.codeUnits).toString().substring(0, 16);

/// Annuncio e ricerca dell'ospite in rete locale (mDNS), per ritrovarlo
/// quando il suo indirizzo cambia dopo l'invito.
abstract interface class LanDiscovery {
  /// Annuncia la partita [name] sulla [port]; restituisce come smettere.
  Future<void Function()> advertise(String name, int port);

  /// Cerca l'annuncio [name]; `null` se nessuno risponde entro [timeout].
  Future<(String, int)?> find(String name, {Duration? timeout});
}

/// mDNS vero, con Bonjour su iOS e NSD su Android.
class BonsoirLanDiscovery implements LanDiscovery {
  const BonsoirLanDiscovery();

  @override
  Future<void Function()> advertise(String name, int port) async {
    final broadcast = BonsoirBroadcast(
      service: BonsoirService(name: name, type: lanServiceType, port: port),
    );
    await broadcast.ready;
    await broadcast.start();
    return () => unawaited(broadcast.stop());
  }

  @override
  Future<(String, int)?> find(
    String name, {
    Duration? timeout = const Duration(seconds: 5),
  }) async {
    final discovery = BonsoirDiscovery(type: lanServiceType);
    await discovery.ready;
    final found = Completer<(String, int)?>();
    final sub = discovery.eventStream?.listen((event) {
      final service = event.service;
      if (event.type != BonsoirDiscoveryEventType.discoveryServiceResolved ||
          service is! ResolvedBonsoirService ||
          service.name != name) {
        return;
      }
      final ip = service.ip;
      if (ip != null && !found.isCompleted) found.complete((ip, service.port));
    });
    try {
      await discovery.start();
      return await found.future.timeout(
        timeout ?? const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } finally {
      await sub?.cancel();
      try {
        await discovery.stop();
      } on Object catch (e) {
        if (kDebugMode) debugPrint('Ricerca mDNS non fermata: $e');
      }
    }
  }
}
