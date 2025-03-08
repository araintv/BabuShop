import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:flutter/material.dart';

class DuePaymentScreen extends StatefulWidget {
  const DuePaymentScreen({super.key});

  @override
  State<DuePaymentScreen> createState() => _DuePaymentScreenState();
}

class _DuePaymentScreenState extends State<DuePaymentScreen> {
  List<Map<String, String>> allData = [];
  List<Map<String, String>> filteredData = [];
  Map<String, List<String>> groupedData = {}; // Grouped Dues
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

    Map<String, List<Map<String, dynamic>>> accountDueDetails = {};

    for (var row in data.skip(1)) {
      String date = row.isNotEmpty ? row[0].trim() : "Unknown Date";
      String? jamaName = row.length > 1 ? row[1].trim() : null;
      String? naamName = row.length > 3 ? row[3].trim() : null;
      double amount =
          row.length > 5 ? (double.tryParse(row[5].trim()) ?? 0.0) : 0.0;

      if (naamName != null && naamName.isNotEmpty) {
        accountDueDetails.putIfAbsent(naamName, () => []);
        accountDueDetails[naamName]!.add({"date": date, "due": amount});
      }
      if (jamaName != null && jamaName.isNotEmpty) {
        accountDueDetails.putIfAbsent(jamaName, () => []);
        accountDueDetails[jamaName]!.add({"date": date, "paid": amount});
      }
    }

    // Apply Payments Chronologically
    Map<String, List<Map<String, dynamic>>> remainingDues = {};

    accountDueDetails.forEach((account, transactions) {
      List<Map<String, dynamic>> dues = [];
      List<Map<String, dynamic>> payments = [];

      for (var txn in transactions) {
        if (txn.containsKey("due")) {
          dues.add({"date": txn["date"], "amount": txn["due"]});
        } else if (txn.containsKey("paid")) {
          payments.add({"amount": txn["paid"]});
        }
      }

      // Sort dues by date (oldest first)
      dues.sort((a, b) => a["date"].compareTo(b["date"]));

      // Process Payments against Due
      for (var payment in payments) {
        double remainingPayment = payment["amount"];
        for (var due in dues) {
          if (remainingPayment <= 0) break;

          double dueAmount = due["amount"];
          if (remainingPayment >= dueAmount) {
            remainingPayment -= dueAmount;
            due["amount"] = 0.0; // Fully paid
          } else {
            due["amount"] -= remainingPayment;
            remainingPayment = 0.0;
          }
        }
      }

      // Keep all unpaid dues
      remainingDues[account] = dues.where((d) => d["amount"] > 0.0).toList();
    });

    // Group Data for Display
    Map<String, List<String>> groupedData = {};
    for (var entry in remainingDues.entries) {
      String accountName = entry.key;
      List<String> dueEntries = entry.value
          .map((due) => "${due["date"]} - ${due["amount"].toStringAsFixed(0)}")
          .toList();

      groupedData[accountName] = dueEntries;
    }

    setState(() {
      allData = remainingDues.entries.expand((entry) {
        return entry.value.map((due) => {
              "Name": entry.key,
              "Date": due["date"].toString(),
              "Due Amount": (due["amount"] as num).toStringAsFixed(0),
            });
      }).toList();
      filteredData = List.from(allData);
      this.groupedData = groupedData;
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
                    itemCount: groupedData.keys.length,
                    itemBuilder: (context, index) {
                      String accountName = groupedData.keys.elementAt(index);
                      List<String> dues = groupedData[accountName]!;

                      // Extract numerical amounts from the dues list and calculate the total
                      double totalDueAmount = dues.fold(0.0, (sum, due) {
                        final parts = due.split(" - ");
                        if (parts.length > 1) {
                          double amount = double.tryParse(parts[1]) ?? 0.0;
                          return sum + amount;
                        }
                        return sum;
                      });

                      return Card(
                        elevation: 2,
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value:
                                        selectedAccounts.contains(accountName),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedAccounts.add(accountName);
                                        } else {
                                          selectedAccounts.remove(accountName);
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    accountName,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              ...dues.map((due) => Padding(
                                    padding:
                                        const EdgeInsets.only(left: 10, top: 5),
                                    child: Text(
                                      due,
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.red),
                                    ),
                                  )),
                              Divider(), // Separating dues and total
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, top: 5),
                                child: Text(
                                  "Total Due: ${totalDueAmount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
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
}

class SelectedAccountsScreen extends StatelessWidget {
  final List<Map<String, String>> selectedAccounts;

  SelectedAccountsScreen({required this.selectedAccounts});

  @override
  Widget build(BuildContext context) {
    // Group the selected accounts by name
    Map<String, List<Map<String, String>>> groupedSelectedAccounts = {};

    for (var account in selectedAccounts) {
      String name = account["Name"] ?? "---";
      groupedSelectedAccounts.putIfAbsent(name, () => []);
      groupedSelectedAccounts[name]!.add(account);
    }

    // Calculate the total due amount across all selected accounts
    double grandTotalDue = selectedAccounts.fold(0.0, (sum, account) {
      double amount = double.tryParse(account["Due Amount"] ?? "0") ?? 0.0;
      return sum + amount;
    });

    return Scaffold(
      appBar: AppBar(title: Text("Selected Accounts")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: groupedSelectedAccounts.keys.length,
              itemBuilder: (context, index) {
                String accountName =
                    groupedSelectedAccounts.keys.elementAt(index);
                List<Map<String, String>> dues =
                    groupedSelectedAccounts[accountName]!;

                // Calculate total due for this account
                double totalDueAmount = dues.fold(0.0, (sum, entry) {
                  double amount =
                      double.tryParse(entry["Due Amount"] ?? "0") ?? 0.0;
                  return sum + amount;
                });

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ...dues.map((due) => Padding(
                              padding: const EdgeInsets.only(left: 10, top: 5),
                              child: Text(
                                "${due["Date"]} - ${due["Due Amount"]}",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.red),
                              ),
                            )),
                        Divider(),
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 5),
                          child: Text(
                            "Total Due: ${totalDueAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "Grand Total Due: ${grandTotalDue.toStringAsFixed(0)}",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
