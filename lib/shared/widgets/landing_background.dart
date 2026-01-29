import 'package:flutter/material.dart';
import '../../core/theme/aura_colors.dart';

/// Dark slate background for Landing screen.
class LandingBackground extends StatelessWidget {
  const LandingBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AuraColors.darkSlate,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF132D4D),
            AuraColors.darkSlate,
            Color(0xFF0A1628),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
