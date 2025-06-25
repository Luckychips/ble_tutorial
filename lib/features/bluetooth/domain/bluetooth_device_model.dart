//lib
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel {
  final String? remoteId;
  final BluetoothDevice? device;
  final int firmwareMaintainVersion;

  BluetoothDeviceModel({ required this.remoteId, required this.device, required this.firmwareMaintainVersion });

  BluetoothDeviceModel copyWith({ String? remoteId, BluetoothDevice? device, int? firmwareMaintainVersion }) {
    return BluetoothDeviceModel(
      remoteId: remoteId ?? this.remoteId,
      device: device ?? this.device,
      firmwareMaintainVersion: firmwareMaintainVersion ?? this.firmwareMaintainVersion,
    );
  }
}