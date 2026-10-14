import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/motion.dart';
import 'clock.dart';

const _maxMinutes = 180;
const _maxIncrement = 120;
const _maxDelay = 60;
const _minPhaseMoves = 5;
const _maxPhaseMoves = 100;
const _maxPhaseMinutes = 180;

/// Chiede minuti, incremento e ritardo di una cadenza libera (RF-40); `null`
/// se si annulla.
Future<TimeControl?> showCustomClockDialog(BuildContext context) =>
    showDialog<TimeControl>(
      context: context,
      animationStyle: motionStyle(context),
      builder: (_) => const _CustomClockDialog(),
    );

class _CustomClockDialog extends StatefulWidget {
  const _CustomClockDialog();

  @override
  State<_CustomClockDialog> createState() => _CustomClockDialogState();
}

class _CustomClockDialogState extends State<_CustomClockDialog> {
  final _minutes = TextEditingController(text: '10');
  final _increment = TextEditingController(text: '0');
  final _delay = TextEditingController(text: '0');
  final _phaseMoves = TextEditingController(text: '0');
  final _phaseMinutes = TextEditingController(text: '0');
  var _type = DelayType.simple;
  var _submitted = false;

  @override
  void dispose() {
    _minutes.dispose();
    _increment.dispose();
    _delay.dispose();
    _phaseMoves.dispose();
    _phaseMinutes.dispose();
    super.dispose();
  }

  int? _value(TextEditingController c, int min, int max) {
    final v = int.tryParse(c.text.trim());
    return v == null || v < min || v > max ? null : v;
  }

  // Un campo della fase lasciato vuoto vale 0, cioè nessuna fase.
  int? _blankAsZero(TextEditingController c) =>
      c.text.trim().isEmpty ? 0 : int.tryParse(c.text.trim());

  // La fase aggiunta è facoltativa: mosse e minuti sono entrambi 0, oppure
  // entrambi indicati, con almeno 5 mosse.
  int? _phaseMovesValue() {
    final moves = _blankAsZero(_phaseMoves);
    final minutes = _blankAsZero(_phaseMinutes);
    if (moves == null || minutes == null || moves > _maxPhaseMoves) {
      return null;
    }
    if (moves == 0) return minutes == 0 ? 0 : null;
    return moves < _minPhaseMoves || minutes == 0 ? null : moves;
  }

  int? _phaseMinutesValue() {
    final minutes = _blankAsZero(_phaseMinutes);
    if (minutes == null || minutes > _maxPhaseMinutes) return null;
    final moves = _blankAsZero(_phaseMoves) ?? 0;
    return (moves == 0) == (minutes == 0) ? minutes : null;
  }

  void _start() {
    final minutes = _value(_minutes, 1, _maxMinutes);
    final increment = _value(_increment, 0, _maxIncrement);
    final delay = _value(_delay, 0, _maxDelay);
    final phaseMoves = _phaseMovesValue();
    final phaseMinutes = _phaseMinutesValue();
    if (minutes == null ||
        increment == null ||
        delay == null ||
        phaseMoves == null ||
        phaseMinutes == null) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.pop(
      context,
      TimeControl(
        minutes: minutes,
        increment: increment,
        delay: delay,
        delayType: delay == 0 ? DelayType.simple : _type,
        phaseMoves: phaseMoves,
        phaseMinutes: phaseMinutes,
      ),
    );
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label,
    int min,
    int max,
    AppLocalizations l10n, {
    bool? valid,
  }) => TextField(
    key: ValueKey(key),
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    maxLength: 3,
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      errorText: _submitted && !(valid ?? _value(controller, min, max) != null)
          ? l10n.gameClockRange(min, max)
          : null,
    ),
    onChanged: (_) => setState(() {}),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasDelay = (int.tryParse(_delay.text.trim()) ?? 0) > 0;
    return AlertDialog(
      title: Text(l10n.gameClockCustomTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(
              'clock-minutes',
              _minutes,
              l10n.gameClockMinutes,
              1,
              _maxMinutes,
              l10n,
            ),
            _field(
              'clock-increment',
              _increment,
              l10n.gameClockIncrement,
              0,
              _maxIncrement,
              l10n,
            ),
            _field(
              'clock-delay',
              _delay,
              l10n.gameClockDelay,
              0,
              _maxDelay,
              l10n,
            ),
            _field(
              'clock-phase-moves',
              _phaseMoves,
              l10n.gameClockPhaseMoves,
              _minPhaseMoves,
              _maxPhaseMoves,
              l10n,
              valid: _phaseMovesValue() != null,
            ),
            _field(
              'clock-phase-minutes',
              _phaseMinutes,
              l10n.gameClockPhaseMinutes,
              1,
              _maxPhaseMinutes,
              l10n,
              valid: _phaseMinutesValue() != null,
            ),
            if (hasDelay) ...[
              const SizedBox(height: 12),
              SegmentedButton<DelayType>(
                key: const ValueKey('clock-delay-type'),
                segments: [
                  ButtonSegment(
                    value: DelayType.simple,
                    label: Text(l10n.gameClockDelaySimple),
                  ),
                  ButtonSegment(
                    value: DelayType.bronstein,
                    label: Text(l10n.gameClockDelayBronstein),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.gameCancel),
        ),
        FilledButton(
          key: const ValueKey('clock-start'),
          onPressed: _start,
          child: Text(l10n.gameClockStart),
        ),
      ],
    );
  }
}
