import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/item_providers.dart';
import '../providers/wear_day_providers.dart';
import 'nfc_service.dart';

/// Keeps an NFC session active while the app is in the foreground.
/// When a known tag is scanned, today's wear day is added automatically.
///
/// Usage: add `NfcForegroundListener(child: ...)` above the navigator.
class NfcForegroundListener extends ConsumerStatefulWidget {
  final Widget child;
  const NfcForegroundListener({super.key, required this.child});

  @override
  ConsumerState<NfcForegroundListener> createState() =>
      _NfcForegroundListenerState();
}

class _NfcForegroundListenerState extends ConsumerState<NfcForegroundListener>
    with WidgetsBindingObserver {
  bool _active = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NfcService.stopSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startListening();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopListening();
    }
  }

  Future<void> _startListening() async {
    if (_active) return;
    final available = await NfcService.isAvailable();
    if (!available || !mounted) return;
    _active = true;

    NfcService.readTag(
      onTagRead: (uid) async {
        _active = false;
        if (!mounted) return;

        final item =
            await ref.read(itemsProvider.notifier).getByNfcTagId(uid);
        if (!mounted) return;

        if (item != null) {
          final now = DateTime.now();
          final name = '${item.brand} ${item.model}';
          final inserted = await ref.read(wearDayActionsProvider).addWearDay(
                item.id,
                DateTime(now.year, now.month, now.day),
              );
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            final message = inserted
                ? l10n.nfcWearDayAdded(name)
                : l10n.nfcAlreadyWornToday(name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // Wait before restarting so a tag held nearby doesn't fire repeatedly.
        if (mounted) {
          await Future.delayed(const Duration(seconds: 5));
          if (mounted) _startListening();
        }
      },
      onError: (_) {
        _active = false;
        // Restart quietly on error (e.g. session interrupted by another dialog).
        if (mounted) Future.delayed(const Duration(seconds: 1), _startListening);
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_active) return;
    _active = false;
    await NfcService.stopSession();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
