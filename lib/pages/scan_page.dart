import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import 'package:ble_tutorial/pages/connected_page.dart';
import 'package:ble_tutorial/states/providers/bluetooth_model.dart';
import 'package:ble_tutorial/utils/debug_logger.dart';

const List<Color> _kDefaultRainbowColors = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
];

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _BetweenPageState();
}

class _BetweenPageState extends State<ScanPage> {
  late List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((peripheral) async {
      _scanResults.clear();

      if (peripheral.isNotEmpty) {
        for (var x in peripheral) {
          BluetoothDevice device = x.device;
          String deviceName = device.platformName.toLowerCase();
          if (deviceName.contains('bladder') || deviceName.contains('medi')) {
            if (_scanResults.indexWhere((element) => element.device.remoteId == x.device.remoteId) < 0) {
              _scanResults.add(x);
            }
          }
        }
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });


  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future<bool> toConnect(BluetoothDevice d) async {
    bool isConnected = false;
    try {
      await d.connect(mtu: null, timeout: const Duration(hours: 10));
      List<BluetoothService> discoverList = await d.discoverServices();
      if (discoverList.isNotEmpty) {
        isConnected = true;
      }
    } catch (e) {
      isConnected = false;
    }

    return isConnected;
  }

  Future<bool> toBonding(BluetoothDevice d) async {
    bool isBonded = false;
    if (Platform.isAndroid) {
      try {
        await d.createBond();
        isBonded = true;
      } catch (e) {
        isBonded = false;
      }
    } else {
      isBonded = true;
    }

    return isBonded;
  }


  void select(BluetoothDevice d) async {
    await FlutterBluePlus.stopScan();
    if (await toConnect(d) && await toBonding(d)) {
      if (mounted) {
        setState(() {
          context.read<BluetoothModel>().device = d;
        });

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConnectedPage()));
      }
    }
  }

  Future startScan() async {
    _scanResults = [];
    int divisor = Platform.isAndroid ? 8 : 1;
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      continuousUpdates: true,
      continuousDivisor: divisor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Scan Page', textAlign: TextAlign.center),
      ),
      body: _isScanning ?
      const Center(
        child: LoadingIndicator(
          indicatorType: Indicator.ballScaleMultiple,
          colors: _kDefaultRainbowColors,
          strokeWidth: 4.0,
          pathBackgroundColor: Colors.black45,
        ),
      ) :
      Column(
        children: [
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: startScan,
            child: const Text('Start Scan'),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final device = _scanResults[index].device;
                return ListTile(
                  title: Text(device.platformName.isEmpty ? 'Unknown Device' : device.platformName),
                  subtitle: Text(device.id.toString()),
                  onTap: () async {
                    try {
                      select(device);
                    } catch (e) {
                      logger.d('$e');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}