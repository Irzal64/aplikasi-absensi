import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // TAMBAHKAN INI
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // INI YANG KURANG, TAMBAHKAN 2 BARIS INI
  await initializeDateFormatting('id_ID', null); 
  
  await Hive.initFlutter();
  await Hive.openBox('absenBox');
  await Hive.openBox('settingBox'); // pastikan ada ini juga
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Ciater',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}