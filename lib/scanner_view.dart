
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Scanner_View extends StatefulWidget {
  Scanner_View({Key? key, required this.isProduct}) : super(key: key);

  bool isProduct;

  @override
  State<Scanner_View> createState() => _Scanner_ViewState();
}

class _Scanner_ViewState extends State<Scanner_View> {

  /// Scanner controller
  late MobileScannerController controller;

  @override
  void initState() {
    controller = MobileScannerController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isProduct ? tr('scanner_product') : tr('scanner_qr')),
      ),
      body: Center(
        child: AiBarcodeScanner(
          startDelay: false,
          bottomBarText: widget.isProduct ? tr('scanner_product') : tr('scanner_qr'),
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
          ),
          onScan: (String value) {
            print(value);
            Navigator.pop(context, value);
          },
          onDetect: (BarcodeCapture barcodeCapture) {
           // print(barcodeCapture.raw);
          },
        ),
      ),
    );
  }

}