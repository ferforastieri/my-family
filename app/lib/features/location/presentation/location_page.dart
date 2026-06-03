import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({
    super.key,
    required this.repository,
    required this.toast,
  });

  final FamilyRepository repository;
  final ToastController toast;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final locations = <LocationSnapshot>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    widget.repository.socket.on('location.updated', _handleLocationUpdated);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    widget.repository.socket.off('location.updated', _handleLocationUpdated);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final rows = await widget.repository.listLocations();
      locations
        ..clear()
        ..addAll(rows);
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _handleLocationUpdated(dynamic data) {
    if (data is! Map) return;
    final row = LocationSnapshot.fromJson(Map<String, dynamic>.from(data));
    final key = row.userName ?? row.id;
    final index = locations.indexWhere((item) => (item.userName ?? item.id) == key);
    setState(() {
      if (index >= 0) {
        locations[index] = row;
      } else {
        locations.insert(0, row);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgStart, palette.bgEnd],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: const AppPageHeader(
                  title: 'Localização',
                  subtitle: 'Onde a família está agora e como anda a bateria.',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: loading && locations.isEmpty
                    ? const PageSkeleton(cards: 4)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 840;
                          final map = _LocationMap(locations: locations);
                          final list = _LocationList(locations: locations);
                          if (!wide) {
                            return Column(
                              children: [
                                SizedBox(height: 360, child: map),
                                const SizedBox(height: 14),
                                list,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: SizedBox(height: 560, child: map)),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: list),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMap extends StatelessWidget {
  const _LocationMap({required this.locations});

  final List<LocationSnapshot> locations;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final center = locations.isEmpty
        ? const LatLng(0, 0)
        : LatLng(locations.first.latitude, locations.first.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: locations.isEmpty
            ? const Center(child: Text('Nenhuma localização recebida ainda.'))
            : FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.viciofer.my_family',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final location in locations)
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 96,
                          height: 74,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: palette.card,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: palette.primary),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  child: Text(
                                    _shortName(location),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              Icon(Icons.location_on, color: palette.primary, size: 38),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _LocationList extends StatelessWidget {
  const _LocationList({required this.locations});

  final List<LocationSnapshot> locations;

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      maxWidth: 1040,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocationPanelTitle(
            title: 'Pessoas',
            description: locations.isEmpty
                ? 'Aguardando atualizações.'
                : '${locations.length} localizações recentes.',
            icon: Icons.people_alt_outlined,
          ),
          const SizedBox(height: 12),
          if (locations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Quando alguém abrir o app e permitir localização, aparece aqui.'),
            )
          else
            for (final location in locations) _LocationTile(location: location),
        ],
      ),
    );
  }
}

class _LocationPanelTitle extends StatelessWidget {
  const _LocationPanelTitle({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: palette.primary.withValues(alpha: .14),
          foregroundColor: palette.primary,
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              Text(description,
                  style: TextStyle(
                      color: palette.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location});

  final LocationSnapshot location;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final battery = location.batteryLevel;
    final batteryColor = battery == null
        ? palette.muted
        : battery <= 20
            ? Colors.red
            : battery <= 45
                ? Colors.orange
                : Colors.green;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: palette.primary.withValues(alpha: .14),
        foregroundColor: palette.primary,
        child: const Icon(Icons.person_pin_circle_outlined),
      ),
      title: Text(_shortName(location), style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(
        '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            location.isCharging == true ? Icons.battery_charging_full : Icons.battery_std,
            color: batteryColor,
          ),
          Text(
            battery == null ? '--%' : '$battery%',
            style: TextStyle(color: batteryColor, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

String _shortName(LocationSnapshot location) {
  final raw = location.userName?.trim();
  if (raw == null || raw.isEmpty) return 'Visitante';
  return raw.contains('@') ? raw.split('@').first : raw;
}
