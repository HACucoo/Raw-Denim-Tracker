// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Raw Denim Tracker';

  @override
  String get noItemsYet => 'Noch keine Kleidungsstücke';

  @override
  String get addFirstItem => 'Tippe auf + um dein erstes Stück hinzuzufügen';

  @override
  String get addItem => 'Kleidungsstück hinzufügen';

  @override
  String get editItem => 'Kleidungsstück bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get brand => 'Marke';

  @override
  String get model => 'Modell';

  @override
  String get size => 'Größe';

  @override
  String get firstWearDate => 'Erstmals getragen';

  @override
  String get notes => 'Notizen';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get fieldRequired => 'Pflichtfeld';

  @override
  String get wearDays => 'Tragetage';

  @override
  String get washes => 'Wäschen';

  @override
  String get noWearDaysYet => 'Noch keine Tragetage erfasst';

  @override
  String get noWashesYet => 'Noch keine Wäschen erfasst';

  @override
  String get addWearDay => 'Tragetag hinzufügen';

  @override
  String get addWash => 'Wäsche hinzufügen';

  @override
  String get date => 'Datum';

  @override
  String get temperature => 'Temperatur';

  @override
  String get deleteItem => 'Kleidungsstück löschen';

  @override
  String get deleteItemConfirm =>
      'Dieses Kleidungsstück und alle zugehörigen Daten werden dauerhaft gelöscht.';

  @override
  String get itemNotFound => 'Kleidungsstück nicht gefunden';

  @override
  String get linkNfcTag => 'NFC-Tag verknüpfen';

  @override
  String get nfcLinkInstructions =>
      'Halte dein Handy an den NFC-Tag, um seine ID auszulesen, und bestätige dann die Verknüpfung.';

  @override
  String get startScan => 'Scan starten';

  @override
  String get holdTagToPhone =>
      'Halte den NFC-Tag an die Rückseite deines Handys…';

  @override
  String get tagDetected => 'Tag erkannt';

  @override
  String get linkTag => 'Tag verknüpfen';

  @override
  String get scanAgain => 'Erneut scannen';

  @override
  String get nfcError => 'NFC-Fehler';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get nfcTagLinked => 'NFC-Tag erfolgreich verknüpft';

  @override
  String get settings => 'Einstellungen';

  @override
  String get widget => 'Startbildschirm-Widget';

  @override
  String get widgetItem => 'Kleidungsstück für Widget';

  @override
  String get none => 'Keines';

  @override
  String get selectWidgetItem => 'Kleidungsstück auswählen';

  @override
  String get backupRestore => 'Backup & Wiederherstellung';

  @override
  String get exportBackup => 'Backup exportieren';

  @override
  String get importBackup => 'Backup importieren';

  @override
  String get importSuccess => 'Backup erfolgreich importiert';

  @override
  String get importInvalidFormat => 'Ungültiges Backup-Format';

  @override
  String get importError => 'Import fehlgeschlagen';

  @override
  String get googleSheets => 'Google Sheets Sync';

  @override
  String get enableSheetsSync => 'Google Sheets Sync aktivieren';

  @override
  String get spreadsheetLinked => 'Tabelle verknüpft';

  @override
  String get createSpreadsheet => 'Tabelle erstellen';

  @override
  String get spreadsheetCreated => 'Tabelle erstellt';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncSuccess => 'Erfolgreich synchronisiert';

  @override
  String get historicalDays => 'Historische Tragetage';

  @override
  String get historicalDaysSubtitle => 'Tage getragen vor dem Tracking';

  @override
  String get historicalDaysLabel => 'Anzahl Tage';

  @override
  String get setBulkCount => 'Gesamtzahl Tragetage setzen';

  @override
  String get setBulkCountHint =>
      'Setze eine Startzahl für Tage, die du vor dem Tracking in dieser App getragen hast.';

  @override
  String get totalWornDays => 'Gesamt getragene Tage';

  @override
  String get days => 'Tage';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortByDate => 'Erstmals getragen (neueste zuerst)';

  @override
  String get sortByWearCount => 'Tragetage (meiste zuerst)';

  @override
  String get sortByBrand => 'Marke A–Z';

  @override
  String get sortByLastWorn => 'Zuletzt getragen (aktuellste zuerst)';

  @override
  String get latestOnTop => 'Aktuellstes immer oben';

  @override
  String get saveBackupLocally => 'Backup auf Gerät speichern';

  @override
  String get autoBackupSaved => 'Auto-Backup gespeichert';

  @override
  String get savedTo => 'Gespeichert unter';

  @override
  String get importLocalBackup => 'Lokales Backup importieren';

  @override
  String get importLocalBackupHint =>
      'Zuletzt lokal gespeichertes Backup laden';

  @override
  String get importLocalBackupConfirm =>
      'Dieses Backup importieren? Bestehende Einträge mit gleicher ID bleiben erhalten.';

  @override
  String get importLocalBackupNotFound =>
      'Kein lokales Backup gefunden. Zuerst über \"Backup auf Gerät speichern\" erstellen.';

  @override
  String get scanNfcAddWearDay => 'NFC-Tag scannen – Tragetag eintragen';

  @override
  String nfcWearDayAdded(String name) {
    return '$name: Tragetag für heute eingetragen';
  }

  @override
  String nfcAlreadyWornToday(String name) {
    return '$name wird heute bereits getragen';
  }

  @override
  String get nfcTagMismatch =>
      'Dieser Tag gehört nicht zu diesem Kleidungsstück';

  @override
  String get nfcScanningWearDay => 'Tag scannen';

  @override
  String get nfcBackgroundEnabled => 'Bereit für Hintergrund-Scan';

  @override
  String get nfcBackgroundDisabled => 'Verknüpft (nur in App erkennbar)';

  @override
  String get unlinkNfcTag => 'Tag entfernen';

  @override
  String get relinkNfcTag => 'Neu verknüpfen';

  @override
  String get unlinkNfcTagConfirm =>
      'NFC-Tag entfernen? Das Kleidungsstück kann dann nicht mehr per Tag erkannt werden.';

  @override
  String get nfcTagUnlinked => 'NFC-Tag entfernt';

  @override
  String get wearDaysAtWash => 'Tragetage bei der Wäsche';

  @override
  String get wearDaysAtWashHint => 'Antippen zum Befüllen';

  @override
  String get addHistoricalDays => 'Historische Tage hinzufügen';

  @override
  String get addHistoricalDaysHint =>
      'Wie viele Tage vor dem Tracking möchtest du hinzufügen?';

  @override
  String get addHistoricalDaysLabel => 'Tage hinzufügen';

  @override
  String get unlinkSpreadsheet => 'Tabelle trennen';

  @override
  String get unlinkSpreadsheetConfirm =>
      'Verknüpfung mit der Google-Tabelle aufheben? Die Tabelle selbst wird nicht gelöscht. Beim nächsten Aktivieren wird eine neue Tabelle angelegt.';

  @override
  String get spreadsheetUnlinked => 'Tabelle getrennt';

  @override
  String daysWorn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tragetage',
      one: '1 Tragetag',
    );
    return '$_temp0';
  }

  @override
  String get homeAssistant => 'Home Assistant';

  @override
  String get haEnable => 'Home Assistant aktivieren';

  @override
  String get haConfigureConnection => 'Verbindung konfigurieren';

  @override
  String get haUrl => 'Home Assistant URL';

  @override
  String get haUrlHint => 'https://deine-instanz.ui.nabu.casa';

  @override
  String get haToken => 'Long-Lived Access Token';

  @override
  String get haTokenHint => 'Token aus HA-Profil → Sicherheit';

  @override
  String get haTestConnection => 'Verbindung testen';

  @override
  String get haConnectionSuccess => 'Verbindung erfolgreich';

  @override
  String get haConnectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get haSave => 'Speichern';

  @override
  String get haNotConfigured => 'Nicht konfiguriert';

  @override
  String get nfcLinked => 'NFC verknüpft';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galerie';
}
