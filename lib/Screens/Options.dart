import 'package:baboo_and_co/Screens/CheeniBrokery.dart';
import 'package:baboo_and_co/Screens/DuePayment.dart';
import 'package:baboo_and_co/Screens/GudBill.dart';
import 'package:baboo_and_co/Screens/online.dart';
import 'package:flutter/material.dart';
import 'package:baboo_and_co/Screens/TodayCB.dart';
import 'package:baboo_and_co/Screens/GeneraLedger.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: SizedBox(
                height: 400,
                width: 600,
                child: Card(
                  semanticContainer: true,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/logo.jpeg',
                    fit: BoxFit.fill,
                  ),
                )),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SizedBox(
                  //     height: 80,
                  //     width: 300,
                  //     child: Button_Widget(context, 'Online', Colors.black, () {
                  //       Navigator.of(context).push(MaterialPageRoute(
                  //           builder: (context) => const OnlineScreen()));
                  //     })),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height: 80,
                      width: 300,
                      child: Button_Widget(
                          context, 'Today Cash Book', Colors.black, () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const Todaycb()));
                      })),
                  const SizedBox(width: 10),
                  SizedBox(
                      height: 80,
                      width: 300,
                      child: Button_Widget(
                          context, 'General ledger', Colors.black, () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const DailyCashBook()));
                      })),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height: 80,
                      width: 300,
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
                      )),
                  // const SizedBox(width: 10),
                  // SizedBox(
                  //     height: 80,
                  //     width: 300,
                  //     child: Button_Widget(
                  //         context, 'Cheeni Brokery', Colors.black, () {
                  //       // Navigator.of(context).push(
                  //       //   MaterialPageRoute(
                  //       //     builder: (context) => const CheeniBrokeryScreen(),
                  //       //   ),
                  //       // );
                  //     })),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height: 80,
                      width: 300,
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
                      )),
                  const SizedBox(width: 10),
                  SizedBox(
                      height: 80,
                      width: 300,
                      child: Button_Widget(context, 'Due Payment', Colors.black,
                          () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DuePaymentScreen(),
                          ),
                        );
                      })),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
