import 'package:fl_chart/fl_chart.dart';
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
            child: GaugeChart(
              GaugeChartData(
                sections: const [
                  GaugeProgressSection(
                    value: 0.3,
                    backgroundColor: Colors.grey,
                    color: Colors.red,
                  ),
                  GaugeProgressSection(
                    value: 0.4,
                    color: Colors.green,
                    backgroundColor: Colors.grey,
                  ),
                  GaugeProgressSection(
                    value: 0.5,
                    color: Colors.blue,
                    backgroundColor: Colors.grey,
                  ),
                  GaugeProgressSection(
                    value: 0.6,
                    color: Colors.cyan,
                    backgroundColor: Colors.grey,
                  ),
                  GaugeProgressSection(
                    value: 0.7,
                    color: Colors.amber,
                    backgroundColor: Colors.grey,
                  ),
                  GaugeProgressSection(
                    value: 0.8,
                    color: Colors.deepOrange,
                    backgroundColor: Colors.grey,
                  ),
                  GaugeProgressSection(
                    value: 0.9,
                    color: Colors.purpleAccent,
                    backgroundColor: Colors.grey,
                  ),
                  GaugeProgressSection(
                    value: 1,
                    color: Colors.purpleAccent,
                    backgroundColor: Colors.teal,
                  ),
                ],
                sectionsSpace: 8,
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
