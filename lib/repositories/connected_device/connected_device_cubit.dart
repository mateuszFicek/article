import 'package:band_parameters_reader/data/blue_manager.dart';
import 'package:band_parameters_reader/repositories/connected_device/device_view_model.dart';
import 'package:band_parameters_reader/utils/ble_gatt_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';

part 'connected_device_state.dart';

class ConnectedDeviceCubit extends Cubit<ConnectedDeviceState> {
  final BuildContext context;

  ConnectedDeviceCubit(this.context) : super(ConnectedDeviceInitial());

  void removeDevice(BluetoothDevice device) {
    final devices = state.connectedDevices.toList();
    devices.remove(device);
    emit(state.copyWith(connectedDevice: devices));
  }

  void setUsername(String name) {
    emit(state.copyWith(username: name));
  }

  void setConnectedDevice(BluetoothDevice device, BuildContext buildContext) async {
    final isConnected = await BlueManager().connectToDevice(device, buildContext);
    final devices = state.connectedDevices.toList();
    devices.add(device);
    if (isConnected == 2)
      emit(state.copyWith(connectedDevice: devices, currentDevice: devices.first));
  }

  void setCurrentDevice(BluetoothDevice device) {
    emit(state.copyWith(currentDevice: device));
  }

  Future<List<BluetoothService>> getDeviceServices(
      BluetoothDevice device, BuildContext context) async {
    final services = await BlueManager().discoverDeviceServices(device);
    return services;
  }

  void setListenerForCharacteristics(BluetoothDevice device, BluetoothCharacteristic characteristic,
      String filePath, BuildContext context) async {
    BlueManager().setListener(device, characteristic, filePath, context);
  }

  void disableListenerForCharacteristics(BluetoothCharacteristic characteristic) {
    BlueManager().disableListener(characteristic);
  }

  disconnectFromDevice() {
    emit(ConnectedDeviceInitial());
  }

  void initDevice(BuildContext buildContext) async {
    Map<BluetoothDevice, DeviceViewModel> viewModels = {};
    print("Initing devices");
    if (state.connectedDevices != null) {
      for (BluetoothDevice device in state.connectedDevices) {
        final services = await getDeviceServices(device, context);
        final batteryLevel = await getBatteryLevel(services);
        String dir = (await getExternalStorageDirectory()).absolute.path + "/";
        final filePath = dir + state.username + "device:${device.name.substring(0, 1)}" + ".csv";

        _setHeartRateListener(device, services, filePath, buildContext);

        final vModel = DeviceViewModel(
            deviceServices: services, batteryLevel: batteryLevel, filePath: filePath);
        viewModels.putIfAbsent(device, () => vModel);
      }
    }
    emit(state.copyWith(viewModels: viewModels));
  }

  void _setHeartRateListener(BluetoothDevice device, List<BluetoothService> services,
      String filePath, BuildContext buildContext) {
    try {
      final heartRateService =
          BlueManager().findService(services, BleGATTServices.HEART_RATE_SERVICE);

      final heartRateCharacteristic = heartRateService.characteristics.firstWhere(
          (element) =>
              element.uuid.toString().contains(BleGATTCharacteristics.HEART_RATE_MEASURMENT),
          orElse: null);
      setListenerForCharacteristics(device, heartRateCharacteristic, filePath, buildContext);
    } catch (e) {
      print(e);
    }
  }

  void setDeviceHeartRate(BluetoothDevice device, int heartRate) {
    Map<BluetoothDevice, DeviceViewModel> viewModels = state.viewModels;
    DeviceViewModel model = viewModels[device];
    DeviceViewModel newModel = DeviceViewModel(
        batteryLevel: model.batteryLevel,
        deviceServices: model.deviceServices,
        filePath: model.filePath,
        heartRate: heartRate);
    viewModels.update(device, (value) => newModel);
    print(viewModels.values.map((e) => e.heartRate).toList());
    emit(state.copyWith(viewModels: viewModels));
  }

  Future<int> getBatteryLevel(List<BluetoothService> services) async {
    final batteryService = BlueManager().findService(services, BleGATTServices.BATTERY_SERVICE);
    try {
      final currentBattery = await BlueManager().getDeviceBatteryLevel(
          batteryService.characteristics.firstWhere(
              (element) => element.uuid.toString().contains(BleGATTCharacteristics.BATTERY_LEVEL),
              orElse: null),
          context);
      return currentBattery;
    } catch (e) {
      print(e);
      return 0;
    }
  }
}
