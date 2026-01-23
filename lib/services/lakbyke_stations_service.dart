import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lakbyke_mobile/models/maps/lakbyke_station.dart';

/// Service providing Lakbyke station locations from Google Maps
/// Uses Geocoding API to get exact coordinates from addresses
class LakbykeStationsService {
  // Known Lakbyke station addresses (as they appear in Google Maps)
  static const List<Map<String, String>> _stationAddresses = [
    {
      'placeId': 'lakbyke_station_001',
      'name': 'Lakbyke Station 001',
      'address': 'Lakbyke Station 001, UCC Camarin, Caloocan, Metro Manila',
    },
    {
      'placeId': 'lakbyke_station_002',
      'name': 'Lakbyke Station 002',
      'address': 'Lakbyke Station 002, 23 Chrysanthemum St',
    },
    // Add more stations here as needed
    // Example:
    // {
    //   'placeId': 'lakbyke_station_003',
    //   'name': 'Lakbyke Station 003',
    //   'address': 'Lakbyke Station 003, Your Address Here',
    // },
  ];

  /// Get all known Lakbyke stations by geocoding their addresses
  /// This fetches exact coordinates from Google Maps
  static Future<List<LakbykeStation>> getAllStations(String apiKey) async {
    List<LakbykeStation> stations = [];

    for (var stationData in _stationAddresses) {
      try {
        // Use Geocoding API to get exact coordinates from Google Maps
        final geocodeUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
          'address=${Uri.encodeComponent(stationData['address']!)}&'
          'region=ph&'
          'key=$apiKey',
        );

        final response = await http.get(
          geocodeUrl,
          headers: {'Accept': 'application/json'},
        ).timeout(
          const Duration(seconds: 10),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' && 
              data['results'] != null && 
              data['results'].isNotEmpty) {
            final result = data['results'][0];
            final location = result['geometry']['location'];
            final formattedAddress = result['formatted_address'] as String? ?? 
                                    stationData['address']!;

            stations.add(LakbykeStation(
              placeId: stationData['placeId']!,
              name: stationData['name']!,
              address: formattedAddress,
              location: LatLng(
                (location['lat'] as num).toDouble(),
                (location['lng'] as num).toDouble(),
              ),
            ));
          }
        }
      } catch (e) {
        // If geocoding fails, skip this station
        // In production, you might want to log this
        continue;
      }
    }

    return stations;
  }

  /// Get stations sorted by distance from a given location
  static Future<List<LakbykeStation>> getStationsSortedByDistance(
    LatLng fromLocation,
    String apiKey,
  ) async {
    final stations = await getAllStations(apiKey);
    
    // Calculate distances
    final stationsWithDistance = stations.map((station) {
      final distance = station.calculateDistance(fromLocation);
      return LakbykeStation(
        placeId: station.placeId,
        name: station.name,
        address: station.address,
        location: station.location,
        distance: distance,
      );
    }).toList();
    
    // Sort by distance
    stationsWithDistance.sort((a, b) => 
      (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity)
    );
    
    return stationsWithDistance;
  }

  /// Get the nearest station from a given location
  static Future<LakbykeStation?> getNearestStation(
    LatLng fromLocation,
    String apiKey,
  ) async {
    final sortedStations = await getStationsSortedByDistance(fromLocation, apiKey);
    return sortedStations.isNotEmpty ? sortedStations[0] : null;
  }
}
