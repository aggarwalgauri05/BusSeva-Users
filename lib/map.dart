import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  final String busNumber;

  const MapScreen({
    Key? key,
    required this.busNumber,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  Location _locationController = Location();

  // Predefined points (For demo)
  static const LatLng _startPoint = LatLng(37.353113, -122.049977);
  static const LatLng _endPoint = LatLng(37.328206, -122.028487);

  LatLng? _currentPosition; // User location

  BitmapDescriptor? customBusIcon;
  BitmapDescriptor? stopIcon;

  // For demo bus heading and position
  LatLng _busLocation = _startPoint;
  double _busHeading = 0.0;

  @override
  void initState() {
    super.initState();

    _createCustomIcons().then((_) {
      setState(() {});
    });

    _requestLocationPermissionAndListen();
  }

  Future<void> _createCustomIcons() async {
    customBusIcon = await _createBusMarkerIcon();

    stopIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/images/bus_stop.png',
    );
  }

  Future<BitmapDescriptor> _createBusMarkerIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF667EEA);

    // Draw bus body
    final rect =
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 60, 40), const Radius.circular(8));
    canvas.drawRRect(rect, paint);

    // Draw windows
    final windowPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(8, 8, 44, 24), windowPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(60, 40);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _requestLocationPermissionAndListen() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        LatLng newPos = LatLng(locationData.latitude!, locationData.longitude!);
        setState(() {
          _currentPosition = newPos;
          // For demo, move bus a bit with user location (replace with real bus location)
          _busLocation = newPos;
          _busHeading += 5;
          if (_busHeading > 360) _busHeading = 0;
        });

        // Center map on user location
      }
    });
  }

  Future<void> _moveCamera(LatLng target) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(target));
  }

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      // User location
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: _currentPosition!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    // Bus marker - custom icon
    if (customBusIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('bus_marker'),
        position: _busLocation,
        icon: customBusIcon!,
        infoWindow: InfoWindow(
          title: 'Bus ${widget.busNumber}',
          snippet: 'Speed: 45 km/h • ETA: 5 mins',
        ),
        rotation: _busHeading,
        anchor: const Offset(0.5, 0.5),
      ));
    }

    // Bus stops sample markers
    final List<Map<String, dynamic>> busStops = [
      {'name': 'City Center', 'lat': 37.353113, 'lng': -122.049977, 'passed': true},
      {'name': 'Hospital', 'lat': 37.356, 'lng': -122.045, 'passed': false},
      {'name': 'College', 'lat': 37.360, 'lng': -122.040, 'passed': false},
    ];

    for (int i = 0; i < busStops.length; i++) {
      final stop = busStops[i];
      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: LatLng(stop['lat'], stop['lng']),
        icon: stop['passed']
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: stop['name'],
          snippet: stop['passed'] ? 'Passed' : 'Upcoming',
        ),
      ));
    }

    return markers;
  }

  Set<Polyline> _createPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('route_polyline'),
        points: [
          _startPoint,
          const LatLng(37.356, -122.045),
          const LatLng(37.360, -122.040),
          _endPoint,
        ],
        color: const Color(0xFF667EEA),
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      )
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking: ${widget.busNumber}'),
        backgroundColor: const Color(0xFF667EEA),
      ),
      body: _currentPosition == null
          ? const Center(child: Text('Fetching location...'))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _startPoint,
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _createMarkers(),
              polylines: _createPolylines(),
              onMapCreated: (controller) => _controller.complete(controller),
            ),
    );
  }
}
