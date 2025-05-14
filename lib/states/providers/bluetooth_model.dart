import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothModel with ChangeNotifier {
  late BluetoothDevice _device;

  BluetoothDevice get device => _device;

  set device(BluetoothDevice d) {
    _device = d;
    notifyListeners();
  }
}