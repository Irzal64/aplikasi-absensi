import 'package:hive_flutter/hive_flutter.dart';

class AppConfig {
  // Default (dipakai kalau belum disetting)
  static const double defaultLat = -6.7489; // Kantor Desa Ciater
  static const double defaultLng = 107.6523;
  static const double defaultRadius = 100;
  static const int defaultJamMasuk = 8;
  static const int defaultMenitMasuk = 0;
  static const int defaultJamPulang = 16;
  static const int defaultMenitPulang = 0;
  static const int defaultToleransi = 15;

  static Box get _box => Hive.box('settingBox');

  static double get kantorLat => (_box.get('kantorLat') ?? defaultLat).toDouble();
  static double get kantorLng => (_box.get('kantorLng') ?? defaultLng).toDouble();
  static double get radiusMeter => (_box.get('radiusMeter') ?? defaultRadius).toDouble();
  static int get jamMasuk => _box.get('jamMasuk') ?? defaultJamMasuk;
  static int get menitMasuk => _box.get('menitMasuk') ?? defaultMenitMasuk;
  static int get jamPulang => _box.get('jamPulang') ?? defaultJamPulang;
  static int get menitPulang => _box.get('menitPulang') ?? defaultMenitPulang;
  static int get toleransiTelatMenit => _box.get('toleransi') ?? defaultToleransi;

  static String get jamMasukStr => '${jamMasuk.toString().padLeft(2,'0')}:${menitMasuk.toString().padLeft(2,'0')}';
  static String get jamPulangStr => '${jamPulang.toString().padLeft(2,'0')}:${menitPulang.toString().padLeft(2,'0')}';
}