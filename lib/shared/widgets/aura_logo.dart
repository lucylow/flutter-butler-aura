import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/aura_colors.dart';

/// A.U.R.A. logo: teal brain icon in rounded square + "A.U.R.A." with coral accent.
class AuraLogo extends StatelessWidget {
  const AuraLogo({
    super.key,
    this.size = 36,
    this.iconSize,
    this.fontSize,
    this.onLightBackground = false,
  });

  final double size;
  final double? iconSize;
  final double? fontSize;
  final bool onLightBackground;

  @override
  Widget build(BuildContext context) {
    final icon = iconSize ?? (size * 0.55);
    final textColor = onLightBackground ? AuraColors.textDark : AuraColors.textOnDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AuraColors.teal,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AuraColors.teal.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            LucideIcons.cpu,
            size: icon,
            color: AuraColors.textOnTeal,
          ),
        ),
        SizedBox(width: size * 0.35),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize ?? (size * 0.65),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            children: [
              const TextSpan(text: 'A.', style: TextStyle(color: AuraColors.coral)),
              TextSpan(text: 'U.R.A.', style: TextStyle(color: textColor)),
            ],
          ),
        ),
      ],
    );
  }
}
