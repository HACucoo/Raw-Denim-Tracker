// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Raw Denim Tracker';

  @override
  String get noItemsYet => 'No garments yet';

  @override
  String get addFirstItem => 'Tap + to add your first pair';

  @override
  String get addItem => 'Add garment';

  @override
  String get editItem => 'Edit garment';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get brand => 'Brand';

  @override
  String get model => 'Model';

  @override
  String get size => 'Size';

  @override
  String get firstWearDate => 'First worn';

  @override
  String get notes => 'Notes';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get fieldRequired => 'Required';

  @override
  String get wearDays => 'Wear days';

  @override
  String get washes => 'Washes';

  @override
  String get noWearDaysYet => 'No wear days recorded yet';

  @override
  String get noWashesYet => 'No washes recorded yet';

  @override
  String get addWearDay => 'Add wear day';

  @override
  String get addWash => 'Add wash';

  @override
  String get date => 'Date';

  @override
  String get temperature => 'Temperature';

  @override
  String get deleteItem => 'Delete garment';

  @override
  String get deleteItemConfirm =>
      'This will permanently delete this garment and all its data.';

  @override
  String get itemNotFound => 'Garment not found';

  @override
  String get linkNfcTag => 'Link NFC tag';

  @override
  String get nfcLinkInstructions =>
      'Hold your phone near the NFC tag to read its ID, then confirm to link it to this garment.';

  @override
  String get startScan => 'Start scan';

  @override
  String get holdTagToPhone =>
      'Hold the NFC tag close to the back of your phone…';

  @override
  String get tagDetected => 'Tag detected';

  @override
  String get linkTag => 'Link this tag';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get nfcError => 'NFC error';

  @override
  String get tryAgain => 'Try again';

  @override
  String get nfcTagLinked => 'NFC tag linked successfully';

  @override
  String get settings => 'Settings';

  @override
  String get widget => 'Home Screen Widget';

  @override
  String get widgetItem => 'Garment for widget';

  @override
  String get none => 'None';

  @override
  String get selectWidgetItem => 'Select garment';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Import backup';

  @override
  String get importSuccess => 'Backup imported successfully';

  @override
  String get importInvalidFormat => 'Invalid backup file format';

  @override
  String get importError => 'Failed to import backup';

  @override
  String get googleSheets => 'Google Sheets Sync';

  @override
  String get enableSheetsSync => 'Enable Google Sheets sync';

  @override
  String get spreadsheetLinked => 'Spreadsheet linked';

  @override
  String get createSpreadsheet => 'Create spreadsheet';

  @override
  String get spreadsheetCreated => 'Spreadsheet created';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncSuccess => 'Synced successfully';

  @override
  String get historicalDays => 'Historical days';

  @override
  String get historicalDaysSubtitle => 'Days worn before tracking';

  @override
  String get historicalDaysLabel => 'Number of days';

  @override
  String get setBulkCount => 'Set total worn days';

  @override
  String get setBulkCountHint =>
      'Set a starting count for days worn before you started tracking in this app.';

  @override
  String get totalWornDays => 'Total days worn';

  @override
  String get days => 'days';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortByDate => 'First worn (newest first)';

  @override
  String get sortByWearCount => 'Wear days (most first)';

  @override
  String get sortByBrand => 'Brand A–Z';

  @override
  String get sortByLastWorn => 'Last worn (latest first)';

  @override
  String get latestOnTop => 'Latest worn always on top';

  @override
  String get saveBackupLocally => 'Save backup to device';

  @override
  String get autoBackupSaved => 'Auto-backup saved';

  @override
  String get savedTo => 'Saved to';

  @override
  String get importLocalBackup => 'Import from device backup';

  @override
  String get importLocalBackupHint => 'Load the last locally saved backup';

  @override
  String get importLocalBackupConfirm =>
      'Import this backup? Existing entries with the same ID will be kept.';

  @override
  String get importLocalBackupNotFound =>
      'No local backup found. Save one first via \"Save backup to device\".';

  @override
  String get scanNfcAddWearDay => 'Scan NFC tag – add wear day';

  @override
  String nfcWearDayAdded(String name) {
    return '$name: wear day added for today';
  }

  @override
  String nfcAlreadyWornToday(String name) {
    return '$name is already tracked as worn today';
  }

  @override
  String get nfcTagMismatch => 'This tag is not linked to this garment';

  @override
  String get nfcScanningWearDay => 'Scan tag';

  @override
  String get nfcBackgroundEnabled => 'Ready for background tap';

  @override
  String get nfcBackgroundDisabled => 'Linked (foreground scan only)';

  @override
  String get unlinkNfcTag => 'Remove tag';

  @override
  String get relinkNfcTag => 'Re-link tag';

  @override
  String get unlinkNfcTagConfirm =>
      'Remove NFC tag? This garment will no longer be recognised by the tag.';

  @override
  String get nfcTagUnlinked => 'NFC tag removed';

  @override
  String get wearDaysAtWash => 'Wear days at time of wash';

  @override
  String get wearDaysAtWashHint => 'Tap to fill current count';

  @override
  String get addHistoricalDays => 'Add historical days';

  @override
  String get addHistoricalDaysHint =>
      'How many days before tracking would you like to add?';

  @override
  String get addHistoricalDaysLabel => 'Days to add';

  @override
  String get unlinkSpreadsheet => 'Unlink spreadsheet';

  @override
  String get unlinkSpreadsheetConfirm =>
      'Remove the link to this Google Sheet? The spreadsheet itself will not be deleted. A new one will be created next time you enable sync.';

  @override
  String get spreadsheetUnlinked => 'Spreadsheet unlinked';

  @override
  String daysWorn(int count) {
    return '$count days worn';
  }

  @override
  String get homeAssistant => 'Home Assistant';

  @override
  String get haEnable => 'Enable Home Assistant';

  @override
  String get haConfigureConnection => 'Configure connection';

  @override
  String get haUrl => 'Home Assistant URL';

  @override
  String get haUrlHint => 'https://your-instance.ui.nabu.casa';

  @override
  String get haToken => 'Long-Lived Access Token';

  @override
  String get haTokenHint => 'Token from HA profile → Security';

  @override
  String get haTestConnection => 'Test connection';

  @override
  String get haConnectionSuccess => 'Connection successful';

  @override
  String get haConnectionFailed => 'Connection failed';

  @override
  String get haSave => 'Save';

  @override
  String get haNotConfigured => 'Not configured';

  @override
  String get haSendNow => 'Send now';

  @override
  String get haSendNowSuccess => 'Sent to Home Assistant';

  @override
  String get haSendNowFailed => 'Nothing to send – no wear days recorded yet';

  @override
  String get nfcLinked => 'NFC linked';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';
}
