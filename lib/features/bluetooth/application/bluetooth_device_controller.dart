//lib
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//this
import 'package:ble_tutorial/features/bluetooth/domain/bluetooth_device_model.dart';

class BluetoothDeviceController extends StateNotifier<BluetoothDeviceModel> {
  BluetoothDeviceController() : super(BluetoothDeviceModel(remoteId: null, device: null, firmwareMaintainVersion: 1));

  void setDeviceRemoteId(String remoteId) {
    state = state.copyWith(remoteId: remoteId);
  }

  void setDevice(BluetoothDevice d) {
    state = state.copyWith(device: d);
  }

  void setFirmwareMaintainVersion(int v) {
    state = state.copyWith(firmwareMaintainVersion: v);
  }

  String? getDeviceRemoteId() {
    return state.remoteId;
  }

  BluetoothDevice? getDevice() {
    return state.device;
  }

  int getFirmwareMaintainVersion() {
    return state.firmwareMaintainVersion;
  }
}
