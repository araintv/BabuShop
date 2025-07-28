import 'package:baboo_and_co/Screens/DuePayment.dart';
import 'package:baboo_and_co/Screens/GeneraLedger.dart';
import 'package:baboo_and_co/Screens/GudBill.dart';
import 'package:baboo_and_co/Screens/RecentRecord.dart';
import 'package:baboo_and_co/Screens/TodayCB.dart';
import 'package:baboo_and_co/Services/Methods.dart';
import 'package:baboo_and_co/Widgets/BankBalanceWidget.dart';
import 'package:flutter/material.dart';
import 'package:baboo_and_co/Widgets/Button.dart';
import 'package:baboo_and_co/Screens/khata.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  Map<String, double> accountBalances = Methods().getInitialAccountBalances();

  @override
  void initState() {
    super.initState();
    fetchBalances();
  }

  Future<void> fetchBalances() async {
    final accountKeys = accountBalances.keys.toSet();
    final newBalances = await Methods().fetchBalances(accountKeys);

    setState(() {
      accountBalances = newBalances;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 20),
          AccountBalanceGrid(
            accountBalances: accountBalances,
            onRefresh: () {
              setState(() {
                fetchBalances();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Methods().showSlogan(context),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      optionButton(context, 'Today Cash Book', () {
                        Methods().navigateTo(context, const Todaycb());
                      }),
                      const SizedBox(width: 10),
                      optionButton(context, 'General ledger', () {
                        Methods().navigateTo(context, const DailyCashBook());
                      }),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      optionButton(context, 'Gud Bill', () {
                        Methods().navigateTo(context, const GudBillScreen());
                      }),
                      const SizedBox(width: 10),
                      optionButton(context, 'Recent Gud Load', () {
                        Methods()
                            .navigateTo(context, const RecentRecordScreen());
                      }),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      optionButton(context, 'Khata \'Accounts\'', () {
                        Methods().navigateTo(context, const KhataScreen());
                      }),
                      const SizedBox(width: 10),
                      optionButton(context, 'Due Payment', () {
                        Methods().navigateTo(context, const DuePaymentScreen());
                      }),
                    ],
                  ),
                ],
              ),
            ],
          )
        ]),
      ),
    );
  }

  optionButton(BuildContext context, String title, Function onClick) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
            height: 70,
            width: width / 5,
            child: Button_Widget(context, title, Colors.black, onClick)),
        const SizedBox(height: 10),
      ],
    );
  }
}
