import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/absen_model.dart';
import 'camera_screen.dart';
import 'rekap_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box _box = Hive.box('absenBox');
  final TextEditingController _catatanController = TextEditingController();
  bool _isLoading = false;

  // 📍 TITIK KOORDINAT KANTOR: CIATER SATU, SERPONG, TANGERANG SELATAN
  final double kantorLat = -6.2538055; 
  final double kantorLng = 106.6660833; 
  
  // 📏 RADIUS MAKSIMAL ABSENSI (10 Meter)
  final double radiusMeter = 10.0; 
  
  // Fungsi Alur V2: Cek Lokasi dan Hitung Selisih Jarak
  Future<Position?> _cekLokasiDanJarak() async {
    bool service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      _showDialogPeringatan("GPS Mati", "Silakan aktifkan GPS pada perangkat Anda terlebih dahulu.");
      return null;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        _showDialogPeringatan("Izin Ditolak", "Aplikasi membutuhkan izin lokasi untuk validasi absensi.");
        return null;
      }
    }

    if (perm == LocationPermission.deniedForever) {
      _showDialogPeringatan("Izin Permanen Ditolak", "Silakan aktifkan izin lokasi secara manual lewat pengaturan HP.");
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  void _prosesAbsen(bool isMasuk) async {
    setState(() => _isLoading = true);
    
    Position? pos = await _cekLokasiDanJarak();
    if (pos == null) {
      setState(() => _isLoading = false);
      return;
    }

    double jarak = Geolocator.distanceBetween(pos.latitude, pos.longitude, kantorLat, kantorLng);
    setState(() => _isLoading = false);

    // 1. Jika pengguna berada di luar radius area kantor
    if (jarak > radiusMeter) {
      int selisihJarak = jarak.round();
      _showDialogPeringatan(
        "Di Luar Area Absen",
        "Anda berada sekitar $selisihJarak meter dari kantor. Silakan mendekat ke area kantor terlebih dahulu."
      );
      return;
    }

    // 2. Jika lolos validasi jarak -> Buka Kamera Depan
    if (!mounted) return;
    final String? pathFotoHasil = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    // Jika pengguna membatalkan foto / menekan tombol kembali
    if (pathFotoHasil == null) return;

    // 3. Simpan data absensi ke Hive
    String hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String jamTerkini = DateFormat('HH:mm:ss').format(DateTime.now());

    if (isMasuk) {
      var dataLama = _box.get(hariIni);
      AbsenModel dataBaru = AbsenModel(
        tanggal: hariIni,
        masuk: jamTerkini,
        catatan: _catatanController.text,
        pulang: dataLama != null ? dataLama['pulang'] : '-',
        lat: pos.latitude,
        lng: pos.longitude,
        fotoPath: pathFotoHasil,
      );
      _box.put(hariIni, dataBaru.toMap());
      _catatanController.clear();
      _showSnackbarSukses("Berhasil Absen Masuk dengan Foto Wajah!");
    } else {
      var dataLama = _box.get(hariIni);
      if (dataLama != null) {
        AbsenModel absen = AbsenModel.fromMap(hariIni, dataLama);
        absen.pulang = jamTerkini;
        _box.put(hariIni, absen.toMap());
        _showSnackbarSukses("Berhasil Absen Pulang!");
      } else {
        _showDialogPeringatan("Gagal Pulang", "Anda belum melakukan absen masuk hari ini.");
      }
    }
  }

  void _showDialogPeringatan(String judul, String isi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(isi),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSnackbarSukses(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absen Ciater V2'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RekapScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _catatanController,
              decoration: const InputDecoration(
                labelText: 'Catatan tugas/izin hari ini',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text('Memvalidasi koordinat GPS...'),
            ] else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _prosesAbsen(true),
                      icon: const Icon(Icons.camera_front),
                      label: const Text('ABSEN MASUK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _prosesAbsen(false),
                      icon: const Icon(Icons.logout),
                      label: const Text('ABSEN PULANG'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Riwayat Hari Ini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (context, Box b, _) {
                  if (b.isEmpty) return const Center(child: Text('Belum ada riwayat absen.'));
                  List keys = b.keys.toList()..sort((a, b) => b.compareTo(a));

                  return ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, i) {
                      var key = keys[i];
                      AbsenModel absen = AbsenModel.fromMap(key, b.get(key));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: absen.fotoPath.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(File(absen.fotoPath), width: 50, height: 50, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.person, size: 40),
                          title: Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(absen.tanggal)), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Masuk: ${absen.masuk} | Pulang: ${absen.pulang}\nKoordinat: ${absen.lat.toStringAsFixed(4)}, ${absen.lng.toStringAsFixed(4)}"),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
