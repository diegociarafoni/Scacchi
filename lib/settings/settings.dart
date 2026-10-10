import 'package:chessground/chessground.dart';
import 'package:flutter/foundation.dart';
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

enum BoardTheme {
  green('Verde', ChessboardColorScheme.green),
  brown('Legno', ChessboardColorScheme.brown),
  blue('Blu', ChessboardColorScheme.blue),
  grey('Grigio', ChessboardColorScheme.grey);

  const BoardTheme(this.label, this.colorScheme);

  final String label;
  final ChessboardColorScheme colorScheme;
}

/// Set di pezzi con licenza compatibile con la GPL (vedi CREDITS.md).
enum PieceStyle {
  cburnett('Classico', PieceSet.cburnett),
  merida('Merida', PieceSet.merida),
  california('California', PieceSet.california),
  cardinal('Cardinal', PieceSet.cardinal),
  maestro('Maestro', PieceSet.maestro);

  const PieceStyle(this.label, this.pieceSet);

  final String label;
  final PieceSet pieceSet;
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
  });

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
      other.confirmMove == confirmMove;

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
