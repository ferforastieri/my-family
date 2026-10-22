import 'package:flutter/material.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/location/location_controller.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../data/family_repository.dart';
import 'package:family_ui/family_ui.dart';

class LocationSettingsSheet extends StatefulWidget {
  const LocationSettingsSheet({
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
  State<LocationSettingsSheet> createState() => _LocationSettingsSheetState();
}

class _LocationSettingsSheetState extends State<LocationSettingsSheet> {
  bool busy = false;

  Future<void> _setSharing(bool enabled) async {
    setState(() => busy = true);
    try {
      await widget.repository.setLocationSharing(enabled);
      await widget.auth.refreshMe();
      if (enabled) {
        await widget.location.bootstrap();
      } else {
        widget.location.stop();
      }
      widget.toast.backendSuccess(widget.repository.takeMessage());
      if (mounted) {
        invalidateQueries(context, QueryKeys.locations);
      }
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final user = widget.auth.user;
        final sharing = user?.locationSharing ?? true;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Localização',
              style: TextStyle(
                color: palette.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Só você controla o compartilhamento da sua localização.',
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FamilyCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: sharing,
                onChanged: !busy ? (value) => _setSharing(value) : null,
                title: const Text('Compartilhar minha localização'),
                subtitle: Text(
                  sharing
                      ? 'A família pode ver você.'
                      : 'Sua localização está pausada.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Android, permita a localização “Sempre” para o app continuar atualizando em segundo plano.',
              style: TextStyle(color: palette.muted, fontSize: 12, height: 1.4),
            ),
          ],
        );
      },
    );
  }
}
