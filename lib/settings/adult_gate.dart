import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Domanda per adulti prima di uscire dal profilo bambino (RP-06): una
/// moltiplicazione che un bambino piccolo non risolve al volo. Restituisce
/// true se la risposta è giusta.
Future<bool> askAdult(BuildContext context, {math.Random? random}) async {
  final r = random ?? math.Random();
  final a = 6 + r.nextInt(4);
  final b = 6 + r.nextInt(4);
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _AdultGate(a: a, b: b),
  );
  return ok ?? false;
}

class _AdultGate extends StatefulWidget {
  const _AdultGate({required this.a, required this.b});

  final int a;
  final int b;

  @override
  State<_AdultGate> createState() => _AdultGateState();
}

class _AdultGateState extends State<_AdultGate> {
  final _answer = TextEditingController();
  var _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    if (int.tryParse(_answer.text.trim()) == widget.a * widget.b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('adultGate'),
      title: Text(l10n.kidAdultGateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.kidAdultGateQuestion(widget.a, widget.b),
            key: const Key('adultQuestion'),
          ),
          TextField(
            key: const Key('adultAnswer'),
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              errorText: _wrong ? l10n.kidAdultGateWrong : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.kidAdultGateConfirm)),
      ],
    );
  }
}
