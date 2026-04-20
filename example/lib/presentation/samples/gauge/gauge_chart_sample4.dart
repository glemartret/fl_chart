import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart_app/presentation/resources/app_colors.dart';
import 'package:flutter/material.dart';

class GaugeChartSample4 extends StatelessWidget {
  const GaugeChartSample4({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 28,
        right: 28,
        top: 80,
        bottom: 28,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 280,
            height: 280,
            child: GaugeChart(
              GaugeChartData(
                startDegreeOffset: -200,
                sweepAngle: 220,
                ringsSpace: 6,
                rings: [
                  GaugeZonesRing(
                    width: 100,
                    zonesSpace: 4,
                    zones: [
                      GaugeZone(
                        from: 0,
                        to: 0.25,
                        color: AppColors.contentColorRed,
                      ),
                      GaugeZone(
                        from: 0.25,
                        to: 0.50,
                        color: AppColors.contentColorOrange,
                      ),
                      GaugeZone(
                        from: 0.50,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
