import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_pool.dart';

void main() {
  group('GaugeChart Data equality check', () {
    test('GaugeChartData equality test', () {
      expect(gaugeChartData1 == gaugeChartData1Clone, true);

      expect(
        gaugeChartData1 ==
            gaugeChartData1Clone.copyWith(
              rings: const [
                GaugeProgressRing(value: 0.5, color: Colors.black),
              ],
            ),
        false,
      );

      expect(
        gaugeChartData1 ==
            gaugeChartData1Clone.copyWith(
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.green),
              ),
            ),
        false,
      );

      expect(
        gaugeChartData1 ==
            gaugeChartData1Clone.copyWith(
              rings: [gaugeRing1.copyWith(strokeCap: StrokeCap.square)],
            ),
        false,
      );

      expect(
        gaugeChartData1 ==
            gaugeChartData1Clone.copyWith(touchData: gaugeTouchData2),
        false,
      );

      expect(
        gaugeChartData1 == gaugeChartData1Clone.copyWith(startDegreeOffset: 0),
        false,
      );

      expect(
        gaugeChartData1 == gaugeChartData1Clone.copyWith(sweepAngle: 10),
        false,
      );

      expect(
        gaugeChartData1 ==
            gaugeChartData1Clone.copyWith(
              direction: GaugeDirection.counterClockwise,
            ),
        false,
      );

      expect(
        gaugeChartData1 == gaugeChartData1Clone.copyWith(defaultRingWidth: 7),
        false,
      );

      expect(
        gaugeChartData1 == gaugeChartData1Clone.copyWith(ringsSpace: 2),
        false,
      );
    });

    test('GaugeChartData asserts', () {
      expect(
        () => GaugeChartData(
          maxValue: 0,
          rings: const [GaugeProgressRing(value: 0, color: Colors.red)],
        ),
        throwsAssertionError,
      );

      expect(
        () => GaugeChartData(
          sweepAngle: 0,
          rings: const [
            GaugeProgressRing(value: 0.5, color: Colors.red),
          ],
        ),
        throwsAssertionError,
      );

      expect(
        () => GaugeChartData(
          sweepAngle: 400,
          rings: const [
            GaugeProgressRing(value: 0.5, color: Colors.red),
          ],
        ),
        throwsAssertionError,
      );

      // progress value outside [minValue, maxValue]
      expect(
        () => GaugeChartData(
          rings: const [GaugeProgressRing(value: 2, color: Colors.red)],
        ),
        throwsAssertionError,
      );

      // zone outside [minValue, maxValue]
      expect(
        () => GaugeChartData(
          rings: const [
            GaugeZonesRing(
              zones: [GaugeZone(from: 0, to: 2, color: Colors.red)],
            ),
          ],
        ),
        throwsAssertionError,
      );

      // empty zones in a chart rejected at GaugeChartData level
      expect(
        () => GaugeChartData(
          rings: const [GaugeZonesRing(zones: [])],
        ),
        throwsAssertionError,
      );

      // negative ringsSpace
      expect(
        () => GaugeChartData(
          rings: const [
            GaugeProgressRing(value: 0.5, color: Colors.red),
          ],
          ringsSpace: -1,
        ),
        throwsAssertionError,
      );

      // invalid ring width
      expect(
        () => GaugeProgressRing(value: 0.5, color: Colors.red, width: 0),
        throwsAssertionError,
      );

      // invalid zone range
      expect(
        () => GaugeZone(from: 0.5, to: 0.3, color: Colors.red),
        throwsAssertionError,
      );

      // negative zonesSpace
      expect(
        () => GaugeZonesRing(
          zones: const [GaugeZone(from: 0, to: 1, color: Colors.red)],
          zonesSpace: -1,
        ),
        throwsAssertionError,
      );
    });

    test('GaugeChartData.progress factory', () {
      final data = GaugeChartData.progress(
        value: 0.6,
        color: Colors.red,
        width: 20,
        backgroundColor: Colors.grey,
      );
      expect(data.rings.length, 1);
      final ring = data.rings.first as GaugeProgressRing;
      expect(ring.value, 0.6);
      expect(ring.color, Colors.red);
      expect(ring.width, 20);
      expect(ring.backgroundColor, Colors.grey);
      expect(data.defaultRingWidth, 20);

      final clampedHigh = GaugeChartData.progress(
        value: 2,
        color: Colors.red,
        width: 20,
      );
      expect(
        (clampedHigh.rings.first as GaugeProgressRing).value,
        1,
      );

      final clampedLow = GaugeChartData.progress(
        value: -1,
        color: Colors.red,
        width: 20,
      );
      expect((clampedLow.rings.first as GaugeProgressRing).value, 0);
    });

    test('GaugeProgressRing equality and copyWith', () {
      expect(gaugeRing1 == gaugeRing1.copyWith(), true);
      expect(gaugeRing1 == gaugeRing1.copyWith(value: 0.4), false);
      expect(gaugeRing1 == gaugeRing1.copyWith(color: Colors.red), false);
      expect(gaugeRing1 == gaugeRing1.copyWith(width: 10), false);
      expect(
        gaugeRing1 == gaugeRing1.copyWith(backgroundColor: Colors.pink),
        false,
      );
    });

    test('GaugeProgressRing.lerp', () {
      const a = GaugeProgressRing(
        value: 0.2,
        color: Colors.red,
        width: 10,
        backgroundColor: Colors.pink,
      );
      const b = GaugeProgressRing(
        value: 0.8,
        color: Colors.blue,
        width: 30,
        backgroundColor: Colors.lightBlue,
      );
      final mid = GaugeProgressRing.lerp(a, b, 0.5);
      expect(mid.value, closeTo(0.5, 1e-9));
      expect(mid.width, 20);
      expect(mid.color, Color.lerp(Colors.red, Colors.blue, 0.5));
      expect(
        mid.backgroundColor,
        Color.lerp(Colors.pink, Colors.lightBlue, 0.5),
      );
    });

    test('GaugeZone equality and lerp', () {
      const a = GaugeZone(from: 0.1, to: 0.5, color: Colors.red);
      const b = GaugeZone(from: 0.3, to: 0.9, color: Colors.blue);
      expect(a == a.copyWith(), true);
      expect(a == a.copyWith(from: 0.2), false);
      expect(a == a.copyWith(to: 0.4), false);
      expect(a == a.copyWith(color: Colors.green), false);

      final mid = GaugeZone.lerp(a, b, 0.5);
      expect(mid.from, closeTo(0.2, 1e-9));
      expect(mid.to, closeTo(0.7, 1e-9));
      expect(mid.color, Color.lerp(Colors.red, Colors.blue, 0.5));
    });

    test('GaugeZonesRing equality, copyWith, lerp', () {
      const a = GaugeZonesRing(
        zones: [
          GaugeZone(from: 0, to: 0.5, color: Colors.red),
          GaugeZone(from: 0.5, to: 1, color: Colors.green),
        ],
        zonesSpace: 4,
        width: 10,
      );
      const a2 = GaugeZonesRing(
        zones: [
          GaugeZone(from: 0, to: 0.5, color: Colors.red),
          GaugeZone(from: 0.5, to: 1, color: Colors.green),
        ],
        zonesSpace: 4,
        width: 10,
      );
      expect(a == a2, true);
      expect(a == a.copyWith(width: 20), false);
      expect(a == a.copyWith(zonesSpace: 8), false);

      const b = GaugeZonesRing(
        zones: [
          GaugeZone(from: 0, to: 0.3, color: Colors.red),
          GaugeZone(from: 0.3, to: 1, color: Colors.blue),
        ],
        zonesSpace: 8,
        width: 20,
      );
      final mid = GaugeZonesRing.lerp(a, b, 0.5);
      expect(mid.width, 15);
      expect(mid.zonesSpace, closeTo(6, 1e-9));
      expect(mid.zones[0].to, closeTo(0.4, 1e-9));
      expect(
        mid.zones[1].color,
        Color.lerp(Colors.green, Colors.blue, 0.5),
      );
    });

    test('GaugeRing.lerp dispatches by type', () {
      const progressA = GaugeProgressRing(value: 0.2, color: Colors.red);
      const progressB = GaugeProgressRing(value: 0.8, color: Colors.red);
      final progressMid =
          GaugeRing.lerp(progressA, progressB, 0.5) as GaugeProgressRing;
      expect(progressMid.value, closeTo(0.5, 1e-9));

      const zonesA = GaugeZonesRing(
        zones: [GaugeZone(from: 0, to: 0.5, color: Colors.red)],
        width: 10,
      );
      const zonesB = GaugeZonesRing(
        zones: [GaugeZone(from: 0, to: 0.5, color: Colors.red)],
        width: 20,
      );
      final zonesMid = GaugeRing.lerp(zonesA, zonesB, 0.5) as GaugeZonesRing;
      expect(zonesMid.width, 15);

      // Cross-type snaps to target
      expect(GaugeRing.lerp(progressA, zonesA, 0.2), zonesA);
      expect(GaugeRing.lerp(zonesA, progressA, 0.8), progressA);
    });

    test('GaugeZonesRing.copyWith with zones parameter', () {
      const a = GaugeZonesRing(
        zones: [GaugeZone(from: 0, to: 0.5, color: Colors.red)],
        width: 10,
      );
      final b = a.copyWith(
        zones: const [GaugeZone(from: 0.1, to: 0.9, color: Colors.green)],
      );
      expect(b.zones.length, 1);
      expect(b.zones.first.from, 0.1);
      expect(b.width, 10);
    });

    test('GaugeTouchData equality test', () {
      expect(gaugeTouchData1 == gaugeTouchData1Clone, true);
      expect(gaugeTouchData1 == gaugeTouchData2, false);

      expect(
        gaugeTouchData1 ==
            GaugeTouchData(enabled: true, touchCallback: (_, __) {}),
        false,
      );

      expect(
        gaugeTouchData1 ==
            GaugeTouchData(
              enabled: true,
              mouseCursorResolver: (_, __) => MouseCursor.uncontrolled,
            ),
        false,
      );

      expect(
        gaugeTouchData1 ==
            GaugeTouchData(enabled: true, longPressDuration: Duration.zero),
        false,
      );
    });

    test('GaugeTouchedRing equality test', () {
      expect(gaugeTouchedRing1 == gaugeTouchedRingClone1, true);
      expect(gaugeTouchedRing1 == gaugeTouchedRing2, false);
      expect(gaugeTouchedRing1 == gaugeTouchedRing3, false);
    });

    test('GaugeChartDataTween lerp', () {
      final a = GaugeChartData(
        rings: const [
          GaugeProgressRing(
            value: 0.2,
            color: MockData.color0,
            width: 5,
            strokeCap: StrokeCap.round,
          ),
        ],
        startDegreeOffset: 0,
        touchData: GaugeTouchData(
          touchCallback: (_, __) {},
          longPressDuration: const Duration(seconds: 7),
          mouseCursorResolver: (_, __) => MouseCursor.defer,
        ),
      );

      final b = GaugeChartData(
        rings: const [
          GaugeProgressRing(
            value: 0.8,
            color: MockData.color2,
            width: 3,
            strokeCap: StrokeCap.square,
          ),
        ],
        startDegreeOffset: 20,
        sweepAngle: 230,
        touchData: GaugeTouchData(
          touchCallback: (_, __) {},
          longPressDuration: const Duration(seconds: 7),
          mouseCursorResolver: (_, __) => MouseCursor.defer,
        ),
      );

      final data = GaugeChartDataTween(begin: a, end: b).lerp(0.5);

      expect(data.rings.length, 1);
      final lerped = data.rings.first as GaugeProgressRing;
      expect(lerped.value, closeTo(0.5, 1e-9));
      expect(lerped.width, 4);
      expect(data.startDegreeOffset, 10);
      expect(data.sweepAngle, 250);
      expect(lerped.strokeCap, StrokeCap.square);
      expect(data.gaugeTouchData, b.gaugeTouchData);
    });

    test('GaugeChartData.lerp throws on illegal state', () {
      final gauge = GaugeChartData(
        rings: const [
          GaugeProgressRing(value: 0.5, color: MockData.color0),
        ],
        sweepAngle: 180,
      );

      expect(
        () => gauge.lerp(_DummyData(), _DummyData(), 0.3),
        throwsA(isA<Exception>()),
      );
    });

    test('GaugeTouchResponse.copyWith', () {
      final response = GaugeTouchResponse(
        touchLocation: const Offset(10, 20),
        touchedRing: gaugeTouchedRing1,
      );

      final same = response.copyWith();
      expect(same.touchLocation, response.touchLocation);
      expect(same.touchedRing, response.touchedRing);

      final updated = response.copyWith(
        touchLocation: const Offset(30, 40),
        touchedRing: gaugeTouchedRing2,
      );
      expect(updated.touchLocation, const Offset(30, 40));
      expect(updated.touchedRing, gaugeTouchedRing2);
    });
  });
}

class _DummyData extends BaseChartData {
  _DummyData();

  @override
  BaseChartData lerp(BaseChartData a, BaseChartData b, double t) => this;
}
