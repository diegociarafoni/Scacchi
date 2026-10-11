import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AnimationSpeed {
  none('Nessuna', Duration.zero),
  fast('Veloce', Duration(milliseconds: 120)),
  normal('Normale', Duration(milliseconds: 250)),
  slow('Lenta', Duration(milliseconds: 450));

  const AnimationSpeed(this.label, this.duration);

  final String label;
  final Duration duration;
}

/// Temi a tinta unita: le immagini delle scacchiere di chessground hanno
/// licenza AGPL. Alcuni si sbloccano con i progressi (`progress/rewards.dart`).
enum BoardTheme {
  green('Verde', scheme: ChessboardColorScheme.green),
  brown('Legno', scheme: ChessboardColorScheme.brown),
  blue('Blu', scheme: ChessboardColorScheme.blue),
  grey('Grigio', light: Color(0xffb8b8b8), dark: Color(0xff7d7d7d)),
  sand('Sabbia', light: Color(0xfff3e5c0), dark: Color(0xffc8a26b)),
  ocean('Oceano', light: Color(0xffd6ecf0), dark: Color(0xff3f7f93)),
  coral('Corallo', light: Color(0xfffbe3d6), dark: Color(0xffd9776a)),
  night('Notte', light: Color(0xff9aa5b8), dark: Color(0xff3b4459)),
  gold('Oro', light: Color(0xfffaf0c8), dark: Color(0xffc9a227));

  const BoardTheme(this.label, {this.scheme, this.light, this.dark})
    : assert(scheme != null || (light != null && dark != null));

  final String label;

  /// Schema di chessground, se il tema non è definito dai soli [light] e [dark].
  final ChessboardColorScheme? scheme;
  final Color? light;
  final Color? dark;

  static final _solid = <BoardTheme, ChessboardColorScheme>{};

  /// Sempre la stessa istanza per tema, per non ridisegnare lo sfondo.
  ChessboardColorScheme get colorScheme =>
      scheme ?? _solid.putIfAbsent(this, () => _solidScheme(light!, dark!));
}

ChessboardColorScheme _solidScheme(Color light, Color dark) {
  ChessboardBackground background({Side? coordinates}) =>
      SolidColorChessboardBackground(
        lightSquare: light,
        darkSquare: dark,
        coordinates: coordinates != null,
        orientation: coordinates ?? Side.white,
      );
  return ChessboardColorScheme(
    lightSquare: light,
    darkSquare: dark,
    background: background(),
    whiteCoordBackground: background(coordinates: Side.white),
    blackCoordBackground: background(coordinates: Side.black),
    lastMove: const HighlightDetails(solidColor: Color(0x809cc700)),
    selected: const HighlightDetails(solidColor: Color(0x6014551e)),
    validMoves: const Color(0x4014551e),
    validPremoves: const Color(0x40203085),
  );
}

/// Set di pezzi la cui licenza permette la distribuzione negli store insieme
/// a codice GPL-3.0 (vedi CREDITS.md). Esclusi i set CC BY-NC-SA.
enum PieceStyle {
  cburnett('Classico', PieceSet.cburnett, 'Colin M.L. Burnett', 'GPL-2.0+'),
  merida('Merida', PieceSet.merida, 'Armando Hernández Marroquín', 'GPL-2.0+'),
  chessnut('Chessnut', PieceSet.chessnut, 'Alexis Luengas', 'Apache-2.0'),
  fantasy('Fantasy', PieceSet.fantasy, 'Maurizio Monge', 'MIT'),
  spatial('Spatial', PieceSet.spatial, 'Maurizio Monge', 'MIT'),
  celtic('Celtic', PieceSet.celtic, 'Maurizio Monge', 'MIT'),
  shapes('Shapes', PieceSet.shapes, 'flugsio', 'CC BY-SA 4.0'),
  firi('Firi', PieceSet.firi, 'James Faure', 'CC BY 4.0'),
  mpchess('Mpchess', PieceSet.mpchess, 'Maxime Chupin', 'GPL-3.0+'),
  kiwenSuwi('Kiwen-suwi', PieceSet.kiwenSuwi, 'neverRare', 'CC BY 4.0'),
  totoy('Totoy', PieceSet.totoy, 'Kosal Sen', 'CC BY 4.0'),
  rhosgfx('RhosGFX', PieceSet.rhosgfx, 'RhosGFX', 'CC0');

  const PieceStyle(this.label, this.pieceSet, this.author, this.license);

  final String label;
  final PieceSet pieceSet;
  final String author;
  final String license;
}

class AppSettings {
  AppSettings({
    this.showLegalMoves = true,
    this.showCoordinates = true,
    this.autoQueen = false,
    this.drawShapes = true,
    this.autoFlip = false,
    this.animation = AnimationSpeed.normal,
    this.boardTheme = BoardTheme.green,
    this.pieceSet = PieceStyle.cburnett,
    this.sound = true,
    this.volume = 1.0,
    this.haptics = true,
    this.tableMode = false,
    this.confirmMove = false,
    String whiteName = '',
    String blackName = '',
  }) : whiteName = _cleanName(whiteName),
       blackName = _cleanName(blackName);

  static const maxNameLength = 24;

  static String _cleanName(String name) {
    final trimmed = name.trim();
    return trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength).trim()
        : trimmed;
  }

  final bool showLegalMoves;
  final bool showCoordinates;
  final bool autoQueen;
  final bool drawShapes;
  final bool autoFlip;
  final AnimationSpeed animation;
  final BoardTheme boardTheme;
  final PieceStyle pieceSet;
  final bool sound;
  final double volume;
  final bool haptics;
  final bool tableMode;
  final bool confirmMove;
  final String whiteName;
  final String blackName;

  /// Nome scelto per [side], `null` se non indicato.
  String? nameOf(Side side) {
    final name = side == Side.white ? whiteName : blackName;
    return name.isEmpty ? null : name;
  }

  AppSettings copyWith({
    bool? showLegalMoves,
    bool? showCoordinates,
    bool? autoQueen,
    bool? drawShapes,
    bool? autoFlip,
    AnimationSpeed? animation,
    BoardTheme? boardTheme,
    PieceStyle? pieceSet,
    bool? sound,
    double? volume,
    bool? haptics,
    bool? tableMode,
    bool? confirmMove,
    String? whiteName,
    String? blackName,
  }) => AppSettings(
    showLegalMoves: showLegalMoves ?? this.showLegalMoves,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    autoQueen: autoQueen ?? this.autoQueen,
    drawShapes: drawShapes ?? this.drawShapes,
    autoFlip: autoFlip ?? this.autoFlip,
    animation: animation ?? this.animation,
    boardTheme: boardTheme ?? this.boardTheme,
    pieceSet: pieceSet ?? this.pieceSet,
    sound: sound ?? this.sound,
    volume: volume ?? this.volume,
    haptics: haptics ?? this.haptics,
    tableMode: tableMode ?? this.tableMode,
    confirmMove: confirmMove ?? this.confirmMove,
    whiteName: whiteName ?? this.whiteName,
    blackName: blackName ?? this.blackName,
  );

  late final ChessboardSettings board = ChessboardSettings(
    colorScheme: boardTheme.colorScheme,
    pieceAssets: pieceSet.pieceSet.assets,
    enableCoordinates: showCoordinates,
    showValidMoves: showLegalMoves,
    animationDuration: animation.duration,
    autoQueenPromotion: autoQueen,
    drawShape: DrawShapeOptions(enable: drawShapes),
    pieceOrientationBehavior: tableMode
        ? PieceOrientationBehavior.opponentUpsideDown
        : PieceOrientationBehavior.facingUser,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.showLegalMoves == showLegalMoves &&
      other.showCoordinates == showCoordinates &&
      other.autoQueen == autoQueen &&
      other.drawShapes == drawShapes &&
      other.autoFlip == autoFlip &&
      other.animation == animation &&
      other.boardTheme == boardTheme &&
      other.pieceSet == pieceSet &&
      other.sound == sound &&
      other.volume == volume &&
      other.haptics == haptics &&
      other.tableMode == tableMode &&
      other.confirmMove == confirmMove &&
      other.whiteName == whiteName &&
      other.blackName == blackName;

  @override
  int get hashCode => Object.hash(
    showLegalMoves,
    showCoordinates,
    autoQueen,
    drawShapes,
    autoFlip,
    animation,
    boardTheme,
    pieceSet,
    sound,
    volume,
    haptics,
    tableMode,
    confirmMove,
    whiteName,
    blackName,
  );
}

/// Impostazioni correnti, salvate in locale a ogni modifica.
class SettingsController extends ValueNotifier<AppSettings> {
  SettingsController._(this._prefs, super.value);

  /// Impostazioni predefinite non salvate, se la memoria locale non è disponibile.
  SettingsController.defaults() : this._(null, AppSettings());

  final SharedPreferences? _prefs;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = AppSettings();
    T read<T>(String key, T fallback) {
      final v = prefs.get(key);
      return v is T ? v : fallback;
    }

    T byName<T extends Enum>(List<T> values, String key, T fallback) =>
        values.asNameMap()[read<String?>(key, null)] ?? fallback;
    return SettingsController._(
      prefs,
      AppSettings(
        showLegalMoves: read('showLegalMoves', d.showLegalMoves),
        showCoordinates: read('showCoordinates', d.showCoordinates),
        autoQueen: read('autoQueen', d.autoQueen),
        drawShapes: read('drawShapes', d.drawShapes),
        autoFlip: read('autoFlip', d.autoFlip),
        animation: byName(AnimationSpeed.values, 'animation', d.animation),
        boardTheme: byName(BoardTheme.values, 'boardTheme', d.boardTheme),
        pieceSet: byName(PieceStyle.values, 'pieceSet', d.pieceSet),
        sound: read('sound', d.sound),
        volume: read<double>('volume', d.volume).clamp(0.0, 1.0),
        haptics: read('haptics', d.haptics),
        tableMode: read('tableMode', d.tableMode),
        confirmMove: read('confirmMove', d.confirmMove),
        whiteName: read('whiteName', d.whiteName),
        blackName: read('blackName', d.blackName),
      ),
    );
  }

  /// Applica subito [settings] e salva solo i valori cambiati.
  Future<void> update(AppSettings settings) async {
    final old = value;
    value = settings;
    final prefs = _prefs;
    if (prefs == null) return;
    final writes = <Future<bool>>[
      if (old.showLegalMoves != settings.showLegalMoves)
        prefs.setBool('showLegalMoves', settings.showLegalMoves),
      if (old.showCoordinates != settings.showCoordinates)
        prefs.setBool('showCoordinates', settings.showCoordinates),
      if (old.autoQueen != settings.autoQueen)
        prefs.setBool('autoQueen', settings.autoQueen),
      if (old.drawShapes != settings.drawShapes)
        prefs.setBool('drawShapes', settings.drawShapes),
      if (old.autoFlip != settings.autoFlip)
        prefs.setBool('autoFlip', settings.autoFlip),
      if (old.animation != settings.animation)
        prefs.setString('animation', settings.animation.name),
      if (old.boardTheme != settings.boardTheme)
        prefs.setString('boardTheme', settings.boardTheme.name),
      if (old.pieceSet != settings.pieceSet)
        prefs.setString('pieceSet', settings.pieceSet.name),
      if (old.sound != settings.sound) prefs.setBool('sound', settings.sound),
      if (old.volume != settings.volume)
        prefs.setDouble('volume', settings.volume),
      if (old.haptics != settings.haptics)
        prefs.setBool('haptics', settings.haptics),
      if (old.tableMode != settings.tableMode)
        prefs.setBool('tableMode', settings.tableMode),
      if (old.confirmMove != settings.confirmMove)
        prefs.setBool('confirmMove', settings.confirmMove),
      if (old.whiteName != settings.whiteName)
        prefs.setString('whiteName', settings.whiteName),
      if (old.blackName != settings.blackName)
        prefs.setString('blackName', settings.blackName),
    ];
    try {
      await Future.wait(writes);
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'impostazioni',
          context: ErrorDescription(
            'durante il salvataggio delle impostazioni',
          ),
        ),
      );
    }
  }
}
