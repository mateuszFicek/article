import 'package:band_parameters_reader/models/measure.dart';
import 'package:band_parameters_reader/repositories/connected_device/connected_device_cubit.dart';
import 'package:band_parameters_reader/repositories/connected_device/device_view_model.dart';
import 'package:band_parameters_reader/repositories/measurment/measurment_cubit.dart';
import 'package:band_parameters_reader/utils/colors.dart';
import 'package:band_parameters_reader/widgets/connected_device/last_measurment_chart.dart';
import 'package:band_parameters_reader/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share/share.dart';

import 'measurment_summary.dart';

class ConnectedDevicePage extends StatefulWidget {
  const ConnectedDevicePage({Key key}) : super(key: key);

  @override
  _ConnectedDevicePageState createState() => _ConnectedDevicePageState();
}

class _ConnectedDevicePageState extends State<ConnectedDevicePage> {
  ConnectedDeviceCubit connectedDeviceCubit;
  MeasurmentCubit measurmentCubit;
  List<BluetoothService> services;
  BluetoothCharacteristic heartRateCharacteristic;
  String dropdownValue;

  @override
  void initState() {
    super.initState();
    connectedDeviceCubit = BlocProvider.of<ConnectedDeviceCubit>(context);
    measurmentCubit = BlocProvider.of<MeasurmentCubit>(context);
    connectedDeviceCubit.initDevice(context);
    dropdownValue = connectedDeviceCubit.state.currentDevice.name;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 1080, height: 2340);
    return Scaffold(
      backgroundColor: UIColors.BACKGROUND_COLOR,
      body: BlocBuilder<ConnectedDeviceCubit, ConnectedDeviceState>(
        builder: (_, state) => BlocBuilder<MeasurmentCubit, MeasurmentState>(
          builder: (_, measureState) => Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _nameAndBattery(),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  height: 500,
                  child: LastSessionChart(),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(children: [
                    _shareButton(state),
                    Spacer(),
                    _pauseButton(measureState),
                  ]),
                ),
                Spacer(),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25),
                        child: _measures(state, measureState))),
                SizedBox(height: 20),
                _endButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(ConnectedDeviceState state) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<String>(
        value: dropdownValue,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
        ),
        iconSize: 24,
        isExpanded: true,
        elevation: 16,
        dropdownColor: Colors.black,
        style: TextStyle(color: Colors.black, fontSize: 16),
        underline: Container(
          height: 1.5,
          color: UIColors.GRADIENT_DARK_COLOR,
        ),
        onChanged: (String newValue) {
          setState(() {
            dropdownValue = newValue;
            final value = state.connectedDevices.map((e) => e.name).toList().indexOf(newValue);
            final device = state.connectedDevices[value];
            connectedDeviceCubit.setCurrentDevice(device);
          });
        },
        items: state.connectedDevices
            .map((e) => e.name)
            .toSet()
            .toList()
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              "$value",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _deviceNameText(BluetoothDevice device) => Text(
        "${device.name == '' ? device.id : device.name}",
        style: TextStyle(
          color: Colors.white,
          fontSize: 70.h,
        ),
        textAlign: TextAlign.start,
      );

  Widget _nameAndBattery() {
    return BlocBuilder<ConnectedDeviceCubit, ConnectedDeviceState>(
      builder: (context, state) => Container(
        width: double.infinity,
        padding: EdgeInsets.only(left: 50.h, right: 50.h, top: 40.h + ScreenUtil.statusBarHeight),
        height: 400.h,
        color: UIColors.GRADIENT_DARK_COLOR,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dropdown(state),
            SizedBox(height: 4),
            _batteryBox(state.viewModels[state.currentDevice]),
          ],
        ),
      ),
    );
  }

  Widget _batteryBox(DeviceViewModel viewModel) {
    return viewModel == null
        ? Container()
        : Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Device battery level ${viewModel.batteryLevel}%',
                  style: TextStyle(color: Colors.white70, fontSize: 40.w),
                ),
              ],
            ),
          );
  }

  Widget _endButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.all(15),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  side: BorderSide(color: UIColors.GRADIENT_DARK_COLOR)),
              padding: const EdgeInsets.all(8),
              color: UIColors.GRADIENT_DARK_COLOR,
              onPressed: () {
                pauseMeasure();
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => MeasurmentSummary()));
              },
              child: Text(
                'End measure',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            )),
      ),
    );
  }

//  Widget _heartRateBox(ConnectedDeviceState state) {
//    return Container(
//      width: double.infinity,
//      height: 80.h,
//      alignment: Alignment.centerLeft,
//      child: Row(
//        mainAxisSize: MainAxisSize.min,
//        crossAxisAlignment: CrossAxisAlignment.center,
//        mainAxisAlignment: MainAxisAlignment.start,
//        children: [
//          Text(
//            'Last HB measure ${state.currentHeartRate}',
//            style: TextStyle(color: Colors.white70, fontSize: 40.w),
//          ),
//          SizedBox(width: 20.w),
//          Container(
//            height: 80.h,
//            alignment: Alignment.center,
//            child: Text(
//              state.lastHeartRateMeasureTime,
//              style: TextStyle(color: UIColors.LIGHT_FONT_COLOR, fontSize: 25.h),
//            ),
//          ),
//        ],
//      ),
//    );
//  }

  Widget _pauseButton(MeasurmentState state) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 30,
      child: CustomButton(
        isPassive: false,
        onPressed: state.isMeasuring ? pauseMeasure : resumeMeasure,
        text: state.isMeasuring ? "Stop" : "Continue",
      ),
    );
  }

  Widget _shareButton(ConnectedDeviceState state) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 30,
      child: CustomButton(
        onPressed: () => shareFile(state.viewModels[state.currentDevice].filePath),
        text: "Share",
      ),
    );
  }

  shareFile(String filePath) async {
    print(filePath);
    await Share.shareFiles([filePath], text: 'Measurment');
  }

  void pauseMeasure() {
    context.bloc<MeasurmentCubit>().pauseMeasure();
  }

  void resumeMeasure() {
    context.bloc<MeasurmentCubit>().startMeasure();
  }

  Widget _measures(ConnectedDeviceState deviceState, MeasurmentState state) {
    if(state.heartbeatMeasure[deviceState.currentDevice] == null) return Container();
    List<Measure> measures =
        List<Measure>.from(state.heartbeatMeasure[deviceState.currentDevice]);
    var valueMax = 0;
    var valueMin = 0;
    int secondsElapsed = 0;
    if (measures.isNotEmpty) {
      secondsElapsed = measures.last.date.difference(measures.first.date).inSeconds;

      measures.sort((a, b) => a.measure.compareTo(b.measure));
      valueMax = measures.last.measure;
      valueMin = measures.first.measure;
    }

    return Column(
      children: [
        _textWithValue("Max value", valueMax ?? 0),
        SizedBox(height: 8),
        _textWithValue("Min value", valueMin ?? 0),
        SizedBox(height: 8),
        _textWithValue(
            "Time since first measure", _printDuration(Duration(seconds: secondsElapsed))),
      ],
    );
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _textWithValue(String text, var value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: _textStyle()),
        Text(
          value.toString(),
          style: _valueStyle(),
        )
      ],
    );
  }

  TextStyle _textStyle() {
    return TextStyle(color: UIColors.LIGHT_FONT_COLOR, fontSize: 17, fontWeight: FontWeight.w400);
  }

  TextStyle _valueStyle() {
    return TextStyle(
        color: UIColors.GRADIENT_DARK_COLOR, fontSize: 17, fontWeight: FontWeight.w700);
  }

  @override
  void dispose() {
    connectedDeviceCubit.disconnectFromDevice();
    connectedDeviceCubit.disableListenerForCharacteristics(heartRateCharacteristic);
    measurmentCubit.setInitialState();
    super.dispose();
  }
}
