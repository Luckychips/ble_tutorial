//core
import 'dart:async';
import 'dart:convert';
//lib
import 'package:ble_tutorial/features/bluetooth/application/bluetooth_device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
//this
import 'package:ble_tutorial/config/engine.dart';
import 'package:ble_tutorial/core/domains/core_model.dart';
import 'package:ble_tutorial/core/mixins/patch_connect_listener.dart';
import 'package:ble_tutorial/core/utils/command_parser.dart';
import 'package:ble_tutorial/core/utils/to_number.dart';
import 'package:ble_tutorial/features/bluetooth/provider.dart';

class ConnectedPage extends ConsumerStatefulWidget {
  const ConnectedPage({super.key});

  @override
  ConsumerState<ConnectedPage> createState() => _ConnectedPageState();
}

class _ConnectedPageState extends ConsumerState<ConnectedPage> with PatchConnectListener {
  final Box<CoreModel> coreBox = Hive.box<CoreModel>('core');
  static const String suid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'; // nordic uart service uuid
  late BluetoothDeviceController _controller;
  late int _firmwareMaintainVersion;
  late BluetoothDevice _device;
  late String _remoteId;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;

  late List<int> codeUnits = [];

  final _cmdController = TextEditingController();
  final _digit16Controller = TextEditingController();
  bool _isNormal = false;
  String _deviceName = '';
  String _response = '......';
  String _data = '';

  String _state = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _controller = ref.read(bluetoothDeviceControllerProvider.notifier);
      // _firmwareMaintainVersion = _controller.getFirmwareMaintainVersion();
      // _device = _controller.getDevice()!;
      // setState(() {
      //   _deviceName = _device.platformName;
      // });

      CoreModel scanned = coreBox.get('scanned') as CoreModel;
      _firmwareMaintainVersion = scanned.deviceVersion!;
      _remoteId = scanned.remoteId!;
      _device = BluetoothDevice.fromId(scanned.remoteId.toString());
      reconnect(_remoteId, () {
        _state = 'connect';
      });

      setState(() {
        _deviceName = _device.platformName;
      });

      _connectionStateSubscription = _device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.connected) {
          setState(() {
            _state = 'connect!';
          });
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

                  List<int> inputs = [];
                  if (_cmdController.text.isEmpty) {
                    inputs = codeUnits;
                  } else {
                    inputs = _cmdController.text.codeUnits;
                  }

                  if (isNormalReceived(inputs, value)) {
                    _isNormal = true;
                    final List<int> trimmed = value.sublist(4, value.length - 2);
                    if (hasAscii(_cmdController.text)) {
                      _data = String.fromCharCodes(trimmed);
                    } else {
                      _data = '${convertToInt16BigEndian(trimmed)}';
                    }

                    // _cmdController.text = '';
                  } else {
                    final List<int> trimmed = value.sublist(4, value.length - 2);
                    final List<int> errorCodes = convertToInt16BigEndian(trimmed);
                    if (errorCodes.isNotEmpty) {
                      _data = getErrorMessage(errorCodes[0]);
                    }
                  }
                });
              }
            });

            _device.cancelWhenDisconnected(_lastValueSubscription);
          });
        }

        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            _state = 'disconnect';
          });
        }
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

  Future<void> toListen(String v) async {
    codeUnits = v.codeUnits;
    Future.delayed(const Duration(milliseconds: 500), () async {
      BluetoothService? service = await getConnectedService();
      List<BluetoothCharacteristic> characteristics = service!.characteristics;
      // String v = _cmdController.text;
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
              List<String> text = v.split('?');
              if (text.isNotEmpty && text.length >= 2) {
                String parameter = text[1];
                int n = -1;
                if (hasTransferValue(v)) {
                  List<String> transfer = parameter.split(',');
                  n = int.parse(transfer[0]);
                } else {
                  n = int.parse(parameter);
                }

                if (n >= 0) {
                  bytes.add(0x00);
                  bytes.add(to16(n));
                }

                if (hasTransferValue(v)) {
                  List<String> transfer = parameter.split(',');
                  int value = int.parse(transfer[1]);
                  bytes.addAll(convertToBigEndianInt16(value));
                }
              }
            } else {
              if (hasTransferValue(v)) {
                List<String> text = v.split('?');
                bytes.addAll(convertToBigEndianInt16(int.parse(text[1])));
                // bytes.add(0x00);
                // bytes.add((int.parse(text[1])));
              }
            }

            if (isRequireCrc(v)) {
              List<int> codes = calculateCrc16(bytes);
              bytes.addAll(codes);
              // bytes.add(0x3F);
              // bytes.add(0xC7);
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

            // 7373 663f 002f 03e8 c82d
            // [115, 115, 102, 63, 0, 47, 3, 232, 200, 45]
            // 47, 1000
            // List<int> bytes = [];
            // bytes.add(0x73);
            // bytes.add(0x73);
            // bytes.add(0x66);
            // bytes.add(0x3F);
            // bytes.add(0x00);
            // bytes.add(0x2F);
            // bytes.add(0x03);
            // bytes.add(0xE8);
            // bytes.add(0xC8);
            // bytes.add(0x2D);
            // await characteristics[0].write(bytes, withoutResponse: characteristics[0].properties.writeWithoutResponse);

            // [115, 115, 102, 63, 0, 47, 3, 232, 200, 45]
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
                      List<String> text = value.split('?');
                      if (text.isNotEmpty && text.length >= 2) {
                        List<int> encoded = utf8.encode(text[0]);
                        String parameter = text[1];
                        if (parameter.isNotEmpty) {
                          if (hasTransferValue(value)) {
                          } else {
                            int n = int.parse(parameter);
                            for (int i = 0; i < encoded.length; i++) {
                              output += '${to16With0x(encoded[i])} ';
                            }

                            output += '0x00 ';
                            output += '${to16With0x(n)} ';
                          }
                        }
                      } else {
                        List<int> encoded = utf8.encode(value);
                        for (int i = 0; i < encoded.length; i++) {
                          output += '${to16With0x(encoded[i])} ';
                        }
                      }

                      _digit16Controller.text = output;
                    },
                    onSubmitted: (_) => toListen(_cmdController.text),
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
                  onPressed: () {
                    if (_cmdController.text.isNotEmpty) {
                      toListen(_cmdController.text);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    child: Text(
                      'Send',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300)
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    toListen('sst?');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('ssn?');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('sta?1');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('ssk?8');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('ssl?5000');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('sta?0');
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    child: Text(
                      'Initialize',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300)
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    toListen('sst?');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('sta?1');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    for (int i = 0; i < 48; i++) {
                      await toListen('ssb?$i,155');
                      await Future.delayed(const Duration(milliseconds: 1500));
                    }
                    await toListen('ssn?');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('sag?');
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await toListen('sta?0');
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    child: Text(
                      'Optimize',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300)
                    ),
                  ),
                ),
              ]
            ),
            Column(
              children: [
                Text(_state),
                const SizedBox(height: 12),
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
