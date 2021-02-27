import 'package:band_parameters_reader/repositories/available_devices/available_devices_cubit.dart';
import 'package:band_parameters_reader/repositories/bluetooth_devices/bluetooth_devices_cubit.dart';
import 'package:band_parameters_reader/repositories/connected_device/connected_device_cubit.dart';
import 'package:band_parameters_reader/ui/connected_device/connected_device.dart';
import 'package:band_parameters_reader/utils/colors.dart';
import 'package:band_parameters_reader/widgets/custom_button.dart';
import 'package:band_parameters_reader/widgets/information_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BluetoothLEDevices extends StatefulWidget {
  BluetoothLEDevices({Key key}) : super(key: key);

  @override
  _BluetoothLEDevicesState createState() => _BluetoothLEDevicesState();
}

class _BluetoothLEDevicesState extends State<BluetoothLEDevices>
    with AutomaticKeepAliveClientMixin<BluetoothLEDevices> {
  bool isSearchingForBLE = true;
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.bloc<AvailableDevicesCubit>().toggleIsScanning();
      context.bloc<AvailableDevicesCubit>().getAvailableDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 1080, height: 2340);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _availableDevicesText,
        _availableDevicesListView,
        SizedBox(height: 32),
        Row(children: [_bleButton, SizedBox(width: 16), _proceedButton])
      ],
    );
  }

  Widget get _availableDevicesText => InformationText(
        text: 'Pick devices from available:',
      );

  Widget get _availableDevicesListView => Expanded(
        child: BlocBuilder<AvailableDevicesCubit, AvailableDevicesState>(
          builder: (context, state) => ListView.builder(
              itemBuilder: (context, index) =>
                  _availableDeviceContainer(state.availableDevices.elementAt(index)),
              itemCount: state.availableDevices.length),
        ),
      );

  Widget _availableDeviceContainer(BluetoothDevice device) {
    return StreamBuilder<BluetoothDeviceState>(
      stream: device.state.asBroadcastStream(),
      initialData: BluetoothDeviceState.disconnected,
      builder: (c, snapshot) => snapshot.data.index == 2
          ? _connectedDeviceContainer(device, snapshot.data.index)
          : _disconnectedDeviceContainer(device, snapshot.data.index),
    );
  }

  Widget _connectedDeviceContainer(BluetoothDevice device, int stateIndex) {
    return BlocBuilder<ConnectedDeviceCubit, ConnectedDeviceState>(
      builder: (ctx, state) => Container(
        height: 200.h,
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.symmetric(vertical: 20.w, horizontal: 40.w),
        decoration: BoxDecoration(
            color: UIColors.GRADIENT_DARK_COLOR, borderRadius: BorderRadius.circular(40.w)),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  device.name == '' ? "No name given" : device.name,
                  style: TextStyle(fontSize: 40.w, color: Colors.white),
                  textAlign: TextAlign.left,
                ),
                Text(
                  _getConnectionState(stateIndex),
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 30.w, color: Colors.black45),
                ),
                Text(
                  device.id.toString(),
                  style: TextStyle(fontSize: 30.w, color: Colors.black45),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
            Spacer(),
            Checkbox(
              checkColor: Colors.black,
              activeColor: Colors.white,
              onChanged: (bool value) {
                if (value)
                  context.bloc<ConnectedDeviceCubit>().setConnectedDevice(device, context);
                else {
                  context.bloc<ConnectedDeviceCubit>().removeDevice(device);
                }
              },
              value: state.connectedDevices.contains(device),
            ),
          ],
        ),
      ),
    );
  }

  void connectToDevice(BluetoothDevice device, BuildContext context) {
    context.bloc<ConnectedDeviceCubit>().setConnectedDevice(device, context);
  }

  Widget _disconnectedDeviceContainer(BluetoothDevice device, int stateIndex) {
    return Container(
        height: 200.h,
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.symmetric(vertical: 20.w, horizontal: 40.w),
        decoration: BoxDecoration(
            border: Border.all(
              color: UIColors.GRADIENT_DARK_COLOR,
            ),
            borderRadius: BorderRadius.circular(40.w)),
        alignment: Alignment.centerLeft,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                device.name == '' ? "No name given" : device.name,
                style: informationTextStyle.copyWith(fontSize: 40.w),
                textAlign: TextAlign.left,
              ),
              Text(_getConnectionState(stateIndex),
                  textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 30.w)),
              Text(
                device.id.toString(),
                style: TextStyle(color: Colors.black, fontSize: 30.w),
                textAlign: TextAlign.left,
              ),
            ],
          ),
          FlatButton(
            color: Colors.black12,
            textColor: Colors.black,
            child: Text("Connect"),
            onPressed: () {
              try {
                device.connect();
              } catch (e) {
                print(e);
              }
            },
          )
        ]));
  }

  String _getConnectionState(int index) {
    switch (index) {
      case 0:
        return 'Disconnected';
        break;
      case 1:
        return 'Connecting';
        break;
      case 2:
        return 'Connected';
        break;
      case 3:
        return 'Disconnecting';
        break;
      default:
    }
  }

  TextStyle get informationTextStyle => TextStyle(color: UIColors.LIGHT_FONT_COLOR, fontSize: 50.w);

  Widget get _bleButton => Flexible(
        child: CustomButton(
          onPressed: () {
            context.bloc<AvailableDevicesCubit>().toggleIsScanning();
            context.bloc<AvailableDevicesCubit>().getAvailableDevices();
            setState(() {
              isSearchingForBLE = true;
            });
          },
          text: "Refresh",
        ),
      );

  Widget get _proceedButton => Flexible(
          child: CustomButton(
        onPressed: proceedToMeasure,
        text: "Proceed",
        isPassive: false,
      ));

  void proceedToMeasure() async {
    await showNameDialog();
  }

  Future showNameDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 400,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: InformationText(
                      text: "Type your name",
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(16),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(borderSide: BorderSide()), hintText: "Name"),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                    child: CustomButton(
                        text: "Continue",
                        onPressed: () {
                          context.bloc<ConnectedDeviceCubit>().setUsername(_nameController.text);
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) => ConnectedDevicePage()));
                        }),
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}
