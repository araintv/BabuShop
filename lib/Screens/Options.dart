import 'package:baboo_and_co/Screens/DuePayment.dart';
import 'package:baboo_and_co/Screens/GeneraLedger.dart';
import 'package:baboo_and_co/Screens/GudBill.dart';
import 'package:baboo_and_co/Screens/TodayCB.dart';
import 'package:flutter/material.dart';
import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:baboo_and_co/Widgets/Button.dart';
import 'package:baboo_and_co/Screens/khata.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  Map<String, double> accountBalances = {
    "UBL Babu": 0.0,
    "Meezan Babu": 0.0,
    "AlHabib Babu": 0.0,
    "Allied Babu": 0.0,
    "HBL Babu": 0.0,
    "UBL Ali": 0.0,
    "Meezan Ali": 0.0,
    "AlHabib Ali": 0.0,
    "Allied Ali": 0.0,
    "MCB Ali": 0.0,
    "UBL Abu": 0.0,
    "Meezan Abu": 0.0,
    "AlHabib Abu": 0.0,
    "Faisal Bank Ali": 0.0,
    "Islami Bank Ali": 0.0,
  };

  @override
  void initState() {
    super.initState();
    fetchBalances();
  }

  Future<void> fetchBalances() async {
    final data = await UserSheetsApi.fetchAllRows();
    final accountKeys = accountBalances.keys.toSet();
    Map<String, double> newBalances =
        Map.fromIterable(accountKeys, value: (_) => 0.0);

    for (var row in data.skip(1)) {
      if (row.length < 6) continue;

      final amount = double.tryParse(row[5].trim()) ?? 0.0;
      final jama = row[1].trim();
      final naam = row[3].trim();

      if (accountKeys.contains(jama)) {
        newBalances[jama] = newBalances[jama]! + amount;
      }
      if (accountKeys.contains(naam)) {
        newBalances[naam] = newBalances[naam]! - amount;
      }
    }

    setState(() {
      accountBalances = newBalances;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        const SizedBox(height: 20),
        Card(
          elevation: 20,
          color: Colors.blue[50],
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: accountBalances.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 2.9,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemBuilder: (context, index) {
                String account = accountBalances.keys.elementAt(index);
                double balance = accountBalances[account] ?? 0.0;
                return InkWell(
                  onTap: () {
                    setState(() {
                      fetchBalances();
                    });
                  },
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            account,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${balance >= 0 ? "+" : ""}${balance.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 300,
              width: 500,
              child: Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 50,
                margin: const EdgeInsets.all(10),
                child: Image.asset(
                  'assets/logo.jpeg',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                        child: Button_Widget(
                            context, 'Due Payment', Colors.black, () {
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
        )
      ]),
    );
  }
}
