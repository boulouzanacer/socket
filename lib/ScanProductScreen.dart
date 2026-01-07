import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({Key? key}) : super(key: key);

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool isTorchOn = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product Barcode"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            //allowDuplicates: false,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && isScanning) {
                  isScanning = false;
                  Navigator.pop(context, code);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context, "-1"),
                child: const Text("Cancel"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
