import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ble_link.dart';
import 'game_invite.dart';
import 'nostr_transport.dart';
import 'transport.dart';

/// Crea un canale in più per la partita [invite] (Bluetooth LE, relay…), o
/// `null` se non è disponibile su questo telefono. Può fallire: la partita
/// continua sugli altri canali.
typedef ChannelFactory = Future<MessageTransport?> Function(
  GameInvite invite, {
  required bool isHost,
});

/// Canali oltre al Wi-Fi locale: una riga per canale, aggiunta dal suo autore.
/// Il controller li apre a ogni partita (nuova, unita o ripresa) e li aggiunge
/// al `MultiTransport` appena sono pronti; si chiudono con la partita.
final List<ChannelFactory> extraChannelFactories = [
  openBleChannel,
  openNostrChannel,
];

/// Apre i canali di [factories] e li aggiunge a [transport] appena pronti.
void addExtraChannels(
  MultiTransport transport,
  GameInvite invite, {
  required bool isHost,
  Iterable<ChannelFactory>? factories,
}) {
  for (final open in factories ?? extraChannelFactories) {
    unawaited(
      open(invite, isHost: isHost)
          .then((channel) {
            if (channel != null) transport.add(channel);
          })
          .catchError((Object e) {
            if (kDebugMode) debugPrint('Canale non disponibile: $e'); // l10n-ok
          }),
    );
  }
}
