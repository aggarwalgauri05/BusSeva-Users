// lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BusReview {
  final String id;
  final String tripId;
  final String busId;
  final String busNumber;
  final String userId;
  final String userName;
  final double overallRating;
  final double cleanlinessRating;
  final double punctualityRating;
  final double safetyRating;
  final double driverRating;
  final String? comments;
  final List<String> photoUrls;
  final DateTime reviewDate;
  final bool isVerified;
  final int helpfulCount;
  
  BusReview({
    required this.id,
    required this.tripId,
    required this.busId,
    required this.busNumber,
    required this.userId,
    required this.userName,
    required this.overallRating,
    required this.cleanlinessRating,
    required this.punctualityRating,
    required this.safetyRating,
    required this.driverRating,
    this.comments,
    required this.photoUrls,
    required this.reviewDate,
    this.isVerified = false,
    this.helpfulCount = 0,
  });

  factory BusReview.fromFirestore(String id, Map<String, dynamic> data) {
    return BusReview(
      id: id,
      tripId: data['tripId'] ?? '',
      busId: data['busId'] ?? '',
      busNumber: data['busNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      overallRating: data['overallRating']?.toDouble() ?? 0.0,
      cleanlinessRating: data['cleanlinessRating']?.toDouble() ?? 0.0,
      punctualityRating: data['punctualityRating']?.toDouble() ?? 0.0,
      safetyRating: data['safetyRating']?.toDouble() ?? 0.0,
      driverRating: data['driverRating']?.toDouble() ?? 0.0,
      comments: data['comments'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      reviewDate: (data['reviewDate'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'busId': busId,
      'busNumber': busNumber,
      'userId': userId,
      'userName': userName,
      'overallRating': overallRating,
      'cleanlinessRating': cleanlinessRating,
      'punctualityRating': punctualityRating,
      'safetyRating': safetyRating,
      'driverRating': driverRating,
      'comments': comments,
      'photoUrls': photoUrls,
      'reviewDate': Timestamp.fromDate(reviewDate),
      'isVerified': isVerified,
      'helpfulCount': helpfulCount,
    };
  }
}
