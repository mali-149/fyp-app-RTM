import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:skyride/Screens/chat/chat.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/database/session_helper.dart';
import 'package:skyride/theme/app_theme.dart';
import 'package:skyride/utils/distance_util.dart';
import 'package:skyride/widgets/shimmer_loading.dart';

class Home extends StatefulWidget {
  final String sessionKey;

  const Home({Key? key, required this.sessionKey}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  final TextEditingController _searchController = TextEditingController();
  LatLng? _destination;
  double? _distanceInKm;
  List<Marker> _providerMarkers = [];
  List<Marker> _requestUserMarkers = [];
  List<Marker> _externalPoiMarkers = [];
  List<Map<String, dynamic>> _searchSuggestions = [];
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _followUserLocation = false;
  bool _hasAutoFittedProviders = false;
  bool _isLoadingRole = true;
  String? _currentUserId;
  String _userRole = 'user';
  Map<String, dynamic>? _currentUser;
  StreamSubscription<LocationData>? _locationSub;
  String? _routeLabel;
  double? _providersAnchorLat;
  double? _providersAnchorLon;
  static const double _providerMaxRangeKm = 50.0;
  List<Map<String, dynamic>> _allProviders = [];

  bool get _isProvider => _userRole == 'machanic' || _userRole == 'fuelpump';

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _init() async {
    try {
      await _loadUserRole();
      await _initLocationTracking();
      _ensureFallbackLocation();
      if (_isProvider) {
        await _loadPendingRequests();
      } else {
        await _loadProviders();
      }
    } catch (e) {
      debugPrint('Home init error: $e');
      _ensureFallbackLocation();
    } finally {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  void _ensureFallbackLocation() {
    if (_currentLocation != null) return;
    final lat = (_currentUser?['latitude'] as num?)?.toDouble() ?? 33.6844;
    final lon = (_currentUser?['longitude'] as num?)?.toDouble() ?? 73.0479;
    _currentLocation = LatLng(lat, lon);
    _routePoints = [_currentLocation!];
  }

  Future<void> _loadUserRole() async {
    _currentUserId = await SessionHelper.getCurrentUserId();
    _currentUser = await SessionHelper.getCurrentUser();
    _userRole = _currentUser?['role'] as String? ?? 'user';
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    await _loadUserRole();
    if (_isProvider) {
      await _loadPendingRequests();
    } else {
      await _loadProviders();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadProviders() async {
    final raw = await SkyRideApi.instance.getMechanicsAndFuelPumps();
    _allProviders = raw.map((u) => Map<String, dynamic>.from(u)).toList();
    _refreshProvidersInRange();
  }

  List<Map<String, dynamic>> _filterProvidersInRange(List<Map<String, dynamic>> raw) {
    if (_currentLocation == null) return [];

    final inRange = <Map<String, dynamic>>[];
    for (final user in raw) {
      final lat = (user['latitude'] as num?)?.toDouble();
      final lon = (user['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final km = DistanceUtil.kmBetween(_currentLocation!, LatLng(lat, lon));
      if (km > _providerMaxRangeKm) continue;

      final copy = Map<String, dynamic>.from(user);
      copy['distanceKm'] = km;
      copy['distanceLabel'] = DistanceUtil.formatKm(km);
      inRange.add(copy);
    }

    inRange.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return inRange;
  }

  void _refreshProvidersInRange() {
    if (!mounted) return;
    final filtered = _filterProvidersInRange(_allProviders);
    setState(() {
      _providers = filtered;
      _providerMarkers = _buildProviderMarkers(filtered);
    });
    if (!_isProvider && filtered.isNotEmpty && !_hasAutoFittedProviders) {
      _hasAutoFittedProviders = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToProviders());
    }
  }

  void _onUserMapInteraction() {
    if (_followUserLocation && mounted) {
      setState(() => _followUserLocation = false);
    }
  }

  void _fitMapToProviders() {
    if (_currentLocation == null || _isProvider || _providers.isEmpty) return;

    final points = <LatLng>[_currentLocation!];
    for (final provider in _providers) {
      final lat = (provider['latitude'] as num?)?.toDouble();
      final lon = (provider['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) points.add(LatLng(lat, lon));
    }
    if (points.length < 2) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(56),
      ),
    );
  }

  Future<void> _anchorProvidersNearUser(double lat, double lon) async {
    if (_providersAnchorLat != null && _providersAnchorLon != null) {
      final movedKm = DistanceUtil.kmBetween(
        LatLng(_providersAnchorLat!, _providersAnchorLon!),
        LatLng(lat, lon),
      );
      if (movedKm < 1.5) return;
    }
    await SkyRideApi.instance.ensureProvidersNearLocation(lat, lon);
    _providersAnchorLat = lat;
    _providersAnchorLon = lon;
  }

  Future<void> _loadPendingRequests() async {
    if (_currentUserId == null) return;
    final requests = await SkyRideApi.instance.getPendingRequestsForProvider(_currentUserId!);
    final mutableRequests = requests.map((r) => Map<String, dynamic>.from(r)).toList();
    if (!mounted) return;
    setState(() {
      _pendingRequests = mutableRequests;
      _requestUserMarkers = _buildRequestUserMarkers(mutableRequests);
    });
  }

  List<Marker> _buildProviderMarkers(List<Map<String, dynamic>> users) {
    return users.map((user) {
      final lat = (user['latitude'] as num?)?.toDouble();
      final lon = (user['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;

      final role = user['role'] as String? ?? '';
      final username = user['username'] as String? ?? '';
      final distLabel = user['distanceLabel'] as String?;

      return Marker(
        point: LatLng(lat, lon),
        width: 130,
        height: 78,
        child: GestureDetector(
          onTap: () => _showProviderSheet(user),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: role == 'fuelpump' ? Colors.red.shade700 : Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(username, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
              if (distLabel != null)
                Text(distLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              Icon(
                role == 'fuelpump' ? Icons.local_gas_station : Icons.build,
                color: role == 'fuelpump' ? Colors.red : Colors.green,
                size: 32,
              ),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  LatLng? _requestUserPoint(Map<String, dynamic> req) {
    final user = req['user'] as Map<String, dynamic>?;
    final profileLat = (user?['latitude'] as num?)?.toDouble();
    final profileLon = (user?['longitude'] as num?)?.toDouble();
    final reqLat = (req['user_latitude'] as num?)?.toDouble();
    final reqLon = (req['user_longitude'] as num?)?.toDouble();

    if (reqLat != null && reqLon != null) {
      return LatLng(reqLat, reqLon);
    }
    if (profileLat != null && profileLon != null) {
      return LatLng(profileLat, profileLon);
    }
    return null;
  }

  List<Marker> _buildRequestUserMarkers(List<Map<String, dynamic>> requests) {
    return requests.map((req) {
      final point = _requestUserPoint(req);
      if (point == null) return null;

      final user = req['user'] as Map<String, dynamic>?;
      final username = user?['username'] as String? ?? 'User';
      String? distLabel;
      if (_currentLocation != null) {
        distLabel = DistanceUtil.between(_currentLocation!, point);
      }

      return Marker(
        point: point,
        width: 130,
        height: 78,
        child: GestureDetector(
          onTap: () => _showRequestDetailSheet(req),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(username, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
              if (distLabel != null)
                Text(distLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              const Icon(Icons.person_pin_circle, color: AppTheme.primary, size: 32),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  Future<void> _showProviderSheet(Map<String, dynamic> provider) async {
    if (_currentUserId == null || _currentLocation == null) return;

    final providerId = provider['id'] as String;
    final existing = await SkyRideApi.instance.getRequestBetween(_currentUserId!, providerId);
    final status = existing?['status'] as String?;

    final pLat = (provider['latitude'] as num?)?.toDouble();
    final pLon = (provider['longitude'] as num?)?.toDouble();
    final distText = provider['distanceLabel'] as String? ??
        (pLat != null && pLon != null && _currentLocation != null
            ? DistanceUtil.between(_currentLocation!, LatLng(pLat, pLon))
            : null);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.15),
                      child: Icon(
                        provider['role'] == 'fuelpump' ? Icons.local_gas_station : Icons.build,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(provider['username'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            provider['role'] == 'fuelpump' ? 'Fuel Pump' : 'Mechanic',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text('Phone: ${provider['phone']}', style: const TextStyle(color: AppTheme.textSecondary)),
                          if (distText != null)
                            Text('Distance: $distText', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (status == 'pending')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Request pending — waiting for acceptance'),
                        ),
                      ],
                    ),
                  )
                else if (status == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              user: SkyRideApi.instance.userToDisplayMap(provider),
                              currentUserId: _currentUserId!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Open Chat'),
                    ),
                  )
                else if (status == 'rejected')
                  Column(
                    children: [
                      const Text('Previous request was rejected.', style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _sendRequest(provider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Send New Request'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendRequest(provider);
                      },
                      icon: const Icon(Icons.send),
                      label: Text(
                        provider['role'] == 'fuelpump' ? 'Request Fuel Delivery' : 'Request Mechanic',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRequest(Map<String, dynamic> provider) async {
    if (_currentUserId == null || _currentLocation == null) {
      Fluttertoast.showToast(msg: 'Location not available');
      return;
    }

    await SkyRideApi.instance.updateUserLocation(
      _currentUserId!,
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    );

    final role = provider['role'] == 'fuelpump' ? 'fuel' : 'mechanic';
    final result = await SkyRideApi.instance.createServiceRequest(
      userId: _currentUserId!,
      providerId: provider['id'] as String,
      userLatitude: _currentLocation!.latitude,
      userLongitude: _currentLocation!.longitude,
      message: 'Request for $role service',
    );

    if (result != null) {
      Fluttertoast.showToast(
        msg: 'Request sent to ${provider['username']}!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await _loadProviders();
    } else {
      Fluttertoast.showToast(
        msg: 'Request already pending or accepted',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    }
  }

  void _showRequestDetailSheet(Map<String, dynamic> request) {
    final user = request['user'] as Map<String, dynamic>;
    final point = _requestUserPoint(request);
    String? distText;
    if (_currentLocation != null && point != null) {
      distText = DistanceUtil.between(_currentLocation!, point);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service Request', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('From: ${user['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Phone: ${user['phone']}'),
                Text('Message: ${request['message'] ?? 'Service request'}'),
                if (distText != null)
                  Text('Distance from you: $distText', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (point != null)
                  Text(
                    'Location: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                const SizedBox(height: 16),
                if (point != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _routeToLocation(point, label: user['username'] ?? 'User');
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Route'),
                    ),
                  ),
                if (point != null) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _rejectRequest(request['id'] as int);
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _acceptRequest(request);
                        },
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    if (_currentUserId == null) return;

    final success = await SkyRideApi.instance.acceptRequest(
      request['id'] as int,
      _currentUserId!,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Request accepted! Chat started.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await _loadPendingRequests();

      final user = request['user'] as Map<String, dynamic>;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              user: SkyRideApi.instance.userToDisplayMap(user),
              currentUserId: _currentUserId!,
            ),
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    if (_currentUserId == null) return;
    await SkyRideApi.instance.rejectRequest(requestId, _currentUserId!);
    Fluttertoast.showToast(msg: 'Request rejected');
    await _loadPendingRequests();
  }

  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await _location.requestService();

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
      }

      if (permissionGranted == PermissionStatus.granted ||
          permissionGranted == PermissionStatus.grantedLimited) {
        final locData = await _location.getLocation();
        if (locData.latitude != null && locData.longitude != null) {
          final initialPoint = LatLng(locData.latitude!, locData.longitude!);
          if (mounted) {
            setState(() {
              _currentLocation = initialPoint;
              _routePoints = [initialPoint];
            });
          }

          if (_currentUserId != null) {
            if (_isProvider) {
              final user = await SkyRideApi.instance.getUserById(_currentUserId!);
              if (user != null) {
                _currentUser = Map<String, dynamic>.from(user);
              }
            } else {
              await SkyRideApi.instance.updateUserLocationSilent(
                _currentUserId!,
                locData.latitude!,
                locData.longitude!,
              );
              await _anchorProvidersNearUser(locData.latitude!, locData.longitude!);
            }
          }

          await _locationSub?.cancel();
          _locationSub = _location.onLocationChanged.listen((LocationData newLoc) async {
            if (!mounted) return;
            if (newLoc.latitude != null && newLoc.longitude != null) {
              final newPoint = LatLng(newLoc.latitude!, newLoc.longitude!);

              if (_currentUserId != null && !_isProvider) {
                await SkyRideApi.instance.updateUserLocationSilent(
                  _currentUserId!,
                  newLoc.latitude!,
                  newLoc.longitude!,
                );
              }

              final filtered = !_isProvider ? _filterProvidersInRange(_allProviders) : _providers;
              setState(() {
                _currentLocation = newPoint;
                if (!_isProvider) {
                  _providers = filtered;
                  _providerMarkers = _buildProviderMarkers(filtered);
                }
              });

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

  void _onSearchChanged() => _fetchSuggestions(_searchController.text);

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchSuggestions = []);
      return;
    }

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=8');

    try {
      final response = await http.get(url, headers: {'User-Agent': 'FlutterMapApp', 'Accept-Language': 'en'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchSuggestions = data.map<Map<String, dynamic>>((e) => e as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Suggestion fetch error: $e");
    }
  }

  Future<void> _onSuggestionTap(Map<String, dynamic> suggestion) async {
    final lat = double.tryParse(suggestion['lat']);
    final lon = double.tryParse(suggestion['lon']);

    if (lat != null && lon != null) {
      final dest = LatLng(lat, lon);
      setState(() {
        _destination = dest;
        _searchSuggestions = [];
        _searchController.text = suggestion['display_name'];
        _routeLabel = suggestion['display_name'];
      });
      await _routeToLocation(dest, label: suggestion['display_name']);
    }
  }

  Future<void> _routeToLocation(LatLng dest, {String? label}) async {
    if (_currentLocation == null) return;

    setState(() {
      _destination = dest;
      if (label != null) _routeLabel = label;
    });

    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${dest.longitude},${dest.latitude}?geometries=geojson');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final distanceInMeters = data['routes'][0]['distance'] as double;
        if (mounted) {
          setState(() {
            _routePoints = coords.map((point) => LatLng(point[1] as double, point[0] as double)).toList();
            _distanceInKm = distanceInMeters / 1000;
          });
        }
        _mapController.move(dest, 15);
      }
    } else {
      final km = DistanceUtil.kmBetween(_currentLocation!, dest);
      if (mounted) setState(() => _distanceInKm = km);
    }
  }


  Future<void> fetchPOIs() async {
    if (_currentLocation == null) return;

    final lat = _currentLocation!.latitude;
    final lon = _currentLocation!.longitude;
    const radius = 1000;

    final query = '''
      [out:json];
      (
        node["amenity"="hospital"](around:$radius,$lat,$lon);
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
        final poiList = <Marker>[];

        for (var el in elements) {
          if (el['lat'] != null && el['lon'] != null) {
            poiList.add(Marker(
              point: LatLng(el['lat'], el['lon']),
              width: 40,
              height: 40,
              child: const Icon(Icons.local_hospital, color: Colors.red, size: 30),
            ));
          }
        }

        if (mounted) setState(() => _externalPoiMarkers = poiList);
      }
    } catch (e) {
      debugPrint("POI fetch error: $e");
    }
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search any location",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: _fetchSuggestions,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _fetchSuggestions(_searchController.text),
                style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48), padding: EdgeInsets.zero),
                child: const Icon(Icons.directions),
              ),
            ],
          ),
          if (_searchSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey)),
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _searchSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place, color: AppTheme.primary),
                    title: Text(suggestion['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _onSuggestionTap(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistanceBanner() {
    if (_distanceInKm == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _routeLabel != null
                  ? 'Distance to $_routeLabel: ${_distanceInKm!.toStringAsFixed(2)} km'
                  : 'Distance: ${_distanceInKm!.toStringAsFixed(2)} km',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRequestsPanel() {
    if (_pendingRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: const Text('No pending requests. User locations will appear when someone requests your service.'),
      );
    }

    return Container(
      height: 200,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Pending Requests (${_pendingRequests.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                final req = _pendingRequests[index];
                final user = req['user'] as Map<String, dynamic>;
                final point = _requestUserPoint(req);
                String? dist;
                if (_currentLocation != null && point != null) {
                  dist = DistanceUtil.between(_currentLocation!, point);
                }
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: SizedBox(
                    width: 210,
                    height: 140,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['username'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (dist != null)
                                Text('Distance: $dist', style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                              const SizedBox(height: 4),
                              Text(
                                req['message'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _rejectRequest(req['id'] as int),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _acceptRequest(req),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.screenBackground,
      appBar: AppBar(
        title: Text(_isProvider ? 'Incoming Requests' : 'Find Help Nearby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (_isProvider) {
                await _loadPendingRequests();
              } else {
                if (_currentLocation != null) {
                  _providersAnchorLat = null;
                  _providersAnchorLon = null;
                  await _anchorProvidersNearUser(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                  );
                }
                await _loadProviders();
                if (_currentLocation != null) {
                  _fitMapToProviders();
                }
              }
            },
          ),
        ],
      ),
      body: _isLoadingRole || _currentLocation == null
          ? const ShimmerMapLoading()
          : Column(
              children: [
                _buildSearchSection(),
                if (!_isProvider)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _legendDot(Colors.green, 'Mechanic'),
                        const SizedBox(width: 12),
                        _legendDot(Colors.red, 'Fuel Pump'),
                        const Spacer(),
                        Text('${_providers.length} within 50 km', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                if (_isProvider)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _legendDot(AppTheme.primary, 'User Request'),
                        const Spacer(),
                        Text('${_pendingRequests.length} pending', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                _buildDistanceBanner(),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation!,
                      initialZoom: _isProvider ? 15 : 11,
                      interactionOptions: const InteractionOptions(enableMultiFingerGestureRace: true),
                      onMapEvent: (event) {
                        if (event.source != MapEventSource.mapController) {
                          _onUserMapInteraction();
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.skyride',
                      ),
                      CurrentLocationLayer(
                        alignPositionOnUpdate: AlignOnUpdate.never,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                          ),
                          if (_destination != null)
                            Marker(
                              point: _destination!,
                              width: 60,
                              height: 60,
                              child: const Icon(Icons.place, color: Colors.red, size: 40),
                            ),
                          if (_isProvider) ..._requestUserMarkers else ..._providerMarkers,
                          if (!_isProvider) ..._externalPoiMarkers,
                        ],
                      ),
                      PolylineLayer(
                        polylines: [
                          if (_routePoints.length > 1)
                            Polyline(points: _routePoints, color: Colors.purple, strokeWidth: 4.0),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isProvider) _buildProviderRequestsPanel(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_currentLocation != null) {
            setState(() => _followUserLocation = true);
            _mapController.move(_currentLocation!, 17);
          }
        },
        child: const Icon(Icons.navigation),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
