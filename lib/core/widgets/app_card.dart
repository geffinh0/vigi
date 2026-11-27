import 'package:flutter/material.dart';

import '../theme/vigi_palette.dart';
import '../theme/vigi_tokens.dart';

/// Card do Vigi: Linho 50 sobre Linho 100, com borda de 1 dp em Linho 200.
///
/// A elevação é feita por cor, não por sombra. Sombra fica reservada para o
/// halo dos estados, onde ela tem significado.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VigiSpace.x4),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final radius = BorderRadius.circular(VigiRadius.md);

    final card = Ink(
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? palette.border),
      ),
      child: Padding(padding: padding, child: child),
    );

    return Material(
      type: MaterialType.transparency,
      child: onTap == null
          ? card
          : InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}
