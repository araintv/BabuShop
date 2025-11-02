import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shop/Services/GsheetApi.dart';
import 'package:shop/Services/Methods.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shop/Components/snackBar.dart';
import 'package:shop/Widgets/Button.dart';

class BankOnlines extends StatefulWidget {
  const BankOnlines({super.key});

  @override
  State<BankOnlines> createState() => _BankOnlinesState();
}

class _BankOnlinesState extends State<BankOnlines> {
  Map<String, List<List<String>>> groupedData = {};
  bool isLoading = true;

  final List<String> bankNames = [
    'ubl',
    'meezan',
    'alhabib',
    'hbl',
    'mcb',
    'islami',
    'faysal',
    'allied',
  ];

  @override
  void initState() {
    super.initState();
    fetchOnlineData();
  }

  Future<void> fetchOnlineData() async {
    setState(() => isLoading = true);

    final allRows = await UserSheetsApi.fetchAllRows();
    if (allRows.isNotEmpty) {
      final rows = allRows.sublist(1); // Skip header

      final filtered = rows
          .where(
            (row) =>
                row.length >= 3 &&
                row[2].toLowerCase().trim() == 'online' &&
                ((row.length > 1 && row[1].trim().isNotEmpty) ||
                    (row.length > 3 && row[3].trim().isNotEmpty)),
          )
          .toList();

      // Group by date
      Map<String, List<List<String>>> grouped = {};
      for (var row in filtered) {
        final date = row[0].replaceAll("'", "").trim();
        grouped.putIfAbsent(date, () => []).add(row);
      }

      // Sort dates descending (latest first)
      final sortedKeys = grouped.keys.toList()
        ..sort((a, b) => parseDate(b).compareTo(parseDate(a)));

      Map<String, List<List<String>>> sortedMap = {
        for (var key in sortedKeys) key: grouped[key]!,
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

  bool _isBankName(String name) {
    final lower = name.toLowerCase();
    return bankNames.any((bank) => lower.contains(bank));
  }

  DateTime parseDate(String dateStr) {
    try {
      dateStr = dateStr.replaceAll("'", "").trim();
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0].padLeft(2, '0'));
        final month = int.parse(parts[1].padLeft(2, '0'));
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      return DateTime(2000);
    } catch (_) {
      return DateTime(2000);
    }
  }

  double _parseAmountString(String? s) {
    if (s == null) return 0;
    final cleaned = s.replaceAll("'", "").replaceAll(",", "").trim();
    return double.tryParse(cleaned) ?? 0;
  }

  double _extractAmount(List<String> row) {
    final candidates = <int>[4, 5, 6, 7];
    for (var idx in candidates) {
      if (idx < row.length) {
        final val = row[idx].trim();
        if (val.isEmpty) continue;
        final cleaned = val.replaceAll(RegExp(r'[^\d\.\-]'), '');
        if (cleaned.isEmpty) continue;
        final parsed = double.tryParse(cleaned);
        if (parsed != null) return parsed;
        final looseParsed = _parseAmountString(val);
        if (looseParsed > 0) return looseParsed;
      }
    }
    for (var cell in row) {
      final cleaned = cell.replaceAll(RegExp(r'[^\d\.\-]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Online Records'),
        centerTitle: true,
        actions: [
          InkWell(
            onTap: () {
              Methods().navigateTo(context, const UploadOnlines());
            },
            child: const Icon(
              Icons.file_upload_outlined,
              color: Colors.transparent,
              size: 10,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedData.isEmpty
          ? const Center(child: Text('No Online records found.'))
          : ListView(
              padding: const EdgeInsets.all(10),
              children: groupedData.entries.map((entry) {
                String date = entry.key;
                List<List<String>> rows = entry.value;

                double totalJama = 0;
                double totalNaam = 0;

                for (var r in rows) {
                  double amt = _extractAmount(r);
                  String jama = r.length > 1 ? r[1].trim() : '';
                  if (_isBankName(jama)) {
                    totalNaam += amt; // Bank-side → red total
                  } else {
                    totalJama += amt; // Customer-side → green total
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Date Header

                    // 🟩 Green + 🟥 Red Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (totalNaam > 0)
                          Text(
                            "- Rs. ${totalNaam.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          "+ Rs. ${totalJama.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(thickness: 2),
                    const SizedBox(height: 6),

                    // 🔸 Rows
                    ...rows.map((row) {
                      String jama = row.length > 1 ? row[1].trim() : '';
                      String naam = row.length > 3 ? row[3].trim() : '';
                      double amtValue = _extractAmount(row);

                      bool jamaIsBank = _isBankName(jama);
                      String customerName = jamaIsBank ? naam : jama;
                      String bankRef = jamaIsBank
                          ? "From $jama"
                          : "Bank: $naam";

                      Color nameColor = jamaIsBank
                          ? Colors.redAccent
                          : Colors.green;

                      String amountDisplay = amtValue % 1 == 0
                          ? amtValue.toStringAsFixed(0)
                          : amtValue.toStringAsFixed(2);

                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 5),
                        title: Text(
                          customerName == '------'
                              ? '---  Unknown'
                              : '✔  ${customerName}',
                          style: TextStyle(
                            color: customerName == '------'
                                ? Colors.amber
                                : nameColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "        Rs. $amountDisplay    |    $bankRef",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      );
                    }),

                    const Divider(thickness: 2),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class UploadOnlines extends StatefulWidget {
  const UploadOnlines({super.key});

  @override
  State<UploadOnlines> createState() => _UploadOnlinesState();
}

class _UploadOnlinesState extends State<UploadOnlines> {
  TextEditingController dateController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController detailsController = TextEditingController();

  List<Map<String, String>> savedData = [];
  List<String> nameSuggestions = [];

  String? selectedBank;
  String? selectedMember;

  final List<String> banks = [
    'AlHabib',
    'UBL',
    'Allied',
    'Meezan',
    'HBL',
    'Islami Bank',
    'Faisal Bank',
  ];

  final List<String> members = ['Ali', 'Babu', 'Abu'];

  @override
  void initState() {
    super.initState();
    _fetchAutocompleteData();
    _loadData();
  }

  Future<void> _fetchAutocompleteData() async {
    List<List<String>> sheetData = await UserSheetsApi.fetchAllRows();
    Set<String> nameSet = {};

    for (var row in sheetData) {
      if (row.isNotEmpty) {
        if (row.length > 1) nameSet.add(row[1]); // Jama
        if (row.length > 3) nameSet.add(row[3]); // Naam
      }
    }

    setState(() {
      nameSuggestions = nameSet
          .where((item) => item.isNotEmpty && item != "Naam" && item != "Jama")
          .toList();
    });
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString('uploadOnlineData');
    if (jsonData != null) {
      setState(() {
        savedData = List<Map<String, String>>.from(
          json.decode(jsonData).map((e) => Map<String, String>.from(e)),
        );
      });
    }
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uploadOnlineData', json.encode(savedData));
  }

  void saveEntry() {
    if (dateController.text.isEmpty ||
        nameController.text.isEmpty ||
        amountController.text.isEmpty ||
        selectedBank == null ||
        selectedMember == null) {
      CustomSnackBar(context, const Text('All fields are required!'));
      return;
    }

    if (detailsController.text == '') {
      setState(() {
        detailsController.text = 'Online Jama';
      });
    }

    setState(() {
      savedData.add({
        'Date': dateController.text,
        'Name': nameController.text,
        'Amount': amountController.text,
        'Bank': selectedBank!,
        'Member': selectedMember!,
        'Details': detailsController.text,
      });
    });
    _saveData();

    nameController.clear();
    amountController.clear();
    detailsController.clear();

    CustomSnackBar(context, const Text('Saved successfully!'));
  }

  void editEntry(int index) {
    Map<String, String> entry = savedData[index];
    TextEditingController editDate = TextEditingController(text: entry['Date']);
    TextEditingController editName = TextEditingController(text: entry['Name']);
    TextEditingController editAmount = TextEditingController(
      text: entry['Amount'],
    );
    TextEditingController editDetails = TextEditingController(
      text: entry['Details'],
    );
    String? editBank = entry['Bank'];
    String? editMember = entry['Member'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Entry"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editDate,
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    editDate.text = DateFormat('dd-MM-yyyy').format(pickedDate);
                  }
                },
              ),
              TextField(
                controller: editName,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: editAmount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: editDetails,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
              const SizedBox(height: 10),
              const Text('Select Bank:'),
              Wrap(
                spacing: 8,
                children: banks.map((bank) {
                  return ChoiceChip(
                    label: Text(bank),
                    selected: editBank == bank,
                    onSelected: (_) => setState(() => editBank = bank),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              const Text('Select Member:'),
              Wrap(
                spacing: 8,
                children: members.map((m) {
                  return ChoiceChip(
                    label: Text(m),
                    selected: editMember == m,
                    onSelected: (_) => setState(() => editMember = m),
                  );
                }).toList(),
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
            onPressed: () {
              setState(() {
                savedData[index] = {
                  'Date': editDate.text,
                  'Name': editName.text,
                  'Amount': editAmount.text,
                  'Bank': editBank ?? '',
                  'Member': editMember ?? '',
                  'Details': editDetails.text,
                };
                _saveData();
              });
              Navigator.pop(context);
              CustomSnackBar(
                context,
                const Text('Entry updated successfully!'),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void deleteEntry(int index) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: 'Are you sure you want to delete this entry?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () {
        setState(() {
          savedData.removeAt(index);
          _saveData();
        });
        Navigator.pop(context);
      },
      onCancelBtnTap: () => Navigator.pop(context),
    );
  }

  Future<void> uploadToGoogleSheet() async {
    if (savedData.isEmpty) {
      CustomSnackBar(context, const Text('No data to upload!'));
      return;
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Uploading...',
      text: 'Please wait while data is uploaded',
      barrierDismissible: false,
    );

    try {
      for (var entry in savedData) {
        // Convert map to list in correct order
        final row = [
          "'${entry['Date']}'", // keep as text in sheet
          entry['Name'] ?? '', // Jama name
          'Online', // fixed type
          '${entry['Bank']} ${entry['Member']}', // combined field
          '',
          entry['Amount'] ?? '',
          entry['Details'] ?? '',
        ];

        await UserSheetsApi.insertRow(row);
      }

      Navigator.pop(context); // Close loading alert

      CustomSnackBar(
        context,
        const Text('✅ All entries uploaded successfully!'),
      );
    } catch (e) {
      Navigator.pop(context); // Ensure dialog closes even on error
      CustomSnackBar(context, Text('❌ Upload failed: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Onlines',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => uploadToGoogleSheet(),
              child: Icon(Icons.file_upload_outlined, size: 30),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Input Fields
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select Date',
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            dateController.text = DateFormat(
                              'dd-MM-yyyy',
                            ).format(pickedDate);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue value) {
                        if (value.text.isEmpty)
                          return const Iterable<String>.empty();
                        return nameSuggestions.where(
                          (option) => option.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (val) => nameController.text = val,
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            controller.text = nameController.text;
                            controller.addListener(() {
                              nameController.text = controller.text;
                            });
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onEditingComplete: onEditingComplete,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Name (Jama/Naam)',
                              ),
                            );
                          },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          String text = newValue.text.replaceAll(',', '');
                          if (text.isEmpty) return newValue;
                          final formatter = NumberFormat.decimalPattern(
                            'en_IN',
                          );
                          String formattedText = formatter.format(
                            int.parse(text),
                          );
                          return TextEditingValue(
                            text: formattedText,
                            selection: TextSelection.collapsed(
                              offset: formattedText.length,
                            ),
                          );
                        }),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Amount',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Details field
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Details',
                ),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 10,
                children: banks.map((bank) {
                  return ChoiceChip(
                    label: Text(bank),
                    selected: selectedBank == bank,
                    onSelected: (_) => setState(() => selectedBank = bank),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Members
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Member:',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    children: members.map((m) {
                      return ChoiceChip(
                        label: Text(m),
                        selected: selectedMember == m,
                        onSelected: (_) => setState(() => selectedMember = m),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Button_Widget(
                      context,
                      'Clear List',
                      Colors.green,
                      () {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.confirm,
                          onConfirmBtnTap: () {
                            setState(() {
                              savedData.clear();
                            });
                            Navigator.pop(context);
                          },
                          title: 'Clear List',
                          text: 'All the saved list entries should be deleted.',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Button_Widget(
                      context,
                      'Save Entry',
                      Colors.blue,
                      saveEntry,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // List of saved data
              const Divider(),
              savedData.isEmpty
                  ? const Center(child: Text('No entries yet'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: savedData.length,
                      itemBuilder: (context, index) {
                        final entry = savedData[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                              '${entry['Date']}\n${entry['Name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Amount: ${entry['Amount']}\nBank: ${entry['Bank']} ${entry['Member']}\nDetails: ${entry['Details']}',
                            ),
                            trailing: Wrap(
                              spacing: 10,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => editEntry(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteEntry(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
