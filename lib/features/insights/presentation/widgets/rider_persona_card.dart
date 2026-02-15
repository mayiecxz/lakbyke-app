import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_layout.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_shared_widgets.dart';

/// Section C: Rider persona (Early Bird / Peak Provider / Sunset Cruiser) and advice.
class RiderPersonaCard extends StatelessWidget {
  const RiderPersonaCard({
    super.key,
    required this.model,
    required this.layout,
  });

  final InsightsModel model;
  final InsightsLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: layout.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(
          color: _personaAccentColor().withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: model.hasEnoughDataForPersona ? _buildContent(context) : _buildEmptyState(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final s = layout.fontScale;
    final accent = _personaAccentColor();
    final icon = _personaIcon();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You are a ${model.riderPersonaName}',
                style: TextStyle(
                  fontSize: (18 * s).clamp(16.0, 22.0),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          model.riderPersonaAdvice,
          style: TextStyle(
            fontSize: (14 * s).clamp(13.0, 16.0),
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'You usually ride at ${model.averageRideTimeFormatted}. The station is busiest at 12:00 PM.',
            style: TextStyle(
              fontSize: (13 * s).clamp(12.0, 14.0),
              color: AppColors.darkText,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return InsightsInfoBanner(
      layout: layout,
      icon: Icons.person_outline_rounded,
      message: 'Complete at least 3 rides to unlock your Rider Persona.',
      backgroundColor: AppColors.homeAccent.withValues(alpha: 0.12),
      iconColor: AppColors.homePrimary,
      textColor: AppColors.darkText,
    );
  }

  Color _personaAccentColor() {
    switch (model.riderPersona) {
      case 'early_bird':
        return const Color(0xFFFFB74D);
      case 'peak_provider':
        return const Color(0xFFF59E0B);
      case 'sunset_cruiser':
        return const Color(0xFF7C4DFF);
      default:
        return AppColors.homePrimary;
    }
  }

  IconData _personaIcon() {
    switch (model.riderPersona) {
      case 'early_bird':
        return Icons.wb_sunny_outlined;
      case 'peak_provider':
        return Icons.local_fire_department_outlined;
      case 'sunset_cruiser':
        return Icons.nights_stay_outlined;
      default:
        return Icons.person_outline_rounded;
    }
  }
}
