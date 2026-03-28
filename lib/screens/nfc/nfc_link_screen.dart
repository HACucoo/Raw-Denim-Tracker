import 'package:flutter/material.dart';
import 'package:raw_denim_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/item_providers.dart';
import '../../services/nfc_service.dart';

class NfcLinkScreen extends ConsumerStatefulWidget {
  final String itemId;
  const NfcLinkScreen({super.key, required this.itemId});

  @override
  ConsumerState<NfcLinkScreen> createState() => _NfcLinkScreenState();
}

class _NfcLinkScreenState extends ConsumerState<NfcLinkScreen> {
  _State _state = _State.idle;
  String? _readUid;
  bool _ndefWritten = false;
  String? _error;

  @override
  void dispose() {
    NfcService.stopSession();
    super.dispose();
  }

  Future<void> _startScan() async {
    final available = await NfcService.isAvailable();
    if (!available) {
      setState(() {
        _state = _State.error;
        _error = 'NFC is not available on this device.';
      });
      return;
    }

    setState(() => _state = _State.scanning);

    NfcService.readAndWriteNdefLink(
      itemId: widget.itemId,
      onTagRead: (uid, ndefWritten) {
        if (mounted) setState(() {
          _state = _State.read;
          _readUid = uid;
          _ndefWritten = ndefWritten;
        });
      },
      onError: (error) {
        if (mounted) setState(() {
          _state = _State.error;
          _error = error;
        });
      },
    );
  }

  Future<void> _linkTag() async {
    if (_readUid == null) return;
    await ref.read(itemsProvider.notifier).linkNfcTag(widget.itemId, _readUid!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nfcTagLinked)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.linkNfcTag)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              switch (_state) {
                _State.idle => _buildIdle(context, l10n),
                _State.scanning => _buildScanning(context, l10n),
                _State.read => _buildRead(context, l10n),
                _State.error => _buildError(context, l10n),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdle(BuildContext context, dynamic l10n) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nfc, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(l10n.nfcLinkInstructions,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.nfc),
            label: Text(l10n.startScan),
          ),
        ],
      );

  Widget _buildScanning(BuildContext context, dynamic l10n) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(l10n.holdTagToPhone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              NfcService.stopSession();
              setState(() => _state = _State.idle);
            },
            child: Text(l10n.cancel),
          ),
        ],
      );

  Widget _buildRead(BuildContext context, dynamic l10n) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(l10n.tagDetected, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_readUid ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _ndefWritten ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                size: 16,
                color: _ndefWritten
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                _ndefWritten
                    ? l10n.nfcBackgroundEnabled
                    : l10n.nfcBackgroundDisabled,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _ndefWritten
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _linkTag,
            icon: const Icon(Icons.link),
            label: Text(l10n.linkTag),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _state = _State.idle;
              _readUid = null;
            }),
            child: Text(l10n.scanAgain),
          ),
        ],
      );

  Widget _buildError(BuildContext context, dynamic l10n) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 80, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(_error ?? l10n.nfcError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() => _state = _State.idle),
            child: Text(l10n.tryAgain),
          ),
        ],
      );
}

enum _State { idle, scanning, read, error }
