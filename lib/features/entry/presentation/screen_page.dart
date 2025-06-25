//core
import 'dart:async';
//lib
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
//this
import 'package:ble_tutorial/core/utils/debug_logger.dart';
import 'package:ble_tutorial/features/bluetooth/presentation/scan_page.dart';

class ScreenPage extends StatefulWidget {
  const ScreenPage({super.key});

  @override
  State<ScreenPage> createState() => _ScreenPageState();
}

class _ScreenPageState extends State<ScreenPage> {

  @override
  void initState() {
    super.initState();
    redirectPage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkBLEPermission() async {
    if (!await FlutterBluePlus.isSupported) {
      logger.d('Bluetooth not supported by this device.');
      return;
    }

    final status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      logger.d('Denied');
      await Permission.bluetoothScan.request();
    }
  }

  void redirectPage() {
    checkBLEPermission().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ScanPage()));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('', textAlign: TextAlign.center),
      ),
      body: const Center(
        child: Column(
          children: [],
        ),
      ),
    );
  }
}
