import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lakbyke_mobile/core/presentation/widgets/header.dart';
import 'package:lakbyke_mobile/features/maps/domain/models/direction_step.dart';
import 'package:lakbyke_mobile/features/maps/domain/models/route_info.dart';
import 'package:lakbyke_mobile/features/maps/domain/models/polyline_decoder.dart';
import 'package:lakbyke_mobile/features/maps/domain/models/lakbyke_station.dart';
import 'package:lakbyke_mobile/features/maps/data/repositories/maps_repository.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key, this.isActive = true});

  /// When false, location is not requested (request only when Maps tab is opened).
  final bool isActive;

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(14.5995, 120.9842); // Default to Manila, Philippines
  bool _isLoading = true;
  String? _errorMessage;
  
  // Directions
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _destination;
  LakbykeStation? _selectedStation;
  bool _isLoadingDirections = false;
  String? _routeDistance = '';
  String? _routeDuration = '';
  List<DirectionStep> _directionsSteps = [];
  bool _showDirectionsPanel = false;
  
  // Real-time navigation
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  double _distanceToNextTurn = 0.0;
  DirectionStep? _currentInstruction;
  final String _googleMapsApiKey = 'AIzaSyCiuyIvt52hTNwThuyx2HSdCGJtIewKV0Q';
  
  // Lakbyke stations
  List<LakbykeStation> _lakbykeStations = [];
  LakbykeStation? _nearestStation;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _getCurrentLocation());
    }
  }

  @override
  void didUpdateWidget(covariant MapsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _getCurrentLocation());
    }
  }

  @override
  void dispose() {
    // Only cancel subscription; do not call _stopNavigation() (it calls setState).
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _mapController?.dispose();
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
      
      // Load Lakbyke stations after getting current location
      _loadLakbykeStations();
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to get current location.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getDirectionsToStation(LakbykeStation station) async {
    setState(() {
      _isLoadingDirections = true;
      _selectedStation = station;
      _destination = station.location;
    });

    try {
      final destLatLng = station.location;

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
                  // Error details removed
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

      // Extract route using RouteInfo model
      final route = directionsData['routes'][0];
      final overviewPolyline = route['overview_polyline']['points'];
      List<LatLng> points = PolylineDecoder.decode(overviewPolyline);
      
      final routeInfo = RouteInfo.fromDirectionsResponse(directionsData, points);

      // Update markers - keep station markers and add origin/destination
      final stationMarkers = _markers.where((m) => 
        m.markerId.value.startsWith('station_')
      ).toSet();
      
      _markers = {
        ...stationMarkers,
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
          points: routeInfo.polylinePoints,
          color: const Color(0xFF317263),
          width: 5,
        ),
      };

      setState(() {
        _routeDistance = routeInfo.distance;
        _routeDuration = routeInfo.duration;
        _directionsSteps = routeInfo.steps;
        _isLoadingDirections = false;
        _showDirectionsPanel = routeInfo.steps.isNotEmpty;
        _currentStepIndex = 0;
        _isNavigating = routeInfo.steps.isNotEmpty;
        if (routeInfo.steps.isNotEmpty) {
          _currentInstruction = routeInfo.steps[0];
          _calculateDistanceToNextTurn();
        }
      });
      
      // Start real-time navigation if we have steps
      if (routeInfo.steps.isNotEmpty) {
        _startNavigation();
      }

      // Fit bounds to show entire route
      if (routeInfo.polylinePoints.isNotEmpty) {
        double minLat = routeInfo.polylinePoints[0].latitude;
        double maxLat = routeInfo.polylinePoints[0].latitude;
        double minLng = routeInfo.polylinePoints[0].longitude;
        double maxLng = routeInfo.polylinePoints[0].longitude;

        for (var point in routeInfo.polylinePoints) {
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

  void _clearDirections() {
    _stopNavigation();
    setState(() {
      _polylines.clear();
      _destination = null;
      _selectedStation = null;
      _routeDistance = '';
      _routeDuration = '';
      _directionsSteps.clear();
      _showDirectionsPanel = false;
      _isNavigating = false;
      _currentStepIndex = 0;
      _currentInstruction = null;
      _distanceToNextTurn = 0.0;
    });
    // Remove only origin and destination markers, keep station markers
    _markers = _markers.where((m) => 
      m.markerId.value.startsWith('station_')
    ).toSet();
    // Re-add station markers if they exist
    if (_lakbykeStations.isNotEmpty) {
      _updateStationMarkers();
    }
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

  Future<void> _loadLakbykeStations() async {
    // Load stations by geocoding their addresses from Google Maps
    // This gets exact coordinates from the actual Google Maps locations
    try {
      final stations = await MapsRepository.getStationsSortedByDistance(
        _currentPosition,
        _googleMapsApiKey,
      );
      final nearest = await MapsRepository.getNearestStation(
        _currentPosition,
        _googleMapsApiKey,
      );

      setState(() {
        _lakbykeStations = stations;
        _nearestStation = nearest;
      });

      // Update markers to include stations
      _updateStationMarkers();
    } catch (e) {
      // Silently fail - stations are optional
      // In production, you might want to log this
    }
  }

  void _updateStationMarkers() {
    Set<Marker> stationMarkers = {};
    
    for (var station in _lakbykeStations) {
      final isNearest = station.placeId == _nearestStation?.placeId;
      
      stationMarkers.add(
        Marker(
          markerId: MarkerId('station_${station.placeId}'),
          position: station.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isNearest ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.address}\n${station.getFormattedDistance()}',
          ),
        ),
      );
    }

    // Merge with existing markers (origin/destination)
    setState(() {
      _markers = {
        ..._markers.where((m) => m.markerId.value == 'origin' || m.markerId.value == 'destination'),
        ...stationMarkers,
      };
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full-screen dark background (for the sides)
            Container(color: Colors.black),
            // 2. Main content area (white)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      // When no station chosen: show station picker. When chosen: only directions + map.
                      if (_destination == null) ...[
                        // Loading route indicator (uses _isLoadingDirections and _selectedStation)
                        if (_isLoadingDirections && _selectedStation != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Loading route to ${_selectedStation!.name}...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Lakbyke Stations list (only when no route)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              if (_lakbykeStations.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Loading stations...',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 64,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _lakbykeStations.length,
                                    itemBuilder: (context, index) {
                                      final station = _lakbykeStations[index];
                                      final isNearest = station.placeId == _nearestStation?.placeId;
                                      return Container(
                                        width: 200,
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: InkWell(
                                            onTap: () => _getDirectionsToStation(station),
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                gradient: isNearest
                                                    ? LinearGradient(
                                                        colors: [
                                                          const Color(0xFF317263).withOpacity(0.9),
                                                          const Color(0xFF317263),
                                                        ],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      )
                                                    : null,
                                                color: isNearest ? null : Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.ev_station,
                                                    color: isNearest ? Colors.white : const Color(0xFF317263),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        if (isNearest)
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.star, color: Colors.amber, size: 10),
                                                              const SizedBox(width: 2),
                                                              Text(
                                                                'Nearest',
                                                                style: TextStyle(
                                                                  color: Colors.white.withOpacity(0.9),
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        Text(
                                                          station.name,
                                                          style: TextStyle(
                                                            color: isNearest ? Colors.white : Colors.black87,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(
                                                          station.getFormattedDistance(),
                                                          style: TextStyle(
                                                            color: isNearest
                                                                ? Colors.white.withOpacity(0.9)
                                                                : Colors.grey[600],
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.directions,
                                                    color: isNearest ? Colors.white : const Color(0xFF317263),
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Station chosen: only directions strip + map (no station list)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Distance, duration, clear
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF317263).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF317263).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.straighten, size: 20, color: Color(0xFF317263)),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '$_routeDistance',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF317263),
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF317263).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF317263).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time, size: 20, color: Color(0xFF317263)),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '$_routeDuration',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF317263),
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: _clearDirections,
                                    icon: const Icon(Icons.close, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF317263),
                                      foregroundColor: Colors.white,
                                    ),
                                    tooltip: 'Clear route',
                                  ),
                                ],
                              ),
                              if (_directionsSteps.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _showDirectionsPanel = !_showDirectionsPanel;
                                      });
                                    },
                                    icon: Icon(
                                      _showDirectionsPanel ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      size: 20,
                                    ),
                                    label: Text(
                                      _showDirectionsPanel
                                          ? 'Hide directions'
                                          : 'Show directions (${_directionsSteps.length} steps)',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF317263),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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
                      _currentInstruction!.icon,
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
                          _currentInstruction!.instruction.isNotEmpty ? _currentInstruction!.instruction : 'Continue',
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
                                          final icon = step.icon;
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
                                                step.instruction.isNotEmpty ? step.instruction : 'Continue',
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
                                                      step.distance,
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
                ),
              ),
            ),
            // 3. Fixed Header overlay
            const Header(),
          ],
        ),
      ),
    );
  }
}
