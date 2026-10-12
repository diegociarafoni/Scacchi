import 'dart:io';

/// Interfacce di Wi-Fi, hotspot ed Ethernet sui sistemi più comuni.
final _localNames = RegExp(
  r'^(wlan|swlan|ap|softap|en|eth|bridge|br)\d*',
  caseSensitive: false,
);

/// Interfacce che non portano all'altro telefono: dati mobili (spesso con
/// indirizzi 10.x del gestore), VPN e tunnel.
final _remoteNames = RegExp(
  r'^(rmnet|ccmni|pdp|v4-|clat|tun|utun|ppp|ipsec|wg)',
  caseSensitive: false,
);

/// Indirizzo IPv4 privato con cui l'altro telefono raggiunge questo in rete
/// locale, preferendo Wi-Fi e hotspot; `null` se il telefono non è in una
/// rete locale. [addresses] sono coppie (nome dell'interfaccia, indirizzo).
String? pickLanAddress(Iterable<(String, InternetAddress)> addresses) {
  String? fallback;
  for (final (name, a) in addresses) {
    if (a.type != InternetAddressType.IPv4 || !_isPrivate(a)) continue;
    if (_remoteNames.hasMatch(name)) continue;
    if (_localNames.hasMatch(name)) return a.address;
    fallback ??= a.address;
  }
  return fallback;
}

bool _isPrivate(InternetAddress a) {
  final b = a.rawAddress;
  return b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168);
}

/// Indirizzo in rete locale di questo telefono.
Future<String?> localLanAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  return pickLanAddress([
    for (final i in interfaces)
      for (final a in i.addresses) (i.name, a),
  ]);
}
