import 'package:flutter/material.dart';

import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../progress/rewards.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';

/// Una scelta della griglia: dopo [visual] il nome, il lucchetto se ancora da
/// sbloccare e la spunta sulla scelta attiva.
class StyleOption<T> {
  const StyleOption({
    required this.value,
    required this.key,
    required this.label,
    required this.visual,
  });

  final T value;
  final String key;
  final String label;
  final Widget visual;
}

/// Griglia di scelte di una scheda di Stile, con in cima il nome di quella
/// attiva. [leading] sta prima delle tessere, per esempio «Scegli una foto».
class StyleGallery<T extends Enum> extends StatelessWidget {
  const StyleGallery({
    super.key,
    required this.options,
    required this.selected,
    required this.selectedLabel,
    required this.onSelected,
    required this.locked,
    required this.kid,
    this.leading,
    this.footer,
  });

  final List<StyleOption<T>> options;
  final T selected;
  final String selectedLabel;
  final ValueChanged<T> onSelected;
  final Requirement? Function(Enum) locked;

  /// Profilo bambino: il requisito non cita il livello.
  final bool kid;
  final Widget? leading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    String why(Requirement r) =>
        kid ? kidRequirement(l10n) : l10n.settingsUnlockWith(r.label(l10n));
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final columns = ((box.maxWidth - 16) / 88).floor().clamp(3, 8);
        final width = (box.maxWidth - 16 - gap * (columns - 1)) / columns;
        return ListView(
          padding: context.withSystemBottom(
            const EdgeInsets.fromLTRB(8, 12, 8, 24),
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                selectedLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                if (leading != null) SizedBox(width: width, child: leading),
                for (final o in options)
                  SizedBox(
                    width: width,
                    child: _Tile<T>(
                      option: o,
                      selected: o.value == selected,
                      requirement: locked(o.value),
                      tokens: tokens,
                      scheme: scheme,
                      l10n: l10n,
                      kid: kid,
                      why: why,
                      onSelected: onSelected,
                    ),
                  ),
              ],
            ),
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
        );
      },
    );
  }
}

class _Tile<T extends Enum> extends StatelessWidget {
  const _Tile({
    required this.option,
    required this.selected,
    required this.requirement,
    required this.tokens,
    required this.scheme,
    required this.l10n,
    required this.kid,
    required this.why,
    required this.onSelected,
  });

  final StyleOption<T> option;
  final bool selected;
  final Requirement? requirement;
  final RokkoTokens tokens;
  final ColorScheme scheme;
  final AppLocalizations l10n;
  final bool kid;
  final String Function(Requirement) why;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final r = requirement;
    void tap() {
      if (r == null) return onSelected(option.value);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kid
                ? l10n.settingsLockedKidMessage(
                    option.label,
                    why(r).toLowerCase(),
                  )
                : l10n.settingsLockedMessage(option.label, r.label(l10n)),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: r == null,
      label: r == null
          ? option.label
          : l10n.settingsLockedSemantics(option.label, why(r)),
      excludeSemantics: true,
      onTap: tap,
      child: Material(
        key: Key(option.key),
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: tokens.minTouch),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: r == null ? 1 : 0.55,
                        child: option.visual,
                      ),
                      if (r != null)
                        Icon(Icons.lock_outline, color: scheme.onSurface),
                      if (selected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(
                            Icons.check_circle,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.label,
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
      ),
    );
  }
}
