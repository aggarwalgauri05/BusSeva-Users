import 'dart:async';

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

Location _locationController = new Location();
  
static const LatLng _pGooglePlex = LatLng(37.353113188232136, -122.04997650519678);
static const LatLng _pApplePlex  = LatLng(37.3282059877143, -122.02848663864638);

  LatLng? _currentP=null;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking: ${widget.busNumber}'),
      ),
      body: _currentP==null 
      ? const Center(
        child: Text('Fetching location...'),
      ) : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _pGooglePlex, 
          zoom: 12,
        ),
        markers: {
           Marker(
            markerId: MarkerId("_currentLocation"),
            icon: BitmapDescriptor.defaultMarker,
            position: _currentP!,
            infoWindow: InfoWindow(title: 'My Location'),
          ),
          Marker(
            markerId: MarkerId("_sourceLocation"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            position: _pGooglePlex,
            infoWindow: InfoWindow(title: 'Bus ${widget.busNumber}'),
          ),
          Marker(
            markerId: MarkerId("_destinationLocation"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            position: _pApplePlex,
            infoWindow: const InfoWindow(title: 'Destination'),
          ),
        },
      ),
    );
  }
  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
if (!_serviceEnabled) {
  _serviceEnabled = await _locationController.requestService();
  if (!_serviceEnabled) {
    return;
  }
}
// no else/return here → continue to permission check


    _permissionGranted= await _locationController.hasPermission();
    if(_permissionGranted==PermissionStatus.denied){  
      _permissionGranted= await _locationController.requestPermission();
      if(_permissionGranted!=PermissionStatus.granted){
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      // Use current location
     if(currentLocation.latitude!=null && currentLocation.longitude!=null){
       setState(() {
         _currentP=LatLng(currentLocation.latitude!, currentLocation.longitude!);
      print(_currentP);
       });
     }
    });
}}