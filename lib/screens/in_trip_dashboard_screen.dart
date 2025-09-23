// lib/screens/in_trip_dashboard_screen.dart
// Update the imports in your in_trip_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_trip_model.dart';
import '../services/user_dashboard_service.dart';
import '../services/bus_tracking_service.dart';
import '../services/auth_service.dart';
import 'emergency_sos_screen.dart';
import 'harassment_report_screen.dart';
import 'malfunction_report_screen.dart';
import 'live_tracking_page.dart';


class InTripDashboardScreen extends StatefulWidget {
  final UserTrip trip;
  
  const InTripDashboardScreen({Key? key, required this.trip}) : super(key: key);
  
  @override
  _InTripDashboardScreenState createState() => _InTripDashboardScreenState();
}

class _InTripDashboardScreenState extends State<InTripDashboardScreen> {
  final UserDashboardService _dashboardService = UserDashboardService();
  final BusTrackingService _trackingService = BusTrackingService();
  
  Map<String, dynamic>? _busStatus;
  bool _isLoading = true;
  bool _showMap = false;
  Position? _userLocation;
  
  @override
  void initState() {
    super.initState();
    _loadTripData();
    _getUserLocation();
    
    // Update trip status to 'ongoing' if not already
    if (widget.trip.status == 'upcoming') {
      _updateTripStatus('ongoing');
    }
  }
  
  void _loadTripData() async {
    try {
      final busStatus = await _dashboardService.getBusStatusForTrip(widget.trip);
      setState(() {
        _busStatus = busStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }
  
  void _updateTripStatus(String status) async {
    // Update trip status in database
    // Implementation would update Firestore document
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderBar(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRouteProgress(),
                          SizedBox(height: 16),
                          _buildEmergencySection(),
                          SizedBox(height: 16),
                          _buildActionsGrid(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildMapToggleFAB(),
    );
  }
  
  Widget _buildHeaderBar() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.trip.busNumber,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          _getDriverName(),
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Text(
                  _getTripStatus(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRouteProgress() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 16),
          
          // Text Route
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _getCurrentStop(),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    child: LinearProgressIndicator(
                      value: _getRouteProgress(),
                      backgroundColor: Colors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    ),
                  ),
                ),
                Text(
                  _getNextStop(),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text('→'),
                SizedBox(width: 8),
                Text(
                  widget.trip.toStopName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667EEA),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // ETAs
          Row(
            children: [
              Expanded(
                child: _buildETACard(
                  'Next Stop',
                  _getNextStopETA(),
                  Icons.location_on,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildETACard(
                  'Destination',
                  _getDestinationETA(),
                  Icons.flag,
                  Color(0xFF667EEA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildETACard(String label, String eta, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            eta,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmergencySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Emergency & Safety',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSOSButton(),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildHarassmentButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPress: () => _showSOSConfirmation(),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red!, Colors.red!],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sos, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Long press',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHarassmentButton() {
    return GestureDetector(
      onTap: () => _openHarassmentReport(),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xFF6B7280),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_outlined, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Report Issue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              'Share Status',
              Icons.share_location,
              Color(0xFF10B981),
              () => _shareStatus(),
            ),
            _buildActionCard(
              'Report Issues',
              Icons.report_problem,
              Color(0xFFEF4444),
              () => _showReportOptions(),
            ),
            _buildActionCard(
              'Rate Experience',
              Icons.star_rate,
              Color(0xFFF59E0B),
              () => _showFeedbackDialog(),
            ),
            _buildActionCard(
              'Call Driver',
              Icons.phone,
              Color(0xFF3B82F6),
              () => _callDriver(),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMapToggleFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _toggleMap(),
      backgroundColor: Color(0xFF667EEA),
      label: Text(_showMap ? 'Hide Map' : 'View on Map'),
      icon: Icon(_showMap ? Icons.list : Icons.map),
    );
  }
  
  // Helper methods
  String _getDriverName() {
    return _busStatus?['busData']?['driver']?['name'] ?? 'Unknown Driver';
  }
  
  String _getTripStatus() {
    if (_busStatus?['isDelayed'] == true) return 'Delayed';
    return widget.trip.status == 'ongoing' ? 'In Transit' : 'Boarding';
  }
  
  Color _getStatusColor() {
    if (_busStatus?['isDelayed'] == true) return Colors.orange;
    return widget.trip.status == 'ongoing' ? Colors.green : Colors.blue;
  }
  
  String _getCurrentStop() {
    return _busStatus?['currentLocation'] ?? 'Unknown Location';
  }
  
  String _getNextStop() {
    // Implementation to get next stop
    return 'Next Stop';
  }
  
  double _getRouteProgress() {
    // Calculate progress based on current location
    return 0.6; // Example value
  }
  
  String _getNextStopETA() {
    return _busStatus?['eta'] ?? 'Calculating...';
  }
  
  String _getDestinationETA() {
    return '35 min'; // Calculate based on route data
  }
  
  // Action methods
  void _showSOSConfirmation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencySOSScreen(trip: widget.trip),
      ),
    );
  }
  
  void _openHarassmentReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HarassmentReportScreen(trip: widget.trip),
      ),
    );
  }
  
  void _shareStatus() {
    final location = _userLocation != null 
        ? 'My Location: ${_userLocation!.latitude.toStringAsFixed(6)}, ${_userLocation!.longitude.toStringAsFixed(6)}'
        : 'Location sharing not available';
    
    final status = '''
🚌 Live Trip Status - BusSeva

Bus: ${widget.trip.busNumber}
Route: ${widget.trip.fromStopName} → ${widget.trip.toStopName}
Status: ${_getTripStatus()}
Current: ${_getCurrentStop()}
ETA: ${_getDestinationETA()}

$location

Track my journey: [Trip Link]
    ''';
    
    Share.share(status);
  }
  
  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Report Issues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Malfunction / Safety Issue'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MalfunctionReportScreen(trip: widget.trip),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_car, color: Colors.red),
              title: Text('Rash Driving'),
              onTap: () {
                Navigator.pop(context);
                _reportRashDriving();
              },
            ),
            ListTile(
              leading: Icon(Icons.cleaning_services, color: Colors.blue),
              title: Text('Cleanliness Issue'),
              onTap: () {
                Navigator.pop(context);
                _reportCleanliness();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate Your Experience'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How is your trip so far?'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _submitRating(index + 1);
                  },
                  icon: Icon(Icons.star, color: Colors.amber),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  void _callDriver() async {
    final phoneNumber = _busStatus?['busData']?['driver']?['phone'] ?? '';
    if (phoneNumber.isNotEmpty) {
      final url = 'tel:$phoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver contact not available')),
      );
    }
  }
  
  void _toggleMap() {
    if (_showMap) {
      setState(() {
        _showMap = false;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveTrackingPage(busId: widget.trip.busId),
        ),
      );
    }
  }
  
  void _reportRashDriving() {
    // Implementation for rash driving report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rash driving report submitted')),
    );
  }
  
  void _reportCleanliness() {
    // Implementation for cleanliness report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleanliness issue reported')),
    );
  }
  
  void _submitRating(int rating) {
    // Submit rating to backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rating submitted: $rating stars')),
    );
  }
}
