import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart_app/presentation/resources/app_resources.dart';
import 'package:flutter/material.dart';

class GaugeChartSample1 extends StatefulWidget {
  const GaugeChartSample1({super.key});

  @override
  State<StatefulWidget> createState() => GaugeChartSample1State();
}

class GaugeChartSample1State extends State<GaugeChartSample1> {
  double _value = 0.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              children: [
                GaugeChart(
                  GaugeChartData.progress(
                    value: _value,
                    color: AppColors.contentColorYellow,
                    width: 30,
                    backgroundColor:
                        AppColors.contentColorPurple.withValues(alpha: 0.2),
                    startDegreeOffset: -200,
                    sweepAngle: 220,
                    touchData: GaugeTouchData(enabled: true),
                  ),
                ),
                Center(
                  child: Text(
                    "${(_value * 100).toInt()}%",
                    style: TextStyle(
                      color: AppColors.contentColorWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
          Slider(value: _value, onChanged: (v) => setState(() => _value = v)),
        ],
      ),
    );
  }
}
