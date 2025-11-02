import 'package:flutter/material.dart';
import 'package:shop/Screens/Options.dart';
import 'package:shop/Services/GsheetApi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Iniatlize the Google Sheet Here
  await UserSheetsApi.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baboo&Co',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OptionsScreen(),
      // home: DuePaymentScreen(),
      // home: OptionsScreen(),
      // home: const HomePage(),
      // home: DailyCashBook(),
      // home: KhataScreen(),
    );
  }
}
