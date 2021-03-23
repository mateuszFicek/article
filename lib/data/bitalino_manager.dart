import 'dart:io';

import 'package:band_parameters_reader/models/measure.dart';
import 'package:band_parameters_reader/repositories/bitalino/bitalino_cubit.dart';
import 'package:bitalino/bitalino.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BitalinoManager {
  BITalinoController bitalinoController;
  final BuildContext context;
  List<Measure> measures = [];
  File file;

  BitalinoManager({this.context});

  void initialize(String address, String path) async {
    bitalinoController = BITalinoController(
      address,
      CommunicationType.BTH,
    );

    file = File(path);

    try {
      await bitalinoController.initialize();
    } on PlatformException catch (Exception) {
      print("Initialization failed: ${Exception.message}");
    }
  }

  Future<BITalinoState> getState() async {
    final state = await bitalinoController.state();
    return state;
  }

  bool connected() {
    return bitalinoController.connected;
  }

  Future<void> connectToDevice() async {
    try {
      await bitalinoController.connect(
        onConnectionLost: () {
          print("Connection lost");
        },
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> startAcquisition() async {
    int index = 0;

    List<List<int>> measures = [];
    try {
      await bitalinoController.start([0, 1, 2, 3], Frequency.HZ100, numberOfSamples: 10,
          onDataAvailable: (frame) async {
        if (!context.bloc<BitalinoCubit>().state.isCollectingData) {
          if (measures.length > 0) {
            _saveToFile(measures, index - measures.length);
            measures.clear();
          }
          return;
        }
        for (int i = 0; i < 4; i++) {
          Measure measure =
              Measure(date: DateTime.now(), measure: frame.analog[i].round(), id: index);

          context.bloc<BitalinoCubit>().addMeasure(measure, i);
        }

        measures.add([frame.analog[0], frame.analog[1], frame.analog[2], frame.analog[3]]);

        if (index % 100 == 0 && index != 0) {
          _saveToFile(measures, index - measures.length + 1);
          measures.clear();
        }

        index++;
      });
    } catch (e) {
      print(e);
    }
  }

  Future _saveToFile(List<List<int>> measure, int startingIndex) async {
    List<List<dynamic>> rows = [];
    for (int i = 0; i < measure.length; i++) {
      List<dynamic> row = [];
      row.add(startingIndex + i);
      row.add(measure[i][0]);
      row.add(measure[i][1]);
      row.add(measure[i][2]);
      row.add(measure[i][3]);
      row.add(DateTime.now().toString());
      print(row);
      rows.add(row);
    }
    String csv = ListToCsvConverter().convert(rows) + '\n';
    print(csv);
    rows.clear();
    await file.writeAsString(csv, mode: FileMode.append);
  }

  Future<void> stopAcquisition() async {
    try {
      await bitalinoController.stop();
    } catch (e) {
      print(e);
    }
  }

  Future<void> endConnection() async {
    await bitalinoController.disconnect();
    await bitalinoController.dispose();
  }
}
