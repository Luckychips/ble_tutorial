// core
import 'dart:async';
import 'dart:convert';
// lib
import 'package:ble_tutorial/features/bluetooth/application/bluetooth_device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// this
import 'package:ble_tutorial/core/utils/command_parser.dart';
import 'package:ble_tutorial/core/utils/to_number.dart';
import 'package:ble_tutorial/features/bluetooth/provider.dart';

class ConnectedPage extends ConsumerStatefulWidget {
  const ConnectedPage({super.key});

  @override
  ConsumerState<ConnectedPage> createState() => _ConnectedPageState();
}

class _ConnectedPageState extends ConsumerState<ConnectedPage> {
  static const String suid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'; // nordic uart service uuid
  late BluetoothDeviceController _controller;
  late int _firmwareMaintainVersion;
  late BluetoothDevice _device;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;

  final _cmdController = TextEditingController();
  final _digit16Controller = TextEditingController();
  bool _isNormal = false;
  String _deviceName = '';
  String _response = '......';
  String _data = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _controller = ref.read(bluetoothDeviceControllerProvider.notifier);
      _firmwareMaintainVersion = _controller.getFirmwareMaintainVersion();
      _device = _controller.getDevice()!;
      setState(() {
        _deviceName = _device.platformName;
      });

      _connectionStateSubscription = _device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.connected) {
          Future.delayed(const Duration(milliseconds: 1500), () async {
            BluetoothService? service = await getConnectedService();
            List<BluetoothCharacteristic> characteristics = service!.characteristics;
            characteristics[1].setNotifyValue(true);
            _lastValueSubscription = characteristics[1].lastValueStream.listen((value) {
              String converted = '';
              switch (_firmwareMaintainVersion) {
                case 1:
                  converted = utf8.decode(value).trimRight();
                  break;
                case 2:
                  List<int> asciiBytes = value.where((byte) => byte >= 0 && byte <= 127).toList();
                  converted = ascii.decode(asciiBytes);
                  break;
              }

              _isNormal = false;
              if (mounted && converted.isNotEmpty) {
                setState(() {
                  // _response = converted;
                  List<String> messages = converted.split(':');
                  if (messages.isNotEmpty) {
                    _response = messages[0];
                  }

                  if (isNormalReceived(_cmdController.text.codeUnits, value)) {
                    _isNormal = true;
                    final List<int> trimmed = value.sublist(4, value.length - 2);
                    if (hasAscii(_cmdController.text)) {
                      _data = String.fromCharCodes(trimmed);
                    } else {
                      _data = '${convertToInt16BigEndian(trimmed)}';
                    }

                    // _cmdController.text = '';
                  }
                });
              }
            });

            _device.cancelWhenDisconnected(_lastValueSubscription);
          });
        }

        if (state == BluetoothConnectionState.disconnected) {}
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectionStateSubscription.cancel();
    _lastValueSubscription.cancel();
  }

  Future<BluetoothService?> getConnectedService() async {
    BluetoothService? service;
    List<BluetoothService> discoverList = await _device.discoverServices();
    for (var x in discoverList) {
      if (_firmwareMaintainVersion == 1) {
        if (x.uuid.toString().toUpperCase() == suid) {
          service = x;
        }
      } else if (_firmwareMaintainVersion == 2) {
        if (x.uuid.toString().toUpperCase() == suid) {
          service = x;
        }
      }
    }

    return service;
  }

  void toListen() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      BluetoothService? service = await getConnectedService();
      List<BluetoothCharacteristic> characteristics = service!.characteristics;
      String v = _cmdController.text;
      switch (_firmwareMaintainVersion) {
        case 1:
          await characteristics[0].write(utf8.encode('$v@'), withoutResponse: characteristics[0].properties.writeWithoutResponse);
          break;
        case 2:
          try {
            List<int> encoded = utf8.encode(v);
            List<int> bytes = [];
            for (int i = 0; i < 4; i++) {
              bytes.add(to16(encoded[i]));
            }

            if (hasParameter(v)) {
              List<String> spliced = v.split('?');
              if (spliced.isNotEmpty && spliced.length >= 2) {
                int n = int.parse(spliced[1]);
                bytes.add(0x00);
                bytes.add(to16(n));
              }
            }

            if (isRequireCrc(v)) {
              bytes.add(0x3F);
              bytes.add(0xC7);
            }

            // List<int> bytes = [];
            // bytes.add(0x73);
            // bytes.add(0x74);
            // bytes.add(0x61);
            // bytes.add(0x3F);
            // bytes.add(0x00);
            // bytes.add(0x01);
            // bytes.add(0x3F);
            // bytes.add(0xC7);

            if (isReadyCommand(bytes)) {
              await characteristics[0].write(bytes, withoutResponse: characteristics[0].properties.writeWithoutResponse);
            }
          } catch (e) {
            print(e);
          }

          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_deviceName, textAlign: TextAlign.center),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _cmdController,
                    textInputAction: TextInputAction.done,
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xffF5FAFF),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xffBBC2C9), width: 1.0)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff00DCA0))),
                      contentPadding: EdgeInsets.all(10),
                    ),
                    onChanged: (String value) {
                      String output = '';
                      List<String> spliced = value.split('?');
                      if (spliced.isNotEmpty && spliced.length >= 2) {
                        int n = int.parse(spliced[1]);
                        List<int> encoded = utf8.encode(spliced[0]);
                        for (int i = 0; i < encoded.length; i++) {
                          output += '${to16With0x(encoded[i])} ';
                        }

                        output += '0x00 ';
                        output += '${to16With0x(n)} ';
                      } else {
                        List<int> encoded = utf8.encode(value);
                        for (int i = 0; i < encoded.length; i++) {
                          output += '${to16With0x(encoded[i])} ';
                        }
                      }

                      _digit16Controller.text = output;
                    },
                    onSubmitted: (_) => toListen(),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _digit16Controller,
                    enabled: false,
                    textInputAction: TextInputAction.done,
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xffF5FAFF),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                    ),
                    onSubmitted: (_) {},
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: toListen,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    child: Text(
                        'Send',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300)
                    ),
                  ),
                ),
              ]
            ),
            Column(
              children: [
                Text(_response, style: TextStyle(fontSize: 20.sp)),
                const SizedBox(height: 12),
                Text(
                  '$_isNormal',
                  style: TextStyle(fontSize: 20.sp, color: _isNormal ? Colors.black : Colors.redAccent),
                ),
                const SizedBox(height: 12),
                Text(_data, style: TextStyle(fontSize: 16.sp)),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
