import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../models/clinic_place.dart';

class OverpassService {
  static final Uri _endpoint = Uri.parse('https://overpass-api.de/api/interpreter');

  Future<List<ClinicPlace>> fetchNearbyClinics({
    required double lat,
    required double lon,
    int radiusMeters = 3000,
  }) async {
    final query = _buildQuery(lat: lat, lon: lon, radiusMeters: radiusMeters);

    final resp = await http.post(
      _endpoint,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
      },
      body: {'data': query},
    );

    if (resp.statusCode != 200) {
      throw Exception('Overpass request failed (${resp.statusCode})');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final elements = (json['elements'] as List<dynamic>? ?? const []);

    final List<ClinicPlace> out = [];

    for (final raw in elements) {
      final el = raw as Map<String, dynamic>;
      final type = (el['type'] as String?) ?? 'node';
      final idNum = el['id'];
      final id = '$type:$idNum';

      double? elLat;
      double? elLon;

      if (el['lat'] is num && el['lon'] is num) {
        elLat = (el['lat'] as num).toDouble();
        elLon = (el['lon'] as num).toDouble();
      } else if (el['center'] is Map<String, dynamic>) {
        final c = el['center'] as Map<String, dynamic>;
        if (c['lat'] is num && c['lon'] is num) {
          elLat = (c['lat'] as num).toDouble();
          elLon = (c['lon'] as num).toDouble();
        }
      }

      if (elLat == null || elLon == null) continue;

      final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

      final name = (tags['name'] as String?)?.trim().isNotEmpty == true
          ? (tags['name'] as String).trim()
          : ((tags['operator'] as String?)?.trim().isNotEmpty == true ? (tags['operator'] as String).trim() : 'Nearby Clinic');

      final kind = ((tags['amenity'] as String?) ?? (tags['healthcare'] as String?) ?? 'clinic').toString();

      final address = _formatAddress(tags);
      final phoneRaw = (tags['phone'] as String?) ?? (tags['contact:phone'] as String?) ?? (tags['mobile'] as String?);
      final phone = phoneRaw?.trim().isNotEmpty == true ? phoneRaw!.trim() : null;

      final distance = Geolocator.distanceBetween(lat, lon, elLat, elLon);

      out.add(
        ClinicPlace(
          id: id,
          name: name,
          kind: kind,
          lat: elLat,
          lon: elLon,
          distanceMeters: distance,
          address: address,
          phone: phone,
        ),
      );
    }

    out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    // Deduplicate by id
    final seen = <String>{};
    final deduped = <ClinicPlace>[];
    for (final p in out) {
      if (seen.add(p.id)) deduped.add(p);
    }
    return deduped;
  }

  String _buildQuery({required double lat, required double lon, required int radiusMeters}) {
    // A mix of amenity/healthcare tags commonly used for health POIs.
    const amenityRegex = 'hospital|clinic|doctors|pharmacy';
    const healthcareRegex = 'hospital|clinic|doctor|pharmacy';

    return '''
[out:json][timeout:25];
(
  node(around:$radiusMeters,$lat,$lon)[amenity~"$amenityRegex"];
  way(around:$radiusMeters,$lat,$lon)[amenity~"$amenityRegex"];
  relation(around:$radiusMeters,$lat,$lon)[amenity~"$amenityRegex"];
  node(around:$radiusMeters,$lat,$lon)[healthcare~"$healthcareRegex"];
  way(around:$radiusMeters,$lat,$lon)[healthcare~"$healthcareRegex"];
  relation(around:$radiusMeters,$lat,$lon)[healthcare~"$healthcareRegex"];
);
out center tags;
''';
  }

  String? _formatAddress(Map<String, dynamic> tags) {
    final street = tags['addr:street'] as String?;
    final housenumber = tags['addr:housenumber'] as String?;
    final city = tags['addr:city'] as String?;
    final postcode = tags['addr:postcode'] as String?;

    final parts = <String>[];
    final streetLine = [
      if (housenumber != null && housenumber.trim().isNotEmpty) housenumber.trim(),
      if (street != null && street.trim().isNotEmpty) street.trim(),
    ].join(' ');
    if (streetLine.trim().isNotEmpty) parts.add(streetLine.trim());
    if (city != null && city.trim().isNotEmpty) parts.add(city.trim());
    if (postcode != null && postcode.trim().isNotEmpty) parts.add(postcode.trim());

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}
