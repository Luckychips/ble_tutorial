import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class BetweenPage extends StatefulWidget {
  const BetweenPage({super.key});

  @override
  State<BetweenPage> createState() => _BetweenPageState();
}

class _BetweenPageState extends State<BetweenPage> {
  late List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) async {
      if (results.isNotEmpty) {
        _scanResults = results;
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) { // is scanning 을 listen
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future startScan() async {
    int divisor = Platform.isAndroid ? 8 : 1;
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      continuousUpdates: true,
      continuousDivisor: divisor,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      body: Column(
        children: [
          Text(_isScanning ? 'scanning...' : 'done!'),
          ElevatedButton(
            onPressed: startScan,
            child: const Text('Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final device = _scanResults[index].device;
                return ListTile(
                  title: Text(device.name.isEmpty
                      ? "Unknown Device"
                      : device.name),
                  subtitle: Text(device.id.toString()),
                  onTap: () => {},
                );
              },
            ),
          ),
        ]
      )
    );
  }
}
