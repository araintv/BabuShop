import 'package:baboo_and_co/Screens/CheeniBrokery.dart';
import 'package:baboo_and_co/Screens/DuePayment.dart';
import 'package:baboo_and_co/Screens/GudBill.dart';
import 'package:flutter/material.dart';
import 'package:baboo_and_co/Screens/TodayCB.dart';
import 'package:baboo_and_co/Screens/dailyCB.dart';
import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:baboo_and_co/Widgets/Button.dart';
import 'package:baboo_and_co/Screens/khata.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  final TextEditingController searchController = TextEditingController();

  List<String> accountNames = [];

  @override
  void initState() {
    super.initState();
    fetchAccountNames();
  }

  // Fetch unique names from Google Sheets
  Future<void> fetchAccountNames() async {
    final data = await UserSheetsApi.fetchAllRows();

    Set<String> uniqueNames = {};
    for (var row in data.skip(1)) {
      if (row.length > 1) uniqueNames.add(row[1].trim()); // Jama
      if (row.length > 3) uniqueNames.add(row[3].trim()); // Naam
    }

    setState(() {
      accountNames = uniqueNames.where((name) => name.isNotEmpty).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: screenWidth * 0.8, // Adjust width dynamically
                height: 400,
                child: Image.asset('assets/logo.jpeg'),
              ),
            ),
            SizedBox(
              height: 80,
              width: screenWidth * 0.8,
              child: Button_Widget(
                context,
                'Gud Bill',
                Colors.black,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GudBillScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 10),
            //   child: SizedBox(
            //     height: 80,
            //     width: screenWidth * 0.8,
            //     child: Button_Widget(context, 'Due Payment', Colors.black, () {
            //       Navigator.of(context).push(
            //         MaterialPageRoute(
            //           builder: (context) => const DuePaymentScreen(),
            //         ),
            //       );
            //     }),
            //   ),
            // ),
            SizedBox(
              height: 80,
              width: screenWidth * 0.8,
              child: Button_Widget(
                context,
                'Khata \'Accounts\'',
                Colors.black,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const KhataScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
