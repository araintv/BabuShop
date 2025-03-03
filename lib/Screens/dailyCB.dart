import 'package:baboo_and_co/Components/snackBar.dart';
import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:baboo_and_co/Widgets/Button.dart';
import 'package:flutter/material.dart';

class DailyCashBook extends StatefulWidget {
  const DailyCashBook({super.key});

  @override
  State<DailyCashBook> createState() => _CustomerKhataState();
}

class _CustomerKhataState extends State<DailyCashBook> {
  List<Map<String, dynamic>> filteredData = []; // Holds row + index
  List<List<String>> allData = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final allRows = await UserSheetsApi.fetchAllRows();

    setState(() {
      allData = allRows.isNotEmpty ? allRows.sublist(1) : [];
      filterData(searchController.text);
      isLoading = false;
    });
  }

  void filterData(String query) {
    setState(() {
      filteredData = allData
          .asMap()
          .entries
          .where((entry) {
            List<String> row = entry.value;
            return row.length >= 4 &&
                (row[1].toLowerCase().contains(query.toLowerCase()) ||
                    row[3].toLowerCase().contains(query.toLowerCase()));
          })
          .map((entry) => {"index": entry.key, "row": entry.value})
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Ledger \'CashBook\'',
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
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 50,
                          child: Button_Widget(
                              context, 'Refresh', Colors.green, fetchData),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredData.isEmpty
                      ? const Center(child: Text('No matching entries found'))
                      : ListView(
                          children: [
                            DataTable(
                              columns: const [
                                DataColumn(
                                    label: Text('No.',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Date',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Jama',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Type',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Naam',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Quantity',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Amount',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Edit',
                                        style: TextStyle(fontSize: 18))),
                                DataColumn(
                                    label: Text('Delete',
                                        style: TextStyle(fontSize: 18))),
                              ],
                              rows: filteredData.map((entry) {
                                int realIndex = entry["index"];
                                List<String> row = entry["row"];

                                return DataRow(cells: [
                                  DataCell(Text((realIndex + 1).toString())),
                                  DataCell(Text(row[0])),
                                  DataCell(Text(row[1])),
                                  DataCell(Text(row[2])),
                                  DataCell(Text(row[3])),
                                  DataCell(Text(row[4])),
                                  DataCell(Text(row[5])),
                                  DataCell(InkWell(
                                      onTap: () => editEntry(realIndex, row),
                                      child: const Icon(Icons.edit,
                                          color: Colors.blue))),
                                  DataCell(InkWell(
                                      onTap: () => deleteEntry(realIndex),
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

  void editEntry(int index, List<String> row) {
    TextEditingController dateController = TextEditingController(text: row[0]);
    TextEditingController jamaController = TextEditingController(text: row[1]);
    TextEditingController naamController = TextEditingController(text: row[3]);
    TextEditingController quantityController =
        TextEditingController(text: row[4]);
    TextEditingController amountController =
        TextEditingController(text: row[5]);

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
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    if (!isValidDateFormat(dateController.text)) {
                      setState(() => isDateValid = false);
                      return;
                    }

                    List<String> updatedRow = [
                      "'${dateController.text}'",
                      jamaController.text,
                      row[2],
                      naamController.text,
                      quantityController.text,
                      amountController.text
                    ];

                    await UserSheetsApi.updateRow(index + 2, updatedRow);
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

  bool isValidDateFormat(String date) {
    RegExp regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
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
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await UserSheetsApi.deleteRow(index + 2);
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
