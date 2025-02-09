import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';

class CustomerKhata extends StatefulWidget {
  const CustomerKhata({super.key});

  @override
  State<CustomerKhata> createState() => _CustomerKhataState();
}

class _CustomerKhataState extends State<CustomerKhata> {
  static const _credentials = r'''
  {
    "type": "service_account",
    "project_id": "gsheet-449905",
    "private_key_id": "603d40df5093c167a90b4e282b54d9521859b794",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCrUCOUktucYr+V\n6HkFUdI80TLQcFNIcCHZS7M0MeZ8u31XlmxDuQaFYnXPct6BfyL93AaFtDJT/0pQ\n+J5m9lYeVqxNyfH4fcZB17UyECUMDN71DJfROJP6qvOJEX46QDPKS4XB3vZALQXj\nUL2f4kfHIVRfx+qo/7H0URswm8lGbDImyWiSl9EpbJ9ojuD5/4yT/8J/GaTRMOrv\nL5z4hApi2YtzMwSop2wBFYJUsEyreh/Mrdt0mdIrRf9RFcyM0SaTInOuI5wjKIjX\nFBLc58o9Ngb6+AANIHT5JBTBQL5EtCFMFK3pQ5mrbFsCkwqNFMYAoa33E6hzZTWJ\nPsw1FagPAgMBAAECggEADIAGeJrWp2yVKi0SV48G1iU1nfv0N77m2WIqq05Q0R0l\nIjT5pV9k2Gq8yexJzA0o0nkxiKQDYBmqpInflQe4dPJCFFL98vHKe5dvwz1mVqDB\nzAOlOED2mz3KE2BRY5K3tLUaB3FrandejJ2hmH78Wc1WyL5fowE1TOx2HW/gmeDA\njB7WuIeJcWwl4sPlrL6FIGHaoGPuXbXGbMepLO8lF3GdOYuPrdBAIxGV3CIRpN8z\nLv3GHNoyP0lUCB7XDF6rnIKDS4AUljD5j2z9xTNZTKKKESY3pLGNGhVZdCaLNVwC\ndRmhEY29qytfEb4uXZYouXT+MUcYZOEA0JblJ2ojAQKBgQDhBABL6EJNZQ0+nV7/\nVrCMw9wDkENabQDMb0+/fXHoUtcyaAmf+xTpxVBSv70yaI+jPY9Rd0sp1wQpVhZL\n45V6hgW8owGR7fPPq9FObQVxFwEZeYlf5feYClD0974eHopndsLgQD3c8PZbPw+9\nTnJXl33cc6PXmDy4KXCUWqhUzwKBgQDC5xMNETZ3ZyNZkj0G+GrYCt4Y9tZbbzVb\ntnmCp7N7wQ/o4ZPA5a4HJDrpQMw/r1Sx+dCkMAqA2UIxjaKBPRv7HIX5Nf5hqwEh\nN8IdSxmRkzX1+wvdxoUqrxhQoxKqpZ2wx7edvMlkdJjIkF/bOsCANF7U7NR6PUPO\n+2QgmlTIwQKBgB+mMmx61KiSKBTAidYcWWTTP6T4q6CSaGRY27yxZk4pKL+cRo5M\nAJsI981Lzs7CSkHJrNjmkJnn9lviEezGrAW5yCDKRLRD5eE155DCYNuRQsRUhfAJ\nJpQqD00Fc6ZE4W7AE5T7NDhZZC1dZ1dXK1oKotdZJJh0f0Xf/ke/oKGdAoGAczB4\njPeIVkdpmA2a7dyx4N+DZgO0qrNuOLb+155fsJto2L1BQvc7xFLAUo0OafEowEsh\n6XfPLVm6CmloCrPgLqgr8h7cKkMT1tsKaZ+yC9ySPr/RwpAKsjBr0XSfmqVpLkrL\nFXm3GRzkE11ombv+e4b4KSWTam98/P6MrcwoocECgYBlQPTVCuaifP0oeyo1KOQC\nGJ7gINbIKiFyypqceWIgIXVV/M2RH/Yr54j50+iRgO72L5YWYbk9pGqRutruhA87\n1qZUh7+t2TXXp5FwscL4+my8UzGU/LNYvZj01Aqi3xA7XdPxHe4FzW9aoLP+yxDs\narvo2UoQKzZixAmWBN+M0w==\n-----END PRIVATE KEY-----\n"
  }
  ''';

  static const _spreadsheetID = '1av-FKCRtNYgCKxnI9-wzF1famBwaX0SsVbxnjOzPZ4A';
  final _gsheets = GSheets(_credentials);
  List<List<String>> filteredEntries = [];

  @override
  void initState() {
    super.initState();
    fetchEntries();
  }

  Future<void> fetchEntries() async {
    try {
      final spreadsheet = await _gsheets.spreadsheet(_spreadsheetID);

      // Fetch data from 'Naam' and 'Jama' sheets
      final naamSheet = spreadsheet.worksheetByTitle('Naam');
      final jamaSheet = spreadsheet.worksheetByTitle('Jama');

      final naamData = await naamSheet?.values.allRows() ?? [];
      final jamaData = await jamaSheet?.values.allRows() ?? [];

      // Merge data and filter for "Rizwan Rasheed"
      List<List<String>> allData = [...naamData, ...jamaData];
      List<List<String>> matchingEntries = allData.where((row) {
        if (row.length > 3) {
          return row[3].trim().toLowerCase() == "rizwan rasheed";
        }
        return false;
      }).toList();

      setState(() {
        filteredEntries = matchingEntries;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Khata')),
      body: filteredEntries.isEmpty
          ? const Center(child: Text("No entries found"))
          : ListView.builder(
              itemCount: filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = filteredEntries[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text("Date: ${entry[0]}"),
                    subtitle: Text(
                        "Jama: ${entry[1]}-| Naam: ${entry[3]} | Amouzfcnt: ${entry[5]}"),
                  ),
                );
              },
            ),
    );
  }
}
