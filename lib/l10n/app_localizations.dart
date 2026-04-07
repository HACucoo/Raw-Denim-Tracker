import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Raw Denim Tracker'**
  String get appTitle;

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No garments yet'**
  String get noItemsYet;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first pair'**
  String get addFirstItem;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add garment'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit garment'**
  String get editItem;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @firstWearDate.
  ///
  /// In en, this message translates to:
  /// **'First worn'**
  String get firstWearDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @wearDays.
  ///
  /// In en, this message translates to:
  /// **'Wear days'**
  String get wearDays;

  /// No description provided for @washes.
  ///
  /// In en, this message translates to:
  /// **'Washes'**
  String get washes;

  /// No description provided for @noWearDaysYet.
  ///
  /// In en, this message translates to:
  /// **'No wear days recorded yet'**
  String get noWearDaysYet;

  /// No description provided for @noWashesYet.
  ///
  /// In en, this message translates to:
  /// **'No washes recorded yet'**
  String get noWashesYet;

  /// No description provided for @addWearDay.
  ///
  /// In en, this message translates to:
  /// **'Add wear day'**
  String get addWearDay;

  /// No description provided for @addWash.
  ///
  /// In en, this message translates to:
  /// **'Add wash'**
  String get addWash;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete garment'**
  String get deleteItem;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this garment and all its data.'**
  String get deleteItemConfirm;

  /// No description provided for @itemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Garment not found'**
  String get itemNotFound;

  /// No description provided for @linkNfcTag.
  ///
  /// In en, this message translates to:
  /// **'Link NFC tag'**
  String get linkNfcTag;

  /// No description provided for @nfcLinkInstructions.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone near the NFC tag to read its ID, then confirm to link it to this garment.'**
  String get nfcLinkInstructions;

  /// No description provided for @startScan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get startScan;

  /// No description provided for @holdTagToPhone.
  ///
  /// In en, this message translates to:
  /// **'Hold the NFC tag close to the back of your phone…'**
  String get holdTagToPhone;

  /// No description provided for @tagDetected.
  ///
  /// In en, this message translates to:
  /// **'Tag detected'**
  String get tagDetected;

  /// No description provided for @linkTag.
  ///
  /// In en, this message translates to:
  /// **'Link this tag'**
  String get linkTag;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @nfcError.
  ///
  /// In en, this message translates to:
  /// **'NFC error'**
  String get nfcError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @nfcTagLinked.
  ///
  /// In en, this message translates to:
  /// **'NFC tag linked successfully'**
  String get nfcTagLinked;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @widget.
  ///
  /// In en, this message translates to:
  /// **'Home Screen Widget'**
  String get widget;

  /// No description provided for @widgetItem.
  ///
  /// In en, this message translates to:
  /// **'Garment for widget'**
  String get widgetItem;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @selectWidgetItem.
  ///
  /// In en, this message translates to:
  /// **'Select garment'**
  String get selectWidgetItem;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully'**
  String get importSuccess;

  /// No description provided for @importInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file format'**
  String get importInvalidFormat;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup'**
  String get importError;

  /// No description provided for @googleSheets.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets Sync'**
  String get googleSheets;

  /// No description provided for @enableSheetsSync.
  ///
  /// In en, this message translates to:
  /// **'Enable Google Sheets sync'**
  String get enableSheetsSync;

  /// No description provided for @spreadsheetLinked.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet linked'**
  String get spreadsheetLinked;

  /// No description provided for @createSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Create spreadsheet'**
  String get createSpreadsheet;

  /// No description provided for @spreadsheetCreated.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet created'**
  String get spreadsheetCreated;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synced successfully'**
  String get syncSuccess;

  /// No description provided for @historicalDays.
  ///
  /// In en, this message translates to:
  /// **'Historical days'**
  String get historicalDays;

  /// No description provided for @historicalDaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Days worn before tracking'**
  String get historicalDaysSubtitle;

  /// No description provided for @historicalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get historicalDaysLabel;

  /// No description provided for @setBulkCount.
  ///
  /// In en, this message translates to:
  /// **'Set total worn days'**
  String get setBulkCount;

  /// No description provided for @setBulkCountHint.
  ///
  /// In en, this message translates to:
  /// **'Set a starting count for days worn before you started tracking in this app.'**
  String get setBulkCountHint;

  /// No description provided for @totalWornDays.
  ///
  /// In en, this message translates to:
  /// **'Total days worn'**
  String get totalWornDays;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'First worn (newest first)'**
  String get sortByDate;

  /// No description provided for @sortByWearCount.
  ///
  /// In en, this message translates to:
  /// **'Wear days (most first)'**
  String get sortByWearCount;

  /// No description provided for @sortByBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand A–Z'**
  String get sortByBrand;

  /// No description provided for @sortByLastWorn.
  ///
  /// In en, this message translates to:
  /// **'Last worn (latest first)'**
  String get sortByLastWorn;

  /// No description provided for @latestOnTop.
  ///
  /// In en, this message translates to:
  /// **'Latest worn always on top'**
  String get latestOnTop;

  /// No description provided for @saveBackupLocally.
  ///
  /// In en, this message translates to:
  /// **'Save backup to device'**
  String get saveBackupLocally;

  /// No description provided for @autoBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup saved'**
  String get autoBackupSaved;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get savedTo;

  /// No description provided for @importLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Import from device backup'**
  String get importLocalBackup;

  /// No description provided for @importLocalBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Load the last locally saved backup'**
  String get importLocalBackupHint;

  /// No description provided for @importLocalBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import this backup? Existing entries with the same ID will be kept.'**
  String get importLocalBackupConfirm;

  /// No description provided for @importLocalBackupNotFound.
  ///
  /// In en, this message translates to:
  /// **'No local backup found. Save one first via \"Save backup to device\".'**
  String get importLocalBackupNotFound;

  /// No description provided for @scanNfcAddWearDay.
  ///
  /// In en, this message translates to:
  /// **'Scan NFC tag – add wear day'**
  String get scanNfcAddWearDay;

  /// No description provided for @nfcWearDayAdded.
  ///
  /// In en, this message translates to:
  /// **'{name}: wear day added for today'**
  String nfcWearDayAdded(String name);

  /// No description provided for @nfcAlreadyWornToday.
  ///
  /// In en, this message translates to:
  /// **'{name} is already tracked as worn today'**
  String nfcAlreadyWornToday(String name);

  /// No description provided for @nfcTagMismatch.
  ///
  /// In en, this message translates to:
  /// **'This tag is not linked to this garment'**
  String get nfcTagMismatch;

  /// No description provided for @nfcScanningWearDay.
  ///
  /// In en, this message translates to:
  /// **'Scan tag'**
  String get nfcScanningWearDay;

  /// No description provided for @nfcBackgroundEnabled.
  ///
  /// In en, this message translates to:
  /// **'Ready for background tap'**
  String get nfcBackgroundEnabled;

  /// No description provided for @nfcBackgroundDisabled.
  ///
  /// In en, this message translates to:
  /// **'Linked (foreground scan only)'**
  String get nfcBackgroundDisabled;

  /// No description provided for @unlinkNfcTag.
  ///
  /// In en, this message translates to:
  /// **'Remove tag'**
  String get unlinkNfcTag;

  /// No description provided for @relinkNfcTag.
  ///
  /// In en, this message translates to:
  /// **'Re-link tag'**
  String get relinkNfcTag;

  /// No description provided for @unlinkNfcTagConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove NFC tag? This garment will no longer be recognised by the tag.'**
  String get unlinkNfcTagConfirm;

  /// No description provided for @nfcTagUnlinked.
  ///
  /// In en, this message translates to:
  /// **'NFC tag removed'**
  String get nfcTagUnlinked;

  /// No description provided for @wearDaysAtWash.
  ///
  /// In en, this message translates to:
  /// **'Wear days at time of wash'**
  String get wearDaysAtWash;

  /// No description provided for @wearDaysAtWashHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to fill current count'**
  String get wearDaysAtWashHint;

  /// No description provided for @addHistoricalDays.
  ///
  /// In en, this message translates to:
  /// **'Add historical days'**
  String get addHistoricalDays;

  /// No description provided for @addHistoricalDaysHint.
  ///
  /// In en, this message translates to:
  /// **'How many days before tracking would you like to add?'**
  String get addHistoricalDaysHint;

  /// No description provided for @addHistoricalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days to add'**
  String get addHistoricalDaysLabel;

  /// No description provided for @unlinkSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Unlink spreadsheet'**
  String get unlinkSpreadsheet;

  /// No description provided for @unlinkSpreadsheetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the link to this Google Sheet? The spreadsheet itself will not be deleted. A new one will be created next time you enable sync.'**
  String get unlinkSpreadsheetConfirm;

  /// No description provided for @spreadsheetUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet unlinked'**
  String get spreadsheetUnlinked;

  /// No description provided for @daysWorn.
  ///
  /// In en, this message translates to:
  /// **'{count} days worn'**
  String daysWorn(int count);

  /// No description provided for @homeAssistant.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant'**
  String get homeAssistant;

  /// No description provided for @haEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Home Assistant'**
  String get haEnable;

  /// No description provided for @haConfigureConnection.
  ///
  /// In en, this message translates to:
  /// **'Configure connection'**
  String get haConfigureConnection;

  /// No description provided for @haUrl.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant URL'**
  String get haUrl;

  /// No description provided for @haUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://your-instance.ui.nabu.casa'**
  String get haUrlHint;

  /// No description provided for @haToken.
  ///
  /// In en, this message translates to:
  /// **'Long-Lived Access Token'**
  String get haToken;

  /// No description provided for @haTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Token from HA profile → Security'**
  String get haTokenHint;

  /// No description provided for @haTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get haTestConnection;

  /// No description provided for @haConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get haConnectionSuccess;

  /// No description provided for @haConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get haConnectionFailed;

  /// No description provided for @haSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get haSave;

  /// No description provided for @haNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get haNotConfigured;

  /// No description provided for @haSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get haSendNow;

  /// No description provided for @haSendNowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sent to Home Assistant'**
  String get haSendNowSuccess;

  /// No description provided for @haSendNowFailed.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send – no wear days recorded yet'**
  String get haSendNowFailed;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryJeans.
  ///
  /// In en, this message translates to:
  /// **'Jeans'**
  String get categoryJeans;

  /// No description provided for @categoryHemd.
  ///
  /// In en, this message translates to:
  /// **'Shirt'**
  String get categoryHemd;

  /// No description provided for @categoryJacke.
  ///
  /// In en, this message translates to:
  /// **'Jacket'**
  String get categoryJacke;

  /// No description provided for @categoryHose.
  ///
  /// In en, this message translates to:
  /// **'Trousers'**
  String get categoryHose;

  /// No description provided for @categorySonstiges.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categorySonstiges;

  /// No description provided for @categoriesEnabled.
  ///
  /// In en, this message translates to:
  /// **'Use categories'**
  String get categoriesEnabled;

  /// No description provided for @trackWearDaysSetting.
  ///
  /// In en, this message translates to:
  /// **'Track wear days'**
  String get trackWearDaysSetting;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @defaultWashTemp.
  ///
  /// In en, this message translates to:
  /// **'Default wash temperature'**
  String get defaultWashTemp;

  /// No description provided for @locationTracking.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTracking;

  /// No description provided for @locationTrackingEnable.
  ///
  /// In en, this message translates to:
  /// **'Record location when logging today\'s wear day'**
  String get locationTrackingEnable;

  /// No description provided for @wearDayLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get wearDayLocation;

  /// No description provided for @nfcLinked.
  ///
  /// In en, this message translates to:
  /// **'NFC linked'**
  String get nfcLinked;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
