import 'package:baboo_and_co/Components/snackBar.dart';
import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:baboo_and_co/Widgets/Button.dart';
import 'package:flutter/material.dart';

class CustomerKhata extends StatefulWidget {
  const CustomerKhata({super.key});

  @override
  State<CustomerKhata> createState() => _CustomerKhataState();
}

class _CustomerKhataState extends State<CustomerKhata> {
  List<List<String>> filteredData = [];
  List<List<String>> allData = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  bool editAccess = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final allRows = await UserSheetsApi.fetchAllRows();

    setState(() {
      if (allRows.isNotEmpty) {
        allData = allRows.sublist(1); // Removes the first row (header)
      } else {
        allData = [];
      }
      filterData(searchController.text);
      isLoading = false;
    });
  }

  void filterData(String query) {
    setState(() {
      filteredData = allData.where((row) {
        if (row.length >= 4) {
          return row[1].toLowerCase().contains(query.toLowerCase()) ||
              row[3].toLowerCase().contains(query.toLowerCase());
        }
        return false;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily CashBook',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500)),
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
                      const SizedBox(width: 10),
                      Button_Widget(
                          context, 'Refresh', Colors.green, fetchData),
                      const SizedBox(width: 10),
                      Button_Widget(
                          context,
                          editAccess == false ? 'Edit' : 'Done',
                          editAccess ? Colors.red : Colors.blue, () {
                        setState(() {
                          if (editAccess == true) {
                            editAccess = false;
                          } else {
                            editAccess = true;
                          }
                          CustomSnackBar(context, Text('$editAccess'));
                        });
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredData.isEmpty
                      ? const Center(child: Text('No matching entries found'))
                      : ListView(
                          children: [
                            DataTable(
                              columns: [
                                const DataColumn(
                                    label: Text('No.',
                                        style: TextStyle(fontSize: 18))),
                                const DataColumn(
                                    label: Text('Date',
                                        style: TextStyle(fontSize: 18))),
                                const DataColumn(
                                    label: Text('Jama',
                                        style: TextStyle(fontSize: 18))),
                                const DataColumn(
                                    label: Text('Type',
                                        style: TextStyle(fontSize: 18))),
                                const DataColumn(
                                    label: Text('Naam',
                                        style: TextStyle(fontSize: 18))),
                                const DataColumn(
                                    label: Text('Quantity',
                                        style: TextStyle(fontSize: 18))),
                                const DataColumn(
                                    label: Text('Amount',
                                        style: TextStyle(fontSize: 18))),
                                if (editAccess)
                                  const DataColumn(
                                      label: Text('Edit',
                                          style: TextStyle(fontSize: 18))),
                                if (editAccess)
                                  const DataColumn(
                                      label: Text('Delete',
                                          style: TextStyle(fontSize: 18))),
                              ],
                              rows: filteredData.map((row) {
                                int index = allData.indexOf(row);
                                return DataRow(cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(Text(row[0])),
                                  DataCell(Text(row[1])),
                                  DataCell(Text(row[2])),
                                  DataCell(Text(row[3])),
                                  DataCell(Text(row[4])),
                                  DataCell(Text(row[5])),
                                  if (editAccess)
                                    DataCell(InkWell(
                                        onTap: () => editEntry(index),
                                        child: const Icon(Icons.edit,
                                            color: Colors.blue))),
                                  if (editAccess)
                                    DataCell(InkWell(
                                        onTap: () => deleteEntry(index),
                                        child: const Icon(Icons.delete,
                                            color: Colors.red))),
                                ]);
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  void editEntry(int index) {
    int actualIndex =
        allData.indexOf(filteredData[index]); // Get actual row index
    if (actualIndex == -1) return; // Prevent errors if index is not found

    TextEditingController dateController =
        TextEditingController(text: filteredData[index][0]);
    TextEditingController jamaController =
        TextEditingController(text: filteredData[index][1]);
    TextEditingController naamController =
        TextEditingController(text: filteredData[index][3]);
    TextEditingController quantityController =
        TextEditingController(text: filteredData[index][4]);
    TextEditingController amountController =
        TextEditingController(text: filteredData[index][5]);

    bool isDateValid = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Entry'),
              content: Column(
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
                      decoration: const InputDecoration(labelText: 'Jama')),
                  TextField(
                      controller: naamController,
                      decoration: const InputDecoration(labelText: 'Naam')),
                  TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number),
                  TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number),
                ],
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
                      "'${dateController.text}'", // Keep date as text
                      jamaController.text,
                      filteredData[index][2], // Keep "Type" unchanged
                      naamController.text,
                      quantityController.text,
                      amountController.text
                    ];

                    int rowIndex = actualIndex + 2; // Fix index misalignment
                    await UserSheetsApi.updateRow(rowIndex, updatedRow);

                    fetchData();
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

  /// **Helper Method for Date Validation**
  bool isValidDateFormat(String date) {
    RegExp regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    return regex.hasMatch(date);
  }

  void deleteEntry(int index) {
    int actualIndex = allData.indexOf(filteredData[index]);
    if (actualIndex == -1) return; // Prevent errors if index is not found

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
                int rowIndex = actualIndex + 2; // Fix index misalignment
                await UserSheetsApi.deleteRow(rowIndex);

                fetchData();
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
