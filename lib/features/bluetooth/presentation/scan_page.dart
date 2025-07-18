//core
import 'dart:async';
import 'dart:io';
//lib
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loading_indicator/loading_indicator.dart';
//this
import 'package:ble_tutorial/config/engine.dart';
import 'package:ble_tutorial/core/domains/core_model.dart';
import 'package:ble_tutorial/core/utils/debug_logger.dart';
import 'package:ble_tutorial/core/utils/device_communication.dart';
import 'package:ble_tutorial/features/bluetooth/application/bluetooth_device_controller.dart';
import 'package:ble_tutorial/features/bluetooth/presentation/connected_page.dart';
import 'package:ble_tutorial/features/bluetooth/provider.dart';

const List<Color> _kDefaultRainbowColors = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
];

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final Box<CoreModel> coreBox = Hive.box<CoreModel>('core');

  late BluetoothDeviceController _controller;
  late List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late bool _isScanning = false;

  // final regex = RegExp(
  //   r'^[0-9]{4}[A-Z]{2}(January|February|March|April|May|June|July|August|September|October|November|December)[0-9]{3}$',
  //   caseSensitive: false,
  // );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _controller = ref.read(bluetoothDeviceControllerProvider.notifier);
        CoreModel scanned = coreBox.get('scanned') as CoreModel;
        if (scanned.remoteId != null) {
          _controller.setDeviceRemoteId(scanned.remoteId.toString());
          BluetoothDevice d = BluetoothDevice.fromId(scanned.remoteId.toString());
          toConnect(d).then((isConnected) async {
            if (mounted && isConnected) {
              _controller.setDevice(d);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConnectedPage()));
            }
          });
        }
      } catch (e) {}
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((peripheral) async {
      _scanResults.clear();
      if (peripheral.isNotEmpty) {
        for (var x in peripheral) {
          BluetoothDevice device = x.device;
          String deviceName = device.platformName.toLowerCase();
          if (getFirstVersionNames().any(deviceName.contains) || getSecondVersionNames().any(deviceName.contains)) {
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

  void select(BluetoothDevice d) async {
    await FlutterBluePlus.stopScan();
    if (await toConnect(d) && await toBonding(d)) {
      if (mounted) {
        setState(() {
          String deviceName = d.platformName.toLowerCase();
          int deviceVersion = 0;
          if (getFirstVersionNames().any(deviceName.contains)) {
            deviceVersion = 1;
          } else if (getSecondVersionNames().any(deviceName.contains)) {
            deviceVersion = 2;
          }

          if (deviceVersion > 0) {
            _controller.setFirmwareMaintainVersion(deviceVersion);
            final model = CoreModel(remoteId: d.remoteId.str, deviceVersion: deviceVersion);
            coreBox.put('scanned', model);
          }

          _controller.setDeviceRemoteId(d.remoteId.str);
          _controller.setDevice(d);
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              child: Text(
                'Start Scan',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300)
              ),
            )
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final device = _scanResults[index].device;
                return ListTile(
                  title: Text(device.platformName.isEmpty ? 'Unknown Device' : device.platformName),
                  subtitle: Text(device.remoteId.str.toString()),
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