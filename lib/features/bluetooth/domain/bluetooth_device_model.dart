// lib
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel {
  final BluetoothDevice? device;
  final int firmwareMaintainVersion;

  BluetoothDeviceModel({ required this.device, required this.firmwareMaintainVersion });

  BluetoothDeviceModel copyWith({ BluetoothDevice? device, int? firmwareMaintainVersion }) {
    return BluetoothDeviceModel(
      device: device ?? this.device,
      firmwareMaintainVersion: firmwareMaintainVersion ?? this.firmwareMaintainVersion,
    );
  }
}