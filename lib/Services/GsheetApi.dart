import 'package:gsheets/gsheets.dart';

class UserSheetsApi {
  static const _credentials = r'''
 {
  "type": "service_account",
  "project_id": "gsheet-449905",
  "private_key_id": "2a514f15c0c3e932584aa76999bdcf81a5a9f33f",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCtKvdkvlbsvtTk\nprV8XbEIi1h9P4zMlb9aGdo09nsDN5geppJQBMX2QTckiiEXo0krft0/wXAxMtXh\nzG2hJRm5b4BDYgyWfMcTgRBvSgUHg2LniOTDQZtjaaBjDI3OhSz4zkqX0hob2nV+\nE/xlgJE+7fX3/3KonzMHMJs9kOVSSWV575P+g56hZd7zrcZcGEOr7yulGzsb4UoZ\noVoE+UucQ2nyx345nkBSQ8xr8LtwBf+kuQo03D/DxpIVa08lx0fk+hxqF/jNrH4+\njLPZrL/3f0eVHkee0x+MmeiO2MVA1a7dqif95xXUvr85VduuFZ7/RYaKUFFYaC8A\nTyoMvDRxAgMBAAECggEAHl3VAU0hiCWUxr33QGZbp6Br9ZbB1ZSC+EVlTvlULAXB\nPsq+CJs1rc/U4Cr6z57aM27tVINS7cW43P5Q0TvkzXBgoTBd/bvG20Q8Qg/MXvtq\nyihm2Vi1a5L3xbbLXUZcUws16Ha3DmBaTzApCBGqJstq4UDh9fDo7V9YMc0pcarU\nZwpV/JCqt4sGV3O9Xg3GnIL+Dl9czb8iO7Cr7dP9uYRP7tIx05KvPnvndtTUqx8Z\n//sgnD2MVf1Jhy/lymyLghGKkN88LqBDetSwP8n01fk+J7iB5B1LM2EvzJOM4SiS\ngJFeGwXx/qQkhtj/XJQcYtO+mH4851jJOHTPhSrhiwKBgQDZf9UalDDiER9O4rHk\n84evV/4fDaLvqWubwRCZy5hi2syAgB6odxEnAWTb9Hnv72HE60f3Os6fL9KfFYbV\nIvlnDT18rLR2waJAcUa19UKAwSAZHtr6O9nPscvsYCs6nsSCbs4gorNIE77yvCFR\nfcT+UZtN7BwoVUQST1CO8CRmUwKBgQDL0jbJJCQhUlg6zspu4lR840U0QYtbyJ9Q\nb9K0pu5Eh7nRMrntlrOpY7C1OFFfTQMkZDaTr9yKri3xXOeyJiAht6AvutqOwhvy\nr+ZIo0nPqKSRBTB6IprhJzvpAizNRsLk7Qe9huIelAiED5OKKi2+wz8zY5ytvQOO\nGeZcEqNZqwKBgQCV36iRMByfKv1P9pZvFgEhqpjJ/TORwkUMhvVRhSH0vKC+y4pU\nu/dt0WAW0VhVJbdRYm+sxTEsMGAKj2Lh67/Aazc7eibAzp1nmqcHK4IwBuR/auuq\nEyP8IqBKudoQAueWmZQgmPzBZhnmWgz7gpcESGekQlcE0/ycQVtZo9DxUQKBgFlr\nUD3ObUtxJOQn9QfQo+BmlOXoG4uY6MwRQw+ebMoEAbGV35wskYWvBsd6fbihwM8m\naAtDDC6LW/yYFc5Ci7Y/KTfHcjtPTZObOByGBsvj4M7+x9XNeMVuwQnoul8UvExS\n8SJlGq7vowzNCJ2FA6y9W+zfts1CL10YX8flJWUhAoGBAMvMIogIY4ViXfzSvfgu\ntDInkMhYS0XcH/HaLXUEe/4MzowOKqVr4ax2r834kTqtwGKkFOD4IXldY1Pa6E4l\nm6Zp0gAQcGynMRDwe/tgRDrQRQFPxhtjakTK1WxQpC8d74U+s//KLsyjmv599jwv\nO5STQLoMid/uO8KAHp7baTBL\n-----END PRIVATE KEY-----\n",
  "client_email": "gsheet@gsheet-449905.iam.gserviceaccount.com",
  "client_id": "114981871230295715085",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/gsheet%40gsheet-449905.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
  ''';

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
