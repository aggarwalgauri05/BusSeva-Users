import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../booking_confirmation_page.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  
  const PaymentScreen({Key? key, required this.bookingData}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'UPI';
  bool isProcessing = false;
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'UPI',
      'title': 'UPI Payment',
      'subtitle': 'Pay with Google Pay, PhonePe, Paytm',
      'icon': Icons.payment,
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'CARD',
      'title': 'Debit/Credit Card',
      'subtitle': 'Visa, Mastercard, Rupay',
      'icon': Icons.credit_card,
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'CASH',
      'title': 'Cash on Bus',
      'subtitle': 'Pay the conductor directly',
      'icon': Icons.money,
      'color': Color(0xFFFF9800),
    },
  ];
  
  @override
  void dispose() {
    _upiController.dispose();
    _emergencyContactController.dispose();
    _emergencyNameController.dispose();
    super.dispose();
  }
  
  Future<void> _processPayment() async {
    if (selectedPaymentMethod == 'UPI' && _upiController.text.isEmpty) {
      _showSnackBar('Please enter UPI ID', isError: true);
      return;
    }
    
    setState(() {
      isProcessing = true;
    });
    
    try {
      // Generate booking ID
      String bookingId = const Uuid().v4();
      
      // Create booking data
      Map<String, dynamic> finalBookingData = {
        'bookingId': bookingId,
        'userId': AuthService.currentUser?.uid,
        'userPhone': AuthService.currentUser?.phoneNumber,
        'from': widget.bookingData['from'],
        'to': widget.bookingData['to'],
        'busNumber': widget.bookingData['busNumber'] ?? 'DL-1234',
        'selectedSeats': widget.bookingData['selectedSeats'],
        'totalFare': widget.bookingData['totalFare'],
        'passengerCount': widget.bookingData['passengerCount'],
        'paymentMethod': selectedPaymentMethod,
        'paymentStatus': selectedPaymentMethod == 'CASH' ? 'Pending' : 'Paid',
        'bookingStatus': 'Confirmed',
        'bookingDate': FieldValue.serverTimestamp(),
        'travelDate': widget.bookingData['travelDate'] ?? DateTime.now(),
        'emergencyContact': _emergencyContactController.text.isNotEmpty ? {
          'name': _emergencyNameController.text,
          'phone': _emergencyContactController.text,
        } : null,
      };
      
      // Save booking to Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .set(finalBookingData);
      
      // Update user's booking history
      if (AuthService.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(AuthService.currentUser!.uid)
            .update({
          'totalTrips': FieldValue.increment(1),
          'totalSpent': FieldValue.increment(widget.bookingData['totalFare'].toDouble()),
        });
      }
      
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        isProcessing = false;
      });
      
      // Navigate to booking confirmation
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationPage(
            bookingData: finalBookingData,
          ),
        ),
        (route) => route.isFirst,
      );
      
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      _showSnackBar('Payment failed: $e', isError: true);
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Summary
                  _buildBookingSummary(),
                  
                  const SizedBox(height: 32),
                  
                  // Payment Methods
                  const Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...paymentMethods.map((method) => _buildPaymentMethod(method)).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // UPI ID Input (if UPI selected)
                  if (selectedPaymentMethod == 'UPI') _buildUPIInput(),
                  
                  const SizedBox(height: 24),
                  
                  // Emergency Contact (Optional)
                  _buildEmergencyContact(),
                  
                  const SizedBox(height: 32),
                  
                  // Terms and Conditions
                  _buildTermsAndConditions(),
                ],
              ),
            ),
          ),
          
          // Payment Button
          _buildPaymentButton(),
        ],
      ),
    );
  }
  
  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow(
            'Route',
            '${widget.bookingData['from']} → ${widget.bookingData['to']}',
          ),
          _buildSummaryRow(
            'Bus Number',
            widget.bookingData['busNumber'] ?? 'DL-1234',
          ),
          _buildSummaryRow(
            'Seats',
            (widget.bookingData['selectedSeats'] as List).join(', '),
          ),
          _buildSummaryRow(
            'Passengers',
            '${widget.bookingData['passengerCount']} ${widget.bookingData['passengerCount'] == 1 ? 'person' : 'people'}',
          ),
          
          const Divider(color: Colors.white54, height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${widget.bookingData['totalFare']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethod(Map<String, dynamic> method) {
    bool isSelected = selectedPaymentMethod == method['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? method['color'] : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? method['color'].withOpacity(0.05) : Colors.white,
      ),
      child: RadioListTile<String>(
        value: method['id'],
        groupValue: selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            selectedPaymentMethod = value!;
          });
        },
        activeColor: method['color'],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: method['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'],
                color: method['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    method['subtitle'],
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
  
  Widget _buildUPIInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UPI ID',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _upiController,
          decoration: InputDecoration(
            hintText: 'yourname@paytm / yourname@gpay',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmergencyContact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_outlined, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                'Emergency Contact (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Add an emergency contact for this trip. They will be notified in case of any emergency.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _emergencyNameController,
            decoration: InputDecoration(
              hintText: 'Contact Name',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _emergencyContactController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Contact Phone Number',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'Important Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Please arrive at the boarding point 15 minutes early\n'
            '• Show your QR ticket to the conductor\n'
            '• Cancellation allowed up to 2 hours before departure\n'
            '• Keep your phone charged for the digital ticket',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF92400E),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: const Color(0xFFE5E7EB),
          ),
          child: isProcessing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Processing Payment...'),
                  ],
                )
              : Text(
                  selectedPaymentMethod == 'CASH' 
                      ? 'Confirm Booking (Pay on Bus)'
                      : 'Pay ₹${widget.bookingData['totalFare']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
