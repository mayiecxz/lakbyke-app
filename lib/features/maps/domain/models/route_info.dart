import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'direction_step.dart';

/// Model representing route information including distance, duration, and steps
class RouteInfo {
  final String distance;
  final String duration;
  final List<DirectionStep> steps;
  final List<LatLng> polylinePoints;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.steps,
    required this.polylinePoints,
  });

  /// Create RouteInfo from Google Maps Directions API response
  factory RouteInfo.fromDirectionsResponse(
    Map<String, dynamic> directionsData,
    List<LatLng> decodedPolyline,
  ) {
    final route = directionsData['routes'][0];
    final leg = route['legs'][0];
    
    // Get distance and duration
    final distance = leg['distance']['value'] as int; // in meters
    final duration = leg['duration']['value'] as int; // in seconds
    
    final distanceKm = (distance / 1000).toStringAsFixed(1);
    final durationMins = (duration / 60).round();

    // Extract turn-by-turn directions
    List<DirectionStep> steps = [];
    if (leg['steps'] != null) {
      for (var step in leg['steps']) {
        final htmlInstruction = step['html_instructions'] as String? ?? '';
        // Remove HTML tags
        final instruction = htmlInstruction
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();
        
        final stepDistance = step['distance']['value'] as int;
        final stepDuration = step['duration']['value'] as int;
        final distanceText = stepDistance > 1000 
            ? '${(stepDistance / 1000).toStringAsFixed(1)} km'
            : '$stepDistance m';
        
        // Get maneuver type
        final maneuver = step['maneuver']?.toString().toLowerCase() ?? '';
        final icon = DirectionStep.getManeuverIcon(maneuver);
        
        steps.add(DirectionStep(
          instruction: instruction,
          distance: distanceText,
          duration: stepDuration > 60 ? '${(stepDuration / 60).round()} min' : '$stepDuration sec',
          maneuver: maneuver,
          icon: icon,
        ));
      }
    }

    return RouteInfo(
      distance: '$distanceKm km',
      duration: '$durationMins mins',
      steps: steps,
      polylinePoints: decodedPolyline,
    );
  }
}
