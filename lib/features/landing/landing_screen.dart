import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/aura_colors.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../shared/widgets/aura_logo.dart';
import '../../shared/widgets/landing_background.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF182736),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: LandingBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: AuraLogo(size: 40, onLightBackground: false),
                  ),
                  const SizedBox(height: 12),
                  _buildHackathonBadge(context),
                  const SizedBox(height: 28),
                  _buildHeadline(context),
                  const SizedBox(height: 16),
                  _buildDescription(context),
                  const SizedBox(height: 24),
                  _buildFeature(context, "Say 'Movie Time'—A.U.R.A. orchestrates lights, blinds, temperature, and audio in one command."),
                  const SizedBox(height: 12),
                  _buildFeature(context, "AI-powered planning translates your goals into reliable device choreography."),
                  const SizedBox(height: 12),
                  _buildFeature(context, "Enterprise cloud platform with real-time sync, automatic backups, and remote access from anywhere."),
                  const SizedBox(height: 40),
                  _buildPrimaryButton(context),
                  const SizedBox(height: 12),
                  _buildSecondaryButton(context),
                  const SizedBox(height: 16),
                  _buildLearnMoreLink(context),
                  const SizedBox(height: 28),
                  _buildLandingFooter(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandingFooter(BuildContext context) {
    return Center(
      child: Text(
        'A.U.R.A. — Your Flutter Butler\nBuild your Flutter Butler with Serverpod • Devpost Hackathon 2026',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 1.4,
          color: AuraColors.textOnDark.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildHackathonBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AuraColors.teal.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AuraColors.teal.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.sparkles, size: 16, color: AuraColors.textOnDark.withValues(alpha: 0.95)),
          const SizedBox(width: 8),
          Text(
            'Build your Flutter Butler with Serverpod',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AuraColors.textOnDark.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.25,
        ),
        children: const [
          TextSpan(text: 'Your ', style: TextStyle(color: AuraColors.textOnDark)),
          TextSpan(text: 'Flutter Butler. ', style: TextStyle(color: AuraColors.teal)),
          TextSpan(text: 'Built to Serve.', style: TextStyle(color: AuraColors.coral)),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      "A.U.R.A. is your personal Flutter Butler—a digital assistant that serves, automates, and delights. Say what you need in plain language; your butler plans and executes.",
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: AuraColors.textOnDark.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildFeature(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AuraColors.teal,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, size: 14, color: AuraColors.textOnTeal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AuraColors.textOnDark.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticUtils.lightImpact();
          context.go('/');
        },
        icon: const Icon(LucideIcons.play, size: 18),
        label: const Text('Meet Your Butler'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraColors.teal,
          foregroundColor: AuraColors.textOnTeal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(999.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticUtils.lightImpact();
          _openDemoVideo(context);
        },
        icon: const Icon(LucideIcons.video, size: 18),
        label: const Text('View Demo Video'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraColors.surfaceDark,
          foregroundColor: AuraColors.textOnDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(999.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildLearnMoreLink(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          HapticUtils.lightImpact();
          final uri = Uri.parse('https://github.com/lucylow/aura-smart-home-agent');
          launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open link')),
              );
            }
          });
        },
        icon: Icon(LucideIcons.github, size: 18, color: AuraColors.textOnDark.withValues(alpha: 0.8)),
        label: Text(
          'Learn more — GitHub',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AuraColors.textOnDark.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  void _openDemoVideo(BuildContext context) {
    final uri = Uri.parse('https://youtu.be/BObaIfH0L6E');
    launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open demo video link')),
        );
      }
    });
  }
}
