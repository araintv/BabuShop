import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:shop/Components/snackBar.dart';
import 'package:shop/Services/GsheetApi.dart';
import 'package:shop/Widgets/Button.dart';

class Todaycb extends StatefulWidget {
  const Todaycb({super.key});

  @override
  State<Todaycb> createState() => _HomePageState();
}

class _HomePageState extends State<Todaycb> {
  TextEditingController dateController = TextEditingController();
  TextEditingController jamaController = TextEditingController();
  TextEditingController naamController = TextEditingController();
  // TextEditingController qntyController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController tafseelController = TextEditingController();

  List<Map<String, String>> savedData = [];

  List<String> jamaSuggestions = [];
  List<String> naamSuggestions = [];
  List<String> typeSuggestions = [];

  Future<void> _fetchAutocompleteData() async {
    List<List<String>> sheetData =
        await UserSheetsApi.fetchAllRows(); // Fetch all rows

    // Extract unique values for Jama and Naam
    Set<String> jamaSet = {};
    Set<String> naamSet = {};

    for (var row in sheetData) {
      if (row.isNotEmpty) {
        if (row.length > 1) jamaSet.add(row[1]); // Jama column
        if (row.length > 3) naamSet.add(row[3]); // Naam column
      }
    }

    setState(() {
      jamaSuggestions = jamaSet.toList();
      naamSuggestions = naamSet.toList();
    });
  }

  Future<void> _fetchTypeAutocompleteData() async {
    List<List<String>> sheetData = await UserSheetsApi.fetchAllRows();
    Set<String> typeSet = {};

    for (var row in sheetData) {
      if (row.isNotEmpty && row.length > 2) {
        typeSet.add(row[2]);
      }
    }

    setState(() {
      typeSuggestions = typeSet
          .toSet() // Remove duplicates
          .where((item) => item.isNotEmpty && item != "Type" && item != "")
          .toList();
    });
  }

  bool uploadingProgress = false;

  final List<String> items = [
    'Online',
    'Good Bill',
    'Wheat',
    'Others',
    'Sugar',
  ];
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchAutocompleteData();
    _fetchTypeAutocompleteData();
  }

  // Load saved data from local storage
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString('savedData');
    if (jsonData != null) {
      setState(() {
        savedData = List<Map<String, String>>.from(
          json.decode(jsonData).map((item) => Map<String, String>.from(item)),
        );
      });
    }
  }

  // Save data to local storage
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = json.encode(savedData);
    await prefs.setString('savedData', jsonData);
  }

  // Add new entry
  void saveData() async {
    if (dateController.text.isEmpty ||
        jamaController.text.isEmpty ||
        naamController.text.isEmpty ||
        // qntyController.text.isEmpty ||
        typeController.text.isEmpty ||
        amountController.text.isEmpty) {
      // Show a custom SnackBar if any of the fields are empty
      CustomSnackBar(
        context,
        const Text('All fields must be filled before saving!'),
      );
    } else if (!isValidDateFormat(dateController.text)) {
      CustomSnackBar(context, const Text('Date is not correctly formatted'));
    } else if (jamaController.text == naamController.text) {
      CustomSnackBar(
        context,
        const Text(
          'The Naam \'Credit\' and Jaama \'Debit\' Should be Different',
        ),
      ); //
    } else {
      setState(() {
        savedData.add({
          'Date': dateController.text.replaceAll("'", ""),
          'Jama': jamaController.text,
          'Type': typeController.text,
          'Naam': naamController.text,
          // 'Quantity': qntyController.text,
          'Amount': amountController.text,
          'Details': tafseelController.text.isNotEmpty
              ? tafseelController.text
              : 'Without Details',
        });
        _saveData(); // Save after adding new entry
        jamaController.clear();
        naamController.clear();
        // qntyController.clear();
        amountController.clear();
        tafseelController.clear();
      });
    }
  }

  void editEntry(int index) {
    jamaController.text = savedData[index]['Jama'] ?? '';
    naamController.text = savedData[index]['Naam'] ?? '';
    // qntyController.text = savedData[index]['Quantity'] ?? '';
    amountController.text = savedData[index]['Amount'] ?? '';
    tafseelController.text = savedData[index]['Details'] ?? '';

    TextEditingController dateController = TextEditingController(
      text: savedData[index]['Date'] ?? '',
    );

    // Ensure selectedValue exists in the items list, otherwise set to null
    String? currentType = savedData[index]['Type'];
    selectedValue = items.contains(currentType) ? currentType : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Entry"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              TextField(
                controller: jamaController,
                decoration: const InputDecoration(labelText: 'Jama'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedValue,
                decoration: const InputDecoration(labelText: 'Type'),
                items: items
                    .map(
                      (String item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedValue = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: naamController,
                decoration: const InputDecoration(labelText: 'Naam'),
              ),
              // TextField(
              //   controller: qntyController,
              //   decoration: const InputDecoration(labelText: 'Quantity'),
              // ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tafseelController,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  savedData[index] = {
                    'Date': dateController.text,
                    'Jama': jamaController.text,
                    'Type': selectedValue ?? '',
                    'Naam': naamController.text,
                    // 'Quantity': qntyController.text,
                    'Amount': amountController.text,
                    'Details': tafseelController.text,
                  };
                  _saveData();
                });

                jamaController.clear();
                naamController.clear();
                // qntyController.clear();
                amountController.clear();
                tafseelController.clear();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
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
          _saveData(); // Save after deleting entry
        });
        Navigator.pop(context);
      },
      onCancelBtnTap: () => Navigator.pop(context),
    );
  }

  bool isValidDateFormat(String date) {
    RegExp regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    return regex.hasMatch(date);
  }

  @override
  void dispose() {
    dateController.dispose();
    jamaController.dispose();
    typeController.dispose();
    naamController.dispose();
    amountController.dispose();
    tafseelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> combinedSuggestions = (naamSuggestions + jamaSuggestions)
        .toSet() // Remove duplicates
        .where(
          (item) =>
              item.isNotEmpty &&
              item != "Naam" &&
              item != "Jama" &&
              item != "Type" &&
              item != "",
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Cash Book',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'DD-MM-YYYY',
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return typeSuggestions.where(
                            (option) => option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (String selection) {
                          typeController.text = selection;
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textFieldController,
                              focusNode,
                              onEditingComplete,
                            ) {
                              textFieldController.text = typeController.text;

                              textFieldController.addListener(() {
                                if (textFieldController.text !=
                                    typeController.text) {
                                  typeController.text =
                                      textFieldController.text;
                                }
                              });

                              return TextField(
                                controller:
                                    textFieldController, // Use textFieldController here
                                focusNode: focusNode,
                                onEditingComplete: onEditingComplete,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Type of Entry',
                                ),
                              );
                            },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return combinedSuggestions.where(
                            (option) => option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (String selection) {
                          jamaController.text = selection;
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textFieldController,
                              focusNode,
                              onEditingComplete,
                            ) {
                              textFieldController.text = jamaController.text;
                              textFieldController.addListener(() {
                                jamaController.text = textFieldController.text;
                              });

                              return TextField(
                                controller: textFieldController,
                                focusNode: focusNode,
                                onEditingComplete: onEditingComplete,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Jama \'Credit\'',
                                ),
                              );
                            },
                      ),
                    ),

                    const SizedBox(width: 5),
                    Expanded(
                      flex: 3,
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return combinedSuggestions.where(
                            (option) => option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (String selection) {
                          naamController.text = selection;
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textFieldController,
                              focusNode,
                              onEditingComplete,
                            ) {
                              textFieldController.text = naamController.text;
                              textFieldController.addListener(() {
                                naamController.text = textFieldController.text;
                              });

                              return TextField(
                                controller: textFieldController,
                                focusNode: focusNode,
                                onEditingComplete: onEditingComplete,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Naam \'Debit\'',
                                ),
                              );
                            },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly, // Allow only numbers
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            String text = newValue.text.replaceAll(
                              ',',
                              '',
                            ); // Remove old commas
                            if (text.isEmpty) return newValue;

                            final formatter = NumberFormat.decimalPattern(
                              'en_IN',
                            ); // Indian format
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
                          hintText: 'Rakam \'Amount\'',
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.text,
                        controller: tafseelController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Tafseel \'Details\'',
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Button_Widget(
                        context,
                        'Clear List',
                        Colors.red,
                        () {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.confirm,
                            text: 'Do you want to clear all entries?',
                            confirmBtnText: 'Yes',
                            cancelBtnText: 'No',
                            confirmBtnColor: Colors.green,
                            onConfirmBtnTap: () {
                              setState(() {
                                savedData.clear();
                                _saveData(); // Save after clearing all
                              });
                              Navigator.pop(context);
                            },
                            onCancelBtnTap: () => Navigator.pop(context),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Button_Widget(
                        context,
                        'Clear All Inputs',
                        Colors.red,
                        () {
                          setState(() {
                            jamaController.clear();
                            naamController.clear();
                            // qntyController.clear();
                            amountController.clear();
                            tafseelController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: uploadingProgress
                          ? const Center(child: CircularProgressIndicator())
                          : Button_Widget(
                              context,
                              'Upload Now!',
                              Colors.blue[900]!,
                              () async {
                                if (savedData.isEmpty) {
                                  CustomSnackBar(
                                    context,
                                    const Text('No data to upload!'),
                                  );
                                  return;
                                }

                                QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.loading,
                                  title: 'Uploading...',
                                  text: 'Please wait while data is uploaded',
                                  barrierDismissible: false,
                                );

                                setState(() {
                                  uploadingProgress = true;
                                });

                                for (var entry in savedData) {
                                  await UserSheetsApi.insertRow([
                                    entry['Date'] ?? '',
                                    entry['Jama'] ?? '',
                                    entry['Type'] ?? '',
                                    entry['Naam'] ?? '',
                                    entry['Quantity'] ?? '',
                                    (entry['Amount'] ?? '')
                                        .toString()
                                        .replaceAll(',', ''),
                                    entry['Details'] ?? '',
                                  ]);
                                }

                                setState(() {
                                  uploadingProgress = false;
                                  savedData.clear();
                                });

                                Navigator.pop(context);

                                CustomSnackBar(
                                  context,
                                  const Text('Data uploaded successfully!'),
                                );
                              },
                            ),
                    ),
                    const SizedBox(width: 5),

                    Expanded(
                      child: Button_Widget(
                        context,
                        'Save Now!',
                        Colors.blue,
                        saveData,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(),
            savedData.isNotEmpty
                ? Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double tableWidth = constraints.maxWidth;

                        // Adjust column widths according to your layout
                        double dateCol = tableWidth * 0.15;
                        double jamaCol = tableWidth * 0.15;
                        double typeCol = tableWidth * 0.15;
                        double naamCol = tableWidth * 0.15;
                        double amountCol = tableWidth * 0.15;
                        double iconCol =
                            tableWidth * 0.075; // ✅ make visible and tappable

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: DataTable(
                              columnSpacing: 4,
                              horizontalMargin: 4,
                              headingRowHeight: 25,
                              dataRowMinHeight: 20,
                              dataRowMaxHeight: 25,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Date',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Jama',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Type',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Naam',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Amount',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Delete',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                              rows: savedData.reversed
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    int reversedIndex =
                                        savedData.length - 1 - entry.key;
                                    Map<String, String> data = entry.value;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: dateCol,
                                            child: Text(
                                              data['Date'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: jamaCol,
                                            child: Text(
                                              data['Jama'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: typeCol,
                                            child: Text(
                                              data['Type'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: naamCol,
                                            child: Text(
                                              data['Naam'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: amountCol,
                                            child: Text(
                                              data['Amount'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // ✅ Edit button
                                        DataCell(
                                          SizedBox(
                                            width: iconCol,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () =>
                                                    editEntry(reversedIndex),
                                                child: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // ✅ Delete button
                                        DataCell(
                                          SizedBox(
                                            width: iconCol,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () =>
                                                    deleteEntry(reversedIndex),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('No Entry was Recorded Today'),
                  ),
          ],
        ),
      ),
    );
  }
}
