import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/Services/GsheetApi.dart';

class DailyCashBook extends StatefulWidget {
  const DailyCashBook({super.key});

  @override
  State<DailyCashBook> createState() => _CustomerKhataState();
}

class _CustomerKhataState extends State<DailyCashBook> {
  List<Map<String, dynamic>> filteredData = [];
  List<List<String>> allData = [];
  bool isLoading = true;
  bool isFiltering = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCachedDataThenFetch();
  }

  /// Load cached data instantly, then fetch fresh data in background
  Future<void> _loadCachedDataThenFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_sheet_data');

    if (cached != null) {
      try {
        final decoded = List<List<String>>.from(jsonDecode(cached));
        setState(() {
          allData = decoded;
          filterData('');
          isLoading = false;
        });
      } catch (_) {}
    }

    fetchData(refreshCache: true);
  }

  Future<void> fetchData({bool refreshCache = false}) async {
    if (refreshCache) {
      final allRows = await UserSheetsApi.fetchAllRows();

      if (allRows.isNotEmpty) {
        allData = allRows.sublist(1);

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_sheet_data', jsonEncode(allData));
        filterData(searchController.text);
      }

      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Run filtering in background isolate
  Future<void> filterData(String query) async {
    if (isFiltering) return;
    setState(() => isFiltering = true);

    final results = await compute(_filterTask, {
      'data': allData,
      'query': query,
    });

    if (mounted) {
      setState(() {
        filteredData = results.reversed.toList();
        isFiltering = false;
      });
    }
  }

  /// Background filtering function
  static List<Map<String, dynamic>> _filterTask(Map<String, dynamic> input) {
    final allData = input['data'] as List<List<String>>;
    final query = input['query'] as String;

    if (query.isEmpty) {
      return allData
          .asMap()
          .entries
          .map((entry) => {"index": entry.key, "row": entry.value})
          .toList();
    }

    final lowerQuery = query.toLowerCase();
    return allData
        .asMap()
        .entries
        .where((entry) {
          final row = entry.value;
          if (row.length < 6) return false;
          return row[0].toLowerCase().contains(lowerQuery) ||
              row[1].toLowerCase().contains(lowerQuery) ||
              row[3].toLowerCase().contains(lowerQuery) ||
              row[5].toLowerCase().contains(lowerQuery);
        })
        .map((entry) => {"index": entry.key, "row": entry.value})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'General Ledger \'CashBook\'',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                filterData('');
                              },
                            ),
                          ),
                          onChanged: (value) => filterData(value),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFiltering)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),
                Expanded(
                  child: filteredData.isEmpty
                      ? const Center(child: Text('No matching entries found'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            double tableWidth = constraints.maxWidth;
                            double dateCol = tableWidth * 0.15;
                            double jamaCol = tableWidth * 0.15;
                            double typeCol = tableWidth * 0.15;
                            double naamCol = tableWidth * 0.15;
                            double amountCol = tableWidth * 0.15;
                            double iconCol = tableWidth * 0.075;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  children: [
                                    // ✅ Header Row
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: dateCol,
                                            child: const Text(
                                              'Date',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          SizedBox(
                                            width: jamaCol,
                                            child: const Text(
                                              'Jama',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          SizedBox(
                                            width: typeCol,
                                            child: const Text(
                                              'Type',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          SizedBox(
                                            width: naamCol,
                                            child: const Text(
                                              'Naam',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          SizedBox(
                                            width: amountCol,
                                            child: const Text(
                                              'Amount',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          SizedBox(
                                            width: iconCol,
                                            child: const Text(
                                              'Edit',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          SizedBox(
                                            width: iconCol,
                                            child: const Text(
                                              'DLT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ✅ Data Rows
                                    Expanded(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: filteredData.length,
                                        itemBuilder: (context, index) {
                                          final entry = filteredData[index];
                                          final realIndex = entry["index"];
                                          final row =
                                              entry["row"] as List<String>;

                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: dateCol,
                                                  child: Text(
                                                    row[0].replaceAll("'", ""),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                SizedBox(
                                                  width: jamaCol,
                                                  child: Text(
                                                    row[1],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                SizedBox(
                                                  width: typeCol,
                                                  child: Text(
                                                    row[2],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                SizedBox(
                                                  width: naamCol,
                                                  child: Text(
                                                    row[3],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                SizedBox(
                                                  width: amountCol,
                                                  child: Text(
                                                    row[5],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: iconCol,
                                                  child: Center(
                                                    child: InkWell(
                                                      onTap: () => editEntry(
                                                        realIndex,
                                                        row,
                                                      ),
                                                      child: const Icon(
                                                        Icons.edit,
                                                        color: Colors.blue,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                SizedBox(
                                                  width: iconCol,
                                                  child: Center(
                                                    child: InkWell(
                                                      onTap: () => deleteEntry(
                                                        realIndex,
                                                      ),
                                                      child: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void editEntry(int index, List<String> row) {
    TextEditingController dateController = TextEditingController(
      text: row[0].replaceAll("'", ""),
    );
    TextEditingController jamaController = TextEditingController(text: row[1]);
    TextEditingController naamController = TextEditingController(text: row[3]);
    TextEditingController quantityController = TextEditingController(
      text: row[4],
    );
    TextEditingController amountController = TextEditingController(
      text: row[5],
    );
    TextEditingController tafseelController = TextEditingController(
      text: row.length > 6 ? row[6] : '',
    );

    bool isDateValid = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date (DD-MM-YYYY)',
                        errorText: isDateValid ? null : 'Invalid date format',
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    TextField(
                      controller: jamaController,
                      decoration: const InputDecoration(labelText: 'Jama'),
                    ),
                    TextField(
                      controller: naamController,
                      decoration: const InputDecoration(labelText: 'Naam'),
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: tafseelController,
                      decoration: const InputDecoration(labelText: 'Tafseel'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (!isValidDateFormat(dateController.text)) {
                      setState(() => isDateValid = false);
                      return;
                    }

                    List<String> updatedRow = [
                      dateController.text,
                      jamaController.text,
                      row[2],
                      naamController.text,
                      quantityController.text,
                      amountController.text,
                      tafseelController.text,
                    ];

                    await UserSheetsApi.updateRow(index + 2, updatedRow);
                    fetchData(refreshCache: true);
                    Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool isValidDateFormat(String date) {
    final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    return regex.hasMatch(date);
  }

  void deleteEntry(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await UserSheetsApi.deleteRow(index + 2);
                fetchData(refreshCache: true);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
