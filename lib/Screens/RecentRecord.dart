import 'package:flutter/material.dart';
import 'package:baboo_and_co/Services/GsheetApi.dart'; // Make sure this is correct

class RecentRecordScreen extends StatefulWidget {
  const RecentRecordScreen({super.key});

  @override
  State<RecentRecordScreen> createState() => _RecentRecordScreenState();
}

class _RecentRecordScreenState extends State<RecentRecordScreen> {
  Map<String, List<List<String>>> groupedData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGoodBillData();
  }

  Future<void> fetchGoodBillData() async {
    setState(() => isLoading = true);

    final allRows = await UserSheetsApi.fetchAllRows();
    if (allRows.isNotEmpty) {
      final rows = allRows.sublist(1); // Skip header

      final filtered = rows
          .where((row) =>
              row.length >= 4 &&
              row[2] == 'Good Bill' &&
              row[3].toLowerCase() != 'rizwan rasheed')
          .toList();

      // Group by date
      Map<String, List<List<String>>> grouped = {};
      for (var row in filtered) {
        final date = row[0].replaceAll("'", "");
        grouped.putIfAbsent(date, () => []).add(row);
      }

      // Sort dates (recent to old)
      final sortedKeys = grouped.keys.toList()
        ..sort((a, b) => parseDate(b).compareTo(parseDate(a)));

      Map<String, List<List<String>>> sortedMap = {
        for (var key in sortedKeys) key: grouped[key]!
      };

      setState(() {
        groupedData = sortedMap;
        isLoading = false;
      });
    } else {
      setState(() {
        groupedData = {};
        isLoading = false;
      });
    }
  }

  DateTime parseDate(String dateStr) {
    try {
      dateStr = dateStr.replaceAll("'", ""); // Remove leading quote if any
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    } catch (_) {
      return DateTime(2000); // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Recent Good Bill Records'),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : groupedData.isEmpty
                ? const Center(child: Text('No Good Bill records found.'))
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: groupedData.entries.map((entry) {
                      String date = entry.key;
                      List<List<String>> rows = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📅 $date',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const Divider(thickness: 2),
                          const SizedBox(height: 6),
                          ...rows.map((row) {
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 5),
                              title: Text(
                                '✔ ${row[3]}',
                                style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600),
                              ), // Naam
                              subtitle: Text(
                                  "       Bags: ${row[4]}   |   Rs. ${row[5]}"),
                            );
                          }),
                          const Divider(thickness: 2),
                        ],
                      );
                    }).toList(),
                  ));
  }
}
