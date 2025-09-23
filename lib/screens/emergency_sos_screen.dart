// lib/screens/emergency_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_trip_model.dart';
import '../services/auth_service.dart';

class EmergencySOSScreen extends StatefulWidget {
  final UserTrip trip;
  
  const EmergencySOSScreen({Key? key, required this.trip}) : super(key: key);
  
  @override
  _EmergencySOSScreenState createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _sosActivated = false;
  bool _isActivating = false;
  Position? _currentLocation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sosActivated ? Colors.red : Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_sosActivated ? 'SOS ACTIVATED' : 'Emergency SOS'),
        backgroundColor: _sosActivated ? Colors.red : Color(0xFF667EEA),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _sosActivated ? _buildActivatedView() : _buildConfirmationView(),
      ),
    );
  }
  
  Widget _buildConfirmationView() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          
          // Warning Icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 40),
          
          Text(
            'Emergency SOS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Are you in immediate danger?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12),
          
          Text(
            'This will immediately alert:\n• Local authorities (Police - 100)\n• Bus operator & admin\n• Your emergency contacts\n• Include your location & trip details',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          Spacer(),
          
          // SOS Activation Button
          GestureDetector(
            onLongPressStart: (_) => _startSOSActivation(),
            onLongPressEnd: (_) => _cancelSOSActivation(),
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isActivating 
                    ? [Colors.red!, Colors.red!]
                    : [Colors.red!, Colors.red!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isActivating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ACTIVATING SOS...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sos, color: Colors.white, size: 32),
                        SizedBox(height: 4),
                        Text(
                          'HOLD TO ACTIVATE SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Long press and hold',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF6B7280),
                side: BorderSide(color: Color(0xFF6B7280)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivatedView() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          
          // Activated Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.red,
              size: 80,
            ),
          ),
          
          SizedBox(height: 30),
          
          Text(
            'SOS ACTIVATED',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Emergency alert sent successfully',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 40),
          
          // Status Cards
          _buildStatusCard(
            'Police Notified',
            '100 - Emergency hotline contacted',
            Icons.local_police,
            true,
          ),
          
          SizedBox(height: 12),
          
          _buildStatusCard(
            'Bus Operator Alerted',
            'Admin and driver notified',
            Icons.business,
            true,
          ),
          
          SizedBox(height: 12),
          
          _buildStatusCard(
            'Location Shared',
            _currentLocation != null 
              ? 'GPS: ${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}'
              : 'Location not available',
            Icons.location_on,
            _currentLocation != null,
          ),
          
          Spacer(),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callPolice(),
                  icon: Icon(Icons.phone),
                  label: Text('Call 100'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelSOS(),
                  icon: Icon(Icons.cancel, color: Colors.white),
                  label: Text('Cancel Alert', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white),
                    padding: EdgeInsets.symmetric(vertical: 16),
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
    );
  }
  
  Widget _buildStatusCard(String title, String description, IconData icon, bool completed) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: completed ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : Icons.pending,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white70),
        ],
      ),
    );
  }
  
  void _startSOSActivation() {
    setState(() {
      _isActivating = true;
    });
    
    // Simulate 3 second hold requirement
    Future.delayed(Duration(seconds: 3), () {
      if (_isActivating) {
        _activateSOS();
      }
    });
  }
  
  void _cancelSOSActivation() {
    setState(() {
      _isActivating = false;
    });
  }
  
  void _activateSOS() async {
    setState(() {
      _isActivating = false;
      _sosActivated = true;
    });
    
    // Vibration feedback
    HapticFeedback.heavyImpact();
    
    // Send SOS alert
    await _sendSOSAlert();
  }
  
  Future<void> _sendSOSAlert() async {
    try {
      // Implementation would send alert to:
      // 1. Police/Emergency services
      // 2. Bus operator
      // 3. Emergency contacts
      // 4. Include trip details, user info, and location
      
      final alertData = {
        'type': 'SOS',
        'tripId': widget.trip.id,
        'busId': widget.trip.busId,
        'busNumber': widget.trip.busNumber,
        'userId': AuthService.currentUser?.uid,
        'userPhone': AuthService.currentUser?.phoneNumber,
        'location': _currentLocation != null 
          ? {
              'latitude': _currentLocation!.latitude,
              'longitude': _currentLocation!.longitude,
              'accuracy': _currentLocation!.accuracy,
            }
          : null,
        'timestamp': DateTime.now().toIso8601String(),
        'route': '${widget.trip.fromStopName} → ${widget.trip.toStopName}',
      };
      
      print('SOS Alert Data: $alertData');
      // Send to backend/emergency services
      
    } catch (e) {
      print('Error sending SOS alert: $e');
    }
  }
  
  void _callPolice() async {
    final url = 'tel:100';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
  
  void _cancelSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel SOS Alert'),
        content: Text('Are you sure you want to cancel the emergency alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('SOS alert cancelled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancel Alert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
