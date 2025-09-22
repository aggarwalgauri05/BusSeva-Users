// lib/models/user_trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTrip {
  final String id;
  final String userId;
  final String busId;
  final String routeId;
  final String bookingId;
  final String fromStopId;
  final String toStopId;
  final String fromStopName;
  final String toStopName;
  final List<String> seatNumbers;
  final DateTime departureTime;
  final DateTime bookingDate;
  final String status; // upcoming, ongoing, completed, cancelled
  final double totalFare;
  final String paymentMethod;
  final String busNumber;
  final bool smsAlertsEnabled;
  
  UserTrip({
    required this.id,
    required this.userId,
    required this.busId,
    required this.routeId,
    required this.bookingId,
    required this.fromStopId,
    required this.toStopId,
    required this.fromStopName,
    required this.toStopName,
    required this.seatNumbers,
    required this.departureTime,
    required this.bookingDate,
    required this.status,
    required this.totalFare,
    required this.paymentMethod,
    required this.busNumber,
    this.smsAlertsEnabled = false,
  });

  factory UserTrip.fromFirestore(String id, Map<String, dynamic> data) {
    return UserTrip(
      id: id,
      userId: data['userId'] ?? '',
      busId: data['busId'] ?? '',
      routeId: data['routeId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      fromStopId: data['fromStopId'] ?? '',
      toStopId: data['toStopId'] ?? '',
      fromStopName: data['fromStopName'] ?? '',
      toStopName: data['toStopName'] ?? '',
      seatNumbers: List<String>.from(data['seatNumbers'] ?? []),
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'upcoming',
      totalFare: data['totalFare']?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? '',
      busNumber: data['busNumber'] ?? '',
      smsAlertsEnabled: data['smsAlertsEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'busId': busId,
      'routeId': routeId,
      'bookingId': bookingId,
      'fromStopId': fromStopId,
      'toStopId': toStopId,
      'fromStopName': fromStopName,
      'toStopName': toStopName,
      'seatNumbers': seatNumbers,
      'departureTime': Timestamp.fromDate(departureTime),
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': status,
      'totalFare': totalFare,
      'paymentMethod': paymentMethod,
      'busNumber': busNumber,
      'smsAlertsEnabled': smsAlertsEnabled,
    };
  }
}
