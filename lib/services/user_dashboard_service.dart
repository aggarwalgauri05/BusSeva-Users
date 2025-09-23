// lib/services/user_dashboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_trip_model.dart';
import '../services/auth_service.dart';
import '../services/bus_tracking_service.dart';

class UserDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BusTrackingService _trackingService = BusTrackingService();

  // Get user's upcoming trips - SIMPLIFIED QUERY
  Stream<List<UserTrip>> getUpcomingTrips() {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      return Stream.value([]);
    }

    print('Getting trips for user: $userId');

    // Simplified query - only filter by userId, then filter in memory
    return _firestore
        .collection('user_trips')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final allTrips = snapshot.docs
              .map((doc) => UserTrip.fromFirestore(doc.id, doc.data()))
              .toList();
          
          // Filter for upcoming/ongoing trips in memory
          final upcomingTrips = allTrips
              .where((trip) => trip.status == 'upcoming' || trip.status == 'ongoing')
              .toList();
          
          // Sort by departure time
          upcomingTrips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
          
          print('Found ${upcomingTrips.length} upcoming trips');
          return upcomingTrips;
        })
        .handleError((error) {
          print('Error in getUpcomingTrips stream: $error');
          return <UserTrip>[];
        });
  }

  // Get trip history - SIMPLIFIED QUERY
  Stream<List<UserTrip>> getTripHistory({int limit = 10}) {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      return Stream.value([]);
    }

    print('Getting trip history for user: $userId');

    // Simplified query - only filter by userId, then filter in memory
    return _firestore
        .collection('user_trips')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final allTrips = snapshot.docs
              .map((doc) => UserTrip.fromFirestore(doc.id, doc.data()))
              .toList();
          
          // Filter for completed/cancelled trips in memory
          final historyTrips = allTrips
              .where((trip) => trip.status == 'completed' || trip.status == 'cancelled')
              .toList();
          
          // Sort by departure time (most recent first)
          historyTrips.sort((a, b) => b.departureTime.compareTo(a.departureTime));
          
          // Limit results
          final limitedTrips = historyTrips.take(limit).toList();
          
          print('Found ${limitedTrips.length} historical trips');
          return limitedTrips;
        })
        .handleError((error) {
          print('Error in getTripHistory stream: $error');
          return <UserTrip>[];
        });
  }

  // Get real-time bus status for a specific trip
  Future<Map<String, dynamic>?> getBusStatusForTrip(UserTrip trip) async {
    try {
      // Get bus location and status
      DocumentSnapshot busDoc = await _firestore
          .collection('buses')
          .doc(trip.busId)
          .get();

      if (!busDoc.exists) return null;

      Map<String, dynamic> busData = busDoc.data() as Map<String, dynamic>;
      
      // Calculate ETA to user's boarding stop
      String eta = await _trackingService.calculateETA(
        busId: trip.busId,
        stopId: trip.fromStopId,
        routeId: trip.routeId,
      );

      // Get current location description
      String currentLocation = await _getCurrentLocationDescription(
        busData, trip.routeId);

      return {
        'busData': busData,
        'eta': eta,
        'currentLocation': currentLocation,
        'occupancy': busData['occupancy'] ?? 0,
        'totalCapacity': busData['totalCapacity'] ?? 45,
        'status': busData['status'] ?? 'unknown',
        'isDelayed': await _trackingService.isBusDelayed(trip.busId),
        'lastUpdate': busData['lastUpdate'],
      };
    } catch (e) {
      print('Error getting bus status: $e');
      return null;
    }
  }

  // Toggle SMS alerts for a trip
  Future<void> toggleSMSAlert(String tripId, bool enabled) async {
    try {
      await _firestore
          .collection('user_trips')
          .doc(tripId)
          .update({'smsAlertsEnabled': enabled});

      if (enabled) {
        // Subscribe to SMS alerts
        final trip = await getUserTrip(tripId);
        if (trip != null && AuthService.currentUser?.phoneNumber != null) {
          await _trackingService.subscribeSMSAlert(
            busId: trip.busId,
            phoneNumber: AuthService.currentUser!.phoneNumber!,
            stopId: trip.fromStopId,
          );
        }
      }
    } catch (e) {
      print('Error toggling SMS alert: $e');
      throw e;
    }
  }

  // Get a specific user trip
  Future<UserTrip?> getUserTrip(String tripId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('user_trips')
          .doc(tripId)
          .get();
      
      if (doc.exists) {
        return UserTrip.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user trip: $e');
      return null;
    }
  }

  // Create trip when booking is confirmed
  Future<String> createTrip(UserTrip trip) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('user_trips')
          .add(trip.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating trip: $e');
      throw e;
    }
  }
// Add to user_dashboard_service.dart
Future<void> updateTripStatus(String tripId, String newStatus) async {
  try {
    await _firestore
        .collection('user_trips')
        .doc(tripId)
        .update({
          'status': newStatus,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
  } catch (e) {
    print('Error updating trip status: $e');
    throw e;
  }
}

// Add method to trigger trip completion
Future<void> completeTripWithSummary(String tripId, Map<String, dynamic> summary) async {
  try {
    await _firestore
        .collection('user_trips')
        .doc(tripId)
        .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'tripSummary': summary,
        });
  } catch (e) {
    print('Error completing trip: $e');
    throw e;
  }
}

  // Report ghost bus
  Future<void> reportGhostBus(String busId, String reason) async {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) return;

    await _trackingService.reportGhostBus(
      busId: busId,
      userId: userId,
      reason: reason,
    );
  }

  // Helper method to get current location description
  Future<String> _getCurrentLocationDescription(
      Map<String, dynamic> busData, String routeId) async {
    try {
      String currentStop = busData['currentStop'] ?? '';
      if (currentStop.isNotEmpty && currentStop != 'between_stops') {
        return 'Currently at $currentStop';
      }

      // If between stops, try to determine which stops
      String? lastStop = busData['lastStop'];
      String? nextStop = busData['nextStop'];
      
      if (lastStop != null && nextStop != null) {
        return 'Between $lastStop & $nextStop';
      }

      return 'Location updating...';
    } catch (e) {
      return 'Location unavailable';
    }
  }
}
