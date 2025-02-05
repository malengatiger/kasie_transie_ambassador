// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
// import 'package:kasie_transie_library/utils/functions.dart';
//
// void main() => runApp(ScannerX1());
//
// class ScannerX1 extends StatefulWidget {
//   const ScannerX1({super.key});
//
//   @override
//   ScannerX1State createState() => ScannerX1State();
// }
//
// class ScannerX1State extends State<ScannerX1> {
//   String _scanBarcode = 'Unknown';
//   static const mm = '🔵🔵🔵🔵 ScannerX1 🐸 🔵🔵';
//
//   @override
//   void initState() {
//     super.initState();
//     pp('$mm initState ....');
//     startBarcodeScanStream();
//   }
//
//   Future<void> startBarcodeScanStream() async {
//     pp('$mm startBarcodeScanStream ....');
//     FlutterBarcodeScanner.getBarcodeStreamReceiver(
//             '#ff6666', 'Cancel', true, ScanMode.BARCODE)!
//         .listen((barcode) => pp(barcode));
//   }
//
//   Future<void> scanQR() async {
//     pp('$mm scanQR ....');
//     String barcodeScanRes;
//     // Platform messages may fail, so we use a try/catch PlatformException.
//     try {
//       barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
//           '#ff6666', 'Cancel', true, ScanMode.QR);
//       pp('$mm barcodeScanRes: $barcodeScanRes');
//     } on PlatformException {
//       barcodeScanRes = 'Failed to get platform version.';
//     }
//
//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) return;
//
//     setState(() {
//       _scanBarcode = barcodeScanRes;
//     });
//   }
//
//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> scanBarcodeNormal() async {
//     pp('$mm scanBarcodeNormal ....');
//     String barcodeScanRes;
//     // Platform messages may fail, so we use a try/catch PlatformException.
//     try {
//       barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
//           '#ff6666', 'Cancel', true, ScanMode.BARCODE);
//       print(barcodeScanRes);
//     } on PlatformException {
//       barcodeScanRes = 'Failed to get platform version.';
//     }
//
//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) return;
//
//     setState(() {
//       _scanBarcode = barcodeScanRes;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: const Text('Barcode scan')),
//         body: Builder(builder: (BuildContext context) {
//           return Container(
//               alignment: Alignment.center,
//               child: Flex(
//                   direction: Axis.vertical,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: <Widget>[
//                     ElevatedButton(
//                         onPressed: () => scanBarcodeNormal(),
//                         child: Text('Start barcode scan')),
//                     ElevatedButton(
//                         onPressed: () => scanQR(),
//                         child: Text('Start QR scan')),
//                     ElevatedButton(
//                         onPressed: () => startBarcodeScanStream(),
//                         child: Text('Start barcode scan stream')),
//                     Text('Scan result : $_scanBarcode\n',
//                         style: TextStyle(fontSize: 20))
//                   ]));
//         }));
//   }
// }
