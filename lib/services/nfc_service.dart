import 'dart:io';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/ndef_record.dart';

class NfcService {
  static Future<bool> isAvailable() async =>
      await NfcManager.instance.checkAvailability() == NfcAvailability.enabled;

  /// Reads a single NFC tag and returns its UID as a hex string.
  /// Works with any tag regardless of what's written on it –
  /// we read the hardware UID (unchangeable), not the NDEF content.
  static Future<void> readTag({
    required void Function(String uid) onTagRead,
    required void Function(String error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        pollingOptions: NfcPollingOption.values.toSet(),
        onDiscovered: (NfcTag tag) async {
          try {
            final uid = _extractUid(tag);
            if (uid != null) {
              onTagRead(uid);
            } else {
              onError('Could not read UID.');
            }
          } catch (e) {
            onError(e.toString());
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  static Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// Scans a tag, writes a `rawdenim://wear/{itemId}` NDEF URI to it, and
  /// returns the hardware UID. Used during tag linking so the tag can later
  /// launch the app from the background.
  ///
  /// [onTagRead] is called with (uid, ndefWritten).
  /// If the tag is not NDEF-writable, ndefWritten = false but UID is still
  /// returned so UID-based foreground matching still works.
  static Future<void> readAndWriteNdefLink({
    required String itemId,
    required void Function(String uid, bool ndefWritten) onTagRead,
    required void Function(String error) onError,
  }) async {
    final ndefUri = 'rawdenim://wear/$itemId';
    try {
      await NfcManager.instance.startSession(
        pollingOptions: NfcPollingOption.values.toSet(),
        onDiscovered: (NfcTag tag) async {
          try {
            final uid = _extractUid(tag);
            if (uid == null) {
              onError('Could not read UID');
              return;
            }
            bool ndefWritten = false;
            if (Platform.isAndroid) {
              final ndef = NdefAndroid.from(tag);
              if (ndef != null && ndef.isWritable) {
                try {
                  // URI NDEF record: type 'U' (0x55), prefix 0x00 = no
                  // abbreviation, followed by the full URI as UTF-8.
                  final uriBytes = utf8Encode(ndefUri);
                  final payload =
                      Uint8List.fromList([0x00, ...uriBytes]);
                  await ndef.writeNdefMessage(NdefMessage(
                    records: [
                      NdefRecord(
                        typeNameFormat: TypeNameFormat.wellKnown,
                        type: Uint8List.fromList([0x55]),
                        identifier: Uint8List(0),
                        payload: payload,
                      ),
                    ],
                  ));
                  ndefWritten = true;
                } catch (_) {
                  // Tag not writable or full — link UID-only, foreground scan
                  // will still work.
                }
              }
            }
            onTagRead(uid, ndefWritten);
          } catch (e) {
            onError(e.toString());
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  static List<int> utf8Encode(String s) =>
      s.codeUnits; // ASCII-safe for our URI

  static String? _extractUid(NfcTag tag) {
    // nfc_manager 4.x on Android: NfcTagAndroid exposes the raw hardware UID
    // via .id (Uint8List). This app is Android-only, so no iOS fallback.
    if (Platform.isAndroid) {
      final androidTag = NfcTagAndroid.from(tag);
      if (androidTag != null && androidTag.id.isNotEmpty) {
        return _bytesToHex(androidTag.id);
      }
    }
    return null;
  }

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
}
