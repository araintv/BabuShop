import 'package:gsheets/gsheets.dart';

class UserSheetsApi {
  static const _spreadsheetID = '1av-FKCRtNYgCKxnI9-wzF1famBwaX0SsVbxnjOzPZ4A';
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _userSheet;

  /// **Fetch All Rows**
  static Future<List<List<String>>> fetchAllRows() async {
    if (_userSheet == null) return [];

    final allRows = await _userSheet!.values.allRows();
    return allRows;
  }

  static Future<void> init() async {
    final spreadsheet = await _gsheets.spreadsheet(_spreadsheetID);
    _userSheet = spreadsheet.worksheetByTitle('CashBook') ??
        await spreadsheet.addWorksheet('CashBook');

    // Ensure headers exist
    final headers = await _userSheet!.values.row(1);
    if (headers.isEmpty || headers[0] != 'Date') {
      await _userSheet!.values
          .insertRow(1, ['Date', 'Jama', 'Type', 'Naam', 'Quantity', 'Amount']);
    }
  }

  /// **Append Data at the Bottom**
  static Future<void> insertRow(List<String> rowData) async {
    if (_userSheet == null) return;

    // Ensuring date remains text (avoiding 45779 issue)
    rowData[0] = "'${rowData[0]}'"; // Forces date to be stored as text

    await _userSheet!.values.appendRow(rowData);
  }

  /// **Update a specific row by index**
  static Future<void> updateRow(int rowIndex, List<String> updatedData) async {
    if (_userSheet == null) return;

    // Ensuring date remains text
    updatedData[0] = "'${updatedData[0]}'";

    await _userSheet!.values.insertRow(rowIndex, updatedData);
  }

  /// **Delete a specific row by index**
  static Future<void> deleteRow(int rowIndex) async {
    if (_userSheet == null) return;

    await _userSheet!.deleteRow(rowIndex);
  }
}
