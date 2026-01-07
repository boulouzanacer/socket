import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanMarketScreen extends StatefulWidget {
  const ScanMarketScreen({Key? key}) : super(key: key);

  @override
  State<ScanMarketScreen> createState() => _ScanMarketScreenState();
}

class _ScanMarketScreenState extends State<ScanMarketScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Market QR"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            //allowDuplicates: false,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  if (isScanning) {
                    isScanning = false; // prevent multiple triggers
                    Navigator.pop(context, code); // return scanned code
                  }
                }
              }
            },
          ),
          // Optional overlay
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
          // Cancel button at the bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
