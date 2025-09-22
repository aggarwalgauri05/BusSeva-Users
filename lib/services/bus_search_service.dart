import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class BusSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<List<RouteSearchResult>> searchRoutes({
    required String fromCity,
    required String toCity,
    int? maxFare,
    String? maxDuration,
    String? departureAfter,
  }) async {
    try {
      // Normalize city names
      String normalizedFrom = fromCity.toLowerCase().trim();
      String normalizedTo = toCity.toLowerCase().trim();
      
      // Get all active routes
      QuerySnapshot routesSnapshot = await _firestore
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .get();
      
      List<RouteSearchResult> results = [];
      
      for (QueryDocumentSnapshot doc in routesSnapshot.docs) {
        BusRoute route = BusRoute.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        
        // Check if route connects the cities
        RouteConnection? connection = _checkRouteConnection(route, normalizedFrom, normalizedTo);
        
        if (connection != null) {
          // Get bus information for this route
          int activeBuses = await _getActiveBusCount(route.id);
          Map<String, dynamic>? nextBus = await _getNextBus(route.id, connection.fromStop);
          
          RouteSearchResult result = RouteSearchResult(
            route: route,
            fromStop: connection.fromStop,
            toStop: connection.toStop,
            distance: connection.distance,
            estimatedDuration: connection.estimatedDuration,
            fare: connection.fare,
            activeBuses: activeBuses,
            nextBus: nextBus,
          );
          
          // Apply filters
          if (_passesFilters(result, maxFare, maxDuration, departureAfter)) {
            results.add(result);
          }
        }
      }
      
      // Sort results by relevance
      results.sort((a, b) {
        // Primary: availability (more buses = better)
        if (a.activeBuses != b.activeBuses) {
          return b.activeBuses.compareTo(a.activeBuses);
        }
        // Secondary: fare (lower = better)
        if (a.fare != b.fare) {
          return a.fare.compareTo(b.fare);
        }
        // Tertiary: distance (shorter = better)
        return a.distance.compareTo(b.distance);
      });
      
      return results;
    } catch (e) {
      throw Exception('Failed to search routes: $e');
    }
  }
  
  RouteConnection? _checkRouteConnection(BusRoute route, String fromCity, String toCity) {
    int fromStopIndex = -1;
    int toStopIndex = -1;
    
    // Find the stops
    for (int i = 0; i < route.stops.length; i++) {
      RouteStop stop = route.stops[i];
      if (stop.city.toLowerCase() == fromCity && fromStopIndex == -1) {
        fromStopIndex = i;
      }
      if (stop.city.toLowerCase() == toCity && fromStopIndex != -1 && toStopIndex == -1) {
        toStopIndex = i;
        break;
      }
    }
    
    if (fromStopIndex != -1 && toStopIndex != -1 && fromStopIndex < toStopIndex) {
      RouteStop fromStop = route.stops[fromStopIndex];
      RouteStop toStop = route.stops[toStopIndex];
      
      return RouteConnection(
        fromStop: fromStop,
        toStop: toStop,
        distance: toStop.distanceFromStart - fromStop.distanceFromStart,
        estimatedDuration: _calculateDuration(fromStop, toStop),
        fare: _calculateFare(route, fromStop, toStop),
      );
    }
    
    return null;
  }
  
  int _calculateFare(BusRoute route, RouteStop fromStop, RouteStop toStop) {
    double distance = toStop.distanceFromStart - fromStop.distanceFromStart;
    int baseFare = route.fare?['baseFare'] ?? 50;
    double perKmRate = route.fare?['perKmRate'] ?? 2.5;
    
    return (baseFare + (distance * perKmRate)).round();
  }
  
  String _calculateDuration(RouteStop fromStop, RouteStop toStop) {
    if (fromStop.departureTime != null && toStop.arrivalTime != null) {
      int fromMinutes = _timeToMinutes(fromStop.departureTime!);
      int toMinutes = _timeToMinutes(toStop.arrivalTime!);
      
      int duration = toMinutes - fromMinutes;
      if (duration < 0) duration += 24 * 60; // Handle overnight travel
      
      int hours = duration ~/ 60;
      int minutes = duration % 60;
      
      return '${hours}h ${minutes}m';
    }
    
    // Fallback calculation based on distance
    double distance = toStop.distanceFromStart - fromStop.distanceFromStart;
    int hours = (distance / 50).floor();
    int minutes = ((distance % 50) * 1.2).round();
    
    return '${hours}h ${minutes}m';
  }
  
  Future<int> _getActiveBusCount(String routeId) async {
    try {
      QuerySnapshot busSnapshot = await _firestore
          .collection('buses')
          .where('routeId', isEqualTo: routeId)
          .where('status', isEqualTo: 'ACTIVE')
          .get();
      
      return busSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
  
  Future<Map<String, dynamic>?> _getNextBus(String routeId, RouteStop fromStop) async {
    try {
      QuerySnapshot busSnapshot = await _firestore
          .collection('buses')
          .where('routeId', isEqualTo: routeId)
          .where('status', isEqualTo: 'ACTIVE')
          .limit(1)
          .get();
      
      if (busSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> busData = busSnapshot.docs.first.data() as Map<String, dynamic>;
        
        // Estimate arrival time (simplified)
        DateTime now = DateTime.now();
        DateTime estimatedArrival = now.add(Duration(minutes: 30 + (DateTime.now().millisecond % 60)));
        
        return {
          'busId': busSnapshot.docs.first.id,
          'busNumber': busData['number'],
          'driver': busData['driver'],
          'occupancy': busData['occupancy'],
          'estimatedArrival': estimatedArrival.toIso8601String(),
          'estimatedMinutes': estimatedArrival.difference(now).inMinutes,
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  bool _passesFilters(RouteSearchResult result, int? maxFare, String? maxDuration, String? departureAfter) {
    if (maxFare != null && result.fare > maxFare) {
      return false;
    }
    
    if (maxDuration != null) {
      int resultDurationMinutes = _durationToMinutes(result.estimatedDuration);
      int maxDurationMinutes = _durationToMinutes(maxDuration);
      if (resultDurationMinutes > maxDurationMinutes) {
        return false;
      }
    }
    
    if (departureAfter != null && result.fromStop.departureTime != null) {
      int departureMinutes = _timeToMinutes(result.fromStop.departureTime!);
      int filterMinutes = _timeToMinutes(departureAfter);
      if (departureMinutes < filterMinutes) {
        return false;
      }
    }
    
    return true;
  }
  
  int _timeToMinutes(String timeStr) {
    List<String> parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
  
  int _durationToMinutes(String durationStr) {
    RegExp regex = RegExp(r'(\d+)h\s*(\d+)m');
    RegExpMatch? match = regex.firstMatch(durationStr);
    if (match != null) {
      int hours = int.parse(match.group(1)!);
      int minutes = int.parse(match.group(2)!);
      return hours * 60 + minutes;
    }
    return 0;
  }
  
  Future<List<String>> searchCities(String query) async {
    try {
      // In a real app, you'd have a cities collection
      // For now, return a mock list based on common Indian cities
      List<String> cities = [
        'Delhi', 'Agra', 'Amritsar', 'Lucknow', 'Jaipur', 'Kolkata',
        'Pune', 'Ahmedabad', 'Jaipur', 'Surat', 'Lucknow', 'Kanpur',
        'Nagpur', 'Patna', 'Indore', 'Thane', 'Bhopal', 'Visakhapatnam',
        'Pimpri-Chinchwad', 'Vadodara', 'Agra', 'Nashik', 'Faridabad',
        'Meerut', 'Rajkot', 'Kalyan-Dombivali', 'Vasai-Virar', 'Varanasi',
        'Srinagar', 'Aurangabad', 'Dhanbad', 'Amritsar', 'Navi Mumbai',
        'Allahabad', 'Ranchi', 'Howrah', 'Coimbatore', 'Jabalpur', 'Gwalior'
      ];
      
      return cities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<List<BusRoute>> getPopularRoutes({int limit = 6}) async {
    try {
      QuerySnapshot routesSnapshot = await _firestore
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return routesSnapshot.docs
          .map((doc) => BusRoute.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

class RouteConnection {
  final RouteStop fromStop;
  final RouteStop toStop;
  final double distance;
  final String estimatedDuration;
  final int fare;
  
  RouteConnection({
    required this.fromStop,
    required this.toStop,
    required this.distance,
    required this.estimatedDuration,
    required this.fare,
  });
}
