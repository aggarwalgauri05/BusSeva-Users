// lib/screens/live_tracking_page.dart
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
  CameraPosition? _initialCameraPosition;
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }
  
  @override
  void dispose() {
    _busSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
  
  void _initializeTracking() async {
    await _getUserLocation();
    await _loadRouteData();
    _startBusTracking();
  }
  
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
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
    }
  }
  
  Future<void> _loadRouteData() async {
    try {
      // Load route information
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
      if (snapshot.exists) {
        Map<String, dynamic> newBusData = snapshot.data() as Map<String, dynamic>;
        
        setState(() {
          _busData = newBusData;
          _isLoading = false;
        });
        
        _updateBusMarker();
        
        if (_followBus) {
          _centerOnBus();
        }
      }
    });
  }
  
  void _updateBusMarker() {
    if (_busData == null) return;
    
    GeoPoint? location = _busData!['currentLocation'];
    if (location == null) return;
    
    LatLng busPosition = LatLng(location.latitude, location.longitude);
    
    Marker busMarker = Marker(
      markerId: MarkerId('bus_${widget.busId}'),
      position: busPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Bus ${_busData!["number"] ?? widget.busId}',
        snippet: _getBusStatusSnippet(),
      ),
      onTap: () => _showBusInfo(),
    );
    
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('bus_'));
      _markers.add(busMarker);
    });
    
    // Set initial camera position if not set
    if (_initialCameraPosition == null) {
      _initialCameraPosition = CameraPosition(
        target: busPosition,
        zoom: 15,
      );
    }
  }
  
  void _updateUserLocationMarker() {
    if (_userLocation == null || !_showUserLocation) return;
    
    LatLng userPosition = LatLng(_userLocation!.latitude, _userLocation!.longitude);
    
    Marker userMarker = Marker(
      markerId: MarkerId('user_location'),
      position: userPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Your Location',
        snippet: 'Current position',
      ),
    );
    
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'user_location');
      _markers.add(userMarker);
    });
  }
  
  void _drawRoute() {
    if (_route == null) return;
    
    List<LatLng> routePoints = _route!.stops.map((stop) {
      return LatLng(stop.latitude, stop.longitude);
    }).toList();
    
    // Add route markers
    for (int i = 0; i < _route!.stops.length; i++) {
      RouteStop stop = _route!.stops[i];
      bool isTerminal = (i == 0 || i == _route!.stops.length - 1);
      
      Marker stopMarker = Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: LatLng(stop.latitude, stop.longitude),
        icon: isTerminal 
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: stop.name,
          snippet: '${stop.city} • ${stop.distanceFromStart.toStringAsFixed(1)} km',
        ),
      );
      
      setState(() {
        _markers.add(stopMarker);
      });
    }
    
    // Add route polyline
    Polyline routePolyline = Polyline(
      polylineId: PolylineId('route_${_route!.id}'),
      points: routePoints,
      color: Colors.blue,
      width: 3,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );
    
    setState(() {
      _polylines.add(routePolyline);
    });
  }
  
  void _centerOnBus() {
    if (_mapController == null || _busData == null) return;
    
    GeoPoint? location = _busData!['currentLocation'];
    if (location == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 16,
        ),
      ),
    );
  }
  
  void _fitMarkersInView() {
    if (_mapController == null || _markers.isEmpty) return;
    
    List<LatLng> positions = _markers.map((marker) => marker.position).toList();
    
    if (positions.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: positions[0], zoom: 15),
        ),
      );
      return;
    }
    
    double minLat = positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }
  
  String _getBusStatusSnippet() {
    if (_busData == null) return 'Loading...';
    
    String status = _busData!['status'] ?? 'unknown';
    int occupancy = _busData!['occupancy'] ?? 0;
    int capacity = _busData!['totalCapacity'] ?? 45;
    
    String statusText = status == 'running' ? 'On Route' : 
                       status == 'stopped' ? 'At Stop' : 
                       status == 'delayed' ? 'Delayed' : 'Unknown';
    
    return '$statusText • $occupancy/$capacity seats';
  }
  
  String _getLastUpdateText() {
    if (_busData == null) return 'No data';
    
    DateTime? lastUpdate = (_busData!['lastUpdate'] as Timestamp?)?.toDate();
    if (lastUpdate == null) return 'No updates';
    
    Duration diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
  
  Color _getStatusColor() {
    if (_busData == null) return Colors.grey;
    
    String status = _busData!['status'] ?? 'unknown';
    switch (status) {
      case 'running': return Colors.green;
      case 'delayed': return Colors.orange;
      case 'stopped': return Colors.blue;
      case 'breakdown': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showUserLocation ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() {
                _showUserLocation = !_showUserLocation;
              });
              if (_showUserLocation) {
                _getUserLocation();
              } else {
                setState(() {
                  _markers.removeWhere((marker) => marker.markerId.value == 'user_location');
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _centerOnBus,
          ),
          IconButton(
            icon: Icon(Icons.zoom_out_map),
            onPressed: _fitMarkersInView,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading live tracking...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: _initialCameraPosition ?? CameraPosition(
                    target: LatLng(28.6139, 77.2090), // Default to Delhi
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onCameraMove: (CameraPosition position) {
                    // Stop following bus when user manually moves the map
                    setState(() {
                      _followBus = false;
                    });
                  },
                  myLocationEnabled: false, // We handle this manually
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                ),
                
                // Bus info panel
                if (_busData != null) 
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildBusInfoPanel(),
                  ),
                
                // Follow bus button
                if (!_followBus)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () {
                        setState(() {
                          _followBus = true;
                        });
                        _centerOnBus();
                      },
                      backgroundColor: Colors.blue[600],
                      child: Icon(Icons.gps_fixed, color: Colors.white),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _buildBottomPanel(),
    );
  }
  
  Widget _buildBusInfoPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus ${_busData!["number"] ?? widget.busId}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _busData!['currentStop'] ?? 'Between stops',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _busData!['status'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              _buildQuickInfo(
                Icons.people, 
                '${_busData!["occupancy"] ?? 0}/${_busData!["totalCapacity"] ?? 45}',
                'Seats'
              ),
              SizedBox(width: 20),
              _buildQuickInfo(
                Icons.update, 
                _getLastUpdateText(),
                'Updated'
              ),
              if (_userLocation != null && _busData!['currentLocation'] != null) ...[
                SizedBox(width: 20),
                _buildQuickInfo(
                  Icons.straighten, 
                  '${_calculateDistance().toStringAsFixed(1)} km',
                  'Away'
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickInfo(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareLocation(),
              icon: Icon(Icons.share_location, size: 18),
              label: Text('Share', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _bookThisBus(),
              icon: Icon(Icons.book_online, size: 18),
              label: Text('Book', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _getSMSUpdates(),
              icon: Icon(Icons.sms, size: 18),
              label: Text('SMS', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  double _calculateDistance() {
    if (_userLocation == null || _busData!['currentLocation'] == null) return 0;
    
    GeoPoint busLocation = _busData!['currentLocation'];
    return Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      busLocation.latitude,
      busLocation.longitude,
    ) / 1000; // Convert to kilometers
  }
  
  void _showBusInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            Text(
              'Bus ${_busData!["number"]}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            _buildDetailRow('Driver', _busData!['driver']?['name'] ?? 'Unknown'),
            _buildDetailRow('Route', _route?.name ?? 'Loading...'),
            _buildDetailRow('Status', _busData!['status'] ?? 'Unknown'),
            _buildDetailRow('Occupancy', '${_busData!["occupancy"] ?? 0}/${_busData!["totalCapacity"] ?? 45} seats'),
            _buildDetailRow('Last Update', _getLastUpdateText()),
            
            Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to previous screen
                },
                child: Text('View Full Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share location feature coming soon!'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
  
  void _bookThisBus() {
    Navigator.pop(context);
    // Navigate to booking page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking feature will be available soon!'),
        backgroundColor: Colors.green[600],
      ),
    );
  }
  
  void _getSMSUpdates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sms, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('SMS Updates'),
          ],
        ),
        content: Text(
          'Get SMS notifications about this bus location and arrival time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('SMS updates enabled!'),
                  backgroundColor: Colors.green[600],
                ),
              );
            },
            child: Text('Enable'),
          ),
        ],
      ),
    );
  }
}