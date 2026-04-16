import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  final TextEditingController _searchController = TextEditingController();
  LatLng? _destination;
  double? _distanceInKm;
  List<Marker> _poiMarkers = [];
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _followUserLocation = true;


  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _searchController.addListener(_onSearchChanged);
    // _followUserLocation = false;
    // fetchMechanicsAndFuelProviders(); // Add this line


  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }



  Future<void> fetchMechanicsAndFuelProviders() async {
    final url = Uri.parse('https://skyride.onrender.com/api/getmechanicfuel');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List users = data['users'];

        List<Marker> markers = users.map((user) {
          final coords = user['location']['coordinates'];
          final lat = coords[1]; // GeoJSON format: [lon, lat]
          final lon = coords[0];
          final role = user['role'];
          final username = user['username'];

          IconData iconData = Icons.location_on; // Default
          Color iconColor = Colors.blue;

          if (role == 'machanic') {
            iconData = Icons.build;
            iconColor = Colors.green;
          } else if (role == 'fuelpump') {
            iconData = Icons.local_gas_station;
            iconColor = Colors.red;
          }

          return Marker(
            point: LatLng(lat, lon),
            width: 120,
            height: 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    username,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                Icon(
                  iconData,
                  color: iconColor,
                  size: 36,
                ),
              ],
            ),
          );
        }).toList();

        setState(() {
          _poiMarkers.clear(); // optional: clear old markers if needed
          _poiMarkers.addAll(markers);
        });
      } else {
        debugPrint('API call failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching mechanics/fuel providers: $e');
    }
  }



  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
      }

      if (permissionGranted == PermissionStatus.granted ||
          permissionGranted == PermissionStatus.grantedLimited) {
        final locData = await _location.getLocation();
        if (locData.latitude != null && locData.longitude != null) {
          final initialPoint = LatLng(locData.latitude!, locData.longitude!);
          setState(() {
            _currentLocation = initialPoint;
            _routePoints.add(initialPoint);
          });

          _location.onLocationChanged.listen((LocationData newLoc) {
            if (newLoc.latitude != null && newLoc.longitude != null) {
              final newPoint = LatLng(newLoc.latitude!, newLoc.longitude!);
              setState(() {
                _currentLocation = newPoint;
              });

              // Only move if follow is true
              if (_followUserLocation) {
                _mapController.move(newPoint, _mapController.camera.zoom);
              }
            }
          });


        }
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _onSearchChanged() {
    _fetchSuggestions(_searchController.text);
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _searchSuggestions = []);
      return;
    }

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&countrycodes=pk');

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlutterMapApp',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        setState(() {
          _searchSuggestions = data
              .map<Map<String, dynamic>>(
                  (e) => e as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Suggestion fetch error: $e");
    }
  }


  Future<void> _onSuggestionTap(Map<String, dynamic> suggestion) async {
    final lat = double.tryParse(suggestion['lat']);
    final lon = double.tryParse(suggestion['lon']);

    if (lat != null && lon != null) {
      setState(() {
        _destination = LatLng(lat, lon);
        _searchSuggestions = [];
        _searchController.text = suggestion['display_name'];
      });
      await _fetchRoute();
      await fetchPOIs();
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;

    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${_destination!.longitude},${_destination!.latitude}?geometries=geojson');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      final distanceInMeters = data['routes'][0]['distance'] as double;
      setState(() {
        _routePoints = coords
            .map((point) => LatLng(point[1] as double, point[0] as double))
            .toList();
        _distanceInKm = distanceInMeters / 1000;
      });
      _mapController.move(_destination!, 15);
    }
  }

  Future<void> fetchPOIs() async {
    if (_currentLocation == null) return;

    final lat = _currentLocation!.latitude;
    final lon = _currentLocation!.longitude;
    final radius = 1000;

    final query = '''
      [out:json];
      (
        node["amenity"="hospital"](around:$radius,$lat,$lon);
        node["amenity"="fuel"](around:$radius,$lat,$lon);
      );
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'];
        List<Marker> poiList = [];

        for (var el in elements) {
          if (el['lat'] != null && el['lon'] != null) {
            final point = LatLng(el['lat'], el['lon']);
            final type = el['tags']?['amenity'] ?? 'POI';

            poiList.add(Marker(
              point: point,
              width: 40,
              height: 40,
              child: Icon(
                type == 'hospital'
                    ? Icons.local_hospital
                    : Icons.local_gas_station,
                color: type == 'hospital' ? Colors.red : Colors.orange,
                size: 30,
              ),
            ));
          }
        }

        setState(() {
          _poiMarkers = poiList;
        });
      }
    } catch (e) {
      debugPrint("POI fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Center(child: Text("Live Map & Routing"))),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search location",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _fetchSuggestions(_searchController.text),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),
                if (_searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                    ),
                    height: 100,
                    child: ListView.builder(
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          title: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              suggestion['display_name'],
                              style: const TextStyle(overflow: TextOverflow.visible),
                            ),
                          ),
                          onTap: () => _onSuggestionTap(suggestion),
                        );
                      },
                    ),
                  )

              ],
            ),
          ),
          if (_distanceInKm != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Distance: ${_distanceInKm!.toStringAsFixed(2)} km",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  enableMultiFingerGestureRace: true,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.yourapp',
                ),
                CurrentLocationLayer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.my_location,
                          color: Colors.blue, size: 40),
                    ),
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 60,
                        height: 60,
                        child: const Icon(Icons.place,
                            color: Colors.red, size: 40),
                      ),
                    ..._poiMarkers,
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.purple,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            setState(() {
              _followUserLocation = true;
            });
            _mapController.move(_currentLocation!, 17);
          }
        },
        child: const Icon(Icons.navigation),
      ),
    );
  }
}
