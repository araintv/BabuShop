import 'package:baboo_and_co/Components/snackBar.dart';
import 'package:baboo_and_co/Details.dart';
import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:baboo_and_co/Widgets/Button.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Iniatlize the Google Sheet Here
  await UserSheetsApi.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baboo&Co',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const HomePage(),
      home: CustomerKhata(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController dateController = TextEditingController();
  TextEditingController jamaController = TextEditingController();
  TextEditingController qntyController = TextEditingController();
  TextEditingController naamController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  List<Map<String, String>> savedData = [];

  List<String> jamaSuggestions = [];
  List<String> naamSuggestions = [];

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

  bool uploadingProgress = false;

  final List<String> items = [
    'Online',
    'Good Bill',
    'Cheeni Brokery',
  ];
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchAutocompleteData();
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
    print("Date: ${dateController.text}");
    print("Jama: ${jamaController.text}");
    print("Naam: ${naamController.text}");
    print("Quantity: ${qntyController.text}");
    print("Type: ${selectedValue}");
    print("Amount: ${amountController.text}");

    if (dateController.text.isEmpty ||
        jamaController.text.isEmpty ||
        naamController.text.isEmpty ||
        qntyController.text.isEmpty ||
        selectedValue == null ||
        amountController.text.isEmpty) {
      // Show a custom SnackBar if any of the fields are empty
      CustomSnackBar(
          context, const Text('All fields must be filled before saving!'));
    } else if (!isValidDateFormat(dateController.text)) {
      CustomSnackBar(context, const Text('Date is not correctly formatted'));
    } else if (jamaController.text == naamController.text) {
      CustomSnackBar(
          context,
          const Text(
              'The Naam \'Credit\' and Jaama \'Debit\' Should be Different')); //
    } else {
      setState(() {
        savedData.add({
          'Date': dateController.text,
          'Jama': jamaController.text,
          'Type': selectedValue!,
          'Naam': naamController.text,
          'Quantity': qntyController.text,
          'Amount': amountController.text,
        });
        _saveData(); // Save after adding new entry
        jamaController.clear();
        naamController.clear();
        qntyController.clear();
        amountController.clear();
      });
    }
  }

  void editEntry(int index) {
    jamaController.text = savedData[index]['Jama'] ?? '';
    naamController.text = savedData[index]['Naam'] ?? '';
    qntyController.text = savedData[index]['Quantity'] ?? '';
    amountController.text = savedData[index]['Amount'] ?? '';

    TextEditingController dateController =
        TextEditingController(text: savedData[index]['Date'] ?? '');

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
                    .map((String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
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
              TextField(
                controller: qntyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
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
                    'Quantity': qntyController.text,
                    'Amount': amountController.text,
                  };
                  _saveData(); // Save after editing entry
                });
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
  Widget build(BuildContext context) {
    List<String> combinedSuggestions =
        naamSuggestions + jamaSuggestions; // Merge lists

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baboo & Company',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Date \'DD-MM-YYYY\''),
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return combinedSuggestions.where((option) => option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      jamaController.text = selection;
                    },
                    fieldViewBuilder: (context, textFieldController, focusNode,
                        onEditingComplete) {
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
                        style: const TextStyle(fontSize: 25),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(9.5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: Text(
                          'Online/Bill/Brokery',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        items: items
                            .map((String item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                        value: selectedValue,
                        onChanged: (String? value) {
                          setState(() {
                            selectedValue = value;
                          });
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 40,
                          width: 140,
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return combinedSuggestions.where((option) => option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      naamController.text = selection;
                    },
                    fieldViewBuilder: (context, textFieldController, focusNode,
                        onEditingComplete) {
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
                        style: const TextStyle(fontSize: 25),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: qntyController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Quantity'),
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const SizedBox(
                    width: 40,
                    child: Center(
                        child: Text('=',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold)))),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Rakam \'Amount\''),
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 300,
                  height: 50,
                  child: Button_Widget(context, 'Clear List', Colors.red, () {
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
                  }),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: Button_Widget(context, 'Clear All Inputs', Colors.red,
                      () {
                    qntyController.clear();
                    jamaController.clear();
                    naamController.clear();
                    amountController.clear();
                  }),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: Button_Widget(
                      context, 'Save Now!', Colors.blue, saveData),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: uploadingProgress
                      ? const Center(child: CircularProgressIndicator())
                      : Button_Widget(context, 'Upload Now!', Colors.blue[900]!,
                          () async {
                          if (savedData.isEmpty) {
                            CustomSnackBar(
                                context, const Text('No data to upload!'));
                            return;
                          }

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
                              entry['Amount'] ?? ''
                            ]);
                          }

                          setState(() {
                            uploadingProgress = false;
                            savedData.clear();
                          });

                          CustomSnackBar(context,
                              const Text('Data uploaded successfully!'));
                        }),
                ),
              ],
            ),
          ),
          savedData.isNotEmpty
              ? Expanded(
                  child: ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(
                              label:
                                  Text('No.', style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label:
                                  Text('Date', style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label:
                                  Text('Jama', style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label:
                                  Text('Type', style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label:
                                  Text('Naam', style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label: Text('Quantity',
                                  style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label: Text('Amount',
                                  style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label:
                                  Text('Edit', style: TextStyle(fontSize: 25))),
                          DataColumn(
                              label: Text('Delete',
                                  style: TextStyle(fontSize: 25))),
                        ],
                        rows: savedData.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, String> data = entry.value;

                          return DataRow(cells: [
                            DataCell(Text((index + 1).toString())),
                            DataCell(Text(data['Date'] ?? '')),
                            DataCell(Text(data['Jama'] ?? '')),
                            DataCell(Text(data['Type'] ?? '')),
                            DataCell(Text(data['Naam'] ?? '')),
                            DataCell(Text(data['Quantity'] ?? '')),
                            DataCell(Text(data['Amount'] ?? '')),
                            DataCell(InkWell(
                                onTap: () => editEntry(index),
                                child: const Icon(Icons.edit,
                                    color: Colors.blue))),
                            DataCell(InkWell(
                                onTap: () => deleteEntry(index),
                                child: const Icon(Icons.delete,
                                    color: Colors.red))),
                          ]);
                        }).toList(),
                      ),
                    ],
                  ),
                )
              : const Text('No Entry was Recorded Today'),
        ],
      ),
    );
  }
}
