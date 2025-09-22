import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import the new package

class RouteStop {
  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final int stopOrder;
  final String? arrivalTime;
  final String? departureTime;
  final double distanceFromStart;

  RouteStop({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.stopOrder,
    this.arrivalTime,
    this.departureTime,
    required this.distanceFromStart,
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    final coordinates = map['coordinates'] as GeoPoint?;

    // Helper function to safely convert a Firestore Timestamp into a time string
    String? _formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) return null;
      // You can change the format here if you like, e.g., 'h:mm a' for 12-hour time
      return DateFormat('HH:mm').format(timestamp.toDate());
    }

    return RouteStop(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      latitude: coordinates?.latitude ?? 0.0,
      longitude: coordinates?.longitude ?? 0.0,
      stopOrder: map['stopOrder'] ?? 0,
      // Use the helper function to convert Timestamps to Strings
      arrivalTime: _formatTimestamp(map['arrivalTime'] as Timestamp?),
      departureTime: _formatTimestamp(map['departureTime'] as Timestamp?),
      distanceFromStart: map['distanceFromStart']?.toDouble() ?? 0.0,
    );
  }
}

class BusRoute {
  final String id;
  final String name;
  final List<RouteStop> stops;
  final bool isActive;
  final double totalDistance;
  final String estimatedDuration;
  final Map<String, dynamic>? fare;
  final List<String> operatingDays;

  BusRoute({
    required this.id,
    required this.name,
    required this.stops,
    required this.isActive,
    required this.totalDistance,
    required this.estimatedDuration,
    this.fare,
    required this.operatingDays,
  });

  factory BusRoute.fromFirestore(String id, Map<String, dynamic> data) {
    return BusRoute(
      id: id,
      name: data['name'] ?? '',
      stops: (data['stops'] as List<dynamic>?)
              ?.map((stop) => RouteStop.fromMap(stop as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: data['isActive'] ?? false,
      totalDistance: data['totalDistance']?.toDouble() ?? 0.0,
      estimatedDuration: data['estimatedDuration'] ?? '',
      fare: data['fare'] as Map<String, dynamic>?,
      operatingDays: List<String>.from(data['operatingDays'] ?? []),
    );
  }
}

class RouteSearchResult {
  final BusRoute route;
  final RouteStop fromStop;
  final RouteStop toStop;
  final double distance;
  final String estimatedDuration;
  final int fare;
  final int activeBuses;
  final Map<String, dynamic>? nextBus;

  RouteSearchResult({
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.distance,
    required this.estimatedDuration,
    required this.fare,
    required this.activeBuses,
    this.nextBus,
  });
}