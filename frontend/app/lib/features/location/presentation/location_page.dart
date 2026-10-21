import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/location/location_controller.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import 'package:family_ui/family_ui.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({
    super.key,
    required this.auth,
    required this.repository,
    required this.location,
    required this.toast,
  });

  final AuthController auth;
  final FamilyRepository repository;
  final LocationController location;
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
    widget.repository.socket.on('location.settings', _handleLocationSettings);
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
    widget.repository.socket.off('location.settings', _handleLocationSettings);
    super.dispose();
  }

  void _handleLocationUpdated(dynamic _) {
    if (mounted) invalidateQueries(context, QueryKeys.locations);
  }

  void _handleLocationPlaceChanged(dynamic _) {
    if (mounted) invalidateQueries(context, QueryKeys.locationPlaces);
  }

  void _handleLocationSettings(dynamic _) {
    if (!mounted) return;
    unawaited(widget.auth.refreshMe());
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
      child: AppFixedHeaderScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
        header: const AppPageHeader(
          title: 'Localização',
          subtitle: 'Localização e bateria da família.',
          icon: FamilyIcons.locationOnOutlined,
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
                LocationSnapshot? currentLocation;
                for (final item in locations) {
                  if (item.userId == widget.auth.user?.id) {
                    currentLocation = item;
                    break;
                  }
                }
                return Column(
                  children: [
                    if (!kIsWeb) ...[
                      _LocationSharingCard(
                        auth: widget.auth,
                        onMySharingChanged: _setMySharing,
                        onFamilySharingChanged: _setFamilySharing,
                      ),
                      const SizedBox(height: 16),
                      _LocationActions(
                        currentLocation: currentLocation,
                        onSos: _sendSos,
                        onCheckIn: _sendCheckIn,
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const _LocationReadOnlyNote(),
                      const SizedBox(height: 16),
                    ],
                    _LocationMapPanel(
                      locations: locations,
                      places: places,
                      canManage: !kIsWeb,
                      onCenterChanged: (center) => mapCenter = center,
                      onCreatePlace: () => _openPlaceSheet(locations),
                      onEditPlace: (place) => _openPlaceSheet(
                        locations,
                        place: place,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LocationList(
                      locations: locations,
                      places: places,
                      currentLocation: currentLocation,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar SOS?'),
        content: const Text(
          'A família receberá uma notificação de ajuda com a sua localização.',
        ),
        actions: [
          FamilyTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FamilyFilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.sendLocationSos();
    widget.toast.backendSuccess(widget.repository.takeMessage());
  }

  Future<void> _sendCheckIn() async {
    await widget.repository.sendLocationCheckIn();
    widget.toast.backendSuccess(widget.repository.takeMessage());
  }

  Future<void> _setMySharing(bool enabled) async {
    await widget.repository.setLocationSharing(enabled);
    await widget.auth.refreshMe();
    if (enabled) {
      await widget.location.bootstrap();
    } else {
      widget.location.stop();
    }
    widget.toast.backendSuccess(widget.repository.takeMessage());
    if (mounted) invalidateQueries(context, QueryKeys.locations);
  }

  Future<void> _setFamilySharing(bool enabled) async {
    await widget.repository.setFamilyLocation(enabled);
    await widget.auth.refreshMe();
    if (enabled) {
      await widget.location.bootstrap();
    } else {
      widget.location.stop();
    }
    widget.toast.backendSuccess(widget.repository.takeMessage());
    if (mounted) {
      invalidateQueries(context, QueryKeys.locations);
      invalidateQueries(context, QueryKeys.locationPlaces);
    }
  }

  void _openPlaceSheet(
    List<LocationSnapshot> locations, {
    LocationPlace? place,
  }) {
    final fallback = locations.isNotEmpty
        ? LatLng(locations.first.latitude, locations.first.longitude)
        : const LatLng(0, 0);
    final initial = place == null
        ? mapCenter ?? fallback
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
    required this.canManage,
    required this.onCenterChanged,
    required this.onCreatePlace,
    required this.onEditPlace,
  });

  final List<LocationSnapshot> locations;
  final List<LocationPlace> places;
  final bool canManage;
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
    return FamilyCard(
      maxWidth: 1200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocationMapHeader(
            locationsCount: locations.length,
            onCreatePlace: onCreatePlace,
            canManage: canManage,
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
                        'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.siao.app',
                  ),
                                    RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                      TextSourceAttribution('CARTO'),
                    ],
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
                              Icon(FamilyIcons.homeWorkOutlined,
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
                                text: _shortName(location),
                                highlighted: true,
                              ),
                              Icon(FamilyIcons.locationOn,
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
            const _MapHint(
              text:
                  'Nenhuma localização recebida ainda. Crie um local pelo botão acima.',
            ),
          ],
          if (places.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Locais cadastrados',
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
                  if (canManage)
                    FamilyOutlinedButton.icon(
                      onPressed: () => onEditPlace(place),
                      icon: const Icon(FamilyIcons.editLocationAltOutlined),
                      label: Text(place.name),
                    )
                  else
                    Chip(label: Text(place.name)),
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
    return FamilyCard(
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
          text,
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
    required this.canManage,
  });

  final int locationsCount;
  final VoidCallback onCreatePlace;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final title = _LocationPanelTitle(
      title: 'Mapa',
      description: locationsCount == 0
          ? 'Aguardando localizações.'
          : '$locationsCount pessoas no mapa.',
      icon: FamilyIcons.mapOutlined,
    );
    if (!canManage) return title;
    final action = FamilyFilledButton.icon(
      onPressed: onCreatePlace,
      icon: const Icon(FamilyIcons.addLocationAltOutlined),
      label: const Text('Novo local'),
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

class _LocationSharingCard extends StatelessWidget {
  const _LocationSharingCard({
    required this.auth,
    required this.onMySharingChanged,
    required this.onFamilySharingChanged,
  });

  final AuthController auth;
  final Future<void> Function(bool) onMySharingChanged;
  final Future<void> Function(bool) onFamilySharingChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;
        final familyEnabled = user?.locationEnabled ?? true;
        final sharing = user?.locationSharing ?? true;
        return FamilyCard(
          maxWidth: 1200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LocationPanelTitle(
                title: 'Compartilhamento',
                description: 'Você decide quem vê sua localização.',
                icon: FamilyIcons.shareLocationOutlined,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: sharing && familyEnabled,
                onChanged: familyEnabled
                    ? (value) => onMySharingChanged(value)
                    : null,
                title: const Text('Compartilhar minha localização'),
                subtitle: Text(
                  !familyEnabled
                      ? 'A localização está desativada para a família.'
                      : sharing
                          ? 'A família pode ver você.'
                          : 'Sua localização está pausada.',
                ),
              ),
              if (user?.isAdmin == true)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: familyEnabled,
                  onChanged: (value) => onFamilySharingChanged(value),
                  title: const Text('Localização da família'),
                  subtitle: const Text(
                    'Desliga o mapa e o compartilhamento para todos.',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationReadOnlyNote extends StatelessWidget {
  const _LocationReadOnlyNote();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return FamilyCard(
      maxWidth: 1200,
      child: Row(
        children: [
          Icon(FamilyIcons.visibilityOutlined, color: palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No navegador, a localização é apenas para consulta. O compartilhamento acontece pelo aplicativo Android.',
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationActions extends StatelessWidget {
  const _LocationActions({
    required this.currentLocation,
    required this.onSos,
    required this.onCheckIn,
  });

  final LocationSnapshot? currentLocation;
  final Future<void> Function() onSos;
  final Future<void> Function() onCheckIn;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final updated =
        currentLocation == null ? null : _relative(currentLocation!.at);
    return FamilyCard(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: palette.primary.withValues(alpha: .14),
                foregroundColor: palette.primary,
                child: const Icon(FamilyIcons.shieldOutlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sua segurança',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      currentLocation == null
                          ? 'Permita o acesso à localização para compartilhar com a família.'
                          : 'Sua localização foi atualizada $updated.',
                      style: TextStyle(
                        color: palette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FamilyFilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: () => onSos(),
                  icon: const Icon(FamilyIcons.sosOutlined),
                  label: const Text('SOS'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FamilyOutlinedButton.icon(
                  onPressed: () => onCheckIn(),
                  icon: const Icon(FamilyIcons.checkCircleOutline),
                  label: const Text('Check-in'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationList extends StatelessWidget {
  const _LocationList({
    required this.locations,
    required this.places,
    required this.currentLocation,
  });

  final List<LocationSnapshot> locations;
  final List<LocationPlace> places;
  final LocationSnapshot? currentLocation;

  @override
  Widget build(BuildContext context) {
    return FamilyCard(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocationPanelTitle(
            title: 'Pessoas',
            description: locations.isEmpty
                ? 'Aguardando atualizações.'
                : '${locations.length} pessoas compartilhando.',
            icon: FamilyIcons.peopleAltOutlined,
          ),
          const SizedBox(height: 12),
          if (locations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Quando alguém abrir o app e permitir localização, aparece aqui.',
              ),
            )
          else
            for (final location in locations)
              _LocationTile(
                location: location,
                places: places,
                currentLocation: currentLocation,
              ),
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
  const _LocationTile({
    required this.location,
    required this.places,
    required this.currentLocation,
  });

  final LocationSnapshot location;
  final List<LocationPlace> places;
  final LocationSnapshot? currentLocation;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isMe = location.userId != null &&
        location.userId == currentLocation?.userId;
    final place = _placeFor(location, places);
    final stale = DateTime.now().difference(location.at).inMinutes > 10;
    final status = place != null
        ? 'Em ${place.name}'
        : (location.speed ?? 0) > 1.5
            ? 'Em movimento'
            : 'Sem local';
    final distance = (!isMe && currentLocation != null)
        ? _distanceLabel(
            const Distance().as(
              LengthUnit.Meter,
              LatLng(currentLocation!.latitude, currentLocation!.longitude),
              LatLng(location.latitude, location.longitude),
            ),
          )
        : null;
    final battery = location.batteryLevel;
    final batteryColor = battery == null
        ? palette.muted
        : battery <= 20
            ? Colors.red
            : battery <= 45
                ? Colors.orange
                : Colors.green;
    final platform = switch (location.platform) {
      'android' => 'Android',
      'ios' => 'iPhone',
      'web' => 'Navegador',
      _ => null,
    };
    final details = [
      _relative(location.at),
      if (distance != null) distance,
      if (location.accuracy != null) '±${location.accuracy!.round()} m',
      if (platform != null) platform,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemberAvatar(
            name: _shortName(location),
            online: !stale,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _shortName(location),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Você',
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      place != null
                          ? FamilyIcons.homeWorkOutlined
                          : (location.speed ?? 0) > 1.5
                              ? FamilyIcons.directionsCarOutlined
                              : FamilyIcons.locationOffOutlined,
                      size: 14,
                      color: place != null ? palette.primary : palette.muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: place != null ? palette.primary : palette.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                location.isCharging == true
                    ? FamilyIcons.batteryChargingFull
                    : FamilyIcons.batteryStd,
                color: batteryColor,
              ),
              Text(
                battery == null ? '--%' : '$battery%',
                style: TextStyle(
                  color: batteryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name, required this.online});

  final String name;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length >= 2 && parts.last.isNotEmpty ? parts.last[0] : '';
    final initials = (first + last).isEmpty ? '?' : (first + last);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          backgroundColor: palette.primary.withValues(alpha: .14),
          foregroundColor: palette.primary,
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? Colors.green : palette.muted,
              border: Border.all(color: palette.card, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

LocationPlace? _placeFor(
  LocationSnapshot location,
  List<LocationPlace> places,
) {
  const distance = Distance();
  for (final place in places) {
    if (!place.active) continue;
    final meters = distance.as(
      LengthUnit.Meter,
      LatLng(location.latitude, location.longitude),
      LatLng(place.latitude, place.longitude),
    );
    if (meters <= place.radiusMeters) return place;
  }
  return null;
}

String _relative(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inSeconds < 60) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  return 'há ${diff.inDays} d';
}

String _distanceLabel(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
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
  bool notifyOnArrive = true;
  bool notifyOnLeave = true;

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
    notifyOnArrive = place?.notifyOnArrive ?? true;
    notifyOnLeave = place?.notifyOnLeave ?? true;
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
            icon: FamilyIcons.addLocationAltOutlined,
          ),
          const SizedBox(height: 16),
          FamilyTextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          FamilyTextField(
            controller: description,
            decoration: const InputDecoration(labelText: 'Descrição'),
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
                            'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.siao.app',
                      ),
                                        RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                      TextSourceAttribution('CARTO'),
                    ],
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
                      FamilyIcons.locationOn,
                      color: palette.primary,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FamilyTextField(
            controller: radius,
            decoration: const InputDecoration(labelText: 'Raio em metros'),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: notifyOnArrive,
            onChanged: saving
                ? null
                : (value) => setState(() => notifyOnArrive = value),
            title: const Text('Avisar quando chegar'),
            subtitle: const Text('Notifica a família ao entrar neste local.'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: notifyOnLeave,
            onChanged: saving
                ? null
                : (value) => setState(() => notifyOnLeave = value),
            title: const Text('Avisar quando sair'),
            subtitle: const Text('Notifica a família ao sair deste local.'),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.onDelete != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FamilyOutlinedButton.icon(
                    onPressed: saving ? null : _delete,
                    icon: const Icon(FamilyIcons.deleteOutline),
                    label: const Text('Excluir'),
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
        'notifyOnArrive': notifyOnArrive,
        'notifyOnLeave': notifyOnLeave,
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

String _shortName(LocationSnapshot location) {
  final raw = location.userName?.trim();
  if (raw == null || raw.isEmpty) return 'Visitante';
  return raw.contains('@') ? raw.split('@').first : raw;
}
