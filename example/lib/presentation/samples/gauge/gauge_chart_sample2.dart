import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart_app/presentation/resources/app_resources.dart';
import 'package:flutter/material.dart';

class GaugeChartSample2 extends StatefulWidget {
  const GaugeChartSample2({super.key});

  @override
  State<StatefulWidget> createState() => GaugeChartSample2State();
}

class GaugeChartSample2State extends State<GaugeChartSample2> {
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
            child: GaugeChart(
              GaugeChartData.progress(
                value: _value,
                color: AppColors.contentColorYellow,
                width: 30,
                backgroundColor:
                    AppColors.contentColorPurple.withValues(alpha: 0.2),
                startDegreeOffset: -225,
                sweepAngle: 270,
                touchData: GaugeTouchData(enabled: true),
              ),
            ),
          ),
          Slider(value: _value, onChanged: (v) => setState(() => _value = v)),
        ],
      ),
    );
  }
}
