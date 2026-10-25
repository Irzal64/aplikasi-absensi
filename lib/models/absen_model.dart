class AbsenModel {
  final String tanggal; // key: yyyy-MM-dd
  final String masuk;
  final String pulang;
  final String catatan;
  final double? latitude;
  final double? longitude;
  final String? fotoMasuk;
  final String? fotoPulang;

  AbsenModel({
    required this.tanggal,
    this.masuk = '-',
    this.pulang = '-',
    this.catatan = '',
    this.latitude,
    this.longitude,
    this.fotoMasuk,
    this.fotoPulang,
  });

  factory AbsenModel.fromMap(String key, dynamic data) {
    if (data is Map) {
      return AbsenModel(
        tanggal: data['tanggal'] ?? key,
        masuk: data['masuk']?.toString() ?? '-',
        pulang: data['pulang']?.toString() ?? '-',
        catatan: data['catatan']?.toString() ?? '',
        latitude: data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null,
        longitude: data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null,
        fotoMasuk: data['fotoMasuk']?.toString(),
        fotoPulang: data['fotoPulang']?.toString(),
      );
    }
    // untuk data lama yang cuma string
    return AbsenModel(tanggal: key, masuk: data.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'tanggal': tanggal,
      'masuk': masuk,
      'pulang': pulang,
      'catatan': catatan,
      'latitude': latitude,
      'longitude': longitude,
      'fotoMasuk': fotoMasuk,
      'fotoPulang': fotoPulang,
    };
  }
}
