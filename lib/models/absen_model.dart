class AbsenModel {
  final String tanggal;
  final String masuk;
  String pulang;
  final String catatan;
  final double lat;
  final double lng;
  final String fotoPath;

  AbsenModel({
    required this.tanggal,
    required this.masuk,
    this.pulang = '-',
    required this.catatan,
    required this.lat,
    required this.lng,
    required this.fotoPath,
  });

  // Fungsi untuk mengubah data dari Map Hive menjadi Objek Dart
  factory AbsenModel.fromMap(String tanggal, Map<dynamic, dynamic> map) {
    return AbsenModel(
      tanggal: tanggal,
      masuk: map['masuk'] ?? '-',
      pulang: map['pulang'] ?? '-',
      catatan: map['catatan'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      fotoPath: map['fotoPath'] ?? '',
    );
  }

  // Fungsi untuk mengubah Objek Dart menjadi Map agar bisa disimpan di Hive
  Map<String, dynamic> toMap() {
    return {
      'masuk': masuk,
      'pulang': pulang,
      'catatan': catatan,
      'lat': lat,
      'lng': lng,
      'fotoPath': fotoPath,
    };
  }
}
