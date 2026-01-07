
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
        child: MobileScanner(
          onDetect: (barcodeCapture) {
            final barcode = barcodeCapture.barcodes.first;
            final value = barcode.rawValue ?? '---';
            print('Scanned: $value');

            Navigator.pop(context, value);
          },
        ),
      ),
    );
  }

}