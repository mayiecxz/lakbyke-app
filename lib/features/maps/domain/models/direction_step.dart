import 'package:flutter/material.dart';

/// Model representing a single step in turn-by-turn directions
class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final String maneuver;
  final IconData icon;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.icon,
  });

  /// Create DirectionStep from Map (for backward compatibility)
  factory DirectionStep.fromMap(Map<String, dynamic> map) {
    return DirectionStep(
      instruction: map['instruction'] as String? ?? '',
      distance: map['distance'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      maneuver: map['maneuver'] as String? ?? '',
      icon: map['icon'] as IconData? ?? Icons.arrow_forward,
    );
  }

  /// Convert to Map (for backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'instruction': instruction,
      'distance': distance,
      'duration': duration,
      'maneuver': maneuver,
      'icon': icon,
    };
  }

  /// Get icon for maneuver type
  static IconData getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-sharp-left':
        return Icons.turn_left;
      case 'turn-sharp-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_left;
      case 'turn-slight-right':
        return Icons.turn_right;
      case 'straight':
        return Icons.straight;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'ramp-left':
      case 'ramp-right':
        return Icons.merge_type;
      case 'merge':
        return Icons.merge_type;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.rotate_right;
      default:
        return Icons.arrow_forward;
    }
  }
}
