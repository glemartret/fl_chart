import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Speedometer-style gauge combining two section types:
/// - an inner [GaugeProgressSection] showing the current measurement
///   (350..value filled green, rest greyed out)
/// - an outer [GaugeZonesSection] painting fixed threshold bands
///   (350-600 red, 600-700 amber, 700-800 light green, 800-850 green)
///
/// Touching the gauge reports which ring was hit and, for the zones
/// ring, which specific zone the touch angle falls in.
class GaugeChartSample4 extends StatefulWidget {
  const GaugeChartSample4({super.key});

  @override
  State<StatefulWidget> createState() => GaugeChartSample4State();
}

class GaugeChartSample4State extends State<GaugeChartSample4> {
  double _value = 370;
  String _touchLabel = 'Touch the gauge to read a value';

  static const _minValue = 350.0;
  static const _maxValue = 850.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          SizedBox(
            width: 280,
            height: 180,
            child: GaugeChart(
              GaugeChartData(
                minValue: _minValue,
                maxValue: _maxValue,
                startDegreeOffset: 180,
                sweepAngle: 180,
                sectionsSpace: 4,
                strokeCap: StrokeCap.round,
                sections: [
                  GaugeProgressSection(
                    value: _value,
                    color: Colors.green.shade300,
                    backgroundColor: Colors.grey.shade300,
                    width: 30,
                  ),
                  const GaugeZonesSection(
                    width: 10,
                    zones: [
                      GaugeZone(from: 350, to: 600, color: Colors.redAccent),
                      GaugeZone(from: 600, to: 700, color: Colors.amber),
                      GaugeZone(from: 700, to: 800, color: Colors.lightGreen),
                      GaugeZone(from: 800, to: 850, color: Colors.green),
                    ],
                  ),
                ],
                touchData: GaugeTouchData(
                  enabled: true,
                  touchCallback: (_, response) => setState(() {
                    final s = response?.touchedSection;
                    if (s == null || s.touchedSection == null) {
                      _touchLabel = 'Outside the gauge';
                      return;
                    }
                    final value = s.touchValue.toStringAsFixed(0);
                    switch (s.touchedSection) {
                      case GaugeProgressSection():
                        _touchLabel =
                            'Progress ring @ $value ${s.isOnValue ? '(filled)' : '(background)'}';
                      case GaugeZonesSection():
                        final zone = s.touchedZone;
                        _touchLabel = zone == null
                            ? 'Zones ring @ $value (gap)'
                            : 'Zones ring @ $value — band ${zone.from.toStringAsFixed(0)}..${zone.to.toStringAsFixed(0)}';
                      case null:
                        _touchLabel = 'Outside the gauge';
                    }
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _value.toStringAsFixed(0),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Slider(
            value: _value,
            min: _minValue,
            max: _maxValue,
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 8),
          Text(
            _touchLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
