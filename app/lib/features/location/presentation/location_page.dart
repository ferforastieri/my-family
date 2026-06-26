import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
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
    assert(() {
      debugPrint('[LocationPage] init');
      return true;
    }());
    widget.repository.socket.on('location.updated', _handleLocationUpdated);
    widget.repository.socket
        .on('location.places.changed', _handleLocationPlaceChanged);
  }

  @override
  void dispose() {
    assert(() {
      debugPrint('[LocationPage] dispose');
      return true;
    }());
    widget.repository.socket.off('location.updated', _handleLocationUpdated);
    widget.repository.socket
        .off('location.places.changed', _handleLocationPlaceChanged);
    super.dispose();
  }

  void _handleLocationUpdated(dynamic _) {
    if (mounted) invalidateQueries(context, QueryKeys.locations);
  }

  void _handleLocationPlaceChanged(dynamic _) {
    if (mounted) invalidateQueries(context, QueryKeys.locationPlaces);
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
      child: AppFixedHeaderScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
        header: const AppPageHeader(
          title: 'Localização',
          subtitle: 'Onde a família está agora e como anda a bateria.',
          icon: Icons.location_on_outlined,
        ),
        children: [
          AppQuery<List<LocationPlace>>(
            queryKey: QueryKeys.locationPlaces,
            queryFn: widget.repository.listLocationPlaces,
            loading: const _LocationLoadingSkeleton(),
            builder: (context, places, _) => AppQuery<List<LocationSnapshot>>(
              queryKey: QueryKeys.locations,
              queryFn: widget.repository.listLocations,
              loading: const _LocationLoadingSkeleton(),
              builder: (context, locations, refetch) {
                assert(() {
                  debugPrint(
                    '[LocationPage] loaded places=${places.length} '
                    'locations=${locations.length}',
                  );
                  return true;
                }());
                return Column(
                  children: [
                    _LocationMapPanel(
                      locations: locations,
                      places: places,
                      onCenterChanged: (center) => mapCenter = center,
                      onCreatePlace: () => _openPlaceSheet(locations),
                      onEditPlace: (place) => _openPlaceSheet(
                        locations,
                        place: place,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LocationList(locations: locations),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openPlaceSheet(
    List<LocationSnapshot> locations, {
    LocationPlace? place,
  }) {
    final firstKnownCenter = locations.isNotEmpty
        ? LatLng(locations.first.latitude, locations.first.longitude)
        : const LatLng(0, 0);
    final initial = place == null
        ? mapCenter ?? firstKnownCenter
        : LatLng(place.latitude, place.longitude);

    showAppSheet<void>(
      context: context,
      builder: (_) => _LocationPlaceSheet(
        place: place,
        initialCenter: initial,
        onDelete: place == null ? null : () => _deletePlace(place),
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

class _LocationMapPanel extends StatelessWidget {
  const _LocationMapPanel({
    required this.locations,
    required this.places,
    required this.onCenterChanged,
    required this.onCreatePlace,
    required this.onEditPlace,
  });

  final List<LocationSnapshot> locations;
  final List<LocationPlace> places;
  final ValueChanged<LatLng> onCenterChanged;
  final VoidCallback onCreatePlace;
  final ValueChanged<LocationPlace> onEditPlace;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final center = locations.isNotEmpty
        ? LatLng(locations.first.latitude, locations.first.longitude)
        : places.isNotEmpty
            ? LatLng(places.first.latitude, places.first.longitude)
            : const LatLng(-23.55052, -46.63331);
    final desktop = MediaQuery.sizeOf(context).width >= 840;
    return LovePanel(
      maxWidth: 1200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocationMapHeader(
            locationsCount: locations.length,
            onCreatePlace: onCreatePlace,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: desktop ? 460 : 320,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: locations.isEmpty && places.isEmpty ? 4 : 14,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.scrollWheelZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) onCenterChanged(camera.center);
                  },
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
                          width: 132,
                          height: 76,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home_work_outlined,
                                  color: palette.primary, size: 32),
                              _MapLabel(text: place.name),
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
                              _MapLabel(
                                text: _shortName(context, location),
                                highlighted: true,
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
          ),
          if (locations.isEmpty && places.isEmpty) ...[
            const SizedBox(height: 12),
            _MapHint(
              text:
                  'Nenhuma localização recebida ainda. Crie um local pelo botão acima.',
            ),
          ],
          if (places.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              context.tr('Locais cadastrados'),
              style: TextStyle(
                color: palette.foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final place in places)
                  OutlinedButton.icon(
                    onPressed: () => onEditPlace(place),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: Text(place.name),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationLoadingSkeleton extends StatelessWidget {
  const _LocationLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SkeletonBox(width: 220, height: 24),
          SizedBox(height: 16),
          SkeletonBox(height: 320, borderRadius: 14),
          SizedBox(height: 16),
          SkeletonBox(width: 180, height: 22),
          SizedBox(height: 12),
          SkeletonBox(height: 72, borderRadius: 14),
        ],
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.text, this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? palette.primary : palette.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          context.tr(text),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: .92),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _LocationMapHeader extends StatelessWidget {
  const _LocationMapHeader({
    required this.locationsCount,
    required this.onCreatePlace,
  });

  final int locationsCount;
  final VoidCallback onCreatePlace;

  @override
  Widget build(BuildContext context) {
    final title = _LocationPanelTitle(
      title: 'Mapa',
      description: locationsCount == 0
          ? 'Aguardando localizações.'
          : context
              .tr('{count} pessoas no mapa.', args: {'count': locationsCount}),
      icon: Icons.map_outlined,
    );
    final action = FilledButton.icon(
      onPressed: onCreatePlace,
      icon: const Icon(Icons.add_location_alt_outlined),
      label: Text(context.tr('Novo local')),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        if (!compact) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              action,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: action),
          ],
        );
      },
    );
  }
}

class _LocationList extends StatelessWidget {
  const _LocationList({required this.locations});

  final List<LocationSnapshot> locations;

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocationPanelTitle(
            title: 'Pessoas',
            description: locations.isEmpty
                ? 'Aguardando atualizações.'
                : context.tr('{count} localizações recentes.',
                    args: {'count': locations.length}),
            icon: Icons.people_alt_outlined,
          ),
          const SizedBox(height: 12),
          if (locations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                context.tr(
                    'Quando alguém abrir o app e permitir localização, aparece aqui.'),
              ),
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
              Text(context.tr(title),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              Text(context.tr(description),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: palette.primary.withValues(alpha: .14),
            foregroundColor: palette.primary,
            child: const Icon(Icons.person_pin_circle_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_shortName(context, location),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                  style: TextStyle(color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
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
                style:
                    TextStyle(color: batteryColor, fontWeight: FontWeight.w900),
              ),
            ],
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
    this.onDelete,
    this.place,
  });

  final LatLng initialCenter;
  final LocationPlace? place;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_LocationPlaceSheet> createState() => _LocationPlaceSheetState();
}

class _LocationPlaceSheetState extends State<_LocationPlaceSheet> {
  late final TextEditingController name;
  late final TextEditingController description;
  late final TextEditingController radius;
  late LatLng selected;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    selected = place == null
        ? widget.initialCenter
        : LatLng(place.latitude, place.longitude);
    name = TextEditingController(text: place?.name ?? '');
    description = TextEditingController(text: place?.description ?? '');
    radius = TextEditingController(text: '${place?.radiusMeters ?? 120}');
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    radius.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final radiusMeters = int.tryParse(radius.text.trim()) ?? 120;
    return SizedBox(
      width: 620,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: widget.place == null ? 'Novo local' : 'Editar local',
            subtitle: 'Arraste o mapa e deixe o marcador no ponto desejado.',
            icon: Icons.add_location_alt_outlined,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            autofocus: true,
            decoration: InputDecoration(labelText: context.tr('Nome')),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            decoration: InputDecoration(labelText: context.tr('Descrição')),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: selected,
                      initialZoom: 16,
                      minZoom: 3,
                      maxZoom: 19,
                      onPositionChanged: (camera, _) {
                        setState(() => selected = camera.center);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.viciofer.my_family',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: selected,
                            radius: radiusMeters.toDouble(),
                            useRadiusInMeter: true,
                            color: palette.primary.withValues(alpha: .12),
                            borderColor: palette.primary.withValues(alpha: .55),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: Icon(
                      Icons.location_on,
                      color: palette.primary,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: radius,
            decoration:
                InputDecoration(labelText: context.tr('Raio em metros')),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.onDelete != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(context.tr('Excluir')),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              AppSheetActions(
                onCancel: saving ? null : () => Navigator.pop(context),
                onSave: saving ? null : _save,
                loading: saving,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({
        'name': name.text.trim(),
        'description': description.text.trim(),
        'latitude': selected.latitude,
        'longitude': selected.longitude,
        'radiusMeters': int.tryParse(radius.text.trim()),
        'active': true,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    setState(() => saving = true);
    try {
      await onDelete();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

String _shortName(BuildContext context, LocationSnapshot location) {
  final raw = location.userName?.trim();
  if (raw == null || raw.isEmpty) return context.tr('Visitante');
  return raw.contains('@') ? raw.split('@').first : raw;
}
