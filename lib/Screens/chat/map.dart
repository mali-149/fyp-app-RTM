import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:math'; // Import the math package


class ViewLocationScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const ViewLocationScreen({
    required this.latitude,
    required this.longitude,
    Key? key,
  }) : super(key: key);

  @override
  _ViewLocationScreenState createState() => _ViewLocationScreenState();
}

class _ViewLocationScreenState extends State<ViewLocationScreen> {
  late LocationData _currentLocation;
  late bool _isLocationReady;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _isLocationReady = false;
    _distance = 0.0;
    _getCurrentLocation();
  }

  // Get the current location using the Location package
  Future<void> _getCurrentLocation() async {
    Location location = Location();
    _currentLocation = await location.getLocation();
    setState(() {
      _isLocationReady = true;
      _distance = _calculateDistance(
        _currentLocation.latitude!,
        _currentLocation.longitude!,
        widget.latitude,
        widget.longitude,
      );
    });
  }

  // Calculate distance between two points using Haversine formula
  // Inside your class _ViewLocationScreenState
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Pi/180
    var a = 0.5 -
        (cos((lat2 - lat1) * p) / 2) +
        (cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2);
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text("View Location"),
        backgroundColor: Color(0xFFF25F12),
        foregroundColor: Colors.black,
      ),
      body: _isLocationReady
          ? FlutterMap(
        mapController: MapController(),
        options: MapOptions(
          initialCenter: LatLng(_currentLocation.latitude!, _currentLocation.longitude!),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.yourapp',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_currentLocation.latitude!, _currentLocation.longitude!),
                width: 40,
                height: 40,
                child: Icon(
                  Icons.my_location,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              Marker(
                point: point,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  LatLng(_currentLocation.latitude!, _currentLocation.longitude!),
                  point,
                ],
                strokeWidth: 4.0,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
      bottomNavigationBar: _isLocationReady
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Distance: ${_distance.toStringAsFixed(2)} km',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      )
          : SizedBox(),
    );
  }
}
