import 'package:flutter/material.dart';
import 'package:shop/Screens/BankOnlines.dart';
import 'package:shop/Screens/DuePayment.dart';
import 'package:shop/Screens/GeneraLedger.dart';
import 'package:shop/Screens/GudBill.dart';
import 'package:shop/Screens/RecentRecord.dart';
import 'package:shop/Screens/TodayCB.dart';
import 'package:shop/Screens/khata.dart';
import 'package:shop/Services/Methods.dart';
import 'package:shop/Widgets/BankBalanceWidget.dart';
import 'package:shop/Widgets/Button.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  Methods().showSlogan(context),
                  SizedBox(width: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
                                Methods().navigateTo(
                                  context,
                                  const DailyCashBook(),
                                );
                              }),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              optionButton(context, 'Gud Bill', () {
                                Methods().navigateTo(
                                  context,
                                  const GudBillScreen(),
                                );
                              }),
                              const SizedBox(width: 10),
                              optionButton(context, 'Recent Shipped', () {
                                Methods().navigateTo(
                                  context,
                                  const RecentRecordScreen(),
                                );
                              }),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              optionButton(context, 'Khata \'Accounts\'', () {
                                Methods().navigateTo(
                                  context,
                                  const KhataScreen(),
                                );
                              }),
                              const SizedBox(width: 10),
                              optionButton(context, 'Due Payment', () {
                                Methods().navigateTo(
                                  context,
                                  const DuePaymentScreen(),
                                );
                              }),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              optionButton(context, 'Bank Onlines', () {
                                Methods().navigateTo(
                                  context,
                                  const BankOnlines(),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              AccountBalanceGrid(
                accountBalances: accountBalances,
                onRefresh: () {
                  setState(() {
                    fetchBalances();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  optionButton(BuildContext context, String title, Function onClick) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: width / 2.2, //desktop 5 - mobile 2.2
          child: Button_Widget(context, title, Colors.black, onClick),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
