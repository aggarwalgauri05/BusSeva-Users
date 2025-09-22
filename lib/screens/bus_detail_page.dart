// lib/screens/bus_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/route_model.dart';
import '../services/bus_tracking_service.dart';
import 'live_tracking_page.dart';
import '../booking_page.dart';

class BusDetailPage extends StatefulWidget {
  final String busId;
  final String routeId;
  
  const BusDetailPage({
    Key? key,
    required this.busId,
    required this.routeId,
  }) : super(key: key);
  
  @override
  _BusDetailPageState createState() => _BusDetailPageState();
}

class _BusDetailPageState extends State<BusDetailPage> {
  final BusTrackingService _trackingService = BusTrackingService();
  
  StreamSubscription<DocumentSnapshot>? _busSubscription;
  Map<String, dynamic>? _busData;
  BusRoute? _route;
  bool _isLoading = true;
  bool _smsAlertEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadBusDetails();
    _startBusTracking();
  }
  
  @override
  void dispose() {
    _busSubscription?.cancel();
    super.dispose();
  }
  
  void _loadBusDetails() async {
    try {
      // Load route information
      BusRoute route = await _trackingService.getRoute(widget.routeId);
      setState(() {
        _route = route;
      });
    } catch (e) {
      print('Error loading route: $e');
    }
  }
  
  void _startBusTracking() {
    _busSubscription = FirebaseFirestore.instance
        .collection('buses')
        .doc(widget.busId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _busData = snapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    });
  }
  
  String _getOccupancyStatus() {
    if (_busData == null) return 'Unknown';
    
    int occupancy = _busData!['occupancy'] ?? 0;
    int capacity = _busData!['totalCapacity'] ?? 45;
    double percentage = occupancy / capacity;
    
    if (percentage < 0.6) return 'Available';
    if (percentage < 0.9) return 'Filling';
    return 'Full';
  }
  
  Color _getOccupancyColor() {
    String status = _getOccupancyStatus();
    switch (status) {
      case 'Available': return Colors.green;
      case 'Filling': return Colors.orange;
      case 'Full': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  String _getBusStatus() {
    if (_busData == null) return 'Unknown';
    
    String status = _busData!['status'] ?? 'unknown';
    DateTime lastUpdate = (_busData!['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    // Check if bus data is stale (more than 5 minutes old)
    if (DateTime.now().difference(lastUpdate).inMinutes > 5) {
      return 'Offline';
    }
    
    switch (status) {
      case 'running': return 'On Route';
      case 'delayed': return 'Delayed';
      case 'breakdown': return 'Breakdown';
      case 'stopped': return 'At Stop';
      default: return 'Unknown';
    }
  }
  
  Color _getStatusColor() {
    String status = _getBusStatus();
    switch (status) {
      case 'On Route': return Colors.green;
      case 'Delayed': return Colors.orange;
      case 'Breakdown': return Colors.red;
      case 'At Stop': return Colors.blue;
      case 'Offline': return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _busData != null ? 'Bus ${_busData!["number"]}' : 'Bus Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareBusDetails(),
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
                    'Loading bus details...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBusInfoCard(),
                  SizedBox(height: 16),
                  _buildDriverInfoCard(),
                  SizedBox(height: 16),
                  _buildCurrentStatusCard(),
                  SizedBox(height: 16),
                  if (_route != null) _buildRouteCard(),
                  SizedBox(height: 16),
                  _buildNotificationCard(),
                  SizedBox(height: 20),
                  _buildActionButtons(),
                  SizedBox(height: 16),
                  _buildReviewSection(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildBusInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.blue[600],
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus ${_busData!["number"]}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_busData!['isAC'] ?? false) ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (_busData!['isAC'] ?? false) ? 'AC' : 'Non-AC',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: (_busData!['isAC'] ?? false) ? Colors.blue[700] : Colors.grey[700],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getOccupancyColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getOccupancyStatus(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getOccupancyColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(
                'Capacity',
                '${_busData!["occupancy"] ?? 0}/${_busData!["totalCapacity"] ?? 45}',
                Icons.people,
              ),
              SizedBox(width: 20),
              _buildInfoItem(
                'Rating',
                '${_busData!["rating"]?.toStringAsFixed(1) ?? "4.0"} ⭐',
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDriverInfoCard() {
    Map<String, dynamic> driverInfo = _busData!['driver'] ?? {};
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue[100],
                child: Icon(
                  Icons.person,
                  color: Colors.blue[600],
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          driverInfo['name'] ?? 'Unknown Driver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (driverInfo['isVerified'] == true)
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 18,
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'License: ${driverInfo['license'] ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Last authenticated: ${_formatLastAuth(driverInfo['lastAuth'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentStatusCard() {
    GeoPoint? currentLocation = _busData!['currentLocation'];
    String currentStop = _busData!['currentStop'] ?? 'Between stops';
    DateTime lastUpdate = (_busData!['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getBusStatus(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Currently at: $currentStop',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          Row(
            children: [
              Icon(Icons.update, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Last updated: ${_formatTime(lastUpdate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          if (currentLocation != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Location: ${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildRouteCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          
          Text(
            _route!.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 8),
          
          Row(
            children: [
              Icon(Icons.route, color: Colors.grey[600], size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_route!.stops.first.name} → ${_route!.stops.last.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              SizedBox(width: 4),
              Text(
                _route!.estimatedDuration,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.straighten, color: Colors.grey[600], size: 16),
              SizedBox(width: 4),
              Text(
                '${_route!.totalDistance.toStringAsFixed(0)} km',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.sms, color: Colors.blue[600], size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Get notified when bus is 2 stops away',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _smsAlertEnabled,
                onChanged: (value) {
                  setState(() {
                    _smsAlertEnabled = value;
                  });
                  _toggleSMSAlert(value);
                },
                activeColor: Colors.blue[600],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveTrackingPage(busId: widget.busId),
                    ),
                  );
                },
                icon: Icon(Icons.track_changes),
                label: Text('Track Live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingPage(
                        busId: widget.busId,
                        routeId: widget.routeId, busData: {},
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.book_online),
                label: Text('Book Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        OutlinedButton.icon(
          onPressed: () => _reportGhostBus(),
          icon: Icon(Icons.report_problem, color: Colors.red[600]),
          label: Text(
            'Report Ghost Bus',
            style: TextStyle(color: Colors.red[600]),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red[300]!),
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildReviewSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () => _showAllReviews(),
                child: Text('See All'),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Placeholder for recent reviews
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, size: 14, color: Colors.blue[600]),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Recent Passenger',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    Spacer(),
                    Text(
                      '⭐ 4.5',
                      style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Good service, on time. Driver was professional.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          Center(
            child: TextButton(
              onPressed: () => _showReviewDialog(),
              child: Text('Write a Review (after trip)'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  
  String _formatLastAuth(dynamic lastAuth) {
    if (lastAuth == null) return 'Unknown';
    if (lastAuth is Timestamp) {
      return _formatTime(lastAuth.toDate());
    }
    return 'Unknown';
  }
  
  void _shareBusDetails() {
    String message = 'Track Bus ${_busData!["number"]} live on BusSeva App!';
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality will be implemented soon!'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
  
  void _toggleSMSAlert(bool enabled) {
    // Implement SMS alert toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'SMS alerts enabled' : 'SMS alerts disabled',
        ),
        backgroundColor: enabled ? Colors.green[600] : Colors.grey[600],
      ),
    );
  }
  
  void _reportGhostBus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Report Ghost Bus'),
          ],
        ),
        content: Text(
          'Are you sure this bus is not running? This will help other passengers avoid disappointment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitGhostBusReport();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _submitGhostBusReport() {
    // Implement ghost bus reporting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ghost bus report submitted. Thank you!'),
        backgroundColor: Colors.orange[600],
      ),
    );
  }
  
  void _showAllReviews() {
    // Navigate to reviews page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reviews page coming soon!'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
  
  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write Review'),
        content: Text(
          'You can write a review after completing your trip with this bus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}