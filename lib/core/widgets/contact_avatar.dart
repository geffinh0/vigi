import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/vigi_palette.dart';
import '../utils/vigi_text.dart';

/// Avatar com as iniciais da pessoa (48 dp em listas).
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.background,
    this.foreground,
  });

  final String name;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? palette.chip,
          shape: BoxShape.circle,
        ),
        child: Text(
          VigiText.initials(name),
          textScaler: TextScaler.noScaling,
          style: AppTypography.label.copyWith(
            color: foreground ?? palette.text,
            fontSize: size * 0.36,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Avatares sobrepostos de quem está de vigília, com o texto ao lado.
class WatchersRow extends StatelessWidget {
  const WatchersRow({
    super.key,
    required this.names,
    required this.text,
    this.onTap,
  });

  final List<String> names;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final shown = names.take(3).toList();

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (shown.isNotEmpty) ...[
            SizedBox(
              width: 40.0 + (shown.length - 1) * 28,
              height: 40,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * 28.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.background,
                            width: 2,
                          ),
                        ),
                        child: ContactAvatar(name: shown[i], size: 36),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: row,
        ),
      ),
    );
  }
}
