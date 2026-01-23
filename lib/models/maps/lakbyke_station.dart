import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model representing a Lakbyke charging station
class LakbykeStation {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;
  final double? distance; // Distance in meters from user's current location

  LakbykeStation({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    this.distance,
  });

  /// Create LakbykeStation from Google Places API response
  factory LakbykeStation.fromPlacesResponse(Map<String, dynamic> place) {
    final geometry = place['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    
    return LakbykeStation(
      placeId: place['place_id'] as String? ?? '',
      name: place['name'] as String? ?? 'Lakbyke Station',
      address: place['formatted_address'] as String? ?? 
               place['vicinity'] as String? ?? 
               'Address not available',
      location: LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      ),
    );
  }

  /// Calculate distance from a given location in meters using Haversine formula
  double calculateDistance(LatLng fromLocation) {
    const double earthRadius = 6371000; // meters
    
    final double lat1Rad = fromLocation.latitude * (math.pi / 180);
    final double lat2Rad = location.latitude * (math.pi / 180);
    final double deltaLatRad = (location.latitude - fromLocation.latitude) * (math.pi / 180);
    final double deltaLngRad = (location.longitude - fromLocation.longitude) * (math.pi / 180);
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Format distance as a readable string
  String getFormattedDistance() {
    if (distance == null) return 'Distance unknown';
    if (distance! < 1000) {
      return '${distance!.round()} m';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)} km';
    }
  }
}
