// import 'package:baboo_and_co/Components/snackBar.dart';
// import 'package:baboo_and_co/Services/GsheetApi.dart';
// import 'package:baboo_and_co/Widgets/Button.dart';
// import 'package:flutter/material.dart';
// import 'package:quickalert/models/quickalert_type.dart';
// import 'package:quickalert/widgets/quickalert_dialog.dart';

// class OnlineScreen extends StatefulWidget {
//   const OnlineScreen({super.key});

//   @override
//   State<OnlineScreen> createState() => _OnlineScreenState();
// }

// class _OnlineScreenState extends State<OnlineScreen> {
//   TextEditingController dateController = TextEditingController();
//   TextEditingController jamaController = TextEditingController();
//   TextEditingController naamController = TextEditingController();
//   TextEditingController amountController = TextEditingController();

//   bool uploadingProgress = false;

//   List<String> jamaSuggestions = [];
//   List<String> naamSuggestions = [];
//   List<String> typeSuggestions = [];

//   Future<void> _fetchAutocompleteData() async {
//     List<List<String>> sheetData =
//         await UserSheetsApi.fetchAllRows(); // Fetch all rows

//     // Extract unique values for Jama and Naam
//     Set<String> jamaSet = {};
//     Set<String> naamSet = {};

//     for (var row in sheetData) {
//       if (row.isNotEmpty) {
//         if (row.length > 1) jamaSet.add(row[1]); // Jama column
//         if (row.length > 3) naamSet.add(row[3]); // Naam column
//       }
//     }

//     setState(() {
//       jamaSuggestions = jamaSet.toList();
//       naamSuggestions = naamSet.toList();
//     });
//   }

//   @override
//   void initState() {
//     _fetchAutocompleteData();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<String> combinedSuggestions = naamSuggestions + jamaSuggestions;

//     return Scaffold(
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: dateController,
//                     decoration: const InputDecoration(
//                         border: OutlineInputBorder(),
//                         hintText: 'Date \'DD-MM-YYYY\''),
//                     style: const TextStyle(fontSize: 20),
//                   ),
//                 ),
//                 const SizedBox(width: 5),
//                 Expanded(
//                   child: Autocomplete<String>(
//                     optionsBuilder: (TextEditingValue textEditingValue) {
//                       if (textEditingValue.text.isEmpty) {
//                         return const Iterable<String>.empty();
//                       }
//                       return combinedSuggestions.where((option) => option
//                           .toLowerCase()
//                           .contains(textEditingValue.text.toLowerCase()));
//                     },
//                     onSelected: (String selection) {
//                       jamaController.text = selection;
//                     },
//                     fieldViewBuilder: (context, textFieldController, focusNode,
//                         onEditingComplete) {
//                       textFieldController.text = jamaController.text;
//                       textFieldController.addListener(() {
//                         jamaController.text = textFieldController.text;
//                       });

//                       return TextField(
//                         controller: textFieldController,
//                         focusNode: focusNode,
//                         onEditingComplete: onEditingComplete,
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                           hintText: 'Jama \'Credit\'',
//                         ),
//                         style: const TextStyle(fontSize: 20),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 5),
//                 Expanded(
//                   child: Autocomplete<String>(
//                     optionsBuilder: (TextEditingValue textEditingValue) {
//                       if (textEditingValue.text.isEmpty) {
//                         return const Iterable<String>.empty();
//                       }
//                       return combinedSuggestions.where((option) => option
//                           .toLowerCase()
//                           .contains(textEditingValue.text.toLowerCase()));
//                     },
//                     onSelected: (String selection) {
//                       naamController.text = selection;
//                     },
//                     fieldViewBuilder: (context, textFieldController, focusNode,
//                         onEditingComplete) {
//                       textFieldController.text = naamController.text;
//                       textFieldController.addListener(() {
//                         naamController.text = textFieldController.text;
//                       });

//                       return TextField(
//                         controller: textFieldController,
//                         focusNode: focusNode,
//                         onEditingComplete: onEditingComplete,
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                           hintText: 'Naam \'Debit\'',
//                         ),
//                         style: const TextStyle(fontSize: 20),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(
//                     width: 25,
//                     child: Center(
//                         child: Text('=',
//                             style: TextStyle(
//                                 fontSize: 30, fontWeight: FontWeight.bold)))),
//                 Expanded(
//                   child: TextField(
//                     controller: amountController,
//                     decoration: const InputDecoration(
//                         border: OutlineInputBorder(),
//                         hintText: 'Rakam \'Amount\''),
//                     style: const TextStyle(fontSize: 20),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 SizedBox(
//                   width: 300,
//                   height: 50,
//                   child: Button_Widget(context, 'Clear List', Colors.red, () {
//                     QuickAlert.show(
//                       context: context,
//                       type: QuickAlertType.confirm,
//                       text: 'Do you want to clear all entries?',
//                       confirmBtnText: 'Yes',
//                       cancelBtnText: 'No',
//                       confirmBtnColor: Colors.green,
//                       onConfirmBtnTap: () {
//                         setState(() {});
//                         Navigator.pop(context);
//                       },
//                       onCancelBtnTap: () => Navigator.pop(context),
//                     );
//                   }),
//                 ),
//                 const SizedBox(width: 20),
//                 SizedBox(
//                   width: 300,
//                   height: 50,
//                   child: Button_Widget(context, 'Clear All Inputs', Colors.red,
//                       () {
//                     setState(() {
//                       jamaController.clear();
//                       naamController.clear();
//                       amountController.clear();
//                     });
//                   }),
//                 ),
//                 const SizedBox(width: 20),
//                 SizedBox(
//                   width: 300,
//                   height: 50,
//                   child:
//                       Button_Widget(context, 'Save Now!', Colors.blue, () {}),
//                 ),
//                 const SizedBox(width: 20),
//                 SizedBox(
//                   width: 300,
//                   height: 50,
//                   child: uploadingProgress
//                       ? const Center(child: CircularProgressIndicator())
//                       : Button_Widget(context, 'Upload Now!', Colors.blue[900]!,
//                           () async {
//                           if (savedData.isEmpty) {
//                             CustomSnackBar(
//                                 context, const Text('No data to upload!'));
//                             return;
//                           }

//                           setState(() {
//                             uploadingProgress = true;
//                           });

//                           for (var entry in savedData) {
//                             await UserSheetsApi.insertRow([
//                               entry['Date'] ?? '',
//                               entry['Jama'] ?? '',
//                               entry['Type'] ?? '',
//                               entry['Naam'] ?? '',
//                               entry['Quantity'] ?? '',
//                               entry['Amount'] ?? '',
//                               entry['Details'] ?? ''
//                             ]);
//                           }

//                           setState(() {
//                             uploadingProgress = false;
//                             savedData.clear();
//                           });

//                           CustomSnackBar(context,
//                               const Text('Data uploaded successfully!'));
//                         }),
//                 ),
//               ],
//             ),
//           ),
//           savedData.isNotEmpty
//               ? Expanded(
//                   child: ListView(
//                     children: [
//                       DataTable(
//                         columns: const [
//                           DataColumn(
//                               label:
//                                   Text('No.', style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label:
//                                   Text('Date', style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label:
//                                   Text('Jama', style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label:
//                                   Text('Type', style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label:
//                                   Text('Naam', style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label: Text('Quantity',
//                                   style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label: Text('Amount',
//                                   style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label: Text('Details',
//                                   style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label:
//                                   Text('Edit', style: TextStyle(fontSize: 25))),
//                           DataColumn(
//                               label: Text('Delete',
//                                   style: TextStyle(fontSize: 25))),
//                         ],
//                         rows: savedData.reversed
//                             .toList()
//                             .asMap()
//                             .entries
//                             .map((entry) {
//                           int reversedIndex =
//                               savedData.length - 1 - entry.key; // Reverse index
//                           Map<String, String> data = entry.value;

//                           return DataRow(cells: [
//                             DataCell(Text((reversedIndex + 1)
//                                 .toString())), // Display correct index
//                             DataCell(Text(data['Date'] ?? '')),
//                             DataCell(Text(data['Jama'] ?? '')),
//                             DataCell(Text(data['Type'] ?? '')),
//                             DataCell(Text(data['Naam'] ?? '')),
//                             DataCell(Text(data['Quantity'] ?? '')),
//                             DataCell(Text(data['Amount'] ?? '')),
//                             DataCell(Text(data['Details'] ?? '')),
//                             DataCell(InkWell(
//                                 onTap: () => editEntry(
//                                     reversedIndex), // Pass correct index
//                                 child: const Icon(Icons.edit,
//                                     color: Colors.blue))),
//                             DataCell(InkWell(
//                                 onTap: () => deleteEntry(
//                                     reversedIndex), // Pass correct index
//                                 child: const Icon(Icons.delete,
//                                     color: Colors.red))),
//                           ]);
//                         }).toList(),
//                       ),
//                     ],
//                   ),
//                 )
//               : const Text(
//                   'No Entry was Recorded Today',
//                   style: TextStyle(fontSize: 20),
//                 ),
//         ],
//       ),
//     );
//   }
// }
