import 'package:flutter_blue/flutter_blue.dart';

class DeviceViewModel {
  final List<BluetoothService> deviceServices;
  final int batteryLevel;
  final int heartRate;
  final String filePath;

  DeviceViewModel({this.deviceServices, this.batteryLevel, this.heartRate, this.filePath});
}