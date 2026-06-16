import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class DistanceUtil {
  static const Distance _distance = Distance();
  static const double _metersPerDegreeLat = 111320.0;

  static double kmBetween(LatLng from, LatLng to) {
    return _distance.as(LengthUnit.Kilometer, from, to);
  }

  static String formatKm(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(2)} km';
  }

  static String between(LatLng from, LatLng to) {
    return formatKm(kmBetween(from, to));
  }

  /// Convert meters (north = +y, east = +x) to lat/lon offset from a base point.
  static LatLng offsetByMeters(double baseLat, double baseLon, double northMeters, double eastMeters) {
    final latRad = baseLat * math.pi / 180;
    final metersPerDegreeLon = _metersPerDegreeLat * math.cos(latRad).abs().clamp(0.2, 1.0);
    return LatLng(
      baseLat + (northMeters / _metersPerDegreeLat),
      baseLon + (eastMeters / metersPerDegreeLon),
    );
  }

  /// Place a point at [km] distance and [bearingDegrees] from base (0° = north, 90° = east).
  static LatLng offsetByKmAndBearing(double baseLat, double baseLon, double km, double bearingDegrees) {
    final bearingRad = bearingDegrees * math.pi / 180;
    final northM = km * 1000 * math.cos(bearingRad);
    final eastM = km * 1000 * math.sin(bearingRad);
    return offsetByMeters(baseLat, baseLon, northM, eastM);
  }
}