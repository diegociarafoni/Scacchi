import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show PieceKind, Side;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'board_marks.dart';
import 'color_blind.dart';
import 'notation.dart';

enum AnimationSpeed {
  none('Nessuna', Duration.zero),
  fast('Veloce', Duration(milliseconds: 120)),
  normal('Normale', Duration(milliseconds: 250)),
  slow('Lenta', Duration(milliseconds: 450));

  const AnimationSpeed(this.label, this.duration);

  final String label;
  final Duration duration;
}

/// Temi della scacchiera. Le immagini di chessground hanno licenza AGPL, quindi
/// i temi con texture usano solo le nostre in `assets/boards/`, generate da
/// `tool/board_art/`. Alcuni si sbloccano con i progressi
/// (`progress/rewards.dart`).
enum BoardTheme {
  green('Verde', scheme: ChessboardColorScheme.green),
  brown('Legno', scheme: ChessboardColorScheme.brown),
  blue('Blu', scheme: ChessboardColorScheme.blue),
  grey('Grigio', light: Color(0xffb8b8b8), dark: Color(0xff7d7d7d)),
  sand('Sabbia', light: Color(0xfff3e5c0), dark: Color(0xffc8a26b)),
  ocean('Oceano', light: Color(0xffd6ecf0), dark: Color(0xff3f7f93)),
  coral('Corallo', light: Color(0xfffbe3d6), dark: Color(0xffd9776a)),
  night('Notte', light: Color(0xff9aa5b8), dark: Color(0xff3b4459), dim: true),
  gold('Oro', light: Color(0xfffaf0c8), dark: Color(0xffc9a227)),
  arancia(
    'Arancia',
    light: Color(0xfffcebd5),
    dark: Color(0xffee9b55),
    textured: true,
  ),
  crepuscolo(
    'Crepuscolo',
    light: Color(0xffd5c7e3),
    dark: Color(0xff6e5b8f),
    textured: true,
    dim: true,
  ),
  pergamena(
    'Pergamena',
    light: Color(0xfff1e2bc),
    dark: Color(0xffb48a55),
    textured: true,
  ),
  castello(
    'Castello',
    light: Color(0xffa49c90),
    dark: Color(0xff5a544d),
    textured: true,
    dim: true,
  ),
  bosco(
    'Bosco elfico',
    light: Color(0xffece6d0),
    dark: Color(0xff5e7f5a),
    textured: true,
  ),
  noce(
    'Noce',
    light: Color(0xffe6c597),
    dark: Color(0xff93603a),
    textured: true,
  ),
  spazio(
    'Spazio',
    light: Color(0xff4a4f86),
    dark: Color(0xff1d1f45),
    textured: true,
    dim: true,
  ),
  retro(
    'Retrò',
    light: Color(0xff9bbc0f),
    dark: Color(0xff306230),
    textured: true,
  ),
  giardino(
    'Giardino',
    light: Color(0xffdcebb4),
    dark: Color(0xff6e9a4c),
    textured: true,
  ),
  terracotta(
    'Terracotta',
    light: Color(0xfff3dfc6),
    dark: Color(0xffc4643c),
    textured: true,
  );

  const BoardTheme(
    this.label, {
    this.scheme,
    this.light,
    this.dark,
    this.textured = false,
    this.dim = false,
  }) : assert(scheme != null || (light != null && dark != null));

  final String label;

  /// Con texture in `assets/boards/` invece della tinta unita.
  final bool textured;

  /// Tema scuro: i pezzi neri prendono un alone chiaro per restare leggibili.
  final bool dim;

  /// Immagine della texture, `null` per i temi a tinta unita.
  AssetImage? get image =>
      textured ? AssetImage('assets/boards/$name.webp') : null;

  /// Schema di chessground, se il tema non è definito dai soli [light] e [dark].
  final ChessboardColorScheme? scheme;
  final Color? light;
  final Color? dark;

  static final _solid = <BoardTheme, ChessboardColorScheme>{};
  static final _colorBlind = <BoardTheme, ChessboardColorScheme>{};

  /// Sempre la stessa istanza per tema, per non ridisegnare lo sfondo.
  ChessboardColorScheme get colorScheme => _solid.putIfAbsent(
    this,
    () => scheme == null
        ? _customScheme(light!, dark!, image)
        : _withVisibleHighlights(scheme!),
  );

  /// Stesse case di [colorScheme], evidenziazioni senza rosso e verde.
  ChessboardColorScheme get colorBlindScheme =>
      _colorBlind.putIfAbsent(this, () => colorBlindHighlights(colorScheme));
}

/// Evidenziazioni candidate: per ogni tema vince la più discreta tra quelle
/// ben visibili, così i colori per daltonici possono ancora eguagliarla.
const _lastMoveHues = [
  Color(0x809cc700),
  Color(0x999cc700),
  Color(0x52ffffff),
  Color(0xb3ffb000),
  Color(0x99e8453c),
  Color(0xb30f6fff),
  Color(0x66ffffff),
  Color(0x80ffffff),
];
const _selectedHues = [
  Color(0x6014551e),
  Color(0x50000000),
  Color(0x66000000),
  Color(0x4dffffff),
  Color(0x80ffffff),
];

/// Punti delle mosse possibili: nero o bianco, dal più trasparente al più
/// coprente.
final _dotHues = [
  for (var step = 5; step <= 18; step++)
    for (final c in const [Color(0xff000000), Color(0xffffffff)])
      c.withValues(alpha: step * 0.05),
];

Color _visible(
  List<Color> hues,
  Color light,
  Color dark, [
  double floor = minHighlightContrast,
]) {
  double contrast(Color h) => highlightContrast(h, light, dark);
  final visible = hues.where((h) => contrast(h) >= floor).toList()
    ..sort((a, b) => contrast(a).compareTo(contrast(b)));
  return visible.isEmpty
      ? hues.reduce((a, b) => contrast(b) > contrast(a) ? b : a)
      : visible.first;
}

/// [current] se già visibile, altrimenti il candidato più discreto che lo è.
Color _keepOrVisible(
  Color current,
  List<Color> hues,
  Color light,
  Color dark, [
  double floor = minHighlightContrast,
]) => highlightContrast(current, light, dark) >= floor
    ? current
    : _visible(hues, light, dark, floor);

/// Gli schemi di chessground con ultima mossa, selezione e punti delle mosse
/// possibili alzati dove si confondono con le case.
ChessboardColorScheme _withVisibleHighlights(ChessboardColorScheme s) {
  final light = s.lightSquare;
  final dark = s.darkSquare;
  return ChessboardColorScheme(
    lightSquare: light,
    darkSquare: dark,
    background: s.background,
    whiteCoordBackground: s.whiteCoordBackground,
    blackCoordBackground: s.blackCoordBackground,
    lastMove: HighlightDetails(
      solidColor: _keepOrVisible(
        s.lastMove.solidColor!,
        _lastMoveHues,
        light,
        dark,
      ),
    ),
    selected: HighlightDetails(
      solidColor: _keepOrVisible(
        s.selected.solidColor!,
        _selectedHues,
        light,
        dark,
      ),
    ),
    validMoves: _keepOrVisible(
      s.validMoves,
      _dotHues,
      light,
      dark,
      minDotContrast,
    ),
    validPremoves: s.validPremoves,
  );
}

ChessboardColorScheme _customScheme(
  Color light,
  Color dark, [
  AssetImage? image,
]) {
  ChessboardBackground background({Side? coordinates}) => image == null
      ? SolidColorChessboardBackground(
          lightSquare: light,
          darkSquare: dark,
          coordinates: coordinates != null,
          orientation: coordinates ?? Side.white,
        )
      : ImageChessboardBackground(
          lightSquare: light,
          darkSquare: dark,
          coordinates: coordinates != null,
          orientation: coordinates ?? Side.white,
          image: image,
        );
  return ChessboardColorScheme(
    lightSquare: light,
    darkSquare: dark,
    background: background(),
    whiteCoordBackground: background(coordinates: Side.white),
    blackCoordBackground: background(coordinates: Side.black),
    // I temi a tinta unita tengono le evidenziazioni di sempre, se si vedono.
    lastMove: HighlightDetails(
      solidColor: image == null
          ? _keepOrVisible(_lastMoveHues.first, _lastMoveHues, light, dark)
          : _visible(_lastMoveHues, light, dark),
    ),
    selected: HighlightDetails(
      solidColor: image == null
          ? _keepOrVisible(_selectedHues.first, _selectedHues, light, dark)
          : _visible(_selectedHues, light, dark),
    ),
    validMoves: _visible(_dotHues, light, dark, minDotContrast),
    validPremoves: const Color(0x40203085),
  );
}

/// Set di pezzi la cui licenza permette la distribuzione negli store insieme
/// a codice GPL-3.0 (vedi CREDITS.md). Esclusi i set CC BY-NC-SA. Quelli
/// senza [pieceSet] sono in `assets/pieces/`, generati da `tool/board_art/`.
enum PieceStyle {
  cburnett('Classico', 'Colin M.L. Burnett', 'GPL-2.0+', PieceSet.cburnett),
  merida('Merida', 'Armando Hernández Marroquín', 'GPL-2.0+', PieceSet.merida),
  chessnut('Chessnut', 'Alexis Luengas', 'Apache-2.0', PieceSet.chessnut),
  fantasy('Fantasy', 'Maurizio Monge', 'MIT', PieceSet.fantasy),
  spatial('Spatial', 'Maurizio Monge', 'MIT', PieceSet.spatial),
  celtic('Celtic', 'Maurizio Monge', 'MIT', PieceSet.celtic),
  shapes('Shapes', 'flugsio', 'CC BY-SA 4.0', PieceSet.shapes),
  firi('Firi', 'James Faure', 'CC BY 4.0', PieceSet.firi),
  mpchess('Mpchess', 'Maxime Chupin', 'GPL-3.0+', PieceSet.mpchess),
  kiwenSuwi('Kiwen-suwi', 'neverRare', 'CC BY 4.0', PieceSet.kiwenSuwi),
  totoy('Totoy', 'Kosal Sen', 'CC BY 4.0', PieceSet.totoy),
  rhosgfx('RhosGFX', 'RhosGFX', 'CC0', PieceSet.rhosgfx),
  rokko('Rokko', 'Progetto Rokko', 'GPL-3.0+'),
  pixel('Pixel', 'Progetto Rokko', 'GPL-3.0+'),
  arcano('Arcano', 'Progetto Rokko', 'GPL-3.0+'),
  papercut('Papercut', 'Nikolay Anzarov', 'CC BY 4.0'),
  noto('Noto', 'Google (Noto Sans Symbols 2)', 'OFL-1.1');

  const PieceStyle(this.label, this.author, this.license, [this.pieceSet]);

  final String label;
  final String author;
  final String license;

  /// Set incluso in chessground, `null` per quelli in `assets/pieces/`.
  final PieceSet? pieceSet;

  static final _assets = <PieceStyle, PieceAssets>{};
  static final _halo = <PieceStyle, PieceAssets>{};

  PieceAssets get assets =>
      pieceSet?.assets ??
      _assets.putIfAbsent(
        this,
        () => _local('assets/pieces/$name', PieceKind.values),
      );

  /// Pezzi da usare su [theme]: sui temi scuri i neri hanno un alone chiaro.
  PieceAssets assetsOn(BoardTheme theme) => theme.dim
      ? _halo.putIfAbsent(
          this,
          () => {
            ...assets,
            ..._local(
              'assets/pieces/halo/$name',
              PieceKind.values.where((k) => k.side == Side.black),
            ),
          },
        )
      : assets;

  static PieceAssets _local(String dir, Iterable<PieceKind> kinds) => {
    for (final k in kinds)
      k: AssetImage(
        '$dir/${k.side == Side.white ? 'w' : 'b'}${k.role.letter.toUpperCase()}.webp',
      ),
  };
}

class AppSettings {
  AppSettings({
    this.showLegalMoves = true,
    this.showCoordinates = true,
    this.coordinatesOutside = false,
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
    this.colorBlind = false,
    this.explainWhy = false,
    this.zenMode = false,
    this.kidMode = false,
    this.themeMode = ThemeMode.system,
    this.notation = MoveNotation.figurine,
    String whiteName = '',
    String blackName = '',
  }) : whiteName = _cleanName(whiteName),
       blackName = _cleanName(blackName);

  static const maxNameLength = 24;

  static final _defaults = AppSettings();

  /// Impostazioni di [SettingsScope], o i valori predefiniti fuori dall'app.
  static AppSettings of(BuildContext context) =>
      SettingsScope.maybeOf(context) ?? _defaults;

  static String _cleanName(String name) {
    final trimmed = name.trim();
    return trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength).trim()
        : trimmed;
  }

  final bool showLegalMoves;
  final bool showCoordinates;

  /// Coordinate attorno alla scacchiera invece che sulle case.
  final bool coordinatesOutside;
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
  final bool colorBlind;

  /// «Spiegami perché» (RF-122): dopo ogni mossa del computer una riga su cosa
  /// minaccia o prepara.
  final bool explainWhy;

  /// Durante la partita restano scacchiera e mosse (RP-07).
  final bool zenMode;

  /// Profilo bambino (RP-06): interfaccia e testi semplici, bot amichevoli,
  /// nessuna statistica numerica.
  final bool kidMode;

  /// Aspetto dell'app: chiaro, scuro o come il sistema.
  final ThemeMode themeMode;

  /// Come si scrivono i pezzi nelle mosse.
  final MoveNotation notation;
  final String whiteName;
  final String blackName;

  /// Pezzi fuori dalla scacchiera (catturati, tavolozze): mai con l'alone.
  PieceAssets get pieceAssets => pieceSet.assets;

  /// Scacchiera senza [BoardFrame], come quella dell'editor: coordinate sulle
  /// case se attive e pezzi della tavolozza senza alone.
  ChessboardSettings get editorBoard => board.copyWith(
    enableCoordinates: showCoordinates,
    pieceAssets: pieceAssets,
  );

  /// Vero se le coordinate vanno disegnate fuori, da [BoardFrame].
  bool get outsideCoordinates => showCoordinates && coordinatesOutside;

  /// Schema verde fisso degli esercizi guidati, con le evidenziazioni per
  /// daltonici se attive.
  ChessboardColorScheme get exerciseScheme => colorBlind
      ? BoardTheme.green.colorBlindScheme
      : BoardTheme.green.colorScheme;

  /// Colori di frecce e cerchi sulla scacchiera del tema scelto.
  BoardMarks get marks => BoardMarks.of(boardTheme, colorBlind: colorBlind);

  /// Frecce e cerchi sulla scacchiera degli esercizi ([exerciseScheme]).
  BoardMarks get exerciseMarks =>
      BoardMarks.of(BoardTheme.green, colorBlind: colorBlind);

  /// Colore di indizi e frecce di suggerimento.
  Color get hintColor => marks.hint;

  /// Colore della freccia della minaccia.
  Color get threatColor => marks.threat;

  /// Colore della casa toccata negli esercizi, secondo l'esito.
  Color answerColor(bool correct) => colorBlind
      ? (correct ? okabeBlue : okabeOrange).withValues(alpha: 0.5)
      : Color(correct ? 0x8040a040 : 0x80d04040);

  /// Colore pieno della mossa sbagliata negli esercizi: rosso, arancione per
  /// daltonici. Va sempre accompagnato da icona e testo.
  Color get wrongColor => colorBlind ? okabeOrange : const Color(0xffd32f2f);

  /// Nome scelto per [side], `null` se non indicato.
  String? nameOf(Side side) {
    final name = side == Side.white ? whiteName : blackName;
    return name.isEmpty ? null : name;
  }

  AppSettings copyWith({
    bool? showLegalMoves,
    bool? showCoordinates,
    bool? coordinatesOutside,
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
    bool? colorBlind,
    bool? explainWhy,
    bool? zenMode,
    bool? kidMode,
    ThemeMode? themeMode,
    MoveNotation? notation,
    String? whiteName,
    String? blackName,
  }) => AppSettings(
    showLegalMoves: showLegalMoves ?? this.showLegalMoves,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    coordinatesOutside: coordinatesOutside ?? this.coordinatesOutside,
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
    colorBlind: colorBlind ?? this.colorBlind,
    explainWhy: explainWhy ?? this.explainWhy,
    zenMode: zenMode ?? this.zenMode,
    kidMode: kidMode ?? this.kidMode,
    themeMode: themeMode ?? this.themeMode,
    notation: notation ?? this.notation,
    whiteName: whiteName ?? this.whiteName,
    blackName: blackName ?? this.blackName,
  );

  late final ChessboardSettings board = ChessboardSettings(
    colorScheme: colorBlind
        ? boardTheme.colorBlindScheme
        : boardTheme.colorScheme,
    pieceAssets: pieceSet.assetsOn(boardTheme),
    enableCoordinates: showCoordinates && !coordinatesOutside,
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
      other.coordinatesOutside == coordinatesOutside &&
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
      other.colorBlind == colorBlind &&
      other.explainWhy == explainWhy &&
      other.zenMode == zenMode &&
      other.kidMode == kidMode &&
      other.themeMode == themeMode &&
      other.notation == notation &&
      other.whiteName == whiteName &&
      other.blackName == blackName;

  @override
  int get hashCode => Object.hashAll([
    showLegalMoves,
    showCoordinates,
    coordinatesOutside,
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
    colorBlind,
    explainWhy,
    zenMode,
    kidMode,
    themeMode,
    notation,
    whiteName,
    blackName,
  ]);
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
        coordinatesOutside: read('coordinatesOutside', d.coordinatesOutside),
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
        colorBlind: read('colorBlind', d.colorBlind),
        explainWhy: read('explainWhy', d.explainWhy),
        zenMode: read('zenMode', d.zenMode),
        kidMode: read('kidMode', d.kidMode),
        themeMode: byName(ThemeMode.values, 'themeMode', d.themeMode),
        notation: byName(MoveNotation.values, 'notation', d.notation),
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
      if (old.coordinatesOutside != settings.coordinatesOutside)
        prefs.setBool('coordinatesOutside', settings.coordinatesOutside),
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
      if (old.colorBlind != settings.colorBlind)
        prefs.setBool('colorBlind', settings.colorBlind),
      if (old.explainWhy != settings.explainWhy)
        prefs.setBool('explainWhy', settings.explainWhy),
      if (old.zenMode != settings.zenMode)
        prefs.setBool('zenMode', settings.zenMode),
      if (old.kidMode != settings.kidMode)
        prefs.setBool('kidMode', settings.kidMode),
      if (old.themeMode != settings.themeMode)
        prefs.setString('themeMode', settings.themeMode.name),
      if (old.notation != settings.notation)
        prefs.setString('notation', settings.notation.name),
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

/// Espone le impostazioni a tutte le schermate, così le scacchiere di problemi
/// e allenamento le seguono senza passare il controller a ogni pagina.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Impostazioni correnti, o null fuori dall'app (per esempio nei test).
  static AppSettings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SettingsScope>()
      ?.notifier
      ?.value;
}
