import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../minigames/blind.dart' show pieceLabel;
import '../minigames/board_layout.dart';
import '../share/position_image.dart';
import '../share/position_image_page.dart';
import '../theme/motion.dart';
import 'position_draft.dart';

/// Editor di posizione: pezzi liberi, tratto, arrocco, FEN. Restituisce la
/// posizione da giocare con `Navigator.pop`.
class PositionEditorPage extends StatefulWidget {
  const PositionEditorPage({
    super.key,
    this.initialFen,
    this.board = const ChessboardSettings(),
  });

  /// Posizione di partenza; senza, quella iniziale degli scacchi.
  final String? initialFen;

  /// Aspetto della scacchiera e dei pezzi scelto nelle impostazioni.
  final ChessboardSettings board;

  @override
  State<PositionEditorPage> createState() => _PositionEditorPageState();
}

String _castlingLabel(AppLocalizations l10n, CastlingRight right) =>
    switch (right) {
      CastlingRight.whiteKingSide => l10n.editorCastleWhiteShort,
      CastlingRight.whiteQueenSide => l10n.editorCastleWhiteLong,
      CastlingRight.blackKingSide => l10n.editorCastleBlackShort,
      CastlingRight.blackQueenSide => l10n.editorCastleBlackLong,
    };

/// Spiegazione del motivo per cui la posizione non si può giocare.
String setupProblemText(AppLocalizations l10n, SetupProblem problem) =>
    switch (problem) {
      SetupProblem.empty => l10n.editorProblemEmpty,
      SetupProblem.kings => l10n.editorProblemKings,
      SetupProblem.pawnsOnBackrank => l10n.editorProblemPawnsOnBackrank,
      SetupProblem.oppositeCheck => l10n.editorProblemOppositeCheck,
      SetupProblem.impossibleCheck => l10n.editorProblemImpossibleCheck,
      SetupProblem.invalid => l10n.editorProblemInvalid,
      SetupProblem.gameOver => l10n.editorProblemGameOver,
    };

class _PositionEditorPageState extends State<PositionEditorPage> {
  late PositionDraft _draft;
  Side _orientation = Side.white;

  /// Pezzo da posare; `null` è la gomma.
  Piece? _selected = const Piece(color: Side.white, role: Role.pawn);

  @override
  void initState() {
    super.initState();
    final fen = widget.initialFen;
    _draft =
        (fen == null ? null : PositionDraft.parseFen(fen)) ??
        PositionDraft.initial();
  }

  void _tap(Square square) {
    final current = _draft.board.pieceAt(square);
    // Toccare un pezzo uguale a quello scelto lo toglie.
    final piece = current == _selected ? null : _selected;
    setState(() => _draft = _draft.put(square, piece));
  }

  void _set(PositionDraft draft) => setState(() => _draft = draft);

  Future<void> _paste() async {
    final text = await showDialog<String>(
      context: context,
      animationStyle: motionStyle(context),
      builder: (context) => const _FenDialog(),
    );
    if (!mounted || text == null) return;
    final draft = PositionDraft.parseFen(text);
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).editorFenInvalid)),
      );
      return;
    }
    _set(draft);
  }

  void _copy() {
    unawaited(Clipboard.setData(ClipboardData(text: _draft.fen)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).editorFenCopied)),
    );
  }

  Widget _paletteButton(Piece? piece) {
    final selected = piece == _selected;
    final key = piece == null
        ? const Key('editor-eraser')
        : Key(
            'editor-piece-${piece.color == Side.white ? 'w' : 'b'}'
            '${piece.role.uppercaseLetter}',
          );
    return Semantics(
      selected: selected,
      button: true,
      label: piece == null
          ? AppLocalizations.of(context).editorEraser
          : pieceLabel(AppLocalizations.of(context), piece),
      child: ExcludeSemantics(
        child: InkWell(
          key: key,
          onTap: () => setState(() => _selected = piece),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(2),
            child: piece == null
                ? const Icon(Icons.delete_outline)
                : Image(image: widget.board.pieceAssets[piece.kind]!),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problem = _draft.problem;
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editorTitle),
        actions: [
          PositionImageButton(
            image: () =>
                PositionImage(fen: _draft.fen, orientation: _orientation),
          ),
          IconButton(
            tooltip: l10n.editorFlipBoard,
            icon: const Icon(Icons.swap_vert),
            onPressed: () =>
                setState(() => _orientation = _orientation.opposite),
          ),
        ],
      ),
      body: BoardLayout(
        board: (size) => StaticChessboard(
          size: size,
          orientation: _orientation,
          fen: _draft.board.fen,
          onTouchedSquare: _tap,
          settings: StaticChessboardSettings.fromBoardSettings(widget.board),
        ),
        panel: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final side in Side.values)
              Wrap(
                spacing: 4,
                children: [
                  for (final role in Role.values)
                    _paletteButton(Piece(color: side, role: role)),
                  if (side == Side.black) _paletteButton(null),
                ],
              ),
            const SizedBox(height: 12),
            SegmentedButton<Side>(
              segments: [
                ButtonSegment(
                  value: Side.white,
                  label: Text(l10n.editorTurnWhite),
                ),
                ButtonSegment(
                  value: Side.black,
                  label: Text(l10n.editorTurnBlack),
                ),
              ],
              selected: {_draft.turn},
              onSelectionChanged: (s) => _set(_draft.withTurn(s.single)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final right in CastlingRight.values)
                  FilterChip(
                    label: Text(_castlingLabel(l10n, right)),
                    selected: _draft.castling.contains(right),
                    onSelected: _draft.isCastlingAvailable(right)
                        ? (on) => _set(_draft.withCastling(right, enabled: on))
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _set(PositionDraft.initial()),
                  child: Text(l10n.editorInitial),
                ),
                OutlinedButton(
                  onPressed: () => _set(PositionDraft.empty()),
                  child: Text(l10n.editorClear),
                ),
                OutlinedButton(
                  onPressed: () => _set(_draft.flipped()),
                  child: Text(l10n.editorSwapColors),
                ),
                OutlinedButton(
                  onPressed: _paste,
                  child: Text(l10n.editorPasteFen),
                ),
                OutlinedButton(
                  onPressed: _copy,
                  child: Text(l10n.editorCopyFen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      AppLocalizations.of(context).editorFenTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('editor-fen-help'),
                  icon: const Icon(Icons.help_outline),
                  tooltip: AppLocalizations.of(context).editorFenHelpTooltip,
                  onPressed: () => showDialog<void>(
                    context: context,
                    animationStyle: motionStyle(context),
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return AlertDialog(
                        title: Text(l10n.editorFenTitle),
                        content: Text(l10n.editorFenHelpBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.editorFenHelpClose),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            SelectionArea(
              child: Text(
                _draft.fen,
                key: const Key('editor-fen'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (problem != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  setupProblemText(l10n, problem),
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: problem == null
                  ? () => Navigator.pop(context, _draft.toPosition())
                  : null,
              child: Text(l10n.editorPlayFromHere),
            ),
          ],
        ),
      ),
    );
  }
}

class _FenDialog extends StatefulWidget {
  const _FenDialog();

  @override
  State<_FenDialog> createState() => _FenDialogState();
}

class _FenDialogState extends State<_FenDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editorPasteFen),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.editorFenField),
        onSubmitted: (text) => Navigator.pop(context, text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.editorCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.editorLoad),
        ),
      ],
    );
  }
}
