import 'package:baboo_and_co/Services/GsheetApi.dart';
import 'package:flutter/material.dart';

class Methods {
  // Main Screen pr show hona wala Card Logo
  showSlogan(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 250,
        width: width / 2.5, //desktop 2.5 - mobile 1
        child: Card(
          semanticContainer: true,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 10,
          margin: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/logo.jpeg',
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  } //End Here

  // Navigate Method
  void navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  } // End Here

  // Bank Names Where Accounts are Registered
  Map<String, double> getInitialAccountBalances() {
    return {
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
      "Dukan Cash": 0.0,
    };
  }

// Start Checking Account Balances
  Future<Map<String, double>> fetchBalances(Set<String> accountKeys) async {
    final data = await UserSheetsApi.fetchAllRows();
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

    return newBalances;
  } // End Here
}
