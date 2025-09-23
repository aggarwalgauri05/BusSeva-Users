// lib/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Submit a new review
  // The new method to submit a review with full details.
  Future<void> submitFullReview({
    required String tripId,
    required String busId,
    required String busNumber,
    required String userId,
    required double overallRating,
    required double driverRating,
    required double cleanlinessRating,
    required double punctualityRating,
    required double comfortRating,
    required String comment,
    required String route,
  }) async {
    try {
      // Create a document reference
      DocumentReference docRef = await _firestore.collection('reviews').add({
        'tripId': tripId,
        'busId': busId,
        'busNumber': busNumber,
        'userId': userId,
        'overallRating': overallRating,
        'driverRating': driverRating,
        'cleanlinessRating': cleanlinessRating,
        'punctualityRating': punctualityRating,
        'comfortRating': comfortRating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'route': route,
      });

      // Update the trip as reviewed for the user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .set({'reviewed': true}, SetOptions(merge: true));

    } catch (e) {
      print('Error submitting full review: $e');
      throw e;
    }
  }
  
  // Get reviews for a specific bus
  Future<List<BusReview>> getBusReviews(String busId, {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('busId', isEqualTo: busId)
          .orderBy('reviewDate', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => BusReview.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting bus reviews: $e');
      return [];
    }
  }
  
  // Get recent verified reviews for display
  Future<List<BusReview>> getRecentVerifiedReviews(String busId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('busId', isEqualTo: busId)
          .where('isVerified', isEqualTo: true)
          .orderBy('reviewDate', descending: true)
          .limit(3)
          .get();
      
      return snapshot.docs
          .map((doc) => BusReview.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting recent reviews: $e');
      return [];
    }
  }
  
  // Update bus average rating
  Future<void> _updateBusRating(String busId) async {
    try {
      // Get all reviews for this bus
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('busId', isEqualTo: busId)
          .get();
      
      if (reviews.docs.isEmpty) return;
      
      // Calculate averages
      double totalOverall = 0;
      double totalCleanliness = 0;
      double totalPunctuality = 0;
      double totalSafety = 0;
      double totalDriver = 0;
      int count = reviews.docs.length;
      
      for (var doc in reviews.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalOverall += data['overallRating']?.toDouble() ?? 0;
        totalCleanliness += data['cleanlinessRating']?.toDouble() ?? 0;
        totalPunctuality += data['punctualityRating']?.toDouble() ?? 0;
        totalSafety += data['safetyRating']?.toDouble() ?? 0;
        totalDriver += data['driverRating']?.toDouble() ?? 0;
      }
      
      // Update bus document with new ratings
     await _firestore.collection('buses').doc(busId).set({
  'ratings.overall': totalOverall / count,
  'ratings.cleanliness': totalCleanliness / count,
  'ratings.punctuality': totalPunctuality / count,
  'ratings.safety': totalSafety / count,
  'ratings.driver': totalDriver / count,
  'ratings.totalReviews': count,
}, SetOptions(merge: true));

      
    } catch (e) {
      print('Error updating bus rating: $e');
    }
  }
}
