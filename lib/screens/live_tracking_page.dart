
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/route_model.dart';
import '../services/bus_tracking_service.dart';

class LiveTrackingPage extends StatefulWidget {
  final String busId;
  final bool showRoute;

  const LiveTrackingPage({
    Key? key,
    required this.busId,
    this.showRoute = true,
  }) : super(key: key);

  @override
  _LiveTrackingPageState createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  GoogleMapController? _mapController;
  final BusTrackingService _trackingService = BusTrackingService();

  StreamSubscription<DocumentSnapshot>? _busSubscription;
  StreamSubscription<Position>? _locationSubscription;

  Map<String, dynamic>? _busData;
  Position? _userLocation;
  BusRoute? _route;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isLoading = true;
  bool _followBus = true;
  bool _showUserLocation = false;
  
  // Default initial position (you can adjust this to your city center)
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(28.6139, 77.2090), // Delhi coordinates as example
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    await _getUserLocation();
    await _loadRouteData();
    _startBusTracking();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = position;
        _showUserLocation = true;
      });

      _updateUserLocationMarker();
    } catch (e) {
      print('Error getting user location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRouteData() async {
    try {
      DocumentSnapshot busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(widget.busId)
          .get();

      if (busDoc.exists) {
        Map<String, dynamic> busData = busDoc.data() as Map<String, dynamic>;
        String? routeId = busData['routeId'];

        if (routeId != null && widget.showRoute) {
          BusRoute route = await _trackingService.getRoute(routeId);
          setState(() {
            _route = route;
          });
          _drawRoute();
        }
      }
    } catch (e) {
      print('Error loading route data: $e');
    }
  }

  void _startBusTracking() {
    _busSubscription = FirebaseFirestore.instance
        .collection('buses')
        .doc(widget.busId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        Map<String, dynamic> newBusData = snapshot.data() as Map<String, dynamic>;

        setState(() {
          _busData = newBusData;
          _isLoading = false;
        });

        _updateBusMarker();

        if (_followBus && _mapController != null) {
          _centerOnBus();
        }
      }
    });
  }

  void _updateUserLocationMarker() {
    if (_userLocation == null) return;

    final userLatLng = LatLng(_userLocation!.latitude, _userLocation!.longitude);

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: userLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Your Location'),
    );

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == const MarkerId('user_location'));
      _markers.add(userMarker);
    });
  }

  void _updateBusMarker() {
    if (_busData == null || !_busData!.containsKey('location')) {
      // If no real location data, use sample coordinates
      final sampleLocation = LatLng(28.6139, 77.2090);
      
      final busMarker = Marker(
        markerId: const MarkerId('bus_marker'),
        position: sampleLocation,
        infoWindow: InfoWindow(
          title: 'Bus ${_busData?['busNumber'] ?? 'Unknown'}',
          snippet: 'Speed: ${_busData?['speed'] ?? '45'} km/h',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      setState(() {
        _markers.removeWhere((marker) => marker.markerId == const MarkerId('bus_marker'));
        _markers.add(busMarker);
      });
      return;
    }

    final GeoPoint location = _busData!['location'];
    final busPosition = LatLng(location.latitude, location.longitude);

    final busMarker = Marker(
      markerId: const MarkerId('bus_marker'),
      position: busPosition,
      infoWindow: InfoWindow(
        title: 'Bus ${_busData!['busNumber'] ?? 'Unknown'}',
        snippet: 'Speed: ${_busData!['speed'] ?? '-'} km/h',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == const MarkerId('bus_marker'));
      _markers.add(busMarker);
    });
  }

  void _centerOnBus() {
    if (_busData == null || !_busData!.containsKey('location') || _mapController == null) {
      return;
    }

    final location = _busData!['location'] as GeoPoint;
    final busPosition = LatLng(location.latitude, location.longitude);

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: busPosition,
          zoom: 16.0,
        ),
      ),
    );
  }

  void _drawRoute() {
    if (_route == null || _route!.polylinePoints.isEmpty) return;

    final polylinePoints = _route!.polylinePoints;

    final polyline = Polyline(
      polylineId: const PolylineId('route_polyline'),
      points: polylinePoints,
      color: const Color(0xFF667EEA),
      width: 5,
    );

    setState(() {
      _polylines = {polyline};
    });

    // Add route stop markers
    for (int i = 0; i < _route!.stops.length; i++) {
      final stop = _route!.stops[i];
      final stopMarker = Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: LatLng(stop.latitude, stop.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: stop.name),
      );
      
      _markers.add(stopMarker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_followBus ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () {
              setState(() {
                _followBus = !_followBus;
              });
              if (_followBus) _centerOnBus();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Container - FIXED HEIGHT AND PROPER CONSTRAINTS
          Container(
            height: MediaQuery.of(context).size.height * 0.3, // 60% of screen height
            width: double.infinity,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : GoogleMap(
                    initialCameraPosition: _userLocation != null
                        ? CameraPosition(
                            target: LatLng(_userLocation!.latitude, _userLocation!.longitude),
                            zoom: 14.0,
                          )
                        : _defaultCamera,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      // Initial setup after map is created
                      Future.delayed(Duration(seconds: 1), () {
                        if (_busData != null) _centerOnBus();
                      });
                    },
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: _showUserLocation,
                    myLocationButtonEnabled: false, // We have custom button
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                  ),
          ),
          
          // Bottom Content - Route Progress and Actions
          Expanded(
            child: Container(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBusStatusCard(),
                    const SizedBox(height: 16),
                    _buildEnhancedRouteProgress(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userLocation != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(_userLocation!.latitude, _userLocation!.longitude),
                  zoom: 16.0,
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.my_location),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBusStatusCard() {
    if (_busData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Bus data not available'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus ${_busData!['busNumber'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Driver: ${_busData!['driver']?['name'] ?? 'Unknown'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Rest of the widget methods remain the same...
  Widget _buildEnhancedRouteProgress() {
    final List<Map<String, dynamic>> routeStops = [
      {'name': 'City Center', 'status': 'completed', 'time': '10:00 AM', 'eta': null},
      {'name': 'Bus Stand', 'status': 'completed', 'time': '10:15 AM', 'eta': null},
      {'name': 'Hospital', 'status': 'current', 'time': '10:30 AM', 'eta': '2 mins'},
      {'name': 'College', 'status': 'upcoming', 'time': '10:45 AM', 'eta': '15 mins'},
      {'name': 'Railway Station', 'status': 'upcoming', 'time': '11:00 AM', 'eta': '28 mins'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Route Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    const Text('Bus Location:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('On Route', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.4, // Calculate based on current position
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: routeStops.length,
            itemBuilder: (context, index) {
              final stop = routeStops[index];
              final isLast = index == routeStops.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getStopColor(stop['status']),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _getStopIcon(stop['status']),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 50,
                          color: stop['status'] == 'completed' ? const Color(0xFF10B981) : Colors.grey[300],
                        ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Stop details
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stop['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: stop['status'] == 'current' ? const Color(0xFF667EEA) : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              if (stop['status'] == 'current')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Current',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                stop['time'],
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              if (stop['eta'] != null) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ETA: ${stop['eta']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStopColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'current':
        return const Color(0xFFFF6B35);
      case 'upcoming':
        return Colors.grey[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Widget _getStopIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check, size: 12, color: Colors.white);
      case 'current':
        return const Icon(Icons.directions_bus, size: 12, color: Colors.white);
      default:
        return const SizedBox();
    }
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    _initializeTracking();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refreshing location...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_location,
                  label: 'Share Location',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location shared!')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
