import 'package:band_parameters_reader/repositories/bluetooth_devices/bluetooth_devices_cubit.dart';
import 'package:band_parameters_reader/ui/bitalino/bitalino_measurment.dart';
import 'package:band_parameters_reader/utils/colors.dart';
import 'package:band_parameters_reader/widgets/custom_button.dart';
import 'package:band_parameters_reader/widgets/information_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BluetoothDevices extends StatefulWidget {
  BluetoothDevices({Key key}) : super(key: key);

  @override
  _BluetoothDevicesState createState() => _BluetoothDevicesState();
}

class _BluetoothDevicesState extends State<BluetoothDevices>
    with AutomaticKeepAliveClientMixin<BluetoothDevices> {
  TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 1080, height: 2340);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _availableBluetoothListView,
        SizedBox(height: 32),
        _classicButton,
      ],
    );
  }

  Widget get _availableBluetoothListView => Expanded(
        child: BlocBuilder<BluetoothDevicesCubit, BluetoothDevicesState>(builder: (context, state) {
          return ListView.builder(
              itemBuilder: (context, index) =>
                  _availableDeviceContainer(state.availableDevices[index]),
              itemCount: state.availableDevices.length);
        }),
      );

  Widget get _classicButton => CustomButton(
        onPressed: () {
          context.bloc<BluetoothDevicesCubit>().getAvailableDevices(context);
        },
        text: "Refresh",
      );

  Widget _availableDeviceContainer(BluetoothDevice device) {
    if (device.type.stringValue != 'classic') return Container();
    return device.isConnected
        ? _connectedDeviceContainer(device)
        : _disconnectedDeviceContainer(device);
  }

  Future showNameDialog(BluetoothDevice device) async {
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
                          try {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        BitalinoMeasurment(address: device.address, name: _nameController.text)));
                          } catch (exception) {
                            print('Cannot connect, exception occured');
                          }
                        }),
                  )
                ],
              ),
            ),
          );
        });
  }

  Widget _connectedDeviceContainer(BluetoothDevice device) {
    return GestureDetector(
      child: Container(
        height: 200.h,
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.symmetric(vertical: 20.w, horizontal: 40.w),
        decoration: BoxDecoration(
            color: UIColors.GRADIENT_DARK_COLOR, borderRadius: BorderRadius.circular(40.w)),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              device.name == '' ? "No name given" : device.name,
              style: TextStyle(fontSize: 40.w, color: Colors.white),
              textAlign: TextAlign.left,
            ),
            Text(
              device.address.toString(),
              style: TextStyle(fontSize: 30.w, color: Colors.black45),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _disconnectedDeviceContainer(BluetoothDevice device) {
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
                device.name == null ? "No name given" : device.name,
                style: informationTextStyle.copyWith(fontSize: 40.w),
                textAlign: TextAlign.left,
              ),
              Text(
                device.address,
                style: TextStyle(color: Colors.black, fontSize: 30.w),
                textAlign: TextAlign.left,
              ),
            ],
          ),
          FlatButton(
            color: Colors.black12,
            textColor: Colors.black,
            child: Text("Connect"),
            onPressed: () async {
              showNameDialog(device);
            },
          )
        ]));
  }

  TextStyle get informationTextStyle => TextStyle(color: UIColors.LIGHT_FONT_COLOR, fontSize: 50.w);

  @override
  bool get wantKeepAlive => true;
}
