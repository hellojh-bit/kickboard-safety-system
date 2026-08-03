import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MyCameraView extends StatefulWidget {
  const MyCameraView({super.key});

  @override
  State<MyCameraView> createState() => _MyCameraViewState();
}

class _MyCameraViewState extends State<MyCameraView> {
  // 컨트롤러를 선언해서 직접 제어합니다.
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;
  @override
  void dispose() {
    controller.dispose(); // 화면 닫힐 때 스캐너 자원 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 제목을 하얀색으로 유지
        title: const Text("킥보드 QR 스캔", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 버튼도 하얀색
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) async {
          if (_isScanned) return;

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;

          final String? code = barcodes.first.rawValue;
          if (code == null) return;

          _isScanned = true;
          await controller.stop();

          if (!context.mounted) return;
          Navigator.pop(context, code);
        },
      ),
    );
  }
}
