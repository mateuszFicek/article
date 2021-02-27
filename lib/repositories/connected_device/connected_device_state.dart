part of 'connected_device_cubit.dart';

@immutable
class ConnectedDeviceState {
  final String username;
  final List<BluetoothDevice> connectedDevices;
  final Map<BluetoothDevice, DeviceViewModel> viewModels;
  final BluetoothDevice currentDevice;

  ConnectedDeviceState({this.username, this.connectedDevices, this.currentDevice, this.viewModels});

  ConnectedDeviceState copyWith(
      {String username,
      List<BluetoothDevice> connectedDevice,
      BluetoothDevice currentDevice,
      Map<BluetoothDevice, DeviceViewModel> viewModels}) {
    return ConnectedDeviceState(
      username: username ?? this.username,
      connectedDevices: connectedDevice ?? this.connectedDevices,
      currentDevice: currentDevice ?? this.currentDevice,
      viewModels: viewModels ?? this.viewModels,
    );
  }
}

class ConnectedDeviceInitial extends ConnectedDeviceState {
  ConnectedDeviceInitial()
      : super(
          username: "",
          connectedDevices: [],
          viewModels: {},
          currentDevice: null,
        );
}
