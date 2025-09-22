// booking_page.dart
import 'package:flutter/material.dart';
import 'package:bus_seva/booking_confirmation_page.dart'; // We'll create this next
class BookingPage extends StatefulWidget {
  final Map<String, dynamic> busData;

  const BookingPage({super.key, required this.busData, required String busId, required String routeId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedPaymentMethod;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _bookTicket() {
    // Basic validation
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select a payment method.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement actual booking logic (e.g., API call to book a ticket)
    // For now, we will navigate to the confirmation page.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(bookingData: widget.busData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Book Ticket'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripSummaryCard(),
            const SizedBox(height: 20),
            _buildPassengerSection(),
            const SizedBox(height: 20),
            _buildPaymentOptions(),
            const SizedBox(height: 40),
            _buildBookButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummaryCard() {
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
            'Trip Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 15),
          _buildDetailRow('Bus:', '${widget.busData['busName']} (${widget.busData['busNumber']})'),
          _buildDetailRow('Route:', '${widget.busData['route']}'),
          _buildDetailRow('Departure:', 'Today, 10:00 AM'),
          _buildDetailRow('Fare:', '₹${widget.busData['fare']}'),
        ],
      ),
    );
  }

  Widget _buildPassengerSection() {
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
            'Passenger Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField('Full Name', 'e.g., John Doe', controller: _nameController),
          const SizedBox(height: 15),
          _buildTextField('Phone Number', 'e.g., 9876543210', keyboardType: TextInputType.phone, controller: _phoneController),
          const SizedBox(height: 15),
          _buildTextField('Email (Optional)', 'e.g., johndoe@example.com', keyboardType: TextInputType.emailAddress, controller: _emailController),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    final List<String> paymentMethods = ['UPI', 'Debit/Credit Card', 'Cash on Bus'];

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
            'Payment Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 15),
          ...paymentMethods.map((method) =>
              _buildPaymentChip(method, method == _selectedPaymentMethod)),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(String method, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = isSelected ? null : method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667EEA).withOpacity(0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF667EEA) : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: ListTile(
          tileColor: Colors.transparent,
          title: Text(
            method,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF667EEA) : const Color(0xFF1F2937),
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Color(0xFF667EEA))
              : const Icon(Icons.circle_outlined, color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _bookTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Book Now',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {TextInputType? keyboardType, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}