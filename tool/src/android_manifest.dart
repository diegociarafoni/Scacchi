/// Manifest Android letto dall'output di `aapt2 dump xmltree`.
class AndroidManifest {
  AndroidManifest._(this._elements);

  /// Interpreta l'output di `aapt2 dump xmltree --file AndroidManifest.xml`.
  factory AndroidManifest.parseXmlTree(String dump) {
    final elements = <_Element>[];
    final element = RegExp(r'^(\s*)E: ([\w-]+)');
    final attribute = RegExp(
      r'^\s*A: (?:\S*:)?(\w+)(?:\(0x[0-9a-f]+\))?=(.*)$',
    );
    for (final line in dump.split('\n')) {
      final e = element.firstMatch(line);
      if (e != null) {
        elements.add(_Element(e.group(2)!, e.group(1)!.length));
        continue;
      }
      final a = attribute.firstMatch(line);
      if (a != null && elements.isNotEmpty) {
        elements.last.attributes[a.group(1)!] = _value(a.group(2)!);
      }
    }
    return AndroidManifest._(elements);
  }

  final List<_Element> _elements;

  String? get packageName => _first('manifest')?.attributes['package'];

  List<String> get permissions => [
    for (final e in _elements)
      if (e.name == 'uses-permission') e.attributes['name']!,
  ];

  bool get isDebuggable =>
      _isTrue(_first('application')?.attributes['debuggable']);

  bool get allowsBackup =>
      _first('application')?.attributes['allowBackup'] != 'false';

  /// Componenti esportati che altre app possono avviare senza permessi.
  List<String> get unprotectedExportedComponents => [
    for (final e in _elements)
      if (_components.contains(e.name) &&
          _isTrue(e.attributes['exported']) &&
          e.attributes['permission'] == null)
        e.attributes['name']!,
  ];

  static const _components = {
    'activity',
    'activity-alias',
    'service',
    'receiver',
    'provider',
  };

  _Element? _first(String name) =>
      _elements.where((e) => e.name == name).firstOrNull;

  static bool _isTrue(String? value) =>
      value == 'true' || value == '0xffffffff';

  static String _value(String raw) {
    final quoted = RegExp(r'^"([^"]*)"').firstMatch(raw);
    if (quoted != null) return quoted.group(1)!;
    final typed = RegExp(r'^\(type 0x[0-9a-f]+\)(\S+)').firstMatch(raw);
    return typed?.group(1) ?? raw.trim();
  }
}

class _Element {
  _Element(this.name, this.depth);

  final String name;
  final int depth;
  final Map<String, String> attributes = {};
}
