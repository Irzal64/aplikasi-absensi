import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  // Menginisialisasi kamera yang tersedia di perangkat
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Menggunakan kamera belakang secara default (_cameras![0])
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false, // Ubah ke true jika ingin merekam suara
        );

        await _controller!.initialize();
        
        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        debugPrint("Kamera tidak ditemukan pada perangkat.");
      }
    } catch (e) {
      debugPrint("Error saat inisialisasi kamera: \$e");
    }
  }

  // Menangani lifecycle aplikasi (misal: saat aplikasi diminimize)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // Fungsi untuk mengambil foto
    // Fungsi untuk mengambil foto
    Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isTakingPicture) {
      return;
    }

    try {
      // 1. Mengambil foto tanpa menyimpannya ke variabel yang tidak terpakai jika hanya untuk debug
      final XFile picture = await _controller!.takePicture();
      
      // Menggunakan variabel 'picture' di debugPrint agar warning hilang
      debugPrint("Foto berhasil disimpan di: ${picture.path}");
      
      if (!mounted) return;

      // 2. Menambahkan keyword 'const' pada widget Text di dalam SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto berhasil diambil!"),
        ),
      );
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kamera'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                // Live preview kamera fullscreen
                Center(
                  child: CameraPreview(_controller!),
                ),
                // Tombol capture di bagian bawah
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _takePicture,
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
