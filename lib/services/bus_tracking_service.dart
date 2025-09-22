// lib/services/bus_tracking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/route_model.dart';

class BusTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get real-time bus location stream
  Stream<DocumentSnapshot> getBusLocationStream(String busId) {
    return _firestore
        .collection('buses')
        .doc(busId)
        .snapshots();
  }
  
  // Get bus details
  Future<Map<String, dynamic>?> getBusDetails(String busId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('buses')
          .doc(busId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting bus details: $e');
      return null;
    }
  }
  
  // Get route information
  Future<BusRoute> getRoute(String routeId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('routes')
          .doc(routeId)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return BusRoute.fromFirestore(data, doc.id);
      }
      
      throw Exception('Route not found');
    } catch (e) {
      print('Error getting route: $e');
      throw e;
    }
  }
  
  // Get all buses on a specific route
  Stream<QuerySnapshot> getBusesOnRoute(String routeId) {
    return _firestore
        .collection('buses')
        .where('routeId', isEqualTo: routeId)
        .where('status', whereIn: ['running', 'stopped', 'delayed'])
        .snapshots();
  }
  
  // Get nearby buses
  Future<List<Map<String, dynamic>>> getNearbyBuses({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Note: Firestore doesn't support geo-queries natively
      // For production, consider using GeoFirestore or similar
      
      QuerySnapshot snapshot = await _firestore
          .collection('buses')
          .where('status', whereIn: ['running', 'stopped'])
          .get();
      
      List<Map<String, dynamic>> nearbyBuses = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> busData = doc.data() as Map<String, dynamic>;
        GeoPoint? busLocation = busData['currentLocation'];
        
        if (busLocation != null) {
          double distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            busLocation.latitude,
            busLocation.longitude,
          ) / 1000; // Convert to km
          
          if (distance <= radiusKm) {
            busData['id'] = doc.id;
            busData['distanceKm'] = distance;
            nearbyBuses.add(busData);
          }
        }
      }
      
      // Sort by distance
      nearbyBuses.sort((a, b) => a['distanceKm'].compareTo(b['distanceKm']));
      
      return nearbyBuses;
    } catch (e) {
      print('Error getting nearby buses: $e');
      return [];
    }
  }
  
  // Calculate ETA to a specific stop
  Future<String> calculateETA({
    required String busId,
    required String stopId,
    required String routeId,
  }) async {
    try {
      // Get bus current location
      DocumentSnapshot busDoc = await _firestore
          .collection('buses')
          .doc(busId)
          .get();
      
      if (!busDoc.exists) return 'Unknown';
      
      Map<String, dynamic> busData = busDoc.data() as Map<String, dynamic>;
      GeoPoint? busLocation = busData['currentLocation'];
      
      if (busLocation == null) return 'Unknown';
      
      // Get route with stops
      BusRoute route = await getRoute(routeId);
      
      // Find target stop
      RouteStop? targetStop = route.stops.firstWhere(
        (stop) => stop.id == stopId,
        orElse: () => throw Exception('Stop not found'),
      );
      
      // Calculate distance
      double distanceKm = Geolocator.distanceBetween(
        busLocation.latitude,
        busLocation.longitude,
        targetStop.latitude,
        targetStop.longitude,
      ) / 1000;
      
      // Estimate time (assuming average speed of 30 km/h in city)
      double averageSpeedKmh = 30.0;
      int etaMinutes = (distanceKm / averageSpeedKmh * 60).round();
      
      // Add buffer time for stops
      etaMinutes += 5;
      
      if (etaMinutes < 1) return 'Arriving now';
      if (etaMinutes < 60) return '${etaMinutes} min';
      
      int hours = etaMinutes ~/ 60;
      int mins = etaMinutes % 60;
      return '${hours}h ${mins}m';
      
    } catch (e) {
      print('Error calculating ETA: $e');
      return 'Unknown';
    }
  }
  
  // Track bus for a specific journey
  Future<void> startTracking(String busId, String userId) async {
    try {
      await _firestore
          .collection('tracking')
          .doc('${userId}_$busId')
          .set({
        'userId': userId,
        'busId': busId,
        'startTime': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Error starting tracking: $e');
      throw e;
    }
  }
  
  // Stop tracking
  Future<void> stopTracking(String busId, String userId) async {
    try {
      await _firestore
          .collection('tracking')
          .doc('${userId}_$busId')
          .update({
        'endTime': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } catch (e) {
      print('Error stopping tracking: $e');
      throw e;
    }
  }
  
  // Get user's active tracking sessions
  Stream<QuerySnapshot> getActiveTrackingSessions(String userId) {
    return _firestore
        .collection('tracking')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }
  
  // Report ghost bus (bus not actually running)
  Future<void> reportGhostBus({
    required String busId,
    required String userId,
    String? reason,
  }) async {
    try {
      await _firestore
          .collection('ghost_reports')
          .add({
        'busId': busId,
        'reportedBy': userId,
        'reason': reason ?? 'Bus not running as scheduled',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      // Update bus status if multiple reports
      await _updateBusStatusIfNeeded(busId);
    } catch (e) {
      print('Error reporting ghost bus: $e');
      throw e;
    }
  }
  
  // Check if bus should be marked as ghost based on reports
  Future<void> _updateBusStatusIfNeeded(String busId) async {
    try {
      // Get recent reports (last 1 hour)
      DateTime oneHourAgo = DateTime.now().subtract(Duration(hours: 1));
      
      QuerySnapshot reports = await _firestore
          .collection('ghost_reports')
          .where('busId', isEqualTo: busId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();
      
      // If 3 or more reports in the last hour, mark as potential ghost
      if (reports.docs.length >= 3) {
        await _firestore
            .collection('buses')
            .doc(busId)
            .update({
          'isGhost': true,
          'ghostReports': reports.docs.length,
          'lastGhostUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating bus status: $e');
    }
  }
  
  // Get bus occupancy status
  String getBusOccupancyStatus(int occupancy, int capacity) {
    double percentage = occupancy / capacity;
    
    if (percentage < 0.6) return 'Available';
    if (percentage < 0.9) return 'Filling';
    return 'Full';
  }
  
  // Subscribe to SMS alerts for bus
  Future<void> subscribeSMSAlert({
    required String busId,
    required String phoneNumber,
    required String stopId,
  }) async {
    try {
      await _firestore
          .collection('sms_subscriptions')
          .doc('${phoneNumber}_$busId')
          .set({
        'phoneNumber': phoneNumber,
        'busId': busId,
        'stopId': stopId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error subscribing to SMS alerts: $e');
      throw e;
    }
  }
  
  // Unsubscribe from SMS alerts
  Future<void> unsubscribeSMSAlert({
    required String busId,
    required String phoneNumber,
  }) async {
    try {
      await _firestore
          .collection('sms_subscriptions')
          .doc('${phoneNumber}_$busId')
          .update({
        'isActive': false,
        'unsubscribedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error unsubscribing from SMS alerts: $e');
      throw e;
    }
  }
  
  // Get historical bus locations for route analysis
  Future<List<Map<String, dynamic>>> getBusHistory({
    required String busId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bus_history')
          .where('busId', isEqualTo: busId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting bus history: $e');
      return [];
    }
  }
  
  // Check if bus is delayed based on schedule
  Future<bool> isBusDelayed(String busId) async {
    try {
      DocumentSnapshot busDoc = await _firestore
          .collection('buses')
          .doc(busId)
          .get();
      
      if (!busDoc.exists) return false;
      
      Map<String, dynamic> busData = busDoc.data() as Map<String, dynamic>;
      
      // Check if explicitly marked as delayed
      if (busData['status'] == 'delayed') return true;
      
      // Check against schedule (if available)
      DateTime? scheduledTime = (busData['scheduledArrival'] as Timestamp?)?.toDate();
      if (scheduledTime != null) {
        DateTime now = DateTime.now();
        return now.isAfter(scheduledTime.add(Duration(minutes: 10)));
      }
      
      return false;
    } catch (e) {
      print('Error checking if bus is delayed: $e');
      return false;
    }
  }
  
  // Get live traffic/delay updates
  Stream<QuerySnapshot> getTrafficUpdates(String routeId) {
    return _firestore
        .collection('traffic_updates')
        .where('routeId', isEqualTo: routeId)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }
}