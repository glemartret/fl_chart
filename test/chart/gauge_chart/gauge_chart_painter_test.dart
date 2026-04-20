import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/gauge_chart/gauge_chart_painter.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../data_pool.dart';
import 'gauge_chart_painter_test.mocks.dart';

@GenerateMocks([Canvas, CanvasWrapper, BuildContext, Utils])
void main() {
  final utilsMainInstance = Utils();

  /// Installs a mocked [Utils] whose [radians] / [degrees] methods pass
  /// values through unchanged. This lets tests assert on the *degree*
  /// arguments passed to [Canvas.drawArc] instead of radian values.
  MockUtils installIdentityUtilsMock() {
    final mockUtils = MockUtils();
    Utils.changeInstance(mockUtils);
    when(mockUtils.radians(any)).thenAnswer(
      (inv) => inv.positionalArguments[0] as double,
    );
    when(mockUtils.degrees(any)).thenAnswer(
      (inv) => inv.positionalArguments[0] as double,
    );
    return mockUtils;
  }

  /// Installs a mocked [Utils] that delegates radians/degrees to the real
  /// implementation — used by handleTouch tests that need honest
  /// conversions.
  MockUtils installRealUtilsMock() {
    final mockUtils = MockUtils();
    Utils.changeInstance(mockUtils);
    when(mockUtils.radians(any)).thenAnswer(
      (inv) => utilsMainInstance.radians(inv.positionalArguments[0] as double),
    );
    when(mockUtils.degrees(any)).thenAnswer(
      (inv) => utilsMainInstance.degrees(inv.positionalArguments[0] as double),
    );
    return mockUtils;
  }

  group('paint()', () {
    test('dispatches to drawSections (no ticks)', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        rings: const [
          GaugeProgressRing(value: 0.5, color: Colors.red, width: 2),
        ],
        sweepAngle: 90,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());
      gaugePainter.paint(MockBuildContext(), mockCanvasWrapper, holder);

      // One drawArc for the ring's filled portion (no background).
      verify(mockCanvasWrapper.drawArc(any, any, any, any, any)).called(1);
      Utils.changeInstance(utilsMainInstance);
    });
  });

  group('drawSections()', () {
    test('single ring draws only filled arc when backgroundColor is null', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        rings: const [
          GaugeProgressRing(value: 0.5, color: MockData.color0, width: 2),
        ],
        startDegreeOffset: 0,
        sweepAngle: 90,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final captured = <Map<String, dynamic>>[];
      when(
        mockCanvasWrapper.drawArc(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).thenAnswer((inv) {
        captured.add({
          'rect': inv.positionalArguments[0] as Rect,
          'start_angle': inv.positionalArguments[1] as double,
          'sweep_angle': inv.positionalArguments[2] as double,
          'paint_color': (inv.positionalArguments[4] as Paint).color,
          'paint_stroke_width':
              (inv.positionalArguments[4] as Paint).strokeWidth,
        });
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);

      expect(captured.length, 1);
      expect(captured[0]['start_angle'], 0);
      // 0.5/1.0 * 90° = 45°
      expect(captured[0]['sweep_angle'], 45);
      expect(captured[0]['paint_color'], isSameColorAs(MockData.color0));
      expect(captured[0]['paint_stroke_width'], 2);
      Utils.changeInstance(utilsMainInstance);
    });

    test('draws background arc + filled arc when backgroundColor is set', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        rings: const [
          GaugeProgressRing(
            value: 0.5,
            color: MockData.color0,
            width: 8,
            backgroundColor: MockData.color1,
          ),
        ],
        startDegreeOffset: 10,
        sweepAngle: 90,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final captured = <Map<String, dynamic>>[];
      when(
        mockCanvasWrapper.drawArc(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).thenAnswer((inv) {
        captured.add({
          'start_angle': inv.positionalArguments[1] as double,
          'sweep_angle': inv.positionalArguments[2] as double,
          'paint_color': (inv.positionalArguments[4] as Paint).color,
          'paint_stroke_width':
              (inv.positionalArguments[4] as Paint).strokeWidth,
        });
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);

      expect(captured.length, 2);
      // Background: full sweep
      expect(captured[0]['start_angle'], 10);
      expect(captured[0]['sweep_angle'], 90);
      expect(captured[0]['paint_color'], isSameColorAs(MockData.color1));
      // Filled: value/range * sweep
      expect(captured[1]['start_angle'], 10);
      expect(captured[1]['sweep_angle'], 45);
      expect(captured[1]['paint_color'], isSameColorAs(MockData.color0));
      Utils.changeInstance(utilsMainInstance);
    });

    test('multiple rings stack innermost-first with ringsSpace', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        rings: const [
          // innermost
          GaugeProgressRing(value: 0.5, color: Colors.red, width: 10),
          GaugeProgressRing(value: 0.8, color: Colors.green, width: 20),
          // outermost
          GaugeProgressRing(value: 0.3, color: Colors.blue, width: 15),
        ],
        sweepAngle: 180,
        ringsSpace: 4,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final rects = <Rect>[];
      when(
        mockCanvasWrapper.drawArc(captureAny, any, any, any, any),
      ).thenAnswer((inv) {
        rects.add(inv.positionalArguments[0] as Rect);
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);

      // 3 rings, no backgroundColor → 3 draws.
      expect(rects.length, 3);

      // Outer = 200. Widths 10, 20, 15; gaps 4 each; total depth = 53.
      // innermost edge = 200 - 53 = 147.
      // Section 0 (innermost, width 10): stroke center = 147 + 5 = 152.
      // Section 1 (width 20, space 4):  161 + 10 = 171.
      // Section 2 (outermost, width 15): 185 + 7.5 = 192.5.
      expect(rects[0].shortestSide / 2, 152);
      expect(rects[1].shortestSide / 2, 171);
      expect(rects[2].shortestSide / 2, 192.5);
      Utils.changeInstance(utilsMainInstance);
    });

    test('non-default min/max scales the filled sweep proportionally', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeProgressRing(value: 75, color: Colors.red, width: 10),
        ],
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final sweeps = <double>[];
      when(
        mockCanvasWrapper.drawArc(any, any, captureAny, any, any),
      ).thenAnswer((inv) {
        sweeps.add(inv.positionalArguments[2] as double);
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);
      expect(sweeps.length, 1);
      // 75/100 * 180 = 135
      expect(sweeps[0], 135);
      Utils.changeInstance(utilsMainInstance);
    });

    test('counterClockwise direction flips the filled sweep sign', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        rings: const [
          GaugeProgressRing(value: 0.5, color: Colors.red, width: 5),
        ],
        sweepAngle: 100,
        direction: GaugeDirection.counterClockwise,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final sweeps = <double>[];
      when(
        mockCanvasWrapper.drawArc(any, any, captureAny, any, any),
      ).thenAnswer((inv) {
        sweeps.add(inv.positionalArguments[2] as double);
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);
      // -100 * 0.5/1.0 = -50
      expect(sweeps[0], -50);
      Utils.changeInstance(utilsMainInstance);
    });
  });

  group('handleTouch()', () {
    test('returns null for touches outside the arc angular range', () {
      const viewSize = Size(250, 250);
      final data = GaugeChartData(
        rings: const [
          GaugeProgressRing(value: 1, color: Colors.red, width: 30),
        ],
        startDegreeOffset: 0,
        sweepAngle: 90, // arc from 0° to 90°
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installRealUtilsMock();

      // Touch above center (angle = -90°), outside [0°, 90°].
      final result = gaugePainter.handleTouch(
        const Offset(125, 30),
        viewSize,
        holder,
      );
      expect(result, isNull);
      Utils.changeInstance(utilsMainInstance);
    });

    test('reports correct ring and isOnValue for a touch on the filled part',
        () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeProgressRing(value: 70, color: Colors.red, width: 20),
        ],
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installRealUtilsMock();

      // Ring stroke center at 200 - 10 = 190.
      // Touch the ring at 45° (value 25 — on the filled portion since 25 < 70).
      const center = Offset(200, 200);
      const deg = 45.0;
      const rad = deg * pi / 180;
      final touch = center + Offset(cos(rad), sin(rad)) * 190;
      final hit = gaugePainter.handleTouch(touch, viewSize, holder);

      expect(hit, isNotNull);
      expect(hit!.touchedRingIndex, 0);
      expect(hit.touchValue, closeTo(25, 1e-6));
      expect(hit.isOnValue, isTrue);
      Utils.changeInstance(utilsMainInstance);
    });

    test(
        'ring hit on background part returns isOnValue=false with a '
        'valid touchValue', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeProgressRing(value: 70, color: Colors.red, width: 20),
        ],
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installRealUtilsMock();

      // Touch at 162° (value 90 — past 70, on the background portion).
      const center = Offset(200, 200);
      const deg = 162.0;
      const rad = deg * pi / 180;
      final touch = center + Offset(cos(rad), sin(rad)) * 190;
      final hit = gaugePainter.handleTouch(touch, viewSize, holder);

      expect(hit, isNotNull);
      expect(hit!.touchedRingIndex, 0);
      expect(hit.touchValue, closeTo(90, 1e-6));
      expect(hit.isOnValue, isFalse);
      Utils.changeInstance(utilsMainInstance);
    });

    test('inner rings are reachable when stacked with ringsSpace', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        rings: const [
          GaugeProgressRing(value: 1, color: Colors.red, width: 10),
          GaugeProgressRing(value: 1, color: Colors.blue, width: 10),
        ],
        ringsSpace: 4,
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installRealUtilsMock();

      // Sections listed innermost-first: total depth = 10 + 4 + 10 = 24,
      // innermost edge at 200 - 24 = 176. Ring 0 (innermost) stroke center
      // 181; ring 1 (outermost) stroke center 195.
      const center = Offset(200, 200);
      final hitInner = gaugePainter.handleTouch(
        center + const Offset(181, 0),
        viewSize,
        holder,
      );
      expect(hitInner!.touchedRingIndex, 0);

      final hitOuter = gaugePainter.handleTouch(
        center + const Offset(195, 0),
        viewSize,
        holder,
      );
      expect(hitOuter!.touchedRingIndex, 1);

      // Touch in the gap between rings (radius 188 → neither ring).
      final miss = gaugePainter.handleTouch(
        center + const Offset(188, 0),
        viewSize,
        holder,
      );
      expect(miss, isNotNull);
      expect(miss!.touchedRing, isNull);
      expect(miss.touchedRingIndex, -1);
      expect(miss.isOnValue, isFalse);
      Utils.changeInstance(utilsMainInstance);
    });
  });

  group('drawSections() — zones ring', () {
    test('draws one arc per zone with correct sweep and color', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeZonesRing(
            width: 10,
            zones: [
              GaugeZone(from: 0, to: 50, color: MockData.color0),
              GaugeZone(from: 50, to: 80, color: MockData.color1),
              GaugeZone(from: 80, to: 100, color: MockData.color2),
            ],
          ),
        ],
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final captured = <Map<String, dynamic>>[];
      when(
        mockCanvasWrapper.drawArc(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).thenAnswer((inv) {
        captured.add({
          'start': inv.positionalArguments[1] as double,
          'sweep': inv.positionalArguments[2] as double,
          'color': (inv.positionalArguments[4] as Paint).color,
        });
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);

      expect(captured.length, 3);
      // Zone 0: 0..50 → 90°
      expect(captured[0]['start'], 0);
      expect(captured[0]['sweep'], 90);
      expect(captured[0]['color'], isSameColorAs(MockData.color0));
      // Zone 1: 50..80 → starts at 90°, sweeps 54°
      expect(captured[1]['start'], 90);
      expect(captured[1]['sweep'], closeTo(54, 1e-9));
      // Zone 2: 80..100 → starts at 144°, sweeps 36°
      expect(captured[2]['start'], closeTo(144, 1e-9));
      expect(captured[2]['sweep'], closeTo(36, 1e-9));
      Utils.changeInstance(utilsMainInstance);
    });

    test(
        'zonesSpace shrinks only between-zone boundaries, not gauge '
        'extremes', () {
      const viewSize = Size(400, 400);
      // stroke center radius = 200 - 10/2 = 195
      const strokeCenter = 195.0;
      const zonesSpace = 10.0;
      // Identity utils mock returns Utils().degrees(x) == x, so the
      // "degrees" per half-space are (zonesSpace / 2) / radius.
      const halfSpaceDeg = (zonesSpace / 2) / strokeCenter;
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeZonesRing(
            width: 10,
            zonesSpace: zonesSpace,
            zones: [
              GaugeZone(from: 0, to: 50, color: MockData.color0),
              GaugeZone(from: 50, to: 80, color: MockData.color1),
              GaugeZone(from: 80, to: 100, color: MockData.color2),
            ],
          ),
        ],
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final captured = <Map<String, double>>[];
      when(
        mockCanvasWrapper.drawArc(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).thenAnswer((inv) {
        captured.add({
          'start': inv.positionalArguments[1] as double,
          'sweep': inv.positionalArguments[2] as double,
        });
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);

      expect(captured.length, 3);
      // Zone 0 (first): no leading shrink, trailing shrink.
      expect(captured[0]['start'], 0);
      expect(captured[0]['sweep'], closeTo(90 - halfSpaceDeg, 1e-9));
      // Zone 1 (middle): both shrinks.
      expect(captured[1]['start'], closeTo(90 + halfSpaceDeg, 1e-9));
      expect(captured[1]['sweep'], closeTo(54 - 2 * halfSpaceDeg, 1e-9));
      // Zone 2 (last): leading shrink, no trailing shrink.
      expect(captured[2]['start'], closeTo(144 + halfSpaceDeg, 1e-9));
      expect(captured[2]['sweep'], closeTo(36 - halfSpaceDeg, 1e-9));
      Utils.changeInstance(utilsMainInstance);
    });

    test('zonesSpace skips zones whose arc collapses to zero', () {
      const viewSize = Size(400, 400);
      // sweepAngle 180 / maxValue 100 = 1.8°/unit. Middle zone spans
      // 1°→1.8° — collapses when both-side shrink > 1.8°.
      // halfSpaceDeg = (400/2)/195 ≈ 1.025°, so middle shrinks to
      // 1.8 - 2*1.025 = -0.25 → skipped. First and last zones only
      // bear one-sided shrink and survive comfortably.
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeZonesRing(
            width: 10,
            zonesSpace: 400,
            zones: [
              GaugeZone(from: 0, to: 50, color: MockData.color0),
              // Narrow middle — collapses
              GaugeZone(from: 50, to: 51, color: MockData.color1),
              GaugeZone(from: 51, to: 100, color: MockData.color2),
            ],
          ),
        ],
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installIdentityUtilsMock();

      final mockCanvasWrapper = MockCanvasWrapper();
      when(mockCanvasWrapper.size).thenAnswer((_) => viewSize);
      when(mockCanvasWrapper.canvas).thenReturn(MockCanvas());

      final captured = <Color>[];
      when(
        mockCanvasWrapper.drawArc(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).thenAnswer((inv) {
        captured.add((inv.positionalArguments[4] as Paint).color);
      });

      gaugePainter.drawSections(mockCanvasWrapper, holder);

      // Middle zone collapsed and skipped; first and last drawn.
      expect(captured.length, 2);
      expect(captured[0], isSameColorAs(MockData.color0));
      expect(captured[1], isSameColorAs(MockData.color2));
      Utils.changeInstance(utilsMainInstance);
    });
  });

  group('handleTouch() — zones ring', () {
    test('returns the hit zone for a touch inside a zone', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeZonesRing(
            width: 20,
            zones: [
              GaugeZone(from: 0, to: 50, color: Colors.red),
              GaugeZone(from: 50, to: 80, color: Colors.amber),
              GaugeZone(from: 80, to: 100, color: Colors.green),
            ],
          ),
        ],
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installRealUtilsMock();

      // ring stroke center = 200 - 10 = 190
      const center = Offset(200, 200);
      // Touch at 45° — value = 25 → zone 0
      {
        const rad = 45 * pi / 180;
        final touch = center + Offset(cos(rad), sin(rad)) * 190;
        final hit = gaugePainter.handleTouch(touch, viewSize, holder);
        expect(hit, isNotNull);
        expect(hit!.touchedRingIndex, 0);
        expect(hit.touchedZoneIndex, 0);
        expect(hit.touchedZone?.color, Colors.red);
        expect(hit.isOnValue, isFalse); // zones never flag isOnValue
      }
      // Touch at 135° — value = 75 → zone 1
      {
        const rad = 135 * pi / 180;
        final touch = center + Offset(cos(rad), sin(rad)) * 190;
        final hit = gaugePainter.handleTouch(touch, viewSize, holder);
        expect(hit!.touchedZoneIndex, 1);
        expect(hit.touchedZone?.color, Colors.amber);
      }
      Utils.changeInstance(utilsMainInstance);
    });

    test('reports null zone when touch falls in a gap between zones', () {
      const viewSize = Size(400, 400);
      final data = GaugeChartData(
        maxValue: 100,
        rings: const [
          GaugeZonesRing(
            width: 20,
            zones: [
              GaugeZone(from: 0, to: 30, color: Colors.red),
              // gap 30..70
              GaugeZone(from: 70, to: 100, color: Colors.green),
            ],
          ),
        ],
        startDegreeOffset: 0,
        sweepAngle: 180,
      );
      final gaugePainter = GaugeChartPainter();
      final holder =
          PaintHolder<GaugeChartData>(data, data, TextScaler.noScaling);
      installRealUtilsMock();

      // Touch at 90° — value = 50, sits in the gap
      const center = Offset(200, 200);
      const rad = 90 * pi / 180;
      final touch = center + Offset(cos(rad), sin(rad)) * 190;
      final hit = gaugePainter.handleTouch(touch, viewSize, holder);

      expect(hit, isNotNull);
      // Ring itself IS hit
      expect(hit!.touchedRingIndex, 0);
      expect(hit.touchedRing, isA<GaugeZonesRing>());
      // But no zone contains value 50
      expect(hit.touchedZone, isNull);
      expect(hit.touchedZoneIndex, -1);
      Utils.changeInstance(utilsMainInstance);
    });
  });
}
