import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shop/Components/snackBar.dart';
import 'package:shop/Services/GsheetApi.dart';
import 'package:shop/Widgets/Button.dart';

class GudBillScreen extends StatefulWidget {
  const GudBillScreen({super.key});

  @override
  State<GudBillScreen> createState() => _GudBillScreenState();
}

class _GudBillScreenState extends State<GudBillScreen> {
  List<Map<String, dynamic>> partyList = [];
  TextEditingController purchasedParty = TextEditingController();
  TextEditingController driverNumber = TextEditingController();
  TextEditingController goodBillNumber = TextEditingController();
  TextEditingController totalKG = TextEditingController();
  TextEditingController totalRaqam = TextEditingController();
  TextEditingController truckNumber = TextEditingController();
  TextEditingController dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );

  bool isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _fetchAutocompleteData();
  }

  void addNewParty() {
    setState(() {
      partyList.add({
        'partyName': TextEditingController(),
        'items': [
          {
            'bags': TextEditingController(),
            'kg': TextEditingController(),
            'description': TextEditingController(),
            'rate': TextEditingController(),
            'total': TextEditingController(),
          },
        ],
      });
    });
  }

  void addNewItem(int partyIndex) {
    setState(() {
      partyList[partyIndex]['items'].add({
        'bags': TextEditingController(),
        'kg': TextEditingController(),
        'description': TextEditingController(),
        'rate': TextEditingController(),
        'total': TextEditingController(),
      });
    });
  }

  void removeItem(int partyIndex, int itemIndex) {
    setState(() {
      partyList[partyIndex]['items'].removeAt(itemIndex);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
      setState(() {
        dateController.text = formattedDate;
      });
    }
  }

  void calculateTotal(int partyIndex, int itemIndex) {
    double bags =
        double.tryParse(
          partyList[partyIndex]['items'][itemIndex]['bags']!.text,
        ) ??
        0;
    double kg =
        double.tryParse(
          partyList[partyIndex]['items'][itemIndex]['kg']!.text,
        ) ??
        0;
    double rate =
        double.tryParse(
          partyList[partyIndex]['items'][itemIndex]['rate']!.text,
        ) ??
        0;
    double total = (bags * kg) / 40 * rate;

    setState(() {
      partyList[partyIndex]['items'][itemIndex]['total']!.text = total
          .toStringAsFixed(2);
    });
  }

  void saveData() async {
    if (dateController.text.isEmpty ||
        purchasedParty.text.isEmpty ||
        driverNumber.text.isEmpty ||
        goodBillNumber.text.isEmpty ||
        totalKG.text.isEmpty ||
        totalRaqam.text.isEmpty ||
        truckNumber.text.isEmpty ||
        partyList.isEmpty) {
      CustomSnackBar(
        context,
        const Text('All fields must be filled before saving!'),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    double totalQuantity = 0;
    double totalAmount = double.tryParse(totalRaqam.text) ?? 0;

    // Calculate total quantity across all parties
    for (var party in partyList) {
      for (var item in party['items']) {
        totalQuantity += double.tryParse(item['bags'].text) ?? 0;
      }
    }

    // First Entry (Main Entry)
    List<String> firstEntry = [
      dateController.text.replaceAll("'", ""), // Date
      purchasedParty.text, // Jama (Purchased Party)
      "Good Bill", // Type
      "Rizwan Rasheed", // Naam
      totalQuantity.toString(), // Quantity (Total Sum)
      totalAmount.toString(), // Amount (Total Sum)
      "Total Weight : ${totalKG.text}, Gud Bill Number : ${goodBillNumber.text}, Driver Number : ${driverNumber.text}, Truck Number : ${truckNumber.text}", // Details
    ];

    await UserSheetsApi.insertRow(firstEntry); // Upload first entry

    // Upload Multiple Entries (Per Party)
    for (var party in partyList) {
      String partyName = party['partyName'].text;
      double partyQuantity = 0; // Same logic for quantity
      double partyAmount = 0;
      double multipliedWeight = 0; // New variable for (bags * kg) calculation
      List<String> tafseelList = []; // Store all Tafseel descriptions

      for (var item in party['items']) {
        double bags = double.tryParse(item['bags'].text) ?? 0;
        double kg = double.tryParse(item['kg'].text) ?? 0;
        double total = double.tryParse(item['total'].text) ?? 0;
        String tafseel = item['description'].text; // Get Tafseel data

        partyQuantity += bags; // Keeping original quantity logic (sum of bags)
        partyAmount += total;
        multipliedWeight += (bags * kg); // Multiply total bags by total weight
        if (tafseel.isNotEmpty) {
          tafseelList.add(tafseel); // Add Tafseel to list if not empty
        }
      }

      String tafseelDetails = tafseelList.isNotEmpty
          ? tafseelList.join(", ")
          : "No Tafseel";

      List<String> partyEntry = [
        dateController.text.replaceAll("'", ""), // Date (Same)
        "Rizwan Rasheed", // Jama
        "Good Bill", // Type
        partyName, // Naam (Party Name)
        partyQuantity.toString(), // Quantity (Original sum of bags)
        partyAmount.toString(), // Amount (Party Sum)
        "Total Bags: ${partyQuantity.toString()} Total Weight: ${multipliedWeight.toString()}, Gud Bill Number: ${goodBillNumber.text}, Tafseel: $tafseelDetails", // Tafseel added
      ];

      await UserSheetsApi.insertRow(partyEntry); // Upload Party Entry
    }

    // Clear input fields after saving

    CustomSnackBar(
      context,
      const Text('Data successfully saved to Google Sheets!'),
    );
    await Share.share(
      'Date : ${dateController.text}, \nDriver Phone Number : ${driverNumber.text}, \nTruck Number : ${truckNumber.text} \nBaboo and Company, Galla Mandi, Liaqatpur',
    );

    setState(() {
      purchasedParty.clear();
      driverNumber.clear();
      goodBillNumber.clear();
      totalKG.clear();
      totalRaqam.clear();
      truckNumber.clear();
      partyList.clear();
      isLoading = false;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Memo Gud Bill'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: isLoading
                ? const CircularProgressIndicator()
                : InkWell(
                    onTap: () async {
                      bool hasInternet = await isInternetAvailable();
                      if (hasInternet) {
                        saveData();
                      } else {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          title: 'No Internet',
                          text: 'You are Disconnected',
                        );
                      }
                    },
                    child: const Icon(Icons.file_upload_outlined, size: 35),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: dateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  label: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: screenWidth * 0.030,
                                    ),
                                  ),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () => _selectDate(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: purchasedParty.text.isEmpty
                                ? null
                                : purchasedParty.text,
                            decoration: const InputDecoration(
                              labelText: 'Purchased From',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 5,
                              ),
                            ),
                            items:
                                [
                                      "Talib Hussain LQP",
                                      "Al Hilal Corporation",
                                      "Liaqat Amjad Yazman",
                                      "No Choice",
                                    ]
                                    .map(
                                      (String item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  purchasedParty.text = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: totalKG,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              label: Text(
                                'Total Weight KG',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.030,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: goodBillNumber,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              label: Text(
                                'Gud Bill',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.030,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: totalRaqam,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              label: Text(
                                'Total Raqam',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.030,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: truckNumber,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              label: Text(
                                'Truck No',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.030,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: driverNumber,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              label: Text(
                                'Driver Number',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.030,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 2),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: partyList.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, partyIndex) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                '${partyIndex + 1}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 60, // Set a defined height
                              child: Autocomplete<String>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<String>.empty();
                                      }
                                      List<String> combinedSuggestions =
                                          (jamaSuggestions + naamSuggestions)
                                              .toSet()
                                              .toList();
                                      return combinedSuggestions.where(
                                        (option) =>
                                            option.toLowerCase().contains(
                                              textEditingValue.text
                                                  .toLowerCase(),
                                            ),
                                      );
                                    },
                                onSelected: (String selection) {
                                  setState(() {
                                    partyList[partyIndex]['partyName'].text =
                                        selection;
                                  });
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      textFieldController,
                                      focusNode,
                                      onEditingComplete,
                                    ) {
                                      // Assign the initial value only once
                                      if (textFieldController.text.isEmpty) {
                                        textFieldController.text =
                                            partyList[partyIndex]['partyName']
                                                .text;
                                      }

                                      textFieldController.addListener(() {
                                        // Avoid calling `setState()` unnecessarily
                                        if (partyList[partyIndex]['partyName']
                                                .text !=
                                            textFieldController.text) {
                                          partyList[partyIndex]['partyName']
                                                  .text =
                                              textFieldController.text;
                                        }
                                      });

                                      return TextField(
                                        controller: textFieldController,
                                        focusNode: focusNode,
                                        onEditingComplete: onEditingComplete,
                                        decoration: const InputDecoration(
                                          labelText: 'Party Name',
                                          border: OutlineInputBorder(),
                                        ),
                                      );
                                    },
                              ),
                            ),
                            const SizedBox(height: 5),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  partyList[partyIndex]['items'].length +
                                  1, // Extra item for total weight
                              itemBuilder: (context, itemIndex) {
                                if (itemIndex <
                                    partyList[partyIndex]['items'].length) {
                                  double quantity =
                                      double.tryParse(
                                        partyList[partyIndex]['items'][itemIndex]['bags']
                                                ?.text ??
                                            '0',
                                      ) ??
                                      0;
                                  double kg =
                                      double.tryParse(
                                        partyList[partyIndex]['items'][itemIndex]['kg']
                                                ?.text ??
                                            '0',
                                      ) ??
                                      0;
                                  double itemWeight = quantity * kg;

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: TextField(
                                              controller:
                                                  partyList[partyIndex]['items'][itemIndex]['bags'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                label: Text(
                                                  'Quantity',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        screenWidth * 0.040,
                                                  ),
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                                hintText: "Katta",
                                              ),
                                              onChanged: (_) => calculateTotal(
                                                partyIndex,
                                                itemIndex,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 1,
                                            child: TextField(
                                              controller:
                                                  partyList[partyIndex]['items'][itemIndex]['kg'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                label: Text(
                                                  'Kilogram',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        screenWidth * 0.040,
                                                  ),
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                                hintText: "Weight Per Bag",
                                              ),
                                              onChanged: (_) => calculateTotal(
                                                partyIndex,
                                                itemIndex,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              '$itemWeight KG',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  partyList[partyIndex]['items'][itemIndex]['rate'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                label: Text(
                                                  'Rate',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        screenWidth * 0.040,
                                                  ),
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                                hintText: "Rate as per 40 KG",
                                              ),
                                              onChanged: (_) => calculateTotal(
                                                partyIndex,
                                                itemIndex,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Rs. ${partyList[partyIndex]['items'][itemIndex]['total']!.text}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller:
                                                  partyList[partyIndex]['items'][itemIndex]['description'],
                                              keyboardType: TextInputType.text,
                                              decoration: InputDecoration(
                                                label: Text(
                                                  'Tafseel',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        screenWidth * 0.040,
                                                  ),
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                                hintText: "Bori/Lal/Sabza",
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => removeItem(
                                              partyIndex,
                                              itemIndex,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      const Divider(),
                                    ],
                                  );
                                }
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Button_Widget(
                                    context,
                                    'Add Selling Details',
                                    Colors.black,
                                    () => addNewItem(partyIndex),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(thickness: 2),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                // Expanded(
                //   child: Padding(
                //       padding: const EdgeInsets.all(10),
                //       child: isLoading
                //           ? const Center(child: CircularProgressIndicator())
                //           : Button_Widget(
                //               context,
                //               'Upload Order Now..',
                //               Colors.black,
                //               saveData,
                //             )),
                // ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Button_Widget(
                      context,
                      'Add Selling Party',
                      Colors.redAccent,
                      addNewParty,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
