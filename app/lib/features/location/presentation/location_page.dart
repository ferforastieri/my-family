import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
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
  LatLng? mapCenter;

  @override
  void initState() {
    super.initState();
    widget.repository.socket.on('location.updated', _handleLocationUpdated);
    widget.repository.socket
        .on('location.places.changed', _handleLocationPlaceChanged);
  }

  @override
  void dispose() {
    widget.repository.socket.off('location.updated', _handleLocationUpdated);
    widget.repository.socket
        .off('location.places.changed', _handleLocationPlaceChanged);
    super.dispose();
  }

  void _handleLocationUpdated(dynamic _) {
    if (!mounted) return;
    invalidateQueries(context, QueryKeys.locations);
  }

  void _handleLocationPlaceChanged(dynamic _) {
    if (!mounted) return;
    invalidateQueries(context, QueryKeys.locationPlaces);
  }

  void _invalidateAll() {
    invalidateQueries(context, QueryKeys.locations);
    invalidateQueries(context, QueryKeys.locationPlaces);
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
        onRefresh: () async => _invalidateAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
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
                constraints: const BoxConstraints(maxWidth: 1200),
                child: AppQuery<List<LocationPlace>>(
                  queryKey: QueryKeys.locationPlaces,
                  queryFn: widget.repository.listLocationPlaces,
                  loading: const PageSkeleton(cards: 3),
                  builder: (context, places, _) =>
                      AppQuery<List<LocationSnapshot>>(
                    queryKey: QueryKeys.locations,
                    queryFn: widget.repository.listLocations,
                    loading: const PageSkeleton(cards: 4),
                    builder: (context, locations, refetch) => Column(
                      children: [
                        _LocationActions(
                          places: places,
                          onCreate: () => _openPlaceSheet(locations),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: MediaQuery.of(context).size.width >= 840
                              ? 620
                              : 460,
                          child: _LocationMap(
                            locations: locations,
                            places: places,
                            onCenterChanged: (center) => mapCenter = center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PlacesList(
                          places: places,
                          onEdit: (place) => _openPlaceSheet(
                            locations,
                            place: place,
                          ),
                          onDelete: _deletePlace,
                        ),
                        const SizedBox(height: 16),
                        _LocationList(locations: locations),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaceSheet(
    List<LocationSnapshot> locations, {
    LocationPlace? place,
  }) {
    final fallback = locations.isNotEmpty
        ? LatLng(locations.first.latitude, locations.first.longitude)
        : const LatLng(0, 0);
    final center = mapCenter ?? fallback;
    showAppSheet<void>(
      context: context,
      builder: (_) => _LocationPlaceSheet(
        place: place,
        initialCenter: center,
        onSave: (data) async {
          if (place == null) {
            await widget.repository.createLocationPlace(data);
          } else {
            await widget.repository.updateLocationPlace(place.id, data);
          }
          widget.toast.backendSuccess(widget.repository.takeMessage());
          if (mounted) invalidateQueries(context, QueryKeys.locationPlaces);
        },
      ),
    );
  }

  Future<void> _deletePlace(LocationPlace place) async {
    await widget.repository.deleteLocationPlace(place.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
    if (mounted) invalidateQueries(context, QueryKeys.locationPlaces);
  }
}

class _LocationMap extends StatelessWidget {
  const _LocationMap({
    required this.locations,
    required this.places,
    required this.onCenterChanged,
  });

  final List<LocationSnapshot> locations;
  final List<LocationPlace> places;
  final ValueChanged<LatLng> onCenterChanged;

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
        child: locations.isEmpty && places.isEmpty
            ? const Center(child: Text('Nenhuma localização recebida ainda.'))
            : FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14,
                  minZoom: 3,
                  maxZoom: 19,
                  onPositionChanged: (camera, _) =>
                      onCenterChanged(camera.center),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.viciofer.my_family',
                  ),
                  CircleLayer(
                    circles: [
                      for (final place in places)
                        CircleMarker(
                          point: LatLng(place.latitude, place.longitude),
                          radius: place.radiusMeters.toDouble(),
                          useRadiusInMeter: true,
                          color: palette.primary.withValues(alpha: .12),
                          borderColor: palette.primary.withValues(alpha: .55),
                          borderStrokeWidth: 2,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (final place in places)
                        Marker(
                          point: LatLng(place.latitude, place.longitude),
                          width: 120,
                          height: 70,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home_work_outlined,
                                  color: palette.primary, size: 32),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: palette.card,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  child: Text(
                                    place.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  child: Text(
                                    _shortName(location),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              Icon(Icons.location_on,
                                  color: palette.primary, size: 38),
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

class _LocationActions extends StatelessWidget {
  const _LocationActions({
    required this.places,
    required this.onCreate,
  });

  final List<LocationPlace> places;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      maxWidth: 1040,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: palette.primary.withValues(alpha: .14),
            foregroundColor: palette.primary,
            child: const Icon(Icons.add_location_alt_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Locais importantes',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                Text(
                  places.isEmpty
                      ? 'Crie locais como casa, igreja ou trabalho.'
                      : '${places.length} locais monitorados.',
                  style: TextStyle(
                    color: palette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onCreate,
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Novo local',
          ),
        ],
      ),
    );
  }
}

class _PlacesList extends StatelessWidget {
  const _PlacesList({
    required this.places,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LocationPlace> places;
  final ValueChanged<LocationPlace> onEdit;
  final ValueChanged<LocationPlace> onDelete;

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      maxWidth: 1040,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LocationPanelTitle(
            title: 'Locais',
            description: 'Alertas automáticos de chegada e saída.',
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(height: 12),
          if (places.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nenhum local monitorado ainda.'),
            )
          else
            for (final place in places)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.place_outlined),
                ),
                title: Text(place.name,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  '${place.radiusMeters}m de raio - ${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onEdit(place),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      onPressed: () => onDelete(place),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
              ),
        ],
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
              child: Text(
                  'Quando alguém abrir o app e permitir localização, aparece aqui.'),
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
      title: Text(_shortName(location),
          style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(
        '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            location.isCharging == true
                ? Icons.battery_charging_full
                : Icons.battery_std,
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

class _LocationPlaceSheet extends StatefulWidget {
  const _LocationPlaceSheet({
    required this.initialCenter,
    required this.onSave,
    this.place,
  });

  final LatLng initialCenter;
  final LocationPlace? place;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_LocationPlaceSheet> createState() => _LocationPlaceSheetState();
}

class _LocationPlaceSheetState extends State<_LocationPlaceSheet> {
  late final TextEditingController name;
  late final TextEditingController description;
  late final TextEditingController latitude;
  late final TextEditingController longitude;
  late final TextEditingController radius;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    name = TextEditingController(text: place?.name ?? '');
    description = TextEditingController(text: place?.description ?? '');
    latitude = TextEditingController(
      text:
          (place?.latitude ?? widget.initialCenter.latitude).toStringAsFixed(6),
    );
    longitude = TextEditingController(
      text: (place?.longitude ?? widget.initialCenter.longitude)
          .toStringAsFixed(6),
    );
    radius = TextEditingController(text: '${place?.radiusMeters ?? 120}');
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    latitude.dispose();
    longitude.dispose();
    radius.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 540,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.place == null ? 'Novo local' : 'Editar local',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            decoration: const InputDecoration(labelText: 'Descrição'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: latitude,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: longitude,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: radius,
            decoration: const InputDecoration(labelText: 'Raio em metros'),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: _save,
            label: 'Salvar local',
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await widget.onSave({
      'name': name.text.trim(),
      'description': description.text.trim(),
      'latitude': double.tryParse(latitude.text.trim().replaceAll(',', '.')),
      'longitude': double.tryParse(longitude.text.trim().replaceAll(',', '.')),
      'radiusMeters': int.tryParse(radius.text.trim()),
      'active': true,
    });
    if (mounted) Navigator.pop(context);
  }
}

String _shortName(LocationSnapshot location) {
  final raw = location.userName?.trim();
  if (raw == null || raw.isEmpty) return 'Visitante';
  return raw.contains('@') ? raw.split('@').first : raw;
}
