// lib/screens/user_dashboard_screen.dart
import 'package:bus_seva/screens/in_trip_dashboard_screen.dart';
import 'package:bus_seva/screens/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_trip_model.dart';
import '../services/user_dashboard_service.dart';
import '../services/auth_service.dart';
import 'trip_detail_screen.dart';
import 'live_tracking_page.dart';
import '../home_screen.dart';
import 'in_trip_dashboard_screen.dart';
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with TickerProviderStateMixin {
  final UserDashboardService _dashboardService = UserDashboardService();
  late TabController _tabController;
  void _openInTripDashboard(UserTrip trip) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InTripDashboardScreen(trip: trip),
    ),
  );
}
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Please sign in to view your trips',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'My Trips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.upcoming),
              text: 'Upcoming',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTripsTab(),
          _buildTripHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildUpcomingTripsTab() {
  return StreamBuilder<List<UserTrip>>(
    stream: _dashboardService.getUpcomingTrips(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        print('Dashboard error: ${snapshot.error}'); // Debug log
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              SizedBox(height: 16),
              Text('Error loading trips'),
              SizedBox(height: 8),
              Text(
                'Error: ${snapshot.error}', // Show actual error
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {}),
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }

      final trips = snapshot.data ?? [];
      
      if (trips.isEmpty) {
        return _buildEmptyState(
          icon: Icons.directions_bus,
          title: 'No Upcoming Trips',
          subtitle: 'Book your next journey from the home screen',
          actionButton: ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            ),
            child: Text('Book a Trip'),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            return _buildTripCard(trips[index], isUpcoming: true);
          },
        ),
      );
    },
  );
}

  Widget _buildTripHistoryTab() {
    return StreamBuilder<List<UserTrip>>(
      stream: _dashboardService.getTripHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading trip history'));
        }

        final trips = snapshot.data ?? [];

        if (trips.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No Trip History',
            subtitle: 'Your completed trips will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            return _buildTripCard(trips[index], isUpcoming: false);
          },
        );
      },
    );
  }

  Widget _buildTripCard(UserTrip trip, {required bool isUpcoming}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          // Trip header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.fromStopName} → ${trip.toStopName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bus ${trip.busNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(trip.status),
            ],
          ),

          SizedBox(height: 16),

          // Trip details
          Row(
            children: [
              _buildDetailItem(
                Icons.event_seat,
                'Seats',
                trip.seatNumbers.join(', '),
              ),
              SizedBox(width: 20),
              _buildDetailItem(
                Icons.currency_rupee,
                'Fare',
                '₹${trip.totalFare.toStringAsFixed(0)}',
              ),
              SizedBox(width: 20),
              _buildDetailItem(
                Icons.schedule,
                'Departure',
                _formatTime(trip.departureTime),
              ),
            ],
          ),

          if (isUpcoming) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 12),
            _buildUpcomingTripActions(trip),
          ] else ...[
            SizedBox(height: 12),
            _buildHistoryTripActions(trip),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String displayText;
    
    switch (status) {
      case 'upcoming':
        color = Colors.blue;
        displayText = 'Upcoming';
        break;
      case 'ongoing':
        color = Colors.green;
        displayText = 'In Progress';
        break;
      case 'completed':
        color = Colors.grey;
        displayText = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        displayText = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        displayText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Color(0xFF6B7280)),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTripActions(UserTrip trip) {
    return Column(
      children: [
        // Real-time status section
        FutureBuilder<Map<String, dynamic>?>(
          future: _dashboardService.getBusStatusForTrip(trip),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading bus status...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 12),
                    Text(
                      'Bus status unavailable',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ),
              );
            }

            final busStatus = snapshot.data!;
            return _buildBusStatusSection(trip, busStatus);
          },
        ),

        SizedBox(height: 12),

        // Action buttons
        Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showTripDetails(trip),
              icon: Icon(Icons.info_outline, size: 16),
              label: Text('Details', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF667EEA),
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          if (trip.status == 'ongoing') // ADD THIS CONDITION
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openInTripDashboard(trip), // NEW METHOD
                icon: Icon(Icons.dashboard, size: 16),
                label: Text('Trip', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEF4444), // Red for active trip
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _trackBusLive(trip),
                icon: Icon(Icons.my_location, size: 16),
                label: Text('Track', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareTripDetails(trip),
              icon: Icon(Icons.share, size: 16),
              label: Text('Share', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF6B7280),
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}


  Widget _buildBusStatusSection(UserTrip trip, Map<String, dynamic> busStatus) {
    final busData = busStatus['busData'] as Map<String, dynamic>;
    final occupancy = busStatus['occupancy'] as int;
    final totalCapacity = busStatus['totalCapacity'] as int;
    final currentLocation = busStatus['currentLocation'] as String;
    final eta = busStatus['eta'] as String;
    final isDelayed = busStatus['isDelayed'] as bool;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA).withOpacity(0.1),
            Color(0xFF764BA2).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF667EEA).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF667EEA), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentLocation,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (isDelayed)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DELAYED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              // Occupancy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Color(0xFF6B7280)),
                        SizedBox(width: 4),
                        Text(
                          '$occupancy/$totalCapacity seats',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: occupancy / totalCapacity,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getOccupancyColor(occupancy / totalCapacity),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // ETA
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Color(0xFF6B7280)),
                      SizedBox(width: 4),
                      Text(
                        'ETA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    eta,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              // SMS Alert Toggle
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.sms, size: 16, color: Color(0xFF6B7280)),
                    SizedBox(width: 8),
                    Text(
                      'SMS Alert',
                      style: TextStyle(fontSize: 12),
                    ),
                    Spacer(),
                    Switch(
                      value: trip.smsAlertsEnabled,
                      onChanged: (value) => _toggleSMSAlert(trip.id, value),
                      activeColor: Color(0xFF10B981),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),

              // Report Ghost Bus
              TextButton.icon(
                onPressed: () => _showReportGhostBusDialog(trip),
                icon: Icon(Icons.report_problem, size: 16, color: Colors.red),
                label: Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTripActions(UserTrip trip) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showTripDetails(trip),
          icon: const Icon(Icons.receipt, size: 16),
          label: const Text('View Receipt', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF667EEA),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      if (trip.status == 'completed') ...[
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToReview(trip),
            icon: const Icon(Icons.star, size: 16),
            label: const Text('Review', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    ],
  );
}

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Color(0xFFE5E7EB),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
            if (actionButton != null) ...[
              SizedBox(height: 24),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Color _getOccupancyColor(double percentage) {
    if (percentage < 0.6) return Colors.green;
    if (percentage < 0.9) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showTripDetails(UserTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(trip: trip),
      ),
    );
  }
void _navigateToReview(UserTrip trip) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReviewScreen(trip: trip),
    ),
  );
}
  void _trackBusLive(UserTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingPage(busId: trip.busId),
      ),
    );
  }

  void _shareTripDetails(UserTrip trip) {
    final shareText = '''
🚌 BusSeva Trip Details
📍 ${trip.fromStopName} → ${trip.toStopName}
🚌 Bus: ${trip.busNumber}
💺 Seats: ${trip.seatNumbers.join(', ')}
🕐 Departure: ${_formatTime(trip.departureTime)}
💰 Fare: ₹${trip.totalFare.toStringAsFixed(0)}
🆔 Booking: ${trip.bookingId}
    ''';
    
    Share.share(shareText);
  }

  void _toggleSMSAlert(String tripId, bool enabled) async {
    try {
      await _dashboardService.toggleSMSAlert(tripId, enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'SMS alerts enabled' : 'SMS alerts disabled'),
          backgroundColor: enabled ? Colors.green : Colors.grey[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update SMS alerts'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportGhostBusDialog(UserTrip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red),
            SizedBox(width: 8),
            Text('Report Ghost Bus'),
          ],
        ),
        content: Text(
          'Are you sure this bus is not running as scheduled? This will help other passengers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dashboardService.reportGhostBus(
                  trip.busId,
                  'Bus not running as per schedule',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ghost bus report submitted'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to submit report'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(UserTrip trip) {
    // Implementation for review dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate Your Trip'),
        content: Text('Review functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
}