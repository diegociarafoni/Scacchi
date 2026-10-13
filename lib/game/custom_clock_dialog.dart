import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'clock.dart';

const _maxMinutes = 180;
const _maxIncrement = 120;
const _maxDelay = 60;

/// Chiede minuti, incremento e ritardo di una cadenza libera (RF-40); `null`
/// se si annulla.
Future<TimeControl?> showCustomClockDialog(BuildContext context) =>
    showDialog<TimeControl>(
      context: context,
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
  var _type = DelayType.simple;
  var _submitted = false;

  @override
  void dispose() {
    _minutes.dispose();
    _increment.dispose();
    _delay.dispose();
    super.dispose();
  }

  int? _value(TextEditingController c, int min, int max) {
    final v = int.tryParse(c.text.trim());
    return v == null || v < min || v > max ? null : v;
  }

  void _start() {
    final minutes = _value(_minutes, 1, _maxMinutes);
    final increment = _value(_increment, 0, _maxIncrement);
    final delay = _value(_delay, 0, _maxDelay);
    if (minutes == null || increment == null || delay == null) {
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
      ),
    );
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label,
    int min,
    int max,
    AppLocalizations l10n,
  ) => TextField(
    key: ValueKey(key),
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    maxLength: 3,
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      errorText: _submitted && _value(controller, min, max) == null
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
