import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_trip_model.dart';

class ReviewScreen extends StatefulWidget {
  final UserTrip trip;
  
  const ReviewScreen({Key? key, required this.trip}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int overallRating = 0;
  int driverRating = 0;
  int cleanlinessRating = 0;
  int punctualityRating = 0;
  int comfortRating = 0;
  
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rate Your Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripInfo(),
            const SizedBox(height: 24),
            _buildOverallRating(),
            const SizedBox(height: 24),
            _buildDetailedRatings(),
            const SizedBox(height: 24),
            _buildCommentSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus ${widget.trip.busNumber}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.trip.fromStopName} → ${widget.trip.toStopName}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTripDetail(Icons.event_seat, 'Seats', widget.trip.seatNumbers.join(', ')),
              const SizedBox(width: 20),
              _buildTripDetail(Icons.currency_rupee, 'Fare', '₹${widget.trip.totalFare.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildOverallRating() {
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
            'Overall Experience',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          const Text(
            'How was your overall trip experience?',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    overallRating = index + 1;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < overallRating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: index < overallRating ? const Color(0xFFFFB800) : const Color(0xFFE5E7EB),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(overallRating),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF667EEA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRatings() {
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
            'Rate Different Aspects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 20),
          _buildRatingRow('Driver Behavior', Icons.person, driverRating, (rating) {
            setState(() {
              driverRating = rating;
            });
          }),
          const SizedBox(height: 16),
          _buildRatingRow('Cleanliness', Icons.cleaning_services, cleanlinessRating, (rating) {
            setState(() {
              cleanlinessRating = rating;
            });
          }),
          const SizedBox(height: 16),
          _buildRatingRow('Punctuality', Icons.access_time, punctualityRating, (rating) {
            setState(() {
              punctualityRating = rating;
            });
          }),
          const SizedBox(height: 16),
          _buildRatingRow('Comfort', Icons.airline_seat_recline_normal, comfortRating, (rating) {
            setState(() {
              comfortRating = rating;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String title, IconData icon, int rating, Function(int) onRatingChanged) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF667EEA), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => onRatingChanged(index + 1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 20,
                  color: index < rating ? const Color(0xFFFFB800) : const Color(0xFFE5E7EB),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
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
            'Additional Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your experience to help improve our service',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us about your trip experience...',
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
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting || overallRating == 0 ? null : _submitReview,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : const Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Submitting Review...' : 'Submit Review',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: overallRating == 0 ? Colors.grey[400] : const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Rate your experience';
    }
  }

  Future<void> _submitReview() async {
    if (overallRating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save review to Firestore
      await FirebaseFirestore.instance.collection('reviews').add({
        'tripId': widget.trip.id,
        'busId': widget.trip.busId,
        'busNumber': widget.trip.busNumber,
        'userId': AuthService.currentUser?.uid,
        'overallRating': overallRating,
        'driverRating': driverRating,
        'cleanlinessRating': cleanlinessRating,
        'punctualityRating': punctualityRating,
        'comfortRating': comfortRating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'route': '${widget.trip.fromStopName} → ${widget.trip.toStopName}',
      });

      // Update trip as reviewed
      await FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUser?.uid)
          .collection('trips')
          .doc(widget.trip.id)
          .update({'reviewed': true});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully! Thank you for your feedback.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
