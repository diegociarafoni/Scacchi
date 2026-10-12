import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';

import '../game/sounds.dart';
import '../l10n/app_localizations.dart';
import '../progress/progress_controller.dart';
import '../progress/rewards.dart';
import '../settings/board_preview.dart';
import '../settings/settings.dart';
import '../settings/settings_labels.dart';
import '../theme/rokko_theme.dart';
import 'backdrop_photo.dart';
import 'style_gallery.dart';

/// Sceglie una foto e restituisce il percorso salvato, null se si annulla.
typedef BackdropPhotoPicker = Future<String?> Function();

/// Fa sentire [sound] del set indicato.
typedef SoundPreview = Future<void> Function(GameSound sound, SoundSet set);

/// Stile: in alto l'anteprima della scacchiera dal vivo, sotto le schede
/// Scacchiera, Pezzi, Sfondo e Suoni. Ogni scelta si applica subito, a
/// partita, esercizi e anteprima.
class StylePage extends StatefulWidget {
  const StylePage({
    super.key,
    required this.controller,
    this.progress,
    this.pickPhoto = pickBackdropPhoto,
    this.preview,
  });

  final SettingsController controller;

  /// Progressi che sbloccano temi e pezzi; senza, tutto è disponibile.
  final ProgressController? progress;
  final BackdropPhotoPicker pickPhoto;

  /// Riproduce il campione di un set di suoni; di norma usa i suoni dell'app.
  final SoundPreview? preview;

  @override
  State<StylePage> createState() => _StylePageState();
}

class _StylePageState extends State<StylePage> {
  final SoundPlayer _player = SoundPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _set(AppSettings Function(AppSettings) change) =>
      widget.controller.update(change(widget.controller.value));

  Future<void> _preview(GameSound sound, SoundSet set) async {
    final custom = widget.preview;
    if (custom != null) return custom(sound, set);
    final s = widget.controller.value;
    await _player.play(
      sound,
      enabled: s.sound,
      volume: s.volume,
      haptics: false,
      set: set,
    );
  }

  Future<void> _choosePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final String? path;
    try {
      path = await widget.pickPhoto();
    } on Object {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.styleBackdropPhotoError)),
      );
      return;
    }
    if (path == null) return;
    await widget.controller.update(
      widget.controller.value.copyWith(
        backdrop: BoardBackdrop.photo,
        backdropPhoto: path,
      ),
    );
    unawaited(pruneBackdropPhotos(path));
  }

  Future<void> _chooseSounds(SoundSet set) async {
    _set((c) => c.copyWith(soundSet: set));
    await _preview(GameSound.move, set);
    if (!mounted) return;
    await _preview(GameSound.capture, set);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = widget.progress;
    final media = MediaQuery.of(context);
    final scrolling = media.textScaler.scale(14) > 14 * 1.15;
    return MediaQuery(
      // Il testo ingrandito non deve spingere l'anteprima fuori schermo.
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.3),
      ),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.styleTitle)),
          body: ListenableBuilder(
            listenable: Listenable.merge([widget.controller, p]),
            builder: (context, _) {
              final s = widget.controller.value;
              Requirement? locked(Enum item) =>
                  p == null || isUnlocked(item, p.state, p.settings)
                  ? null
                  : requirementOf(item);
              final tabs = Column(
                children: [
                  TabBar(
                    // Quattro schede stanno in fila; con il testo ingrandito
                    // si scorrono invece di perdere i nomi.
                    isScrollable: scrolling,
                    tabAlignment: scrolling ? TabAlignment.center : null,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    tabs: [
                      Tab(text: l10n.styleTabBoard),
                      Tab(text: l10n.styleTabPieces),
                      Tab(text: l10n.styleTabBackdrop),
                      Tab(text: l10n.styleTabSounds),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _boardTab(l10n, s, locked),
                        _piecesTab(l10n, s, locked),
                        _backdropTab(l10n, s, locked),
                        _soundsTab(l10n, s),
                      ],
                    ),
                  ),
                ],
              );
              return LayoutBuilder(
                builder: (context, box) {
                  if (box.maxWidth > box.maxHeight) {
                    final side = math.min(box.maxHeight - 24, box.maxWidth / 2);
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: BoardPreview(settings: s, size: side),
                          ),
                        ),
                        Expanded(child: tabs),
                      ],
                    );
                  }
                  final side = math.min(box.maxWidth - 24, box.maxHeight * 0.4);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: BoardPreview(settings: s, size: side),
                      ),
                      Expanded(child: tabs),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _boardTab(
    AppLocalizations l10n,
    AppSettings s,
    Requirement? Function(Enum) locked,
  ) => StyleGallery<BoardTheme>(
    kid: s.kidMode,
    options: [
      for (final t in BoardTheme.values)
        StyleOption(
          value: t,
          key: 'theme-tile-${t.name}',
          label: themeLabel(l10n, t),
          visual: _ThemeSwatch(t),
        ),
    ],
    selected: s.boardTheme,
    selectedLabel: themeLabel(l10n, s.boardTheme),
    locked: locked,
    onSelected: (t) => _set((c) => c.copyWith(boardTheme: t)),
  );

  Widget _piecesTab(
    AppLocalizations l10n,
    AppSettings s,
    Requirement? Function(Enum) locked,
  ) => StyleGallery<PieceStyle>(
    kid: s.kidMode,
    options: [
      for (final st in PieceStyle.values)
        StyleOption(
          value: st,
          key: 'piece-tile-${st.name}',
          label: pieceLabel(l10n, st),
          // Il cavallo sulla casa scura del tema: si vede come in partita.
          visual: Container(
            width: 48,
            height: 48,
            color: s.boardTheme.colorScheme.darkSquare,
            child: Image(
              key: Key('piece-icon-${st.name}'),
              image: st.assetsOn(s.boardTheme)[PieceKind.whiteKnight]!,
              excludeFromSemantics: true,
            ),
          ),
        ),
    ],
    selected: s.pieceSet,
    selectedLabel: pieceLabel(l10n, s.pieceSet),
    locked: locked,
    onSelected: (st) => _set((c) => c.copyWith(pieceSet: st)),
  );

  Widget _backdropTab(
    AppLocalizations l10n,
    AppSettings s,
    Requirement? Function(Enum) locked,
  ) {
    final hasPhoto =
        s.backdropPhoto.isNotEmpty && File(s.backdropPhoto).existsSync();
    return StyleGallery<BoardBackdrop>(
      kid: s.kidMode,
      leading: _AddPhotoTile(
        onTap: _choosePhoto,
        label: l10n.styleBackdropPhotoAdd,
      ),
      options: [
        for (final b in BoardBackdrop.values)
          if (b != BoardBackdrop.photo || hasPhoto)
            StyleOption(
              value: b,
              key: 'backdrop-tile-${b.name}',
              label: backdropLabel(l10n, b),
              visual: _BackdropSwatch(b, photo: s.backdropPhoto),
            ),
      ],
      selected: s.backdrop,
      selectedLabel: backdropLabel(l10n, s.backdrop),
      locked: locked,
      onSelected: (b) => _set((c) => c.copyWith(backdrop: b)),
      footer: Text(
        l10n.styleBackdropPhotoNote,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _soundsTab(AppLocalizations l10n, AppSettings s) =>
      StyleGallery<SoundSet>(
        kid: s.kidMode,
        options: [
          for (final set in SoundSet.values)
            StyleOption(
              value: set,
              key: 'sound-tile-${set.name}',
              label: soundSetLabel(l10n, set),
              visual: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.graphic_eq, size: 32),
              ),
            ),
        ],
        selected: s.soundSet,
        selectedLabel: soundSetLabel(l10n, s.soundSet),
        locked: (_) => null,
        onSelected: (set) => unawaited(_chooseSounds(set)),
        footer: Text(
          s.sound ? l10n.styleSoundsHint : l10n.styleSoundsOff,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}

/// Miniatura di un tema: la texture, o quattro file di case a tinta unita.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch(this.theme);

  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final image = theme.image;
    return ExcludeSemantics(
      child: ClipRRect(
        key: Key('theme-swatch-${theme.name}'),
        borderRadius: BorderRadius.circular(
          RokkoTokens.of(context).radiusSmall / 3,
        ),
        child: SizedBox(
          width: 48,
          height: 48,
          child: image != null
              ? Image(image: ResizeImage(image, width: 96), fit: BoxFit.cover)
              : Column(
                  children: [
                    for (var r = 0; r < 4; r++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var c = 0; c < 4; c++)
                              Expanded(
                                child: ColoredBox(
                                  color: (r + c).isEven
                                      ? scheme.lightSquare
                                      : scheme.darkSquare,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Miniatura di uno sfondo; per lo standard, il fondo del tema dell'app.
class _BackdropSwatch extends StatelessWidget {
  const _BackdropSwatch(this.backdrop, {required this.photo});

  final BoardBackdrop backdrop;
  final String photo;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      RokkoTokens.of(context).radiusSmall / 3,
    );
    final scheme = Theme.of(context).colorScheme;
    if (backdrop == BoardBackdrop.standard) {
      return ExcludeSemantics(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outline),
          ),
          child: Icon(Icons.block, color: scheme.onSurfaceVariant),
        ),
      );
    }
    final asset = backdrop.asset;
    final image = backdrop == BoardBackdrop.photo
        ? DecorationImage(
            image: ResizeImage(
              FileImage(File(photo)),
              width: 96,
              policy: ResizeImagePolicy.fit,
            ),
            fit: BoxFit.cover,
            onError: (_, _) {},
          )
        : asset == null
        ? null
        : DecorationImage(
            image: ResizeImage(
              AssetImage(asset),
              width: 96,
              policy: ResizeImagePolicy.fit,
            ),
            fit: BoxFit.cover,
          );
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: backdrop.color ?? const Color(0xff2b2a28),
          gradient: backdrop.gradient,
          image: image,
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        key: const Key('backdrop-photo-add'),
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.add_photo_alternate_outlined, size: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
