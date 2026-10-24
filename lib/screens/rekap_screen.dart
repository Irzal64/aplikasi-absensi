import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/absen_model.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({super.key});

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  final Box _box = Hive.box('absenBox');
  DateTime _selectedDate = DateTime.now();

  // Fungsi membuat dan membagikan file CSV
  Future<void> _exportToCSV(List<AbsenModel> data) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport!')),
      );
      return;
    }

    String csvData = 'Tanggal,Jam Masuk,Jam Pulang,Catatan\n';
    for (var absen in data) {
      String catatanBersih = absen.catatan.replaceAll(',', ';');
      csvData += '${absen.tanggal},${absen.masuk},${absen.pulang},$catatanBersih\n';
    }

    try {
      final directory = await getTemporaryDirectory();
      String namaBulan = DateFormat('MMMM_yyyy').format(_selectedDate);
      final file = File('${directory.path}/Rekap_Absen_$namaBulan.csv');
      await file.writeAsString(csvData);

      final XFile xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Rekap Absen Periode $namaBulan');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export data: $e')),
      );
    }
  }

  // Fungsi Pembantu untuk Menghitung Statistik Kehadiran
  Map<String, int> _hitungStatistik(List<AbsenModel> data) {
    int hadir = 0;
    int telat = 0;
    int alpa = 0;

    for (var absen in data) {
      if (absen.masuk.toLowerCase() == 'alpa') {
        alpa++;
      } else {
        hadir++;
        // Contoh asumsi telat jika masuk di atas jam 08:00
        try {
          List<String> waktu = absen.masuk.split(':');
          int jam = int.parse(waktu[0]);
          if (jam >= 8) {
            telat++;
          }
        } catch (_) {}
      }
    }

    return {'hadir': hadir, 'telat': telat, 'alpa': alpa};
  }

  @override
  Widget build(BuildContext context) {
    String filterBulanTahun = DateFormat('yyyy-MM').format(_selectedDate);

    // Mengambil dan memfilter data dari Hive
    List<AbsenModel> listRekap = [];
    for (var key in _box.keys) {
      if (key.toString().startsWith(filterBulanTahun)) {
        listRekap.add(AbsenModel.fromMap(key.toString(), _box.get(key)));
      }
    }
    listRekap.sort((a, b) => a.tanggal.compareTo(b.tanggal));

    // Menghitung statistik bulan ini
    final stats = _hitungStatistik(listRekap);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Bulanan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bagian Header & Aksi Ganti Bulan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Ubah Bulan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportToCSV(listRekap),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),

          // Ringkasan Dashboard Kecil (Statistik Ringkas)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatTile('Hadir', stats['hadir'].toString(), Colors.green),
                _buildStatTile('Telat', stats['telat'].toString(), Colors.orange),
                _buildStatTile('Alpa', stats['alpa'].toString(), Colors.red),
              ],
            ),
          ),
          const Divider(height: 1),

          // Daftar List Utama
          Expanded(
            child: listRekap.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data absen di bulan ini.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: listRekap.length,
                    itemBuilder: (context, index) {
                      AbsenModel absen = listRekap[index];
                      DateTime? parsedDate;
                      try {
                        parsedDate = DateTime.parse(absen.tanggal);
                      } catch (_) {}

                      String formatHari = parsedDate != null 
                          ? DateFormat('EEEE, dd MMM').format(parsedDate) 
                          : absen.tanggal;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            foregroundColor: Colors.teal.shade900,
                            child: Text(absen.tanggal.split('-').last),
                          ),
                          title: Text(
                            formatHari,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text("Masuk: ${absen.masuk} | Pulang: ${absen.pulang}"),
                          ),
                          trailing: absen.catatan.isNotEmpty 
                              ? const Tooltip(
                                  message: 'Ada Catatan',
                                  child: Icon(Icons.sticky_note_2, color: Colors.amber),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk Kartu Kecil Statistik
  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
