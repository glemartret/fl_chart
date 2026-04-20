import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart_app/presentation/resources/app_resources.dart';
import 'package:flutter/material.dart';

/// Multi-ring ("Apple Watch"-style) gauge. Three concentric progress
/// rings, each tracking its own value against the same 0..1 scale.
/// Sections are listed innermost-first; the slider drives the
/// innermost ring, the outer two are fixed.
class GaugeChartSample3 extends StatefulWidget {
  const GaugeChartSample3({super.key});

  @override
  State<StatefulWidget> createState() => GaugeChartSample3State();
}

class GaugeChartSample3State extends State<GaugeChartSample3> {
  double _value = 0.6;

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
                startDegreeOffset: -225,
                sweepAngle: 270,
                strokeCap: StrokeCap.round,
                defaultSectionWidth: 20,
                sectionsSpace: 4,
                sections: [
                  GaugeProgressSection(
                    value: _value,
                    color: AppColors.contentColorRed,
                    backgroundColor:
                        AppColors.contentColorRed.withValues(alpha: 0.2),
                  ),
                  GaugeProgressSection(
                    value: 0.45,
                    color: AppColors.contentColorGreen,
                    backgroundColor:
                        AppColors.contentColorGreen.withValues(alpha: 0.2),
                  ),
                  GaugeProgressSection(
                    value: 0.9,
                    color: AppColors.contentColorBlue,
                    backgroundColor:
                        AppColors.contentColorBlue.withValues(alpha: 0.2),
                  ),
                ],
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
