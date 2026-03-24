import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/constants/colors.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Modal showing all rider persona badges. Unlocked badge in full color;
/// others shown as silhouettes (locked) with "Complete more rides to unlock".
class BadgeShowcaseModal extends StatelessWidget {
  const BadgeShowcaseModal({
    super.key,
    required this.model,
  });

  final InsightsModel model;

  static Future<void> show(BuildContext context, InsightsModel model) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BadgeShowcaseModal(model: model),
    );
  }

  static const List<_BadgeDef> _allBadges = [
    _BadgeDef(
      id: 'early_bird',
      name: 'Early Bird',
      shortDescription: 'Ride early to stay cool',
      icon: Icons.wb_sunny_outlined,
      accentColor: Color(0xFFFFB74D),
    ),
    _BadgeDef(
      id: 'peak_provider',
      name: 'Peak Provider',
      shortDescription: 'You ride when the station is busiest',
      icon: Icons.local_fire_department_outlined,
      accentColor: Color(0xFFF59E0B),
    ),
    _BadgeDef(
      id: 'sunset_cruiser',
      name: 'Sunset Cruiser',
      shortDescription: 'Evening rides help you wind down',
      icon: Icons.nights_stay_outlined,
      accentColor: Color(0xFF7C4DFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPersona = model.riderPersona;
    
    // FIX: We now look at a list of ALL unlocked personas, not just the active one!
    // (Note: You will need to add `unlockedPersonas` to your InsightsModel in Step 2)
    final unlockedList = model.unlockedPersonas; 

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rider Persona Badges',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.homePrimary,
                ),
          ),
          const SizedBox(height: 6),
          
          // FIX: Updated instructions to include the 30-day reset mechanic
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.homePrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.homePrimary.withValues(alpha: 0.1)),
            ),
            child: Text(
              'Complete at least 3 rides to unlock a badge. Unlocked badges are yours to keep, but all progress will reset after 30 days of inactivity.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
          
          const SizedBox(height: 20),
          ..._allBadges.map((badge) {
            
            // FIX: Check if this specific badge ID is inside the unlocked list
            final isUnlocked = unlockedList.contains(badge.id);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BadgeTile(
                badge: badge,
                isUnlocked: isUnlocked,
                isCurrent: currentPersona == badge.id,
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BadgeDef {
  const _BadgeDef({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.icon,
    required this.accentColor,
  });

  final String id;
  final String name;
  final String shortDescription;
  final IconData icon;
  final Color accentColor;
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.isUnlocked,
    required this.isCurrent,
  });

  final _BadgeDef badge;
  final bool isUnlocked;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? badge.accentColor : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isUnlocked ? badge.accentColor : AppColors.surfaceDim)
            .withValues(alpha: isUnlocked ? 0.15 : 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isUnlocked ? 0.5 : 0.25),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          isUnlocked
              ? Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    badge.icon,
                    color: color,
                    size: 28,
                  ),
                )
              : ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.textTertiary,
                    BlendMode.srcIn,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.textTertiary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      badge.icon,
                      color: AppColors.textTertiary,
                      size: 28,
                    ),
                  ),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      badge.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badge.accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badge.accentColor,
                          ),
                        ),
                      ),
                    ],
                    if (!isUnlocked) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked
                      ? badge.shortDescription
                      : 'Complete more rides to unlock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}