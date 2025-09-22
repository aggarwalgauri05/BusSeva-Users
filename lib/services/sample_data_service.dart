import 'package:cloud_firestore/cloud_firestore.dart';

class SampleDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Call this method once to populate Firestore with sample data.
  

  static Future<void> _setupRoutes() async {
  final routes = [
    // 1) New Route: Delhi → Jaipur
    {
      'createdAt': Timestamp.now(),
      'end': 'Jaipur',
      'estimatedDuration': '5h 00m',
      'fare': {
        'baseFare': 60,
        'perKmRate': 2.0,
      },
      'id': 'route_delhi_jaipur_001',
      'isActive': true,
      'name': 'delhi-jaipur',
      'operatingDays': [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ],
      'start': 'delhi',
      'stops': [
        {
          'arrivalTime': Timestamp.fromDate(DateTime.parse('2025-09-22T08:00:00+05:30')),
          'city': 'Delhi',
          'coordinates': const GeoPoint(28.6139, 77.2090),
          'departureTime': Timestamp.fromDate(DateTime.parse('2025-09-22T08:10:00+05:30')),
          'distanceFromStart': 0,
          'id': 'stop_delhi_001',
          'name': 'ISBT Kashmere Gate',
          'stopOrder': 1,
        },
        {
          'arrivalTime': Timestamp.fromDate(DateTime.parse('2025-09-22T11:00:00+05:30')),
          'city': 'Jaipur',
          'coordinates': const GeoPoint(26.9124, 75.7873),
          'departureTime': Timestamp.fromDate(DateTime.parse('2025-09-22T11:20:00+05:30')),
          'distanceFromStart': 280,
          'id': 'stop_jaipur_001',
          'name': 'Sindhi Camp Bus Stand',
          'stopOrder': 2,
        },
      ],
      'totalDistance': 280,
      'updatedAt': Timestamp.now(),
    },

    // 2) New Route: Delhi → Lucknow
    {
      'createdAt': Timestamp.now(),
      'end': 'Lucknow',
      'estimatedDuration': '8h 45m',
      'fare': {
        'baseFare': 90,
        'perKmRate': 1.8,
      },
      'id': 'route_delhi_lucknow_001',
      'isActive': true,
      'name': 'delhi-lucknow',
      'operatingDays': [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ],
      'start': 'delhi',
      'stops': [
        {
          'arrivalTime': Timestamp.fromDate(DateTime.parse('2025-09-22T07:30:00+05:30')),
          'city': 'Delhi',
          'coordinates': const GeoPoint(28.6139, 77.2090),
          'departureTime': Timestamp.fromDate(DateTime.parse('2025-09-22T07:50:00+05:30')),
          'distanceFromStart': 0,
          'id': 'stop_delhi_002',
          'name': 'Anand Vihar ISBT',
          'stopOrder': 1,
        },
        {
          'arrivalTime': Timestamp.fromDate(DateTime.parse('2025-09-22T16:15:00+05:30')),
          'city': 'Lucknow',
          'coordinates': const GeoPoint(26.8467, 80.9462),
          'departureTime': Timestamp.fromDate(DateTime.parse('2025-09-22T16:35:00+05:30')),
          'distanceFromStart': 500,
          'id': 'stop_lucknow_001',
          'name': 'Lucknow Charbagh',
          'stopOrder': 2,
        },
      ],
      'totalDistance': 500,
      'updatedAt': Timestamp.now(),
    },

    // 3) Additional Delhi - Agra route with different details
    {
      'createdAt': Timestamp.now(),
      'end': 'Agra',
      'estimatedDuration': '4h 15m',
      'fare': {
        'baseFare': 55,
        'perKmRate': 2.4,
      },
      'id': 'route_delhi_agra_002',
      'isActive': true,
      'name': 'delhi-agra-express',
      'operatingDays': [
        'Monday', 'Wednesday', 'Friday', 'Sunday'
      ],
      'start': 'delhi',
      'stops': [
        {
          'arrivalTime': Timestamp.fromDate(DateTime.parse('2025-09-22T06:30:00+05:30')),
          'city': 'Delhi',
          'coordinates': const GeoPoint(28.6139, 77.2090),
          'departureTime': Timestamp.fromDate(DateTime.parse('2025-09-22T06:45:00+05:30')),
          'distanceFromStart': 0,
          'id': 'stop_delhi_003',
          'name': 'ISBT Anand Vihar',
          'stopOrder': 1,
        },
        {
          'arrivalTime': Timestamp.fromDate(DateTime.parse('2025-09-22T10:45:00+05:30')),
          'city': 'Agra',
          'coordinates': const GeoPoint(27.1767, 78.0081),
          'departureTime': Timestamp.fromDate(DateTime.parse('2025-09-22T11:00:00+05:30')),
          'distanceFromStart': 230,
          'id': 'stop_agra_002',
          'name': 'Agra Fort Bus Stand',
          'stopOrder': 2,
        },
      ],
      'totalDistance': 230,
      'updatedAt': Timestamp.now(),
    },
  ];

  for (final route in routes) {
    await _firestore.collection('routes').doc(route['id'] as String?).set(route);
  }
}
// Add this to your sample_data_service.dart
// Add this method to your SampleDataService class
static Future _setupUserTrips() async {
  // Use the actual user ID from the logs
  final String userId = 'rXOtiyQpS0PxXvkUeLOpWU2kRUE2';
  
  final sampleTrips = [
    {
      'userId': userId,
      'busId': 'bus_001',
      'routeId': 'route_delhi_jaipur_001',
      'bookingId': 'BK${DateTime.now().millisecondsSinceEpoch}',
      'fromStopId': 'stop_delhi_001',
      'toStopId': 'stop_jaipur_001',
      'fromStopName': 'ISBT Kashmere Gate',
      'toStopName': 'Sindhi Camp Bus Stand',
      'seatNumbers': ['12A', '12B'],
      'departureTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4))),
      'bookingDate': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))),
      'status': 'upcoming',
      'totalFare': 280.0,
      'paymentMethod': 'UPI',
      'busNumber': 'DL-1CA-1234',
      'smsAlertsEnabled': false,
    },
    {
      'userId': userId,
      'busId': 'bus_002',
      'routeId': 'route_delhi_lucknow_001',
      'bookingId': 'BK${DateTime.now().millisecondsSinceEpoch + 1}',
      'fromStopId': 'stop_delhi_002',
      'toStopId': 'stop_lucknow_001',
      'fromStopName': 'Anand Vihar ISBT',
      'toStopName': 'Lucknow Charbagh',
      'seatNumbers': ['8A'],
      'departureTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 1))),
      'bookingDate': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))),
      'status': 'upcoming',
      'totalFare': 500.0,
      'paymentMethod': 'Card',
      'busNumber': 'DL-1CB-5678',
      'smsAlertsEnabled': true,
    },
    // Add a completed trip for history
    {
      'userId': userId,
      'busId': 'bus_001',
      'routeId': 'route_delhi_agra_002',
      'bookingId': 'BK${DateTime.now().millisecondsSinceEpoch + 2}',
      'fromStopId': 'stop_delhi_003',
      'toStopId': 'stop_agra_002',
      'fromStopName': 'ISBT Anand Vihar',
      'toStopName': 'Agra Fort Bus Stand',
      'seatNumbers': ['15C'],
      'departureTime': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 2))),
      'bookingDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 3))),
      'status': 'completed',
      'totalFare': 230.0,
      'paymentMethod': 'Cash',
      'busNumber': 'DL-1CA-1234',
      'smsAlertsEnabled': false,
    },
    // Add an ongoing trip
    {
      'userId': userId,
      'busId': 'bus_001',
      'routeId': 'route_delhi_jaipur_001',
      'bookingId': 'BK${DateTime.now().millisecondsSinceEpoch + 3}',
      'fromStopId': 'stop_delhi_001',
      'toStopId': 'stop_jaipur_001',
      'fromStopName': 'ISBT Kashmere Gate',
      'toStopName': 'Sindhi Camp Bus Stand',
      'seatNumbers': ['10A'],
      'departureTime': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30))),
      'bookingDate': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 6))),
      'status': 'ongoing',
      'totalFare': 280.0,
      'paymentMethod': 'UPI',
      'busNumber': 'DL-1CA-1234',
      'smsAlertsEnabled': true,
    },
  ];

  for (final trip in sampleTrips) {
    await _firestore.collection('user_trips').add(trip);
  }
  
  print('✅ Created ${sampleTrips.length} sample user trips');
}

// Update your setupSampleData method to include this:
static Future setupSampleData() async {
  try {
    await _setupRoutes();
    await _setupBuses();
    await _setupLiveLocations();
    await _setupUserTrips(); // Add this line
    print('✅ Sample data setup completed!');
  } catch (e) {
    print('❌ Error setting up sample data: $e');
    rethrow;
  }
}



  static Future<void> _setupBuses() async {
    final buses = [
      {
        'busId': 'bus_001',
        'busNumber': 'DL-1CA-1234',
        'busName': 'Volvo Multi-Axle',
        'specifications': {
          'busType': 'AC Sleeper',
          'totalSeats': 40,
          'manufacturer': 'Volvo',
          'model': '9600',
          'yearOfManufacture': 2022,
          'fuelType': 'Diesel'
        },
        'operator': {
          'operatorId': 'op_001',
          'operatorName': 'RedBus Travels',
          'operatorPhone': '+911234567890',
          'operatorEmail': 'contact@redbus.com',
          'licenseNumber': 'DL-OP-2023-001'
        },
        'driver': {
          'driverId': 'driver_001',
          'driverName': 'Rajesh Kumar',
          'driverPhone': '+919876543210',
          'licenseNumber': 'DL-0520230045123',
          'experienceYears': 12,
          'verified': true,
          'rating': 4.5
        },
        'facilities': {
          'hasAC': true,
          'hasWiFi': true,
          'hasCharging': true,
          'hasWashroom': true,
          'hasWater': true,
          'hasEntertainment': false,
          'accessibility': false
        },
        'seatLayout': _generateSeatLayout(40),
        'currentLocation': {
          'latitude': 28.6139,
          'longitude': 77.2090,
          'lastUpdated': FieldValue.serverTimestamp(),
          'speed': 0,
          'heading': 0
        },
        'status': {
          'isActive': true,
          'currentRoute': 'route_delhi_mumbai_001',
          'occupancy': 15,
          'nextMaintenance': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
          'lastInspection': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5)))
        },
        'ratings': {
          'overall': 4.3,
          'cleanliness': 4.5,
          'comfort': 4.2,
          'punctuality': 4.0,
          'totalReviews': 156
        },
        'safety': {
          'gpsEnabled': true,
          'panicButton': true,
          'cctv': true,
          'fireExtinguisher': true,
          'firstAid': true,
          'lastSafetyCheck': FieldValue.serverTimestamp()
        }
      },
      {
        'busId': 'bus_002',
        'busNumber': 'DL-1CB-5678',
        'busName': 'Ashok Leyland AC',
        'specifications': {
          'busType': 'AC Semi-Sleeper',
          'totalSeats': 45,
          'manufacturer': 'Ashok Leyland',
          'model': 'Viking',
          'yearOfManufacture': 2021,
          'fuelType': 'CNG'
        },
        'operator': {
          'operatorId': 'op_002',
          'operatorName': 'Sharma Travels',
          'operatorPhone': '+911234567891',
          'operatorEmail': 'booking@sharmatravels.com',
          'licenseNumber': 'DL-OP-2023-002'
        },
        'driver': {
          'driverId': 'driver_002',
          'driverName': 'Suresh Sharma',
          'driverPhone': '+919876543211',
          'licenseNumber': 'DL-0520230045124',
          'experienceYears': 8,
          'verified': true,
          'rating': 4.2
        },
        'facilities': {
          'hasAC': true,
          'hasWiFi': false,
          'hasCharging': true,
          'hasWashroom': false,
          'hasWater': true,
          'hasEntertainment': true,
          'accessibility': true
        },
        'seatLayout': _generateSeatLayout(45),
        'status': {
          'isActive': true,
          'currentRoute': 'route_delhi_bangalore_001',
          'occupancy': 32,
          'nextMaintenance': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
          'lastInspection': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 3)))
        },
        'ratings': {
          'overall': 4.0,
          'cleanliness': 3.8,
          'comfort': 4.1,
          'punctuality': 4.3,
          'totalReviews': 89
        },
        'safety': {
          'gpsEnabled': true,
          'panicButton': true,
          'cctv': false,
          'fireExtinguisher': true,
          'firstAid': true,
          'lastSafetyCheck': FieldValue.serverTimestamp()
        }
      }
    ];

    for (final bus in buses) {
      await _firestore.collection('buses').doc(bus['busId'] as String?).set(bus);
    }
  }

  static List<Map<String, dynamic>> _generateSeatLayout(int totalSeats) {
    List<Map<String, dynamic>> seats = [];
    final columns = ['A', 'B', 'C', 'D'];

    final seatsPerRow = 4;
    final totalRows = (totalSeats / seatsPerRow).ceil();

    for (int row = 1; row <= totalRows; row++) {
      for (int col = 0; col < seatsPerRow; col++) {
        if (seats.length >= totalSeats) break;
        seats.add({
          'seatNumber': '$row${columns[col]}',
          'seatType': (col == 0 || col == 3) ? 'Window' : 'Aisle',
          'row': row,
          'column': columns[col],
          'isAvailable': true,
        });
      }
    }
    return seats;
  }

  static Future<void> _setupLiveLocations() async {
    final liveLocations = [
      {
        'busId': 'bus_001',
        'busNumber': 'DL-1CA-1234',
        'currentLocation': {
          'latitude': 28.6139,
          'longitude': 77.2090,
          'accuracy': 10.0
        },
        'movement': {
          'speed': 0.0,
          'heading': 0.0,
          'isMoving': false
        },
        'route': {
          'routeId': 'route_delhi_mumbai_001',
          'currentStopId': 'stop_001',
          'nextStopId': 'stop_002',
          'distanceToNextStop': 254.5,
          'estimatedArrival': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4)))
        },
        'passenger': {
          'currentOccupancy': 15,
          'maxCapacity': 40,
          'occupancyPercentage': 37.5
        },
        'metadata': {
          'lastUpdated': FieldValue.serverTimestamp(),
          'updateFrequency': 1,
          'gpsSignalStrength': 4,
          'batteryLevel': 85,
          'isOnline': true
        }
      },
      {
        'busId': 'bus_002',
        'busNumber': 'DL-1CB-5678',
        'currentLocation': {
          'latitude': 26.9124,
          'longitude': 75.7873,
          'accuracy': 15.0
        },
        'movement': {
          'speed': 65.0,
          'heading': 180.0,
          'isMoving': true
        },
        'route': {
          'routeId': 'route_delhi_bangalore_001',
          'currentStopId': 'stop_002',
          'nextStopId': 'stop_003',
          'distanceToNextStop': 120.8,
          'estimatedArrival': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2)))
        },
        'passenger': {
          'currentOccupancy': 32,
          'maxCapacity': 45,
          'occupancyPercentage': 71.1
        },
        'metadata': {
          'lastUpdated': FieldValue.serverTimestamp(),
          'updateFrequency': 1,
          'gpsSignalStrength': 5,
          'batteryLevel': 92,
          'isOnline': true
        }
      }
    ];

    for (final location in liveLocations) {
      await _firestore.collection('live_locations').doc(location['busId'] as String?).set(location);
    }
  }
}
