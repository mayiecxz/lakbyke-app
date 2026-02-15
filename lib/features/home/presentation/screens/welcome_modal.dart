import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';

/// Welcome modal that displays yesterday's achievements with environmental benefits
class WelcomeModal extends StatelessWidget {
  final double yesterdayDistance;
  final double yesterdayWh;
  final VoidCallback onClose;

  const WelcomeModal({
    super.key,
    required this.yesterdayDistance,
    required this.yesterdayWh,
    required this.onClose,
  });

  // Calculate relatable benefits
  // Distance: 1 km cycling ≈ 0.21 kg CO2 saved (vs average car)
  // Tree equivalent: 1 tree absorbs ~22 kg CO2/year, so ~110 km ≈ 1 tree's annual work
  String _getDistanceBenefit(double distanceKm) {
    if (distanceKm <= 0) return '';
    
    // 1 km cycling ≈ 0.21 kg CO2 saved (vs car)
    final co2Saved = (distanceKm * 0.21);
    
    // Tree equivalent: ~110 km = 1 tree's annual CO2 absorption
    // (22 kg CO2/year ÷ 0.21 kg CO2/km ≈ 105 km, rounded to 110 km for clarity)
    final treeEquivalent = distanceKm / 110.0;
    
    final distStr = distanceKm.abs() >= 1000 ? formatCompactNumber(distanceKm, 1) : distanceKm.toStringAsFixed(1);
    final co2Str = co2Saved.abs() >= 1000 ? formatCompactNumber(co2Saved, 1) : co2Saved.toStringAsFixed(2);
    if (distanceKm >= 1.0) {
      if (treeEquivalent >= 1.0) {
        final trees = treeEquivalent.toStringAsFixed(1);
        return 'You pedaled $distStr km yesterday—that avoids as much CO₂ as $trees tree${trees == '1.0' ? '' : 's'} absorb${trees == '1.0' ? 's' : ''} in a year!';
      } else if (treeEquivalent >= 0.1) {
        final treePercent = (treeEquivalent * 100).toStringAsFixed(0);
        return 'You pedaled $distStr km yesterday—avoiding CO₂ equivalent to $treePercent% of a tree\'s annual absorption!';
      } else {
        return 'You pedaled $distStr km yesterday, saving $co2Str kg of CO₂!';
      }
    } else {
      return 'You pedaled ${distanceKm.toStringAsFixed(2)} km yesterday—every pedal counts!';
    }
  }

  // Energy: Convert Wh to smartphone charges
  // Real-world charging efficiency: ~15-18 Wh per full charge (accounting for losses)
  // Using 16 Wh as a middle ground for accuracy
  String _getEnergyBenefit(double wh) {
    if (wh <= 0) return '';
    
    // Real-world phone charge: ~16 Wh (accounting for charging efficiency losses)
    final phoneCharges = wh / 16.0;
    
    final energyStr = wh >= 1000000 ? '${formatCompactNumber(wh / 1000)} kWh' : formatEnergy(wh);
    if (wh >= 16) {
      if (phoneCharges >= 1.0) {
        final charges = phoneCharges >= 1000 ? formatCompactNumber(phoneCharges, 1) : phoneCharges.toStringAsFixed(1);
        return 'You generated $energyStr yesterday—that\'s enough to charge a smartphone $charges time${charges == '1.0' ? '' : 's'}! 📱';
      } else {
        final percent = (phoneCharges * 100).toStringAsFixed(0);
        return 'You generated $energyStr yesterday—that\'s $percent% of a smartphone charge!';
      }
    } else if (wh > 0) {
      return 'You generated $energyStr yesterday—powering towards a greener future!';
    } else {
      return '';
    }
  }

  // Wallet Watch: Money saved from not taking jeepney/tricycle
  // Average trip: 2-3 km, minimum fare: ₱15-20
  // Conservative estimate: ~₱5-7 per km saved
  // Using ₱5/km as minimum to match "at least" framing
  String _getMoneySavedBenefit(double distanceKm) {
    if (distanceKm <= 0) return '';
    
    // Conservative: ₱5 per km (minimum saved)
    // Typical range: ₱5-10 per km depending on trip length
    final minMoneySaved = distanceKm * 5.0;
    final maxMoneySaved = distanceKm * 10.0;
    
    if (distanceKm >= 1.0) {
      if (minMoneySaved >= 15.0) {
        if (maxMoneySaved - minMoneySaved < 10) {
          return 'You saved at least ${formatCompactCurrency(minMoneySaved)} yesterday by pedaling instead of taking public transport! 💰';
        } else {
          return 'You saved ${formatCompactCurrency(minMoneySaved)}-${formatCompactCurrency(maxMoneySaved)} yesterday by pedaling instead of taking public transport! 💰';
        }
      } else {
        return 'You saved at least ${formatCompactCurrency(minMoneySaved)} yesterday—every peso counts! 💵';
      }
    } else {
      return '';
    }
  }

  // Fitness Fuel: Calories burned from cycling
  // Biking burns ~25-30 kcal/km for moderate cycling
  // Using 27.5 kcal/km as middle ground
  String _getCaloriesBurnedBenefit(double distanceKm) {
    if (distanceKm <= 0) return '';
    
    // Moderate cycling: ~27.5 kcal/km
    final caloriesBurned = distanceKm * 27.5;
    
    if (distanceKm >= 1.0) {
      final calories = caloriesBurned >= 1000 ? formatCompactNumber(caloriesBurned, 0) : caloriesBurned.toStringAsFixed(0);
      if (caloriesBurned >= 100) {
        return 'You burned ~$calories calories yesterday—that\'s a solid workout! 💪';
      } else if (caloriesBurned >= 50) {
        return 'You burned ~$calories calories yesterday—great start! 🏃';
      } else {
        return 'You burned ~$calories calories yesterday—every bit helps! ⚡';
      }
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceMessage = _getDistanceBenefit(yesterdayDistance);
    final energyMessage = _getEnergyBenefit(yesterdayWh);
    final moneyMessage = _getMoneySavedBenefit(yesterdayDistance);
    final caloriesMessage = _getCaloriesBurnedBenefit(yesterdayDistance);
    final hasData = yesterdayDistance > 0 || yesterdayWh > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.homeAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.wb_sunny,
                          color: AppColors.homeAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Welcome Back! 🌱',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (hasData) ...[
                    // Environmental Impact Section
                    if (distanceMessage.isNotEmpty || energyMessage.isNotEmpty) ...[
                      const Text(
                        'Environmental Impact 🌱',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Distance achievement
                    if (distanceMessage.isNotEmpty)
                      _buildAchievementCard(
                        icon: Icons.directions_bike,
                        message: distanceMessage,
                        color: AppColors.homePrimary,
                      ),
                    
                    if (distanceMessage.isNotEmpty && energyMessage.isNotEmpty)
                      const SizedBox(height: 12),
                    
                    // Energy achievement
                    if (energyMessage.isNotEmpty)
                      _buildAchievementCard(
                        icon: Icons.flash_on,
                        message: energyMessage,
                        color: AppColors.homeAccent,
                      ),
                    
                    // Personal Wins Section
                    if ((moneyMessage.isNotEmpty || caloriesMessage.isNotEmpty) && 
                        (distanceMessage.isNotEmpty || energyMessage.isNotEmpty))
                      const SizedBox(height: 24),
                    
                    if (moneyMessage.isNotEmpty || caloriesMessage.isNotEmpty) ...[
                      const Text(
                        'Personal Wins 🎯',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Money saved achievement
                    if (moneyMessage.isNotEmpty)
                      _buildAchievementCard(
                        icon: Icons.account_balance_wallet,
                        message: moneyMessage,
                        color: const Color(0xFF4CAF50), // Green for money
                      ),
                    
                    if (moneyMessage.isNotEmpty && caloriesMessage.isNotEmpty)
                      const SizedBox(height: 12),
                    
                    // Calories burned achievement
                    if (caloriesMessage.isNotEmpty)
                      _buildAchievementCard(
                        icon: Icons.fitness_center,
                        message: caloriesMessage,
                        color: const Color(0xFFE91E63), // Pink/red for fitness
                      ),
                  ] else ...[
                    // No data message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.textSecondary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Start pedaling to see your environmental impact! 🚴',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.homePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.darkText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required double yesterdayDistance,
    required double yesterdayWh,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => WelcomeModal(
        yesterdayDistance: yesterdayDistance,
        yesterdayWh: yesterdayWh,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
