import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class CommuterScanner extends StatefulWidget {
  const CommuterScanner({super.key});

  @override
  CommuterScannerState createState() => CommuterScannerState();
}

class CommuterScannerState extends State<CommuterScanner>
    with WidgetsBindingObserver {
  // Remove SingleTickerProviderStateMixin (not needed)
  final MobileScannerController mobileScanController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    // Remove autoStart: true  (we'll handle starting manually)
  );
  static const mm = '🍄🍄🍄🍄CommuterScanner 🍄';
  StreamSubscription<BarcodeCapture>? barcodeSubscription; // Correct type

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission(); // Request permission first
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status == PermissionStatus.granted) {
      pp('$mm camera permission granted, starting scanner ..');
      _startScanner();
    } else {
      pp('$mm Camera permission $status');
      // Handle permission denial or show a message
      // ... your permission handling logic
    }
  }

  Future<void> _startScanner() async {
    try {
      await mobileScanController.start(); // Start the scanner FIRST
      pp('$mm mobileScanController started ...');

      barcodeSubscription = mobileScanController.barcodes.listen(
            (barcodeCapture) {  // Start listening for barcode detections
              pp('$mm barcodeSubscription delivers . barcodeCapture ..');
              var barcode = barcodeCapture.barcodes[0];
              _onDetect(barcode);
        },
        onError: (error) {
          // Handle errors here
          pp('$mm 😈😈😈Error during barcode scan: $error');
          // Consider showing an error message to the user
        },
        cancelOnError: false,  // Don't cancel the stream on errors. Adjust as needed.
      );

      setState(() {}); // Rebuild to show scanner UI
    } catch (e) {
      pp('$mm 😈😈😈😈Error starting scanner: $e');
      if (mounted) {
        showErrorToast(message: '😈😈 Error starting scanner: $e', context: context);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ... (No changes needed in this method. Let it handle pausing and resuming)
    // ... but the logic inside _startScanner and the removal of the other
    // ... start calls will handle the actual starting and stopping of the scanner.
  }

  @override
  void dispose() {
    mobileScanController.dispose(); // Dispose the controller
    barcodeSubscription?.cancel(); // Cancel the subscription
    WidgetsBinding.instance.removeObserver(this); // Remove the observer
    super.dispose();
  }

  void _onDetect(Barcode barcode) {
    // Correct parameter type
    pp('$mm _onDetect: detected barcode: ${barcode.rawValue}');
    Navigator.of(context).pop(barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commuter Scanner'),
        actions: [
          // Remove the IconButton - starting is now handled in initState and permissions
        ],
      ),
      body: SafeArea(
        child: MobileScanner(
          controller: mobileScanController,
          onDetect: (capture) => _onDetect(capture.barcodes[0]),
        ),
      ),
    );
  }
}
