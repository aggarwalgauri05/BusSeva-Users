// lib/screens/trip_completion_screen.dart
import 'package:flutter/material.dart';
import '../models/user_trip_model.dart';
import '../services/user_dashboard_service.dart';
import 'trip_review_screen.dart';
import '../home_screen.dart';

class TripCompletionScreen extends StatefulWidget {
  final UserTrip trip;
  final Map<String, dynamic> tripSummary;
  
  const TripCompletionScreen({
    Key? key,
    required this.trip,
    required this.tripSummary,
  }) : super(key: key);
  
  @override
  _TripCompletionScreenState createState() => _TripCompletionScreenState();
}

class _TripCompletionScreenState extends State<TripCompletionScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _successController;
  late Animation<double> _successAnimation;
  
  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
    
    _successController.forward();
    
    // Update trip status to completed
    _markTripCompleted();
  }
  
  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }
  
  void _markTripCompleted() async {
    // Update trip status in database
    try {
      await UserDashboardService().updateTripStatus(widget.trip.id, 'completed');
    } catch (e) {
      print('Error updating trip status: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    
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
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10B981).withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 32),
                    
                    Text(
                      '🎉 Trip Completed!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 12),
                    
                    Text(
                      'Thank you for choosing BusSeva.\nWe hope you had a safe journey!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Trip Summary
                    _buildTripSummary(),
                    
                    SizedBox(height: 30),
                    
                    // Digital Receipt
                    _buildReceiptSection(),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripSummary() {
    final actualDuration = widget.tripSummary['actualDuration'] ?? '0h 0m';
    final estimatedDuration = widget.tripSummary['estimatedDuration'] ?? '0h 0m';
    final delay = widget.tripSummary['delay'] ?? 0;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          
          SizedBox(height: 16),
          
          _buildSummaryRow('Route', '${widget.trip.fromStopName} → ${widget.trip.toStopName}'),
          _buildSummaryRow('Bus', widget.trip.busNumber),
          _buildSummaryRow('Seats', widget.trip.seatNumbers.join(', ')),
          _buildSummaryRow('Duration', '$actualDuration (Est: $estimatedDuration)'),
          if (delay > 0)
            _buildSummaryRow('Delay', '${delay} minutes', color: Colors.orange),
          _buildSummaryRow('Fare Paid', '₹${widget.trip.totalFare.toStringAsFixed(0)}'),
          _buildSummaryRow('Payment', widget.trip.paymentMethod),
          
          SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'Trip completed successfully ✅',
                  style: TextStyle(
                    color: Color(0xFF10B981),
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
  
  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color ?? Color(0xFF1F2937),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReceiptSection() {
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
        children: [
          Text(
            'Digital Receipt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadReceipt(),
                  icon: Icon(Icons.download),
                  label: Text('Download PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF667EEA),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareReceipt(),
                  icon: Icon(Icons.share),
                  label: Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF667EEA),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
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
              onPressed: () => _openReviewScreen(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667EEA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rate),
                  SizedBox(width: 8),
                  Text(
                    'Rate Your Trip Experience',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _skipReview(),
                  child: Text('Skip Review'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (route) => false,
                  ),
                  child: Text('Back to Home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _downloadReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF receipt will be generated')),
    );
  }
  
  void _shareReceipt() {
    final receiptText = '''
🧾 BusSeva Trip Receipt
━━━━━━━━━━━━━━━━━━━━
🚌 Bus: ${widget.trip.busNumber}
📍 Route: ${widget.trip.fromStopName} → ${widget.trip.toStopName}
💺 Seats: ${widget.trip.seatNumbers.join(', ')}
💰 Fare: ₹${widget.trip.totalFare.toStringAsFixed(0)}
💳 Payment: ${widget.trip.paymentMethod}
📅 Date: ${widget.trip.departureTime.day}/${widget.trip.departureTime.month}/${widget.trip.departureTime.year}
🆔 Trip ID: ${widget.trip.bookingId}
━━━━━━━━━━━━━━━━━━━━
✅ Trip Completed Successfully
Thank you for choosing BusSeva!
    ''';
    
    // Implement share functionality
  }
  
  void _openReviewScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripReviewScreen(trip: widget.trip),
      ),
    );
  }
  
  void _skipReview() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  }
}
