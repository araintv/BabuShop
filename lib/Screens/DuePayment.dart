import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DuePaymentScreen extends StatefulWidget {
  const DuePaymentScreen({super.key});

  @override
  State<DuePaymentScreen> createState() => _DuePaymentScreenState();
}

class _DuePaymentScreenState extends State<DuePaymentScreen> {
  List<Map<String, String>> allData = [];
  List<Map<String, String>> filteredData = [];
  bool isLoading = true;
  Set<String> selectedAccounts = {};
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDuePayments();
    searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterData);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDuePayments() async {
    setState(() => isLoading = true);
    final data = await UserSheetsApi.fetchAllRows();

    Map<String, double> accountBalances = {};

    for (var row in data.skip(1)) {
      String? jamaName = row.length > 1 ? row[1].trim() : null;
      String? naamName = row.length > 3 ? row[3].trim() : null;
      double amount =
          row.length > 5 ? double.tryParse(row[5].trim()) ?? 0.0 : 0.0;

      if (jamaName != null && jamaName.isNotEmpty) {
        accountBalances[jamaName] = (accountBalances[jamaName] ?? 0) + amount;
      }
      if (naamName != null && naamName.isNotEmpty) {
        accountBalances[naamName] = (accountBalances[naamName] ?? 0) - amount;
      }
    }

    setState(() {
      allData = accountBalances.entries
          .where((entry) => entry.value < 0)
          .map((entry) => {
                "Name": entry.key,
                "Due Amount": entry.value.toStringAsFixed(0),
              })
          .toList();
      filteredData = List.from(allData);
      isLoading = false;
    });
  }

  void _filterData() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredData = allData
          .where((entry) => entry["Name"]!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedAccounts.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectedAccountsScreen(
                  selectedAccounts: allData
                      .where(
                          (entry) => selectedAccounts.contains(entry["Name"]))
                      .toList(),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Please select at least one account")),
            );
          }
        },
        child: Icon(Icons.check),
      ),
      appBar: AppBar(title: const Text("Due Payments")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Search Account",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final entry = filteredData[index];
                      final String accountName = entry["Name"] ?? "---";
                      final String dueAmount = entry["Due Amount"] ?? "0";

                      bool isSelected = selectedAccounts.contains(accountName);

                      return CheckboxListTile(
                        title: Text(
                          accountName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Due Amount: $dueAmount",
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                        value: isSelected,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              selectedAccounts.add(accountName);
                            } else {
                              selectedAccounts.remove(accountName);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class SelectedAccountsScreen extends StatelessWidget {
  final List<Map<String, String>> selectedAccounts;

  SelectedAccountsScreen({required this.selectedAccounts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Selected Accounts")),
      // floatingActionButton: FloatingActionButton(
// onPressed: () => generateAndOpenPDF(selectedAccounts),        child: Icon(Icons.picture_as_pdf),
      // ),
      body: ListView.builder(
        itemCount: selectedAccounts.length,
        itemBuilder: (context, index) {
          final account = selectedAccounts[index];
          return ListTile(
            title: Text(
              account["Name"] ?? "---",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Due Amount: ${account["Due Amount"]}",
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
