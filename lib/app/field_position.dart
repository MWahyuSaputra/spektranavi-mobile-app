import 'dart:math' as math;

/// Koordinat relatif terhadap titik acuan yang tetap selama satu sesi.
/// Sumbu atas mengarah ke utara. Tidak melakukan normalisasi ulang per frame.
class FieldPosition {
  final double x;
  final double y;

  const FieldPosition(this.x, this.y);

  bool get isInside => x >= 0 && x <= 1 && y >= 0 && y <= 1;
}

class FieldProjection {
  static const double widthMeters = 9;
  static const double lengthMeters = 18;
  static const double earthRadiusMeters = 6371000;

  final double latitude;
  final double longitude;

  const FieldProjection(this.latitude, this.longitude);

  static bool validCoordinates(double latitude, double longitude) =>
      latitude.isFinite && longitude.isFinite &&
      latitude.abs() <= 90 && longitude.abs() <= 180;

  FieldPosition? project(double latitude, double longitude) {
    if (!validCoordinates(latitude, longitude) ||
        !validCoordinates(this.latitude, this.longitude)) return null;
    final north = (latitude - this.latitude) * math.pi / 180 * earthRadiusMeters;
    final longitudeDelta = (longitude - this.longitude + 540) % 360 - 180;
    final east = longitudeDelta * math.pi / 180 * earthRadiusMeters *
        math.cos(this.latitude * math.pi / 180);
    return FieldPosition(0.5 + east / widthMeters, 0.5 - north / lengthMeters);
  }
}
