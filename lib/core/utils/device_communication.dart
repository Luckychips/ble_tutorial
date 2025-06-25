//core
import 'dart:io';
//lib
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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