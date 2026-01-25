import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:symptom_checker/l10n/app_localizations.dart';

import '../models/clinic_place.dart';
import '../services/overpass_service.dart';

class ClinicLocatorScreen extends StatefulWidget {
  const ClinicLocatorScreen({super.key});

  @override
  State<ClinicLocatorScreen> createState() => _ClinicLocatorScreenState();
}

class _ClinicLocatorScreenState extends State<ClinicLocatorScreen> {
  final OverpassService _overpass = OverpassService();
  final MapController _map = MapController();

  bool _loading = true;
  String? _error;

  Position? _pos;
  List<ClinicPlace> _places = const [];

  int _radiusMeters = 3000;

  Future<void> _ensurePermissionAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      if (kIsWeb) {
        // geolocator web can work, but permissions can be flaky depending on browser settings.
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(l10n.locationServicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(l10n.locationPermissionDenied);
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(l10n.locationPermissionDeniedForever);
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final places = await _overpass.fetchNearbyClinics(
        lat: position.latitude,
        lon: position.longitude,
        radiusMeters: _radiusMeters,
      );

      if (!mounted) return;
      setState(() {
        _pos = position;
        _places = places;
        _loading = false;
        _error = null;
      });

      _moveTo(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _moveTo(double lat, double lon) {
    // MapController might not be ready if widget is rebuilding; delay a frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _map.move(LatLng(lat, lon), 14.5);
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(_ensurePermissionAndLoad());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clinicsNearYou),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _loading ? null : _ensurePermissionAndLoad,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: l10n.recenter,
            onPressed: _pos == null
                ? null
                : () => _moveTo(_pos!.latitude, _pos!.longitude),
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: _ensurePermissionAndLoad,
                )
              : Column(
                  children: [
                    _RadiusChips(
                      valueMeters: _radiusMeters,
                      onChanged: (v) {
                        setState(() => _radiusMeters = v);
                        unawaited(_ensurePermissionAndLoad());
                      },
                    ),
                    Expanded(
                      child: FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          initialCenter: _pos == null ? const LatLng(0, 0) : LatLng(_pos!.latitude, _pos!.longitude),
                          initialZoom: 14.5,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.symptom_checker',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_pos != null)
                                Marker(
                                  width: 46,
                                  height: 46,
                                  point: LatLng(_pos!.latitude, _pos!.longitude),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.primary.withOpacity(0.16),
                                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ..._places.take(60).map((p) => Marker(
                                    width: 48,
                                    height: 48,
                                    point: LatLng(p.lat, p.lon),
                                    child: _PlaceMarker(
                                      kind: p.kind,
                                      onTap: () => _openPlaceSheet(p),
                                    ),
                                  )),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _places.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openListSheet(),
              icon: const Icon(Icons.list_rounded),
              label: Text(l10n.resultsCount(min(_places.length, 60).toString())),
            ),
    );
  }

  void _openListSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final t = Theme.of(context).textTheme;
        final l10n = AppLocalizations.of(context);
        final shown = _places.take(60).toList(growable: false);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(l10n.nearbyClinics, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, i) {
                      final p = shown[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_subtitleFor(p), maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(_formatDistance(p.distanceMeters)),
                        onTap: () {
                          Navigator.of(context).pop();
                          _moveTo(p.lat, p.lon);
                          _openPlaceSheet(p);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPlaceSheet(ClinicPlace p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final t = Theme.of(context).textTheme;
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(p.name, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  _subtitleFor(p),
                  style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: p.phone == null ? null : () => _call(p.phone!),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(l10n.call),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateTo(p.lat, p.lon, label: p.name),
                        icon: const Icon(Icons.navigation_rounded),
                        label: Text(l10n.navigate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  String _subtitleFor(ClinicPlace p) {
    final kind = p.kind.replaceAll('_', ' ');
    final addr = p.address;
    final distance = _formatDistance(p.distanceMeters);
    final parts = <String>[kind, distance];
    if (addr != null && addr.isNotEmpty) parts.add(addr);
    return parts.join(' • ');
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _call(String phoneRaw) async {
    final cleaned = phoneRaw.replaceAll(RegExp(r'[^0-9+]+'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.unableToOpenDialer)));
    }
  }

  Future<void> _navigateTo(double lat, double lon, {String? label}) async {
    // Use a universal maps URL. Works on Android/iOS and falls back to browser.
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.unableToOpenMaps)));
    }
  }
}

class _RadiusChips extends StatelessWidget {
  const _RadiusChips({required this.valueMeters, required this.onChanged});

  final int valueMeters;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final options = const [1500, 3000, 5000, 8000];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(l10n.radius, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          ...options.map((v) {
            final selected = v == valueMeters;
            final label = v < 1000 ? '${v}m' : '${(v / 1000).toStringAsFixed(v == 1500 ? 1 : 0)}km';
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                selected: selected,
                label: Text(label),
                onSelected: (_) => onChanged(v),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.kind, required this.onTap});

  final String kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lower = kind.toLowerCase();
    IconData icon = Icons.local_hospital_rounded;
    Color color = const Color(0xFF1D81C9);

    if (lower.contains('pharmacy')) {
      icon = Icons.local_pharmacy_rounded;
      color = const Color(0xFF059669);
    } else if (lower.contains('doctor') || lower.contains('doctors')) {
      icon = Icons.medical_services_rounded;
      color = const Color(0xFF7C3AED);
    } else if (lower.contains('clinic')) {
      icon = Icons.local_hospital_outlined;
      color = const Color(0xFF2563EB);
    } else if (lower.contains('hospital')) {
      icon = Icons.local_hospital_rounded;
      color = const Color(0xFFDC2626);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 8),
              blurRadius: 20,
              color: Colors.black.withOpacity(0.18),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Geolocator.openLocationSettings(),
              child: Text(l10n.openLocationSettings),
            ),
          ],
        ),
      ),
    );
  }
}
