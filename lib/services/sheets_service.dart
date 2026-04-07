import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import '../models/wear_day.dart';
import '../models/wash.dart';

const _scopes = [SheetsApi.spreadsheetsScope];

final _googleSignIn = GoogleSignIn(scopes: _scopes);

class SheetsService {
  static GoogleSignInAccount? _currentAccount;

  static Future<GoogleSignInAccount> signIn() async {
    GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) throw Exception('Sign-in cancelled by user');
    _currentAccount = account;
    return account;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentAccount = null;
  }

  static Future<SheetsApi> _getSheetsApi() async {
    if (_currentAccount == null) {
      _currentAccount = await _googleSignIn.signInSilently();
    }
    final account = _currentAccount;
    if (account == null) throw Exception('Not signed in to Google');

    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) throw Exception('Could not obtain access token');

    final credentials = gauth.AccessCredentials(
      gauth.AccessToken(
        'Bearer',
        token,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      _scopes,
    );
    return SheetsApi(gauth.authenticatedClient(http.Client(), credentials));
  }

  static Future<String> createSpreadsheet(String title) async {
    final api = await _getSheetsApi();

    final spreadsheet = await api.spreadsheets.create(Spreadsheet(
      properties: SpreadsheetProperties(title: title),
      sheets: [
        _makeSheet('Dashboard', 0),
        _makeSheet('Items', 1),
        _makeSheet('WearDays', 2),
        _makeSheet('Washes', 3),
      ],
    ));
    final id = spreadsheet.spreadsheetId!;
    final dashboardSheetId = spreadsheet.sheets![0].properties!.sheetId!;

    // Headers
    await api.spreadsheets.values.batchUpdate(
      BatchUpdateValuesRequest(
        valueInputOption: 'RAW',
        data: [
          ValueRange(range: 'Dashboard!A1:D1', values: [
            ['Kleidungsstück', 'Tragetage', 'Wäschen', 'Getragen seit']
          ]),
          ValueRange(range: 'Items!A1:K1', values: [
            ['id', 'brand', 'model', 'size', 'first_wear_date', 'notes', 'nfc_tag_id', 'created_at', 'photo_path', 'base_wear_count', 'total_wear_days']
          ]),
          ValueRange(range: 'WearDays!A1:G1', values: [
            ['id', 'item_id', 'brand', 'model', 'date', 'latitude', 'longitude']
          ]),
          ValueRange(range: 'Washes!A1:F1', values: [
            ['id', 'item_id', 'brand', 'model', 'date', 'temp_celsius']
          ]),
        ],
      ),
      id,
    );

    // Embedded bar chart on Dashboard (references Dashboard!A:B, rows 2–100)
    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          addChart: AddChartRequest(
            chart: EmbeddedChart(
              spec: ChartSpec(
                title: 'Tragetage pro Kleidungsstück',
                basicChart: BasicChartSpec(
                  chartType: 'BAR',
                  legendPosition: 'NO_LEGEND',
                  axis: [
                    BasicChartAxis(position: 'BOTTOM_AXIS', title: 'Tragetage'),
                    BasicChartAxis(position: 'LEFT_AXIS'),
                  ],
                  domains: [
                    BasicChartDomain(
                      domain: ChartData(
                        sourceRange: ChartSourceRange(sources: [
                          GridRange(
                            sheetId: dashboardSheetId,
                            startRowIndex: 1,
                            endRowIndex: 100,
                            startColumnIndex: 0,
                            endColumnIndex: 1,
                          ),
                        ]),
                      ),
                    ),
                  ],
                  series: [
                    BasicChartSeries(
                      series: ChartData(
                        sourceRange: ChartSourceRange(sources: [
                          GridRange(
                            sheetId: dashboardSheetId,
                            startRowIndex: 1,
                            endRowIndex: 100,
                            startColumnIndex: 1,
                            endColumnIndex: 2,
                          ),
                        ]),
                      ),
                      targetAxis: 'LEFT_AXIS',
                    ),
                  ],
                  headerCount: 0,
                ),
              ),
              position: EmbeddedObjectPosition(
                overlayPosition: OverlayPosition(
                  anchorCell: GridCoordinate(
                    sheetId: dashboardSheetId,
                    rowIndex: 0,
                    columnIndex: 5,
                  ),
                  offsetXPixels: 0,
                  offsetYPixels: 0,
                  widthPixels: 600,
                  heightPixels: 400,
                ),
              ),
            ),
          ),
        ),
      ]),
      id,
    );

    return id;
  }

  static Sheet _makeSheet(String title, int index) =>
      Sheet(properties: SheetProperties(title: title, index: index));

  static Future<void> syncAll({
    required String spreadsheetId,
    required List<Item> items,
    required List<WearDay> wearDays,
    required List<Wash> washes,
    Map<String, int> trackedCounts = const {},
  }) async {
    final api = await _getSheetsApi();

    // Build lookup maps
    final itemById = {for (final i in items) i.id: i};
    final washCountById = <String, int>{};
    for (final w in washes) {
      washCountById[w.itemId] = (washCountById[w.itemId] ?? 0) + 1;
    }

    await api.spreadsheets.values.batchClear(
      BatchClearValuesRequest(
        ranges: ['Dashboard!A2:D', 'Items!A2:Z', 'WearDays!A2:Z', 'Washes!A2:Z'],
      ),
      spreadsheetId,
    );

    // Ensure headers are up to date (migration for older sheets)
    await api.spreadsheets.values.batchUpdate(
      BatchUpdateValuesRequest(
        valueInputOption: 'RAW',
        data: [
          ValueRange(
            range: 'WearDays!A1:G1',
            values: [['id', 'item_id', 'brand', 'model', 'date', 'latitude', 'longitude']],
          ),
          ValueRange(
            range: 'Washes!A1:F1',
            values: [['id', 'item_id', 'brand', 'model', 'date', 'temp_celsius']],
          ),
        ],
      ),
      spreadsheetId,
    );

    final data = <ValueRange>[];

    // Dashboard: sorted by total wear days descending
    if (items.isNotEmpty) {
      final sorted = [...items]..sort((a, b) {
          final aTotal = a.baseWearCount + (trackedCounts[a.id] ?? 0);
          final bTotal = b.baseWearCount + (trackedCounts[b.id] ?? 0);
          return bTotal.compareTo(aTotal);
        });
      data.add(ValueRange(
        range: 'Dashboard!A2',
        values: sorted.map((i) {
          final total = i.baseWearCount + (trackedCounts[i.id] ?? 0);
          return [
            '${i.brand} ${i.model}',
            total,
            washCountById[i.id] ?? 0,
            i.firstWearDate.toIso8601String().substring(0, 10),
          ];
        }).toList(),
      ));
    }

    // Items sheet
    if (items.isNotEmpty) {
      data.add(ValueRange(
        range: 'Items!A2',
        values: items.map((i) {
          final total = i.baseWearCount + (trackedCounts[i.id] ?? 0);
          return [
            i.id, i.brand, i.model, i.size,
            i.firstWearDate.toIso8601String(),
            i.notes ?? '', i.nfcTagId ?? '',
            i.createdAt.toIso8601String(),
            i.photoPath ?? '',
            i.baseWearCount,
            total,
          ];
        }).toList(),
      ));
    }

    // WearDays sheet — now with brand + model
    if (wearDays.isNotEmpty) {
      data.add(ValueRange(
        range: 'WearDays!A2',
        values: wearDays.map((w) {
          final item = itemById[w.itemId];
          return [
            w.id,
            w.itemId,
            item?.brand ?? '',
            item?.model ?? '',
            w.date.toIso8601String(),
            w.latitude ?? '',
            w.longitude ?? '',
          ];
        }).toList(),
      ));
    }

    // Washes sheet
    if (washes.isNotEmpty) {
      data.add(ValueRange(
        range: 'Washes!A2',
        values: washes.map((w) {
          final item = itemById[w.itemId];
          return [
            w.id,
            w.itemId,
            item?.brand ?? '',
            item?.model ?? '',
            w.date.toIso8601String(),
            w.tempCelsius,
          ];
        }).toList(),
      ));
    }

    if (data.isEmpty) return;

    await api.spreadsheets.values.batchUpdate(
      BatchUpdateValuesRequest(valueInputOption: 'RAW', data: data),
      spreadsheetId,
    );
  }
}
