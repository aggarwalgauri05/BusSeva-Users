// Replace your existing booking_confirmation_page.dart with this enhanced version:
import 'package:bus_seva/widgets/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';
import 'models/user_trip_model.dart';
import 'services/user_dashboard_service.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  
  const BookingConfirmationPage({Key? key, required this.bookingData}) : super(key: key);

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage>
    with TickerProviderStateMixin {
  late AnimationController _successController;
  late AnimationController _slideController;
  late Animation<double> _successAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _successController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _successController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _copyBookingId() {
    Clipboard.setData(ClipboardData(text: widget.bookingData['bookingId']));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking ID copied to clipboard'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareBooking() {
    String shareText = '''
🎫 BusSeva Booking Confirmed!

📍 From: ${widget.bookingData['from']}
📍 To: ${widget.bookingData['to']}
🚌 Bus: ${widget.bookingData['busNumber']}
💺 Seats: ${(widget.bookingData['selectedSeats'] as List).join(', ')}
💰 Fare: ₹${widget.bookingData['totalFare']}
🆔 Booking ID: ${widget.bookingData['bookingId']}

Happy Journey! 🚌✨
    ''';
    
    Share.share(shareText);
  }
// In your booking_confirmation_page.dart, add this after successful booking:
void _createUserTrip() async {
  final user = AuthService.currentUser;
  if (user == null) return;

  UserTrip trip = UserTrip(
    id: '', // Will be set by Firestore
    userId: user.uid,
    busId: widget.bookingData['busId'] ?? '',
    routeId: widget.bookingData['routeId'] ?? '',
    bookingId: widget.bookingData['bookingId'] ?? '',
    fromStopId: widget.bookingData['fromStopId'] ?? '',
    toStopId: widget.bookingData['toStopId'] ?? '',
    fromStopName: widget.bookingData['from'] ?? '',
    toStopName: widget.bookingData['to'] ?? '',
    seatNumbers: List<String>.from(widget.bookingData['selectedSeats'] ?? []),
    departureTime: DateTime.now().add(Duration(hours: 2)), // Set actual departure
    bookingDate: DateTime.now(),
    status: 'upcoming',
    totalFare: widget.bookingData['totalFare']?.toDouble() ?? 0.0,
    paymentMethod: widget.bookingData['paymentMethod'] ?? '',
    busNumber: widget.bookingData['busNumber'] ?? '',
    smsAlertsEnabled: false,
  );

  try {
    final dashboardService = UserDashboardService();
    await dashboardService.createTrip(trip);
  } catch (e) {
    print('Error creating user trip: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Success Animation
                      AnimatedBuilder(
                        animation: _successAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _successAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Success Text
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            const Text(
                              '🎉 Booking Confirmed!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your seats have been reserved successfully.\nShow this QR code to the conductor.',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF6B7280),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: widget.bookingData['bookingId'],
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _copyBookingId,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ID: ${widget.bookingData['bookingId'].toString().substring(0, 8)}...',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Booking Details
                      _buildBookingDetails(),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
              
              // Bottom Navigation
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow(Icons.route, 'Route', '${widget.bookingData['from']} → ${widget.bookingData['to']}'),
          _buildDetailRow(Icons.directions_bus, 'Bus Number', widget.bookingData['busNumber']),
          _buildDetailRow(Icons.event_seat, 'Seats', (widget.bookingData['selectedSeats'] as List).join(', ')),
          _buildDetailRow(Icons.people, 'Passengers', '${widget.bookingData['passengerCount']} ${widget.bookingData['passengerCount'] == 1 ? 'person' : 'people'}'),
          _buildDetailRow(Icons.payment, 'Payment', widget.bookingData['paymentMethod']),
          _buildDetailRow(Icons.currency_rupee, 'Total Fare', '₹${widget.bookingData['totalFare']}'),
          
          if (widget.bookingData['emergencyContact'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.emergency,
              'Emergency Contact',
              '${widget.bookingData['emergencyContact']['name']} - ${widget.bookingData['emergencyContact']['phone']}',
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF667EEA),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareBooking,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF667EEA),
              side: const BorderSide(color: Color(0xFF667EEA)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Download ticket as image/PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon!')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const MainBottomNavigation()),
);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // TODO: Navigate to trip tracking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live tracking will be available closer to departure time')),
              );
            },
            child: const Text(
              'Track Your Bus Live',
              style: TextStyle(
                color: Color(0xFF667EEA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
