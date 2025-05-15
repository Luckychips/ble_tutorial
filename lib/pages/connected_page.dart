// core
import 'dart:async';
import 'dart:convert';
// lib
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
// this
import 'package:ble_tutorial/states/providers/bluetooth_model.dart';

class ConnectedPage extends StatefulWidget {
  const ConnectedPage({super.key});

  @override
  State<ConnectedPage> createState() => _ConnectedPageState();
}

class _ConnectedPageState extends State<ConnectedPage> {
  static const String suid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'; // nordic uart service uuid

  late BluetoothDevice _device;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;

  final _cmdController = TextEditingController();
  String _text = '......';

  @override
  void initState() {
    super.initState();
    _device = context.read<BluetoothModel>().device;
    _connectionStateSubscription = _device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        Future.delayed(const Duration(milliseconds: 1500), () async {
          BluetoothService? service;
          for (var x in await _device.discoverServices()) {
            if (x.uuid.toString().toUpperCase() == suid) {
              service = x;
              break;
            }
          }

          List<BluetoothCharacteristic> characteristics = service!.characteristics;
          characteristics[1].setNotifyValue(true);
          _lastValueSubscription = characteristics[1].lastValueStream.listen((value) {
            String converted = utf8.decode(value).trimRight();
            if (mounted && converted.isNotEmpty) {
              setState(() { _text = converted; });
            }
          });

          _device.cancelWhenDisconnected(_lastValueSubscription);
        });
      }

      if (state == BluetoothConnectionState.disconnected) {
        print('disconnected');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectionStateSubscription.cancel();
    _lastValueSubscription.cancel();
  }

  void toListen() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      BluetoothService? service;
      for (var x in await _device.discoverServices()) {
        if (x.uuid.toString().toUpperCase() == suid) {
          service = x;
          break;
        }
      }

      List<BluetoothCharacteristic> characteristics = service!.characteristics;
      await characteristics[0].write(utf8.encode('${_cmdController.text}@'), withoutResponse: characteristics[0].properties.writeWithoutResponse);
      _cmdController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Connected Page', textAlign: TextAlign.center),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 60,
              child: TextField(
                controller: _cmdController,
                textInputAction: TextInputAction.done,
                cursorColor: Colors.transparent,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xffF5FAFF),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xffBBC2C9), width: 1.0)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff00DCA0))),
                  contentPadding: EdgeInsets.all(30),
                ),
                onSubmitted: (_) {},
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: toListen,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  child: Text(
                    'Send',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300)
                  ),
                )
            ),
            const SizedBox(height: 36),
            Text(_text),
          ],
        ),
      ),
    );
  }
}
