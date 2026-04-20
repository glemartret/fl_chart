import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart_app/presentation/resources/app_colors.dart';
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
                rings: [
                  GaugeZonesRing(
                    width: 100,
                    zonesSpace: 8,
                    zones: [
                      GaugeZone(
                        from: 0.0,
                        to: 0.25,
                        color: AppColors.contentColorRed,
                      ),
                      GaugeZone(
                        from: 0.25,
                        to: 0.5,
                        color: AppColors.contentColorOrange,
                      ),
                      GaugeZone(
                        from: 0.5,
                        to: 0.75,
                        color: AppColors.contentColorYellow,
                      ),
                      GaugeZone(
                        from: 0.75,
                        to: 1.0,
                        color: AppColors.contentColorGreen,
                      ),
                    ],
                  ),
                ],
                startDegreeOffset: -180,
                sweepAngle: 180,
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
