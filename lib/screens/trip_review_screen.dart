// lib/screens/trip_review_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_trip_model.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../home_screen.dart';
import 'dart:io';

class TripReviewScreen extends StatefulWidget {
  final UserTrip trip;
  
  const TripReviewScreen({Key? key, required this.trip}) : super(key: key);
  
  @override
  _TripReviewScreenState createState() => _TripReviewScreenState();
}

class _TripReviewScreenState extends State<TripReviewScreen> {
  final TextEditingController _commentsController = TextEditingController();
  final ReviewService _reviewService = ReviewService();
  final ImagePicker _picker = ImagePicker();
  
  double _overallRating = 5.0;
  double _cleanlinessRating = 5.0;
  double _punctualityRating = 5.0;
  double _safetyRating = 5.0;
  double _driverRating = 5.0;
  
  List<File> _selectedPhotos = [];
  bool _isSubmitting = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Rate Your Trip'),
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripHeader(),
            SizedBox(height: 20),
            _buildOverallRating(),
            SizedBox(height: 20),
            _buildDetailedRatings(),
            SizedBox(height: 20),
            _buildCommentsSection(),
            SizedBox(height: 20),
            _buildPhotoSection(),
            SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your trip?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${widget.trip.fromStopName} → ${widget.trip.toStopName}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            'Bus ${widget.trip.busNumber}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverallRating() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Overall Experience',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _overallRating = (index + 1).toDouble();
                  });
                },
                child: Icon(
                  Icons.star,
                  size: 40,
                  color: index < _overallRating ? Colors.amber : Colors.grey[300],
                ),
              );
            }),
          ),
          SizedBox(height: 8),
          Text(
            _getRatingText(_overallRating),
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF667EEA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedRatings() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Ratings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          _buildRatingRow('Cleanliness', _cleanlinessRating, (rating) {
            setState(() {
              _cleanlinessRating = rating;
            });
          }),
          
          _buildRatingRow('Punctuality', _punctualityRating, (rating) {
            setState(() {
              _punctualityRating = rating;
            });
          }),
          
          _buildRatingRow('Safety', _safetyRating, (rating) {
            setState(() {
              _safetyRating = rating;
            });
          }),
          
          _buildRatingRow('Driver Behavior', _driverRating, (rating) {
            setState(() {
              _driverRating = rating;
            });
          }),
        ],
      ),
    );
  }
  
  Widget _buildRatingRow(String label, double rating, Function(double) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onChanged((index + 1).toDouble()),
                  child: Icon(
                    Icons.star,
                    size: 24,
                    color: index < rating ? Colors.amber : Colors.grey[300],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _commentsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience with other passengers...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Color(0xFFF9FAFB),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhotoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Photos (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          if (_selectedPhotos.isEmpty)
            GestureDetector(
              onTap: _addPhoto,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFE5E7EB),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: Color(0xFF9CA3AF),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add Photos',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedPhotos.map((photo) => _buildPhotoThumbnail(photo)),
                GestureDetector(
                  onTap: _addPhoto,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE5E7EB)),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildPhotoThumbnail(File photo) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(photo),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
              'Submit Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
  
  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Below Average';
    return 'Poor';
  }
  
  void _addPhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    
    if (photo != null) {
      setState(() {
        _selectedPhotos.add(File(photo.path));
      });
    }
  }
  
  void _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final review = BusReview(
        id: '',
        tripId: widget.trip.id,
        busId: widget.trip.busId,
        busNumber: widget.trip.busNumber,
        userId: AuthService.currentUser?.uid ?? '',
        userName: AuthService.currentUser?.displayName ?? 'Anonymous',
        overallRating: _overallRating,
        cleanlinessRating: _cleanlinessRating,
        punctualityRating: _punctualityRating,
        safetyRating: _safetyRating,
        driverRating: _driverRating,
        comments: _commentsController.text.isEmpty ? null : _commentsController.text,
        photoUrls: [], // Will be populated after photo upload
        reviewDate: DateTime.now(),
        isVerified: true, // User has completed trip
      );
      
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your review!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isSubmitting = false;
    });
  }
}
