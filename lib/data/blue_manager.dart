import 'dart:io';

import 'package:band_parameters_reader/models/measure.dart';
import 'package:band_parameters_reader/repositories/connected_device/connected_device_cubit.dart';
import 'package:band_parameters_reader/repositories/measurment/measurment_cubit.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:share/share.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlueManager {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devices = [];
  List<BluetoothService> services = [];
  int value = 0;

  // SCAN FOR AVAILABLE DEVICES
  Future<List<BluetoothDevice>> scanForAvailableDevices() async {
    final List<BluetoothDevice> availableDevices = [];
    final connectedDevices = await flutterBlue.connectedDevices;
    availableDevices.addAll(connectedDevices);
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    final scanResults = flutterBlue.scanResults;
    scanResults.listen((results) {
      for (ScanResult result in results) {
        availableDevices.add(result.device);
      }
    });
    await Future.delayed(Duration(seconds: 4));
    flutterBlue.stopScan();
    return availableDevices;
  }

  // CONNECT TO DEVICE
  Future<int> connectToDevice(BluetoothDevice device, BuildContext context) async {
    try {
      await device.connect();
    } catch (e) {
      print(e);
    }
    final state = await device.state.first;
    return state.index;
  }

  // DISCOVER DEVICE SERVICES
  Future<List<BluetoothService>> discoverDeviceServices(BluetoothDevice device) async {
    final serv = await device.discoverServices();
    return serv;
  }

  setListener(BluetoothDevice device, BluetoothCharacteristic characteristic, String filePath,
      BuildContext context) async {
    String fullPath = filePath;
    List<List<dynamic>> rows = [];

    File file = new File(fullPath);
    int id = 0;

    await characteristic.setNotifyValue(true);
    characteristic.value.listen((vue) async {
      if (vue.length > 0 && vue[1] != null && context.bloc<MeasurmentCubit>().state.isMeasuring) {
        context.bloc<ConnectedDeviceCubit>().setDeviceHeartRate(device, vue[1]);
        List<dynamic> row = List();
        row.add(id);
        row.add(vue[1]);
        row.add(DateTime.now().toString());
        rows.add(row);
        String csv = ListToCsvConverter().convert(rows) + '\n';
        rows.clear();
        await file.writeAsString(csv, mode: FileMode.append);
        context
            .bloc<MeasurmentCubit>()
            .addHeartbeatMeasurment(device, Measure(date: DateTime.now(), measure: vue[1], id: id));
        id++;
      }
    });
  }

  shareFile(String filePath) async {
    await Share.shareFiles([filePath], text: 'Measurment');
  }

  disableListener(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(false);
  }

  // CLOSE DEVICE CONNECTION
  closeConnection(BluetoothDevice device) async {
    device.disconnect();
  }

  BluetoothService findService(List<BluetoothService> services, String serviceUUID) {
    try {
      final service = services
          .firstWhere((element) => element.uuid.toString().contains(serviceUUID), orElse: null);
      return service;
    } catch (e) {
      print(e);
    }
  }

  Future<int> getDeviceBatteryLevel(
      BluetoothCharacteristic characteristic, BuildContext context) async {
    final canRead = await characteristic.properties.read;
    if (canRead) {
      final batteryValues = await characteristic.read();
      return batteryValues[0];
    }
    return 0;
  }
}
