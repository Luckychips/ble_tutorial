// lib
import 'package:flutter_riverpod/flutter_riverpod.dart';
// this
import 'package:ble_tutorial/features/bluetooth/application/bluetooth_device_controller.dart';
import 'package:ble_tutorial/features/bluetooth/domain/bluetooth_device_model.dart';

final bluetoothDeviceControllerProvider = StateNotifierProvider<BluetoothDeviceController, BluetoothDeviceModel>((ref) => BluetoothDeviceController());