import 'package:band_parameters_reader/models/measure.dart';
import 'package:band_parameters_reader/repositories/connected_device/connected_device_cubit.dart';
import 'package:band_parameters_reader/repositories/measurment/measurment_cubit.dart';
import 'package:band_parameters_reader/widgets/boxes/decoration_box.dart';
import 'package:band_parameters_reader/widgets/chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LastSessionChart extends StatelessWidget {
  const LastSessionChart({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 1080, height: 2340);

    return DecorationBox(
      child: BlocBuilder<ConnectedDeviceCubit, ConnectedDeviceState>(builder: (context, dState) {
        return BlocBuilder<MeasurmentCubit, MeasurmentState>(builder: (context, state) {
          List<Measure> measures;

          measures = state.heartbeatMeasure[dState.currentDevice];

          return Container(
              padding: EdgeInsets.only(top: 25, left: 5, right: 5),
              alignment: Alignment.center,
              child: Chart(
                data: measures,
                canZoom: false,
              ));
        });
      }),
      text: 'Current measure',
    );
  }
}
