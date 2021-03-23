import 'package:band_parameters_reader/data/bitalino_manager.dart';
import 'package:band_parameters_reader/models/measure.dart';
import 'package:band_parameters_reader/repositories/bitalino/bitalino_cubit.dart';
import 'package:band_parameters_reader/repositories/measurment/measurment_cubit.dart';
import 'package:band_parameters_reader/utils/colors.dart';
import 'package:band_parameters_reader/widgets/chart.dart';
import 'package:band_parameters_reader/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

class BitalinoMeasurment extends StatefulWidget {
  final String address;
  final String name;

  const BitalinoMeasurment({Key key, this.address, this.name}) : super(key: key);

  @override
  _BitalinoMeasurmentState createState() => _BitalinoMeasurmentState();
}

class _BitalinoMeasurmentState extends State<BitalinoMeasurment> {
  int dropdownValue = 1;
  BitalinoManager manager;
  String filePath;
  bool _wasMeasureStarted = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await initPath();
      manager = BitalinoManager(context: context);
      manager.initialize(widget.address, filePath);
      Future.delayed(Duration(milliseconds: 300), () => manager.connectToDevice());
    });
  }

  Future initPath() async {
    String dir = (await getExternalStorageDirectory()).absolute.path + "/";
    filePath = dir + widget.name + ".csv";
  }

  Future<bool> isConnected() async {
    if (manager != null) {
      while (manager.connected() == false) {
        await Future.delayed(Duration(milliseconds: 100), () {});
      }
      return manager.connected();
    } else {
      await Future.delayed(Duration(milliseconds: 100), () {});
      await isConnected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          centerTitle: true,
          backgroundColor: UIColors.GRADIENT_DARK_COLOR,
          title: Text(
            "Bitalino Measurment",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
          ),
        ),
        body: FutureBuilder(
            future: isConnected(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.done) {
                if (manager.connected()) return _body();
                return Container();
              } else {
                return Container();
              }
            }));
  }

  Widget _body() {
    return BlocBuilder<BitalinoCubit, BitalinoState>(
        builder: (context, state) => Stack(children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 80, top: 24),
                child: ListView(children: [
                  _chartBuilder(state),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _shareButton(),
                      Spacer(),
                      _pauseButton(state),
                    ],
                  ),
                  SizedBox(height: 24),
                  _inputPicker(),
                  SizedBox(height: 24),
                  _measures(state),
                ]),
              ),
              _endMeasure(state),
            ]));
  }

  TextStyle get _dialogTextStyle => TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

  Widget _shareButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 30,
      child: CustomButton(
        onPressed: () => shareFile(),
        text: "Share",
      ),
    );
  }

  shareFile() async {
    print(filePath);
    await Share.shareFiles([filePath], text: 'Measurment');
  }

  Widget _chartBuilder(BitalinoState state) {
    List<Measure> measures;

    if (state.measure[dropdownValue - 1].length > 300) {
      measures = List<Measure>.from(state.measure[dropdownValue - 1].getRange(
          state.measure[dropdownValue - 1].length - 300,
          state.measure[dropdownValue - 1].length - 1));
    } else {
      measures = List<Measure>.from(state.measure[dropdownValue - 1]);
    }
    return Container(
      height: 500,
      width: double.infinity,
      child: Chart(
        data: measures,
      ),
    );
  }

  Widget _pauseButton(BitalinoState state) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 30,
      child: RaisedButton(
        onPressed: state.isCollectingData ? pauseMeasure : resumeMeasure,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
            side: BorderSide(color: UIColors.GRADIENT_DARK_COLOR)),
        padding: const EdgeInsets.all(8),
        color: UIColors.GRADIENT_DARK_COLOR,
        child: Text(
          state.isCollectingData ? "Pause" : "Resume",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void pauseMeasure() {
    context.bloc<BitalinoCubit>().pauseMeasure();
  }

  void resumeMeasure() {
    if(!_wasMeasureStarted) {
      manager.startAcquisition();
      setState(() {
        _wasMeasureStarted = true;
      });
    }
    context.bloc<BitalinoCubit>().startMeasure();
  }

  Widget _measures(BitalinoState state) {
    List<Measure> measures = List<Measure>.from(state.measure[dropdownValue - 1]);
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
        _textWithValue("Max measure", valueMax),
        SizedBox(height: 8),
        _textWithValue("Min measure", valueMin),
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

  Widget _inputPicker() {
    return DropdownButton<int>(
      value: dropdownValue,
      icon: Icon(Icons.arrow_drop_down),
      iconSize: 24,
      isExpanded: true,
      elevation: 16,
      style: TextStyle(color: Colors.black, fontSize: 16),
      underline: Container(
        height: 1.5,
        color: UIColors.GRADIENT_DARK_COLOR,
      ),
      onChanged: (int newValue) {
        setState(() {
          dropdownValue = newValue;
        });
      },
      items: <int>[1, 2, 3, 4].map<DropdownMenuItem<int>>((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(
            "Input A${value}",
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  Widget _endMeasure(BitalinoState state) {
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
                showDialog(
                    context: context,
                    builder: (context) {
                      int numberOfMeasure = state.measure[0].last.id * 4;
                      return Dialog(
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total number of measures: $numberOfMeasure",
                                style: _dialogTextStyle,
                              ),
                              Divider(),
                            ]
                              ..add(SizedBox(
                                height: 20,
                              ))
                              ..add(CustomButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                  manager.stopAcquisition();
                                  manager.endConnection();
                                },
                                text: "Exit",
                              )),
                          ),
                        ),
                      );
                    });
              },
              child: Text(
                'End measure',
                style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            )),
      ),
    );
  }
}
