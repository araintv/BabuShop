import 'package:baboo_and_co/Widgets/Button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  List<Map<String, String>> filteredData = [];
  List<String> accountNames = []; // List for autocomplete suggestions
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAccountNames(); // Load available names for autocomplete
  }

  // Fetch all available names from Jama and Naam columns for suggestions
  Future<void> fetchAccountNames() async {
    final data = await UserSheetsApi.fetchAllRows();
    Set<String> namesSet = {}; // Use Set to avoid duplicates

    for (var row in data.skip(1)) {
      if (row.length > 1) namesSet.add(row[1].trim()); // Jama
      if (row.length > 3) namesSet.add(row[3].trim()); // Naam
    }

    setState(() {
      accountNames = namesSet.where((name) => name.isNotEmpty).toList();
    });
  }

  Future<void> fetchData(String khataName) async {
    setState(() => isLoading = true);
    final data = await UserSheetsApi.fetchAllRows();

    List<Map<String, String>> mappedData = data.skip(1).map((row) {
      return {
        "Date": row.isNotEmpty ? row[0].replaceAll("'", "").trim() : "",
        "Jama": row.length > 1 ? row[1].trim() : "",
        "Type": row.length > 1 ? row[2].trim() : "",
        "Naam": row.length > 3 ? row[3].trim() : "",
        "Amount": row.length > 5 ? row[5].trim() : "",
        "Details": row.length > 6 ? row[6].trim() : "",
      };
    }).toList();

    setState(() {
      filteredData = mappedData
          .where((entry) =>
              entry["Naam"]?.toLowerCase() == khataName.toLowerCase() ||
              entry["Jama"]?.toLowerCase() == khataName.toLowerCase())
          .toList();

      // Sort the filtered data by Date in descending order
      filteredData.sort((a, b) {
        DateTime dateA = _parseDate(a["Date"] ?? "");
        DateTime dateB = _parseDate(b["Date"] ?? "");
        return dateB.compareTo(dateA); // Descending order
      });

      isLoading = false;
    });
  }

// Helper function to parse the date
  DateTime _parseDate(String dateString) {
    try {
      return DateFormat("dd-MM-yyyy")
          .parse(dateString); // Adjust format if needed
    } catch (e) {
      return DateTime(2000, 1, 1); // Default fallback date
    }
  }

  String formatDate(String date) {
    if (date.isNotEmpty && date.contains("-")) {
      List<String> parts = date.split("-");
      if (parts.length >= 2) {
        return "${parts[0]}-${parts[1]}"; // Extracts only DD-MM
      }
    }
    return date; // Return original if format is incorrect
  }

  Future<bool> isInternetAvailable() async {
    List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    return results.isNotEmpty && results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Precompute running balances in correct order (oldest first)
    double runningBalance = 0.0;
    List<double> runningBalances = [];

    for (int i = filteredData.length - 1; i >= 0; i--) {
      final entry = filteredData[i];
      double amount = double.tryParse(entry["Amount"] ?? "0") ?? 0.0;

      bool isDebit =
          entry["Naam"]?.toLowerCase() == searchController.text.toLowerCase();
      bool isCredit =
          entry["Jama"]?.toLowerCase() == searchController.text.toLowerCase();

      if (isDebit) {
        runningBalance -= amount;
      } else if (isCredit) {
        runningBalance += amount;
      }

      runningBalances.insert(
          0, runningBalance); // Insert at index 0 to maintain order
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            const Text("Khata Accounts", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.070,
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty)
                          return const Iterable<String>.empty();
                        return accountNames.where((name) => name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selected) {
                        searchController.text = selected;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                        searchController = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: InputDecoration(
                            hintText: "Search Khata",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: screenWidth * 0.30,
                  height: screenHeight * 0.070,
                  child:
                      Button_Widget(context, 'Search', Colors.black, () async {
                    bool hasInternet = await isInternetAvailable();
                    if (hasInternet) {
                      if (searchController.text.isNotEmpty) {
                        fetchData(searchController.text.trim());
                      }
                    } else {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.error,
                        title: 'No Internet',
                        text: 'You are Disconnected',
                      );
                    }
                  }),
                ),
              ],
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredData.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final entry = filteredData[index];
                          double amount =
                              double.tryParse(entry["Amount"] ?? "0") ?? 0.0;
                          bool isDebit = entry["Naam"]?.toLowerCase() ==
                              searchController.text.toLowerCase();
                          bool isCredit = entry["Jama"]?.toLowerCase() ==
                              searchController.text.toLowerCase();

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          formatDate(entry["Date"] ?? "---"),
                                          style: TextStyle(
                                              fontSize: screenWidth * 0.020),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${entry["Details"] ?? "---"} - ${searchController.text == entry["Naam"] ? entry["Jama"] : searchController.text == "${entry["Jama"]}" ? entry["Naam"] : ""}',
                                        maxLines: 3,
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.010),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          isCredit
                                              ? amount.toStringAsFixed(0)
                                              : "---",
                                          style: TextStyle(
                                              fontSize: isCredit
                                                  ? screenWidth * 0.025
                                                  : screenWidth * 0.015,
                                              color: Colors.green),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          isDebit
                                              ? amount.toStringAsFixed(0)
                                              : "---",
                                          style: TextStyle(
                                              fontSize: isDebit
                                                  ? screenWidth * 0.025
                                                  : screenWidth * 0.015,
                                              color: Colors.red),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          runningBalances[index] >= 0
                                              ? "+${runningBalances[index].toStringAsFixed(0)}"
                                              : runningBalances[index]
                                                  .toStringAsFixed(0),
                                          style: TextStyle(
                                              fontSize: screenWidth * 0.025,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                            ],
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text("No matching records found",
                          style: TextStyle(fontSize: 18, color: Colors.red)),
                    ),
        ],
      ),
    );
  }
}
