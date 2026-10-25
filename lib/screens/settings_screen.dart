import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController latC, lngC, radiusC, jamMasukC, menitMasukC, jamPulangC, menitPulangC, toleransiC;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settingBox');
    latC = TextEditingController(text: (box.get('kantorLat') ?? AppConfig.defaultLat).toString());
    lngC = TextEditingController(text: (box.get('kantorLng') ?? AppConfig.defaultLng).toString());
    radiusC = TextEditingController(text: (box.get('radiusMeter') ?? AppConfig.defaultRadius).toString());
    jamMasukC = TextEditingController(text: (box.get('jamMasuk') ?? AppConfig.defaultJamMasuk).toString());
    menitMasukC = TextEditingController(text: (box.get('menitMasuk') ?? AppConfig.defaultMenitMasuk).toString());
    jamPulangC = TextEditingController(text: (box.get('jamPulang') ?? AppConfig.defaultJamPulang).toString());
    menitPulangC = TextEditingController(text: (box.get('menitPulang') ?? AppConfig.defaultMenitPulang).toString());
    toleransiC = TextEditingController(text: (box.get('toleransi') ?? AppConfig.defaultToleransi).toString());
  }

  void _simpan() {
    final box = Hive.box('settingBox');
    box.put('kantorLat', double.tryParse(latC.text) ?? AppConfig.defaultLat);
    box.put('kantorLng', double.tryParse(lngC.text) ?? AppConfig.defaultLng);
    box.put('radiusMeter', double.tryParse(radiusC.text) ?? 100);
    box.put('jamMasuk', int.tryParse(jamMasukC.text) ?? 8);
    box.put('menitMasuk', int.tryParse(menitMasukC.text) ?? 0);
    box.put('jamPulang', int.tryParse(jamPulangC.text) ?? 16);
    box.put('menitPulang', int.tryParse(menitPulangC.text) ?? 0);
    box.put('toleransi', int.tryParse(toleransiC.text) ?? 15);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Kantor'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('LOKASI KANTOR', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: latC, decoration: const InputDecoration(labelText: 'Latitude (contoh: -6.7489)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          TextField(controller: lngC, decoration: const InputDecoration(labelText: 'Longitude (contoh: 107.6523)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          TextField(controller: radiusC, decoration: const InputDecoration(labelText: 'Radius meter (contoh: 100)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          const Text('Buka Google Maps > klik kanan lokasi kantor > copy koordinat', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 20),
          const Text('JAM KERJA', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: jamMasukC, decoration: const InputDecoration(labelText: 'Jam Masuk', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: menitMasukC, decoration: const InputDecoration(labelText: 'Menit Masuk', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: jamPulangC, decoration: const InputDecoration(labelText: 'Jam Pulang', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: menitPulangC, decoration: const InputDecoration(labelText: 'Menit Pulang', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          TextField(controller: toleransiC, decoration: const InputDecoration(labelText: 'Toleransi Telat (menit)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: _simpan, icon: const Icon(Icons.save), label: const Text('SIMPAN PENGATURAN'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.all(16))),
        ],
      ),
    );
  }
}
