import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/absen_model.dart';

class CameraScreen extends StatefulWidget {
  final bool isMasuk;
  const CameraScreen({super.key, required this.isMasuk});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isLoading = true;
  bool _isSaving = false;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      // 1. Kamera
      final cameras = await availableCameras();
      final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      
      // 2. Lokasi
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          _position = await Geolocator.getCurrentPosition();
        }
      }
    } catch (e) {
      debugPrint('Init error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _ambilFotoDanSimpan() async {
    if (_controller == null || !_controller!.value.isInitialized || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final XFile file = await _controller!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      String fileName = '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}_${widget.isMasuk ? 'masuk' : 'pulang'}.jpg';
      final savedPath = '${dir.path}/$fileName';
      await File(file.path).copy(savedPath);

      final box = Hive.box('absenBox');
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String jamSekarang = DateFormat('HH:mm').format(DateTime.now());

      var existing = box.get(todayKey);
      AbsenModel current;
      if (existing != null) {
        current = AbsenModel.fromMap(todayKey, existing);
      } else {
        current = AbsenModel(tanggal: todayKey);
      }

      AbsenModel updated;
      if (widget.isMasuk) {
        updated = AbsenModel(
          tanggal: todayKey,
          masuk: jamSekarang,
          pulang: current.pulang,
          catatan: _isTelat(jamSekarang) ? 'Terlambat' : 'Tepat Waktu',
          latitude: _position?.latitude ?? current.latitude,
          longitude: _position?.longitude ?? current.longitude,
          fotoMasuk: savedPath,
          fotoPulang: current.fotoPulang,
        );
      } else {
        updated = AbsenModel(
          tanggal: todayKey,
          masuk: current.masuk,
          pulang: jamSekarang,
          catatan: current.catatan,
          latitude: _position?.latitude ?? current.latitude,
          longitude: _position?.longitude ?? current.longitude,
          fotoMasuk: current.fotoMasuk,
          fotoPulang: savedPath,
        );
      }

      await box.put(todayKey, updated.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absen ${widget.isMasuk ? 'Masuk' : 'Pulang'} berhasil jam $jamSekarang')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isTelat(String jam) {
    try {
      int h = int.parse(jam.split(':')[0]);
      return h >= 8;
    } catch (_) { return false; }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(appBar: AppBar(title: const Text('Kamera')), body: const Center(child: Text('Kamera tidak tersedia, jalankan di HP Android')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isMasuk ? 'Absen Masuk' : 'Absen Pulang'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Text(
                _position != null ? 'Lokasi: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}' : 'Mencari lokasi GPS...',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : FloatingActionButton.large(
                      backgroundColor: Colors.teal,
                      onPressed: _ambilFotoDanSimpan,
                      child: const Icon(Icons.camera_alt, size: 40),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
