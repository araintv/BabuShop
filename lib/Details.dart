// import 'package:baboo_and_co/Services/GsheetApi.dart';
// import 'package:flutter/material.dart';

// class DetailsScreen extends StatefulWidget {
//   const DetailsScreen({super.key});

//   @override
//   State<DetailsScreen> createState() => _DetailsScreenState();
// }

// class _DetailsScreenState extends State<DetailsScreen> {
//   Future<List<List<String>>> fetchData() async {
//     return await UserSheetsApi.getAllRows();
//   }

//   @override
//   void initState() {
//     super.initState();
//     UserSheetsApi.init(); // Initialize Google Sheets API
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Google Sheets Data')),
//       body: FutureBuilder<List<List<String>>>(
//         future: fetchData(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData)
//             return Center(child: CircularProgressIndicator());
//           final data = snapshot.data!;

//           return ListView.builder(
//             itemCount: data.length,
//             itemBuilder: (context, index) {
//               final row = data[index];
//               return ListTile(
//                 title: Text("NAAM: ${row[0]}"),
//                 subtitle: Text("JAMA: ${row[1]}, RAKAM: ${row[2]}"),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
