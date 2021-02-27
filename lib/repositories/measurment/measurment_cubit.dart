import 'package:band_parameters_reader/models/measure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue/flutter_blue.dart';

part 'measurment_state.dart';

class MeasurmentCubit extends Cubit<MeasurmentState> {
  final BuildContext context;

  MeasurmentCubit(this.context) : super(MeasurmentInitial());

  addHeartbeatMeasurment(BluetoothDevice device, Measure measure) {
    if (state.isMeasuring) {
      if(state.heartbeatMeasure[device] == null) {
        state.heartbeatMeasure.putIfAbsent(device, () => []);
      }
      final List<Measure> measures = state.heartbeatMeasure[device].toList();
      measures.add(measure);

      if(measures.length > 300) {
        measures.removeAt(0);
      }

      final Map<BluetoothDevice, List<Measure>> map = state.heartbeatMeasure;

      map.update(device, (value) => measures);

      state.copyWith(heartbeatMeasure: map);
    }
  }

  pauseMeasure() {
    emit(state.copyWith(isMeasuring: false));
  }

  startMeasure() {
    emit(state.copyWith(isMeasuring: true));
  }

  setInitialState() {
    emit(MeasurmentInitial());
  }
}
