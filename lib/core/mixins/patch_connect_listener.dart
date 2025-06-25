//core
import 'dart:async';
//lib
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//this
import 'package:ble_tutorial/core/utils/device_communication.dart';

mixin PatchConnectListener<T extends StatefulWidget> on State<T> {
  late BluetoothDevice connectedDevice;
  bool isConnected = false;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;

  @override
  void initState() {
    super.initState();
  }

  void reconnect(String remoteId, Function callback) async {
    if (isConnected) return;

    try {
      connectedDevice = BluetoothDevice.fromId(remoteId);
      isConnected = await toConnect(connectedDevice);
      if (isConnected) {
        callback();
        Fluttertoast.showToast(msg: '장치와 연결되었습니다.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '장치와 연결되지 않았습니다.');
    }

    connectionSubscription ??= connectedDevice.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.disconnected) {
        Fluttertoast.showToast(msg: '장치와의 접속이 끊어졌습니다.');
        isConnected = false;
        await connectedDevice.disconnect();
        Future.delayed(const Duration(seconds: 5), () => reconnect(remoteId, callback));
      }
    });
  }
}