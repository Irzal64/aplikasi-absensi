import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/absen_model.dart';
import 'camera_screen.dart';
import 'rekap_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box _box = Hive.box('absenBox');
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  AbsenModel? get _todayAbsen {
    String key = DateFormat('yyyy-MM-dd').format(_now);
    var data = _box.get(key);
    if (data == null) return null;
    return AbsenModel.fromMap(key, data);
  }

  List<AbsenModel> get _last5 {
    List<AbsenModel> list = [];
    for (var k in _box.keys) {
      var v = _box.get(k);
      if (v != null) list.add(AbsenModel.fromMap(k.toString(), v));
    }
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return list.take(5).toList();
  }

  void _bukaKamera({required bool isMasuk}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(isMasuk: isMasuk),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayAbsen;
    final bool sudahMasuk = today != null && today.masuk.isNotEmpty && today.masuk != '-' && today.masuk.toLowerCase() != 'alpa';
    final bool sudahPulang = today != null && today.pulang.isNotEmpty && today.pulang != '-' && today.pulang.toLowerCase() != 'alpa';

    String statusText = 'Belum Absen';
    Color statusColor = Colors.orange;
    if (sudahMasuk && !sudahPulang) {
      statusText = 'Sudah Masuk - ${today.masuk}';
      statusColor = Colors.green;
    } else if (sudahMasuk && sudahPulang) {
      statusText = 'Selesai - Masuk ${today.masuk} | Pulang ${today.pulang}';
      statusColor = Colors.teal;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Absensi Ciater', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekapScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KARTU JAM & TANGGAL
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF009688), Color(0xFF00695C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_now), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(DateFormat('HH:mm:ss').format(_now), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: statusColor == Colors.orange ? Colors.amber : Colors.greenAccent),
                      const SizedBox(width: 6),
                      Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TOMBOL ABSEN
          Row(
            children: [
              Expanded(
                child: _AbsenButton(
                  label: 'Masuk',
                  icon: Icons.login_rounded,
                  color: Colors.teal,
                  enabled: !sudahMasuk,
                  onTap: () => _bukaKamera(isMasuk: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AbsenButton(
                  label: 'Pulang',
                  icon: Icons.logout_rounded,
                  color: Colors.orange.shade700,
                  enabled: sudahMasuk && !sudahPulang,
                  onTap: () => _bukaKamera(isMasuk: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // RIWAYAT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Riwayat Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekapScreen())), child: const Text('Lihat Semua')),
            ],
          ),
          const SizedBox(height: 8),
          if (_last5.isEmpty)
            const Card(child: ListTile(title: Text('Belum ada data absen'), subtitle: Text('Tekan tombol Masuk untuk mulai')))
          else
            ..._last5.map((e) {
              bool alpa = e.masuk.toLowerCase() == 'alpa' || e.masuk == '-' || e.masuk.isEmpty;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: alpa ? Colors.red.shade50 : Colors.teal.shade50, child: Icon(alpa ? Icons.close : Icons.check, color: alpa ? Colors.red : Colors.teal)),
                  title: Text(e.tanggal, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(alpa ? 'Alpa' : 'Masuk: ${e.masuk} | Pulang: ${e.pulang.isEmpty ? '-' : e.pulang}'),
                  trailing: Text(e.catatan, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AbsenButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _AbsenButton({required this.label, required this.icon, required this.color, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}