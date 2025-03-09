import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

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

      // Keep only unpaid dues with amounts >= 1000
      List<Map<String, dynamic>> filteredDues =
          dues.where((d) => d["amount"] >= 1000).toList();
      if (filteredDues.isNotEmpty) {
        remainingDues[account] = filteredDues;
      }
    });

    // Group Data for Display
    Map<String, List<String>> groupedData = {};
    List<Map<String, String>> allData = [];

    for (var entry in remainingDues.entries) {
      String accountName = entry.key;
      List<String> dueEntries = entry.value
          .map((due) => "${due["date"]} - ${due["amount"].toStringAsFixed(0)}")
          .toList();

      groupedData[accountName] = dueEntries;

      for (var due in entry.value) {
        allData.add({
          "Name": accountName,
          "Date": due["date"].toString(),
          "Due Amount": (due["amount"] as num).toStringAsFixed(0),
        });
      }
    }

    setState(() {
      this.allData = allData;
      this.groupedData = groupedData;
      isLoading = false;
    });
  }

  void _filterData() {
    String query = searchController.text.toLowerCase();
    setState(() {
      groupedData = {};

      for (var entry in allData) {
        String name = entry["Name"]!;
        double dueAmount = double.tryParse(entry["Due Amount"]!) ?? 0.0;

        // Show only accounts with dues >= 1000 and matching the search query
        if (dueAmount >= 1000 && name.toLowerCase().contains(query)) {
          groupedData.putIfAbsent(name, () => []);
          groupedData[name]!.add("${entry["Date"]} - ${entry["Due Amount"]}");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              const SnackBar(
                  content: Text("Please select at least one account")),
            );
          }
        },
        child: const Icon(Icons.check),
      ),
      appBar: AppBar(title: const Text("Due Payments")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Search Account",
                      prefixIcon: const Icon(Icons.search),
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

                      double totalDueAmount = dues.fold(0.0, (sum, due) {
                        final parts = due.split(" - ");
                        if (parts.length > 1) {
                          double amount = double.tryParse(parts[1]) ?? 0.0;
                          return sum + amount;
                        }
                        return sum;
                      });

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.black.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    accountName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
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
                                ],
                              ),
                              ...dues.map((due) => Padding(
                                    padding:
                                        const EdgeInsets.only(left: 10, top: 5),
                                    child: Text(due,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.red)),
                                  )),
                              const Divider(),
                              Text(
                                "Total Due: ${totalDueAmount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
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

  Future<void> generateAndSharePDF() async {
    final pdf = pw.Document();

    // Group accounts by name
    Map<String, List<Map<String, String>>> groupedSelectedAccounts = {};
    for (var account in selectedAccounts) {
      String name = account["Name"] ?? "---";
      groupedSelectedAccounts.putIfAbsent(name, () => []);
      groupedSelectedAccounts[name]!.add(account);
    }

    // Calculate grand total
    double grandTotalDue = selectedAccounts.fold(0.0, (sum, account) {
      double amount = double.tryParse(account["Due Amount"] ?? "0") ?? 0.0;
      return sum + amount;
    });

    // Multi-page PDF generation
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Text("Selected Accounts",
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            // Generate account dues list
            ...groupedSelectedAccounts.keys.map((accountName) {
              List<Map<String, String>> dues =
                  groupedSelectedAccounts[accountName]!;

              double totalDueAmount = dues.fold(0.0, (sum, entry) {
                double amount =
                    double.tryParse(entry["Due Amount"] ?? "0") ?? 0.0;
                return sum + amount;
              });

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(accountName,
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(15),
                      1: const pw.FixedColumnWidth(85),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Date",
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Due Amount",
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...dues.map(
                        (due) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  (due["Date"] ?? "--").replaceAll("'", ""),
                                  style: const pw.TextStyle(fontSize: 12)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(due["Due Amount"] ?? "0",
                                  style: const pw.TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text("Total Due: ${totalDueAmount.toStringAsFixed(0)}",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),

            pw.Divider(),
            pw.Text("Grand Total Due: ${grandTotalDue.toStringAsFixed(0)}",
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green)),
          ];
        },
      ),
    );

    // Save PDF file
    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Share PDF
    Share.shareXFiles([XFile(file.path)],
        text: "Here is the Selected Accounts Report.");
  }

  @override
  Widget build(BuildContext context) {
    // Group the selected accounts by name
    Map<String, List<Map<String, String>>> groupedSelectedAccounts = {};

    for (var account in selectedAccounts) {
      String name = account["Name"] ?? "---";
      groupedSelectedAccounts.putIfAbsent(name, () => []);
      groupedSelectedAccounts[name]!.add(account);
    }

    // Calculate grand total
    double grandTotalDue = selectedAccounts.fold(0.0, (sum, account) {
      double amount = double.tryParse(account["Due Amount"] ?? "0") ?? 0.0;
      return sum + amount;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: generateAndSharePDF,
        child: const Icon(Icons.picture_as_pdf_rounded),
      ),
      appBar: AppBar(
          title: Text(
        "Grand Total Due: ${grandTotalDue.toStringAsFixed(0)}",
        style: const TextStyle(fontSize: 18),
      )),
      body: ListView.builder(
        itemCount: groupedSelectedAccounts.keys.length,
        itemBuilder: (context, index) {
          String accountName = groupedSelectedAccounts.keys.elementAt(index);
          List<Map<String, String>> dues =
              groupedSelectedAccounts[accountName]!;

          // Calculate total due for this account
          double totalDueAmount = dues.fold(0.0, (sum, entry) {
            double amount = double.tryParse(entry["Due Amount"] ?? "0") ?? 0.0;
            return sum + amount;
          });

          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // if you need this
              side: BorderSide(
                color: Colors.black.withOpacity(0.2),
                width: 1,
              ),
            ),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...dues.map((due) => Padding(
                        padding: const EdgeInsets.only(left: 10, top: 5),
                        child: Text(
                          "${due["Date"].toString().replaceAll("'", "")} - ${due["Due Amount"]}",
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      )),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 5),
                    child: Text(
                      "Total Due: ${totalDueAmount.toStringAsFixed(0)}",
                      style: const TextStyle(
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
    );
  }
}
