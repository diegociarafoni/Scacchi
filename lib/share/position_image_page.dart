import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../settings/board_frame.dart';
import '../settings/settings.dart';
import 'image_sharing.dart';
import 'position_image.dart';

/// Larghezza massima dell'anteprima: oltre non serve ingrandirla.
const _maxPreviewWidth = 480.0;

/// Testi dell'esportazione; senza i delegate (schermate montate da sole) si
/// usa l'italiano, la lingua predefinita.
AppLocalizations shareImageL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Apre l'esportazione di [image] come immagine PNG.
Future<void> openPositionImage(BuildContext context, PositionImage image) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PositionImagePage(image: image)),
    );

/// Pulsante della barra del titolo che esporta la posizione di [image].
class PositionImageButton extends StatelessWidget {
  const PositionImageButton({super.key, required this.image});

  /// Letta al tocco, perché la posizione cambia mentre la schermata è aperta.
  final PositionImage Function() image;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: shareImageL10n(context).shareImageTitle,
    icon: const Icon(Icons.image_outlined),
    onPressed: () => unawaited(openPositionImage(context, image())),
  );
}

/// Anteprima della scacchiera con il tema scelto dall'utente, qualche opzione
/// e la condivisione come PNG con il menu di sistema.
class PositionImagePage extends StatefulWidget {
  const PositionImagePage({super.key, required this.image, this.share});

  final PositionImage image;

  /// Consegna il PNG; senza, si apre il menu di condivisione del sistema.
  final ShareImage? share;

  @override
  State<PositionImagePage> createState() => _PositionImagePageState();
}

class _PositionImagePageState extends State<PositionImagePage> {
  final _card = GlobalKey();
  final _button = GlobalKey();
  final _caption = TextEditingController();
  late var _orientation = widget.image.orientation;
  bool? _coordinates;
  bool _lastMove = true;
  bool _sharing = false;
  bool _failed = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _share(double previewWidth) async {
    if (_sharing) return;
    // Letto prima di ogni attesa: dopo, il contesto potrebbe non esserci più.
    final box = _button.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final subject = shareImageL10n(context).shareImageSubject;
    setState(() {
      _sharing = true;
      _failed = false;
    });
    try {
      final png = await capturePng(
        _card,
        pixelRatio: exportPixelRatio(previewWidth),
      );
      if (png == null) {
        _failed = true;
      } else {
        final share = widget.share;
        if (share == null) {
          await shareImageWithSystem(
            png,
            positionImageFileName,
            subject: subject,
            origin: origin,
          );
        } else {
          await share(png, positionImageFileName);
        }
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Condivisione dell\'immagine non riuscita: $e'); // l10n-ok
      }
      _failed = true;
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = shareImageL10n(context);
    final settings = AppSettings.of(context);
    final image = widget.image;
    final coordinates = _coordinates ?? settings.showCoordinates;
    final caption = cleanCaption(_caption.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareImageTitle),
        actions: [
          IconButton(
            tooltip: l10n.shareImageFlip,
            icon: const Icon(Icons.swap_vert),
            onPressed: () =>
                setState(() => _orientation = _orientation.opposite),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 32).clamp(
              0.0,
              _maxPreviewWidth,
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Semantics(
                    label: caption == null
                        ? l10n.shareImagePreview
                        : '${l10n.shareImagePreview}: $caption',
                    image: true,
                    child: ExcludeSemantics(
                      child: RepaintBoundary(
                        key: _card,
                        child: _PositionCard(
                          width: width,
                          image: image,
                          orientation: _orientation,
                          settings: settings,
                          coordinates: coordinates,
                          showLastMove: _lastMove,
                          caption: caption,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(l10n.shareImageCoordinates),
                  value: coordinates,
                  onChanged: (v) => setState(() => _coordinates = v),
                ),
                if (image.lastMove != null)
                  SwitchListTile(
                    title: Text(l10n.shareImageLastMove),
                    value: _lastMove,
                    onChanged: (v) => setState(() => _lastMove = v),
                  ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('position-image-caption'),
                  controller: _caption,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxCaptionLength),
                  ],
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.shareImageCaption,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: _button,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _sharing ? null : () => unawaited(_share(width)),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l10n.shareImageAction),
                ),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.shareImageFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Ciò che finisce nel PNG: scacchiera e, sotto, la didascalia.
class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.width,
    required this.image,
    required this.orientation,
    required this.settings,
    required this.coordinates,
    required this.showLastMove,
    required this.caption,
  });

  final double width;
  final PositionImage image;
  final Side orientation;
  final AppSettings settings;
  final bool coordinates;
  final bool showLastMove;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    // Le coordinate stanno sempre nella cornice, dove non coprono i pezzi.
    final board = StaticChessboardSettings.fromBoardSettings(
      settings.board.copyWith(enableCoordinates: false),
    );
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BoardFrame(
            size: width,
            outside: coordinates,
            orientation: orientation,
            theme: settings.boardTheme,
            builder: (size) => StaticChessboard(
              size: size,
              orientation: orientation,
              fen: image.fen,
              lastMove: showLastMove ? image.lastMove : null,
              shapes: image.shapes,
              settings: board,
            ),
          ),
          if (caption != null)
            Container(
              width: width,
              color: const Color(0xff262421),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                caption!,
                key: const Key('position-image-caption-text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xfff5f1e8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
