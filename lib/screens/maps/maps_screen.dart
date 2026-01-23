import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';
import 'package:lakbyke_mobile/screens/template/chat_fab.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(14.5995, 120.9842); // Default to Manila, Philippines
  bool _isLoading = true;
  String? _errorMessage;
  
  // Directions
  final TextEditingController _destinationController = TextEditingController();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _destination;
  bool _isLoadingDirections = false;
  String? _routeDistance = '';
  String? _routeDuration = '';
  List<Map<String, dynamic>> _directionsSteps = [];
  bool _showDirectionsPanel = false;
  
  // Real-time navigation
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  double _distanceToNextTurn = 0.0;
  Map<String, dynamic>? _currentInstruction;
  String _googleMapsApiKey = 'AIzaSyCiuyIvt52hTNwThuyx2HSdCGJtIewKV0Q';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _stopNavigation();
    _mapController?.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Move camera to current position
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
      );
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _errorMessage = 'Unable to get current location.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getDirections(String destination) async {
    if (destination.isEmpty) return;
    
    setState(() {
      _isLoadingDirections = true;
    });

    try {
      // Use Google Geocoding API to get destination coordinates
      // Add region parameter to bias results (PH for Philippines)
      final geocodeUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(destination)}&region=ph&key=$_googleMapsApiKey',
      );
      
      print('Geocoding URL: $geocodeUrl');
      
      http.Response geocodeResponse;
      try {
        geocodeResponse = await http.get(
          geocodeUrl,
          headers: {
            'Accept': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Geocoding request timed out');
          },
        );
      } catch (e) {
        print('Error fetching geocode: $e');
        setState(() {
          _isLoadingDirections = false;
        });
        if (mounted) {
          String errorMessage = 'Failed to search location';
          final errorString = e.toString().toLowerCase();
          
          if (errorString.contains('failed to fetch') || 
              errorString.contains('cors') || 
              errorString.contains('network') ||
              errorString.contains('clientexception')) {
            errorMessage = 'Network error: Check API key restrictions. Ensure Geocoding API is enabled.';
          } else if (e is TimeoutException) {
            errorMessage = 'Request timed out. Please try again.';
          } else {
            errorMessage = 'Error: ${e.toString()}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      if (geocodeResponse.statusCode != 200) {
        setState(() {
          _isLoadingDirections = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('HTTP Error ${geocodeResponse.statusCode}: Could not search location'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final geocodeData = json.decode(geocodeResponse.body);
      
      // Debug: Print the response
      print('Geocoding Response Status: ${geocodeData['status']}');
      print('Geocoding Response: ${geocodeResponse.body}');
      
      // Check for API errors
      if (geocodeData['status'] != null && geocodeData['status'] != 'OK') {
        final status = geocodeData['status'] as String;
        final errorMessage = geocodeData['error_message'] as String? ?? 'Unknown error';
        
        setState(() {
          _isLoadingDirections = false;
        });
        
        if (mounted) {
          String userMessage = 'Could not find the location';
          
          if (status == 'REQUEST_DENIED') {
            userMessage = 'Geocoding API not enabled or API key invalid. Please enable Geocoding API in Google Cloud Console.';
          } else if (status == 'OVER_QUERY_LIMIT') {
            userMessage = 'API quota exceeded. Please check your billing.';
          } else if (status == 'ZERO_RESULTS') {
            userMessage = 'No results found for "$destination". Please try a different location.';
          } else if (status == 'INVALID_REQUEST') {
            userMessage = 'Invalid search query. Please enter a valid address or place name.';
          } else {
            userMessage = 'Error: $status - $errorMessage';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        
        print('Geocoding API Error: $status - $errorMessage');
        return;
      }
      
      if (geocodeData['results'] == null || geocodeData['results'].isEmpty) {
        setState(() {
          _isLoadingDirections = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No results found for "$destination". Please try a different location.'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final location = geocodeData['results'][0]['geometry']['location'];
      final destLatLng = LatLng(
        location['lat'] as double,
        location['lng'] as double,
      );
      
      setState(() {
        _destination = destLatLng;
      });

      // Get directions using Google Directions API
      final directionsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_currentPosition.latitude},${_currentPosition.longitude}&'
        'destination=${destLatLng.latitude},${destLatLng.longitude}&'
        'key=$_googleMapsApiKey',
      );

      http.Response directionsResponse;
      try {
        directionsResponse = await http.get(
          directionsUrl,
          headers: {
            'Accept': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Directions request timed out');
          },
        );
      } catch (e) {
        print('Error fetching directions: $e');
        print('Error type: ${e.runtimeType}');
        setState(() {
          _isLoadingDirections = false;
        });
        if (mounted) {
          String errorMessage = 'Failed to get directions';
          final errorString = e.toString().toLowerCase();
          
          if (errorString.contains('failed to fetch') || 
              errorString.contains('cors') || 
              errorString.contains('network') ||
              errorString.contains('clientexception')) {
            errorMessage = 'Network/CORS error: Check API key HTTP referrer restrictions in Google Cloud Console. Add "localhost:*" and "127.0.0.1:*" for local development.';
          } else if (e is TimeoutException) {
            errorMessage = 'Request timed out. Please try again.';
          } else {
            errorMessage = 'Error: ${e.toString()}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Details',
                onPressed: () {
                  print('Full error details: $e');
                },
              ),
            ),
          );
        }
        return;
      }
      
      if (directionsResponse.statusCode != 200) {
        setState(() {
          _isLoadingDirections = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('HTTP Error ${directionsResponse.statusCode}: Could not get directions'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final directionsData = json.decode(directionsResponse.body);
      
      // Check for API errors
      if (directionsData['status'] != null && directionsData['status'] != 'OK') {
        final status = directionsData['status'] as String;
        final errorMessage = directionsData['error_message'] as String? ?? 'Unknown error';
        
        setState(() {
          _isLoadingDirections = false;
        });
        
        if (mounted) {
          String userMessage = 'Could not get directions';
          
          if (status == 'REQUEST_DENIED') {
            userMessage = 'Directions API not enabled or API key invalid. Please enable Directions API in Google Cloud Console.';
          } else if (status == 'OVER_QUERY_LIMIT') {
            userMessage = 'API quota exceeded. Please check your billing.';
          } else if (status == 'INVALID_REQUEST') {
            userMessage = 'Invalid request. Please check your origin and destination.';
          } else {
            userMessage = 'Error: $status - $errorMessage';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        
        print('Directions API Error: $status - $errorMessage');
        return;
      }

      if (directionsData['routes'] == null || directionsData['routes'].isEmpty) {
        setState(() {
          _isLoadingDirections = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not calculate route')),
          );
        }
        return;
      }

      // Extract route
      final route = directionsData['routes'][0];
      final leg = route['legs'][0];
      
      // Get distance and duration
      final distance = leg['distance']['value'] as int; // in meters
      final duration = leg['duration']['value'] as int; // in seconds
      
      final distanceKm = (distance / 1000).toStringAsFixed(1);
      final durationMins = (duration / 60).round();

      // Decode polyline
      final overviewPolyline = route['overview_polyline']['points'];
      List<LatLng> points = _decodePolyline(overviewPolyline);

      // Extract turn-by-turn directions
      List<Map<String, dynamic>> steps = [];
      if (leg['steps'] != null) {
        for (var step in leg['steps']) {
          final htmlInstruction = step['html_instructions'] as String? ?? '';
          // Remove HTML tags
          final instruction = htmlInstruction
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .trim();
          
          final distance = step['distance']['value'] as int;
          final duration = step['duration']['value'] as int;
          final distanceText = distance > 1000 
              ? '${(distance / 1000).toStringAsFixed(1)} km'
              : '$distance m';
          
          // Get maneuver type
          final maneuver = step['maneuver']?.toString().toLowerCase() ?? '';
          final icon = _getManeuverIconFromManeuver(maneuver);
          
          steps.add({
            'instruction': instruction,
            'distance': distanceText,
            'duration': duration > 60 ? '${(duration / 60).round()} min' : '$duration sec',
            'maneuver': maneuver,
            'icon': icon,
          });
        }
      }

      // Update markers
      _markers = {
        Marker(
          markerId: const MarkerId('origin'),
          position: _currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: destLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };

      // Update polyline
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: const Color(0xFF317263),
          width: 5,
        ),
      };

      setState(() {
        _routeDistance = '$distanceKm km';
        _routeDuration = '$durationMins mins';
        _directionsSteps = steps;
        _isLoadingDirections = false;
        _showDirectionsPanel = steps.isNotEmpty;
        _currentStepIndex = 0;
        _isNavigating = steps.isNotEmpty;
        if (steps.isNotEmpty) {
          _currentInstruction = steps[0];
          _calculateDistanceToNextTurn();
        }
      });
      
      // Start real-time navigation if we have steps
      if (steps.isNotEmpty) {
        _startNavigation();
      }

      // Fit bounds to show entire route
      if (points.isNotEmpty) {
        double minLat = points[0].latitude;
        double maxLat = points[0].latitude;
        double minLng = points[0].longitude;
        double maxLng = points[0].longitude;

        for (var point in points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            100.0,
          ),
        );
      }
    } catch (e) {
      print('Error getting directions: $e');
      setState(() {
        _isLoadingDirections = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _clearDirections() {
    _stopNavigation();
    setState(() {
      _polylines.clear();
      _markers.clear();
      _destination = null;
      _routeDistance = '';
      _routeDuration = '';
      _directionsSteps.clear();
      _showDirectionsPanel = false;
      _isNavigating = false;
      _currentStepIndex = 0;
      _currentInstruction = null;
      _distanceToNextTurn = 0.0;
    });
    // Move camera to current position
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
    );
  }
  
  void _startNavigation() {
    if (_isNavigating && _positionStreamSubscription == null) {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      );
      
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPosition;
        });
        
        // Update navigation
        _updateNavigation(newPosition);
        
        // Update map camera to follow user
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newPosition),
        );
      });
    }
  }
  
  void _stopNavigation() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _isNavigating = false;
    });
  }
  
  void _updateNavigation(LatLng currentPos) {
    if (_directionsSteps.isEmpty) return;
    
    // Calculate distance to next turn (simplified)
    // In a real implementation, you'd calculate distance along the route
    if (_currentStepIndex < _directionsSteps.length) {
      // Estimate distance based on step index
      final remainingSteps = _directionsSteps.length - _currentStepIndex;
      final estimatedDistance = remainingSteps * 200.0; // Rough estimate
      
      setState(() {
        _distanceToNextTurn = estimatedDistance;
      });
      
      // Auto-advance to next step (simplified logic)
      // In production, you'd use actual route matching
      if (_distanceToNextTurn < 50 && _currentStepIndex < _directionsSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
          _currentInstruction = _directionsSteps[_currentStepIndex];
        });
      }
    }
  }
  
  void _calculateDistanceToNextTurn() {
    if (_currentStepIndex >= _directionsSteps.length - 1) {
      setState(() {
        _distanceToNextTurn = 0.0;
      });
      return;
    }
    
    // Simplified distance calculation
    // In production, calculate actual distance along route
    setState(() {
      _distanceToNextTurn = 200.0; // Placeholder
    });
  }
  
  IconData _getManeuverIconFromManeuver(String maneuver) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      floatingActionButton: const ChatFAB(),
      body: Column(
        children: [
          const ScreenTitle(title: 'Maps'),
          // Destination search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Enter destination address...',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _getDirections(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_destination != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearDirections,
                        tooltip: 'Clear route',
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoadingDirections
                          ? null
                          : () {
                              if (_destinationController.text.isNotEmpty) {
                                _getDirections(_destinationController.text);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF317263),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoadingDirections
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.directions),
                    ),
                  ],
                ),
                // Route information
                if (_routeDistance != null && _routeDistance!.isNotEmpty)
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF317263).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF317263).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.straighten, size: 20, color: Color(0xFF317263)),
                                const SizedBox(width: 8),
                                Text(
                                  'Distance: $_routeDistance',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF317263),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: Color(0xFF317263)),
                                const SizedBox(width: 8),
                                Text(
                                  'Duration: $_routeDuration',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF317263),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Directions toggle button
                      if (_directionsSteps.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showDirectionsPanel = !_showDirectionsPanel;
                              });
                            },
                            icon: Icon(_showDirectionsPanel ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                            label: Text(_showDirectionsPanel ? 'Hide Directions' : 'Show Directions (${_directionsSteps.length} steps)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF317263),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          // Real-time navigation banner (like Waze)
          if (_isNavigating && _currentInstruction != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Navigation icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF317263).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _currentInstruction!['icon'] ?? Icons.arrow_forward,
                      color: const Color(0xFF317263),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Instruction text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentInstruction!['instruction'] ?? 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _distanceToNextTurn > 1000
                                  ? '${(_distanceToNextTurn / 1000).toStringAsFixed(1)} km'
                                  : '${_distanceToNextTurn.round()} m',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_currentStepIndex < _directionsSteps.length - 1) ...[
                              const SizedBox(width: 12),
                              Text(
                                'Step ${_currentStepIndex + 1} of ${_directionsSteps.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Stop navigation button
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.red),
                    onPressed: () {
                      _stopNavigation();
                      setState(() {
                        _isNavigating = false;
                        _currentInstruction = null;
                      });
                    },
                    tooltip: 'Stop navigation',
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _getCurrentLocation,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          GoogleMap(
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            initialCameraPosition: CameraPosition(
                              target: _currentPosition,
                              zoom: 15.0,
                            ),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            markers: _markers,
                            polylines: _polylines,
                            mapType: MapType.normal,
                          ),
                          // Directions panel overlay
                          if (_showDirectionsPanel && _directionsSteps.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Handle bar
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    // Header
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Turn-by-Turn Directions',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF317263),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              setState(() {
                                                _showDirectionsPanel = false;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    // Directions list
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: _directionsSteps.length,
                                        itemBuilder: (context, index) {
                                          final step = _directionsSteps[index];
                                          final icon = step['icon'] as IconData? ?? Icons.arrow_forward;
                                          final isFirst = index == 0;
                                          final isLast = index == _directionsSteps.length - 1;
                                          
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isFirst 
                                                  ? const Color(0xFF317263).withOpacity(0.1)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                              border: isFirst
                                                  ? Border.all(color: const Color(0xFF317263).withOpacity(0.3))
                                                  : null,
                                            ),
                                            child: ListTile(
                                              leading: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF317263).withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  icon,
                                                  color: const Color(0xFF317263),
                                                  size: 20,
                                                ),
                                              ),
                                              title: Text(
                                                step['instruction'] ?? 'Continue',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
                                                  color: isFirst ? const Color(0xFF317263) : Colors.black87,
                                                ),
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.straighten,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      step['distance'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              trailing: isFirst
                                                  ? Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF317263),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: const Text(
                                                        'START',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                  : isLast
                                                      ? Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green,
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: const Text(
                                                            'END',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        )
                                                      : Text(
                                                          '${index + 1}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                              dense: false,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
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
