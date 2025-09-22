import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  
  const SeatSelectionScreen({Key? key, required this.bookingData}) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<String> selectedSeats = [];
  Map<String, String> seatStatus = {}; // Available, Occupied, Selected
  bool isLoading = true;
  
  // Sample seat configuration for a 40-seater bus
  final List<List<String>> seatLayout = [
    ['1A', '1B', '', '1C', '1D'],
    ['2A', '2B', '', '2C', '2D'],
    ['3A', '3B', '', '3C', '3D'],
    ['4A', '4B', '', '4C', '4D'],
    ['5A', '5B', '', '5C', '5D'],
    ['6A', '6B', '', '6C', '6D'],
    ['7A', '7B', '', '7C', '7D'],
    ['8A', '8B', '', '8C', '8D'],
    ['9A', '9B', '', '9C', '9D'],
    ['10A', '10B', '', '10C', '10D'],
  ];
  
  @override
  void initState() {
    super.initState();
    _loadSeatData();
  }
  
  Future<void> _loadSeatData() async {
    try {
      // In a real app, fetch from Firebase based on bus ID and date
      // For now, we'll simulate some occupied seats
      setState(() {
        seatStatus = {
          '1A': 'Occupied',
          '1B': 'Available',
          '1C': 'Occupied',
          '1D': 'Available',
          '2A': 'Available',
          '2B': 'Occupied',
          '2C': 'Available',
          '2D': 'Available',
          '3A': 'Available',
          '3B': 'Available',
          '3C': 'Available',
          '3D': 'Occupied',
          // ... continue for all seats
        };
        
        // Mark remaining seats as available
        for (var row in seatLayout) {
          for (var seat in row) {
            if (seat.isNotEmpty && !seatStatus.containsKey(seat)) {
              seatStatus[seat] = 'Available';
            }
          }
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to load seat data', isError: true);
    }
  }
  
  void _toggleSeat(String seatNumber) {
    if (seatStatus[seatNumber] == 'Occupied') return;
    
    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
        seatStatus[seatNumber] = 'Available';
      } else {
        if (selectedSeats.length < 4) { // Max 4 seats per booking
          selectedSeats.add(seatNumber);
          seatStatus[seatNumber] = 'Selected';
        } else {
          _showSnackBar('Maximum 4 seats can be selected', isError: true);
        }
      }
    });
  }
  
  void _proceedToPayment() {
    if (selectedSeats.isEmpty) {
      _showSnackBar('Please select at least one seat', isError: true);
      return;
    }
    
    Map<String, dynamic> bookingData = {
      ...widget.bookingData,
      'selectedSeats': selectedSeats,
      'totalFare': selectedSeats.length * (widget.bookingData['fare'] ?? 50),
      'passengerCount': selectedSeats.length,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(bookingData: bookingData),
      ),
    );
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
  
  Color _getSeatColor(String seat) {
    switch (seatStatus[seat]) {
      case 'Occupied':
        return const Color(0xFFEF4444);
      case 'Selected':
        return const Color(0xFF10B981);
      case 'Available':
      default:
        return const Color(0xFFF3F4F6);
    }
  }
  
  Color _getSeatTextColor(String seat) {
    switch (seatStatus[seat]) {
      case 'Occupied':
      case 'Selected':
        return Colors.white;
      case 'Available':
      default:
        return const Color(0xFF6B7280);
    }
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
          'Select Seats',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Trip Info Header
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.bookingData['from']} → ${widget.bookingData['to']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bus: ${widget.bookingData['busNumber'] ?? 'DL-1234'}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${widget.bookingData['fare'] ?? 50}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('Available', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
                      _buildLegendItem('Selected', const Color(0xFF10B981), Colors.white),
                      _buildLegendItem('Occupied', const Color(0xFFEF4444), Colors.white),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Seat Layout
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          // Driver seat indicator
                          Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B7280),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.airline_seat_recline_normal,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Driver',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Seat grid
                          ...seatLayout.map((row) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: row.map((seat) {
                                  if (seat.isEmpty) {
                                    return const SizedBox(width: 50); // Aisle space
                                  }
                                  
                                  return GestureDetector(
                                    onTap: () => _toggleSeat(seat),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: _getSeatColor(seat),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: seatStatus[seat] == 'Selected'
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFE5E7EB),
                                          width: seatStatus[seat] == 'Selected' ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          seat,
                                          style: TextStyle(
                                            color: _getSeatTextColor(seat),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (selectedSeats.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected: ${selectedSeats.join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: ₹${selectedSeats.length * (widget.bookingData['fare'] ?? 50)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: selectedSeats.isEmpty ? null : _proceedToPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                          ),
                          child: Text(
                            selectedSeats.isEmpty
                                ? 'Select Seats to Continue'
                                : 'Proceed to Payment (${selectedSeats.length} ${selectedSeats.length == 1 ? 'seat' : 'seats'})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
