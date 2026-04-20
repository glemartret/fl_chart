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
              sections: const [
                GaugeProgressSection(value: 0.5, color: Colors.black),
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
              ticks: const GaugeTicks(
                painter: GaugeTickCirclePainter(color: Colors.white),
              ),
            ),
        false,
      );

      expect(
        gaugeChartData1 ==
            gaugeChartData1Clone.copyWith(strokeCap: StrokeCap.square),
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
        gaugeChartData1 ==
            gaugeChartData1Clone.copyWith(defaultSectionWidth: 7),
        false,
      );

      expect(
        gaugeChartData1 == gaugeChartData1Clone.copyWith(sectionsSpace: 2),
        false,
      );
    });

    test('GaugeChartData asserts', () {
      expect(
        () => GaugeChartData(sections: const []),
        throwsAssertionError,
      );

      expect(
        () => GaugeChartData(
          maxValue: 0,
          sections: const [GaugeProgressSection(value: 0, color: Colors.red)],
        ),
        throwsAssertionError,
      );

      expect(
        () => GaugeChartData(
          sweepAngle: 0,
          sections: const [
            GaugeProgressSection(value: 0.5, color: Colors.red),
          ],
        ),
        throwsAssertionError,
      );

      expect(
        () => GaugeChartData(
          sweepAngle: 400,
          sections: const [
            GaugeProgressSection(value: 0.5, color: Colors.red),
          ],
        ),
        throwsAssertionError,
      );

      // progress value outside [minValue, maxValue]
      expect(
        () => GaugeChartData(
          sections: const [GaugeProgressSection(value: 2, color: Colors.red)],
        ),
        throwsAssertionError,
      );

      // zone outside [minValue, maxValue]
      expect(
        () => GaugeChartData(
          sections: const [
            GaugeZonesSection(
              zones: [GaugeZone(from: 0, to: 2, color: Colors.red)],
            ),
          ],
        ),
        throwsAssertionError,
      );

      // empty zones in a chart rejected at GaugeChartData level
      expect(
        () => GaugeChartData(
          sections: const [GaugeZonesSection(zones: [])],
        ),
        throwsAssertionError,
      );

      // negative sectionsSpace
      expect(
        () => GaugeChartData(
          sections: const [
            GaugeProgressSection(value: 0.5, color: Colors.red),
          ],
          sectionsSpace: -1,
        ),
        throwsAssertionError,
      );

      // invalid section width
      expect(
        () => GaugeProgressSection(value: 0.5, color: Colors.red, width: 0),
        throwsAssertionError,
      );

      // invalid zone range
      expect(
        () => GaugeZone(from: 0.5, to: 0.3, color: Colors.red),
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
      expect(data.sections.length, 1);
      final section = data.sections.first as GaugeProgressSection;
      expect(section.value, 0.6);
      expect(section.color, Colors.red);
      expect(section.width, 20);
      expect(section.backgroundColor, Colors.grey);
      expect(data.defaultSectionWidth, 20);

      final clampedHigh = GaugeChartData.progress(
        value: 2,
        color: Colors.red,
        width: 20,
      );
      expect(
        (clampedHigh.sections.first as GaugeProgressSection).value,
        1,
      );

      final clampedLow = GaugeChartData.progress(
        value: -1,
        color: Colors.red,
        width: 20,
      );
      expect((clampedLow.sections.first as GaugeProgressSection).value, 0);
    });

    test('GaugeProgressSection equality and copyWith', () {
      expect(gaugeSection1 == gaugeSection1.copyWith(), true);
      expect(gaugeSection1 == gaugeSection1.copyWith(value: 0.4), false);
      expect(gaugeSection1 == gaugeSection1.copyWith(color: Colors.red), false);
      expect(gaugeSection1 == gaugeSection1.copyWith(width: 10), false);
      expect(
        gaugeSection1 == gaugeSection1.copyWith(backgroundColor: Colors.pink),
        false,
      );
    });

    test('GaugeProgressSection.lerp', () {
      const a = GaugeProgressSection(
        value: 0.2,
        color: Colors.red,
        width: 10,
        backgroundColor: Colors.pink,
      );
      const b = GaugeProgressSection(
        value: 0.8,
        color: Colors.blue,
        width: 30,
        backgroundColor: Colors.lightBlue,
      );
      final mid = GaugeProgressSection.lerp(a, b, 0.5);
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

    test('GaugeZonesSection equality, copyWith, lerp', () {
      const a = GaugeZonesSection(
        zones: [
          GaugeZone(from: 0, to: 0.5, color: Colors.red),
          GaugeZone(from: 0.5, to: 1, color: Colors.green),
        ],
        width: 10,
      );
      const a2 = GaugeZonesSection(
        zones: [
          GaugeZone(from: 0, to: 0.5, color: Colors.red),
          GaugeZone(from: 0.5, to: 1, color: Colors.green),
        ],
        width: 10,
      );
      expect(a == a2, true);
      expect(a == a.copyWith(width: 20), false);

      const b = GaugeZonesSection(
        zones: [
          GaugeZone(from: 0, to: 0.3, color: Colors.red),
          GaugeZone(from: 0.3, to: 1, color: Colors.blue),
        ],
        width: 20,
      );
      final mid = GaugeZonesSection.lerp(a, b, 0.5);
      expect(mid.width, 15);
      expect(mid.zones[0].to, closeTo(0.4, 1e-9));
      expect(
        mid.zones[1].color,
        Color.lerp(Colors.green, Colors.blue, 0.5),
      );
    });

    test('GaugeSection.lerp dispatches by type', () {
      const progressA = GaugeProgressSection(value: 0.2, color: Colors.red);
      const progressB = GaugeProgressSection(value: 0.8, color: Colors.red);
      final progressMid =
          GaugeSection.lerp(progressA, progressB, 0.5) as GaugeProgressSection;
      expect(progressMid.value, closeTo(0.5, 1e-9));

      const zonesA = GaugeZonesSection(
        zones: [GaugeZone(from: 0, to: 0.5, color: Colors.red)],
        width: 10,
      );
      const zonesB = GaugeZonesSection(
        zones: [GaugeZone(from: 0, to: 0.5, color: Colors.red)],
        width: 20,
      );
      final zonesMid =
          GaugeSection.lerp(zonesA, zonesB, 0.5) as GaugeZonesSection;
      expect(zonesMid.width, 15);

      // Cross-type snaps to target
      expect(GaugeSection.lerp(progressA, zonesA, 0.2), zonesA);
      expect(GaugeSection.lerp(zonesA, progressA, 0.8), progressA);
    });

    test('GaugeZonesSection.copyWith with zones parameter', () {
      const a = GaugeZonesSection(
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

    test('GaugeTicks equality test', () {
      expect(
        gaugeTicks1 ==
            const GaugeTicks(
              count: 4,
              margin: 7,
              position: GaugeTickPosition.center,
              painter: GaugeTickCirclePainter(radius: 4, color: Colors.blue),
            ),
        true,
      );

      expect(
        gaugeTicks1 ==
            const GaugeTicks(
              count: 4,
              margin: 7,
              position: GaugeTickPosition.center,
              painter: GaugeTickCirclePainter(radius: 4, color: Colors.red),
            ),
        false,
      );

      expect(
        gaugeTicks1 ==
            const GaugeTicks(
              count: 5,
              margin: 7,
              position: GaugeTickPosition.center,
              painter: GaugeTickCirclePainter(radius: 4, color: Colors.blue),
            ),
        false,
      );

      expect(
        gaugeTicks1 ==
            const GaugeTicks(
              count: 4,
              margin: 8,
              position: GaugeTickPosition.center,
              painter: GaugeTickCirclePainter(radius: 4, color: Colors.blue),
            ),
        false,
      );

      expect(
        gaugeTicks1 ==
            const GaugeTicks(
              count: 4,
              margin: 7,
              painter: GaugeTickCirclePainter(radius: 4, color: Colors.blue),
            ),
        false,
      );
    });

    test('GaugeTicks.lerp null handling', () {
      expect(GaugeTicks.lerp(null, null, 0.5), isNull);

      const only = GaugeTicks(
        count: 5,
        painter: GaugeTickCirclePainter(color: Colors.red),
      );
      expect(GaugeTicks.lerp(null, only, 0.5), only);
      expect(GaugeTicks.lerp(only, null, 0.5), isNull);

      const a = GaugeTicks(
        margin: 2,
        painter: GaugeTickCirclePainter(radius: 2, color: Colors.red),
      );
      const b = GaugeTicks(
        count: 7,
        margin: 10,
        painter: GaugeTickCirclePainter(radius: 6, color: Colors.blue),
      );
      final mid = GaugeTicks.lerp(a, b, 0.5)!;
      expect(mid.count, 5);
      expect(mid.margin, 6);
      final painter = mid.painter as GaugeTickCirclePainter;
      expect(painter.radius, 4);
      expect(painter.color, Color.lerp(Colors.red, Colors.blue, 0.5));
    });

    test('GaugeTickCirclePainter equality, getSize, lerp', () {
      const a = GaugeTickCirclePainter(color: Colors.red);
      const b = GaugeTickCirclePainter(color: Colors.red);
      const c = GaugeTickCirclePainter(radius: 5, color: Colors.red);

      expect(a == b, true);
      expect(a == c, false);

      expect(a.getSize(), const Size.fromRadius(3));

      final fallback = a.lerp(a, _OtherTickPainter(), 0.5);
      expect(fallback, isA<_OtherTickPainter>());
    });

    test(
      'GaugeTickCirclePainter.draw renders stroke when strokeWidth > 0',
      () {
        const painter = GaugeTickCirclePainter(
          radius: 4,
          color: Colors.red,
          strokeWidth: 2,
          strokeColor: Colors.blue,
        );
        final canvas = _RecordingCanvas();
        painter.draw(canvas, const Offset(10, 10), 0);
        expect(canvas.circles.length, 2);
        expect(canvas.circles[0].paint.style, PaintingStyle.stroke);
        expect(canvas.circles[0].paint.strokeWidth, 2);
        expect(canvas.circles[0].radius, 5);
        expect(canvas.circles[1].paint.style, PaintingStyle.fill);
        expect(canvas.circles[1].radius, 4);
      },
    );

    test('GaugeTickCirclePainter.draw skips stroke when strokeWidth == 0', () {
      const painter = GaugeTickCirclePainter(radius: 4, color: Colors.red);
      final canvas = _RecordingCanvas();
      painter.draw(canvas, const Offset(10, 10), 0);
      expect(canvas.circles.length, 1);
      expect(canvas.circles[0].paint.style, PaintingStyle.fill);
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

    test('GaugeTouchedSection equality test', () {
      expect(gaugeTouchedSection1 == gaugeTouchedSectionClone1, true);
      expect(gaugeTouchedSection1 == gaugeTouchedSection2, false);
      expect(gaugeTouchedSection1 == gaugeTouchedSection3, false);
    });

    test('GaugeChartDataTween lerp', () {
      final a = GaugeChartData(
        sections: const [
          GaugeProgressSection(
            value: 0.2,
            color: MockData.color0,
            width: 5,
          ),
        ],
        startDegreeOffset: 0,
        strokeCap: StrokeCap.round,
        ticks: const GaugeTicks(
          count: 5,
          margin: 7,
          position: GaugeTickPosition.center,
          painter: GaugeTickCirclePainter(color: MockData.color0, radius: 7),
        ),
        touchData: GaugeTouchData(
          touchCallback: (_, __) {},
          longPressDuration: const Duration(seconds: 7),
          mouseCursorResolver: (_, __) => MouseCursor.defer,
        ),
      );

      final b = GaugeChartData(
        sections: const [
          GaugeProgressSection(
            value: 0.8,
            color: MockData.color2,
            width: 3,
          ),
        ],
        startDegreeOffset: 20,
        sweepAngle: 230,
        strokeCap: StrokeCap.square,
        ticks: const GaugeTicks(
          count: 7,
          margin: 9,
          position: GaugeTickPosition.inner,
          painter: GaugeTickCirclePainter(color: MockData.color2, radius: 5),
        ),
        touchData: GaugeTouchData(
          touchCallback: (_, __) {},
          longPressDuration: const Duration(seconds: 7),
          mouseCursorResolver: (_, __) => MouseCursor.defer,
        ),
      );

      final data = GaugeChartDataTween(begin: a, end: b).lerp(0.5);

      expect(data.sections.length, 1);
      final lerped = data.sections.first as GaugeProgressSection;
      expect(lerped.value, closeTo(0.5, 1e-9));
      expect(lerped.width, 4);
      expect(data.startDegreeOffset, 10);
      expect(data.sweepAngle, 250);
      expect(data.strokeCap, StrokeCap.square);
      expect(data.ticks?.count, 6);
      expect(data.ticks?.margin, 8);
      expect(data.ticks?.position, GaugeTickPosition.inner);
      final tickPainter = data.ticks!.painter as GaugeTickCirclePainter;
      expect(tickPainter.radius, 6);
      expect(tickPainter.color, MockData.color1);
      expect(data.gaugeTouchData, b.gaugeTouchData);
    });

    test('GaugeChartData.lerp throws on illegal state', () {
      final gauge = GaugeChartData(
        sections: const [
          GaugeProgressSection(value: 0.5, color: MockData.color0),
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
        touchedSection: gaugeTouchedSection1,
      );

      final same = response.copyWith();
      expect(same.touchLocation, response.touchLocation);
      expect(same.touchedSection, response.touchedSection);

      final updated = response.copyWith(
        touchLocation: const Offset(30, 40),
        touchedSection: gaugeTouchedSection2,
      );
      expect(updated.touchLocation, const Offset(30, 40));
      expect(updated.touchedSection, gaugeTouchedSection2);
    });
  });
}

class _OtherTickPainter extends GaugeTickPainter {
  @override
  void draw(Canvas canvas, Offset center, double angle) {}

  @override
  Size getSize() => Size.zero;

  @override
  GaugeTickPainter lerp(GaugeTickPainter a, GaugeTickPainter b, double t) => b;

  @override
  List<Object?> get props => [];
}

class _RecordedCircle {
  const _RecordedCircle(this.center, this.radius, this.paint);
  final Offset center;
  final double radius;
  final Paint paint;
}

class _RecordingCanvas implements Canvas {
  final List<_RecordedCircle> circles = <_RecordedCircle>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add(_RecordedCircle(c, radius, paint));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _DummyData extends BaseChartData {
  _DummyData();

  @override
  BaseChartData lerp(BaseChartData a, BaseChartData b, double t) => this;
}
