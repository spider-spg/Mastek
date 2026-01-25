class ClinicPlace {
  const ClinicPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.lat,
    required this.lon,
    required this.distanceMeters,
    this.address,
    this.phone,
  });

  final String id;
  final String name;
  final String kind;
  final double lat;
  final double lon;
  final double distanceMeters;
  final String? address;
  final String? phone;
}
