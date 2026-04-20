import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/material.dart';

class GaugeChartPainter extends BaseChartPainter<GaugeChartData> {
  GaugeChartPainter() : super() {
    _arcPaint = Paint()..isAntiAlias = true;
  }

  late Paint _arcPaint;

  @visibleForTesting
  Offset center(Size size) => Offset(size.width / 2.0, size.height / 2.0);

  @override
  void paint(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<GaugeChartData> holder,
  ) {
    super.paint(context, canvasWrapper, holder);
    drawSections(canvasWrapper, holder);
    drawTicks(canvasWrapper, holder);
  }

  /// Draws every ring. Dispatches on the concrete [GaugeSection] type
  /// so progress rings (`GaugeProgressSection`) and zones rings
  /// (`GaugeZonesSection`) paint with their own logic.
  @visibleForTesting
  void drawSections(
    CanvasWrapper canvasWrapper,
    PaintHolder<GaugeChartData> holder,
  ) {
    final data = holder.data;
    final strokeCenters = _sectionStrokeCenters(canvasWrapper.size, data);
    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final width = data.resolveSectionWidth(section);
      final radius = strokeCenters[i];
      final rect =
          Rect.fromCircle(center: center(canvasWrapper.size), radius: radius);

      switch (section) {
        case GaugeProgressSection():
          _drawProgressSection(canvasWrapper, data, section, rect, width);
        case GaugeZonesSection():
          _drawZonesSection(canvasWrapper, data, section, rect, width);
      }
    }
  }

  void _drawProgressSection(
    CanvasWrapper canvasWrapper,
    GaugeChartData data,
    GaugeProgressSection section,
    Rect rect,
    double width,
  ) {
    final signedSweep = _signedSweep(data);
    final range = data.maxValue - data.minValue;

    if (section.backgroundColor != null) {
      _arcPaint
        ..color = section.backgroundColor!
        ..strokeWidth = width
        ..strokeCap = data.strokeCap
        ..style = PaintingStyle.stroke;
      canvasWrapper.drawArc(
        rect,
        Utils().radians(data.startDegreeOffset),
        Utils().radians(signedSweep),
        false,
        _arcPaint,
      );
    }

    final filledSweep = signedSweep * ((section.value - data.minValue) / range);
    _arcPaint
      ..color = section.color
      ..strokeWidth = width
      ..strokeCap = data.strokeCap
      ..style = PaintingStyle.stroke;
    canvasWrapper.drawArc(
      rect,
      Utils().radians(data.startDegreeOffset),
      Utils().radians(filledSweep),
      false,
      _arcPaint,
    );
  }

  void _drawZonesSection(
    CanvasWrapper canvasWrapper,
    GaugeChartData data,
    GaugeZonesSection section,
    Rect rect,
    double width,
  ) {
    final dir = data.direction == GaugeDirection.clockwise ? 1 : -1;
    final degreesPerUnit = data.sweepAngle / (data.maxValue - data.minValue);
    for (final zone in section.zones) {
      final startDeg = data.startDegreeOffset +
          dir * (zone.from - data.minValue) * degreesPerUnit;
      final sweepDeg = dir * (zone.to - zone.from) * degreesPerUnit;
      _arcPaint
        ..color = zone.color
        ..strokeWidth = width
        ..strokeCap = data.strokeCap
        ..style = PaintingStyle.stroke;
      canvasWrapper.drawArc(
        rect,
        Utils().radians(startDeg),
        Utils().radians(sweepDeg),
        false,
        _arcPaint,
      );
    }
  }

  /// Draws tick marks around the gauge as a whole (not a specific ring).
  @visibleForTesting
  void drawTicks(
    CanvasWrapper canvasWrapper,
    PaintHolder<GaugeChartData> holder,
  ) {
    final data = holder.data;
    final ticks = data.ticks;
    if (ticks == null) return;

    final size = canvasWrapper.size;
    final c = center(size);
    final dir = data.direction == GaugeDirection.clockwise ? 1 : -1;
    final interTickDegrees = (dir * data.sweepAngle) / (ticks.count - 1);

    final tickRadius = _tickRadius(size, data);
    for (var i = 0; i < ticks.count; i++) {
      final angleRad =
          Utils().radians(data.startDegreeOffset + interTickDegrees * i);
      final position =
          c + Offset(math.cos(angleRad), math.sin(angleRad)) * tickRadius;
      ticks.painter.draw(canvasWrapper.canvas, position, angleRad);
    }
  }

  /// Returns a [GaugeTouchedSection] describing what the touch hit, or
  /// null when the touch was entirely outside the gauge's angular range.
  ///
  /// When the touch is on-arc but falls in the gap between rings (or
  /// outside every ring's radial band) the returned section has
  /// [GaugeTouchedSection.touchedSectionIndex] == -1 while still carrying
  /// a valid [GaugeTouchedSection.touchValue].
  GaugeTouchedSection? handleTouch(
    Offset touchedPoint,
    Size viewSize,
    PaintHolder<GaugeChartData> holder,
  ) {
    final data = holder.data;
    final c = center(viewSize);
    final vector = touchedPoint - c;
    final distance = vector.distance;
    final touchAngleDeg = Utils().degrees(vector.direction);

    final along = _angleAlongSweep(touchAngleDeg, data);
    if (along == null) return null;

    final range = data.maxValue - data.minValue;
    final touchValue = data.minValue + (along / data.sweepAngle) * range;

    final strokeCenters = _sectionStrokeCenters(viewSize, data);
    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final width = data.resolveSectionWidth(section);
      if ((distance - strokeCenters[i]).abs() > width / 2) continue;

      switch (section) {
        case GaugeProgressSection():
          return GaugeTouchedSection(
            touchedSection: section,
            touchedSectionIndex: i,
            touchAngle: touchAngleDeg,
            touchRadius: distance,
            touchValue: touchValue,
            isOnValue: touchValue <= section.value,
          );
        case GaugeZonesSection():
          var zoneIndex = -1;
          GaugeZone? zone;
          for (var j = 0; j < section.zones.length; j++) {
            final z = section.zones[j];
            if (touchValue >= z.from && touchValue <= z.to) {
              zoneIndex = j;
              zone = z;
              // Later zones paint on top in drawZonesSection, so the
              // visually-topmost zone is the last match — keep iterating.
            }
          }
          return GaugeTouchedSection(
            touchedSection: section,
            touchedSectionIndex: i,
            touchAngle: touchAngleDeg,
            touchRadius: distance,
            touchValue: touchValue,
            isOnValue: false,
            touchedZone: zone,
            touchedZoneIndex: zoneIndex,
          );
      }
    }

    return GaugeTouchedSection(
      touchedSection: null,
      touchedSectionIndex: -1,
      touchAngle: touchAngleDeg,
      touchRadius: distance,
      touchValue: touchValue,
      isOnValue: false,
    );
  }

  /// Padding reserved outside the outermost ring for ticks drawn on the
  /// outer position.
  double _outerTickPadding(GaugeChartData data) {
    final ticks = data.ticks;
    if (ticks == null || ticks.position != GaugeTickPosition.outer) return 0;
    return ticks.margin + ticks.painter.getSize().height / 2;
  }

  /// Outer radius available for the gauge's rings (excludes outer tick
  /// padding).
  double _outerArcRadius(Size viewSize, GaugeChartData data) =>
      viewSize.shortestSide / 2 - _outerTickPadding(data);

  /// Total radial thickness consumed by all rings plus the gaps between
  /// them.
  double _totalRingsDepth(GaugeChartData data) {
    var depth = data.sectionsSpace * (data.sections.length - 1);
    for (final section in data.sections) {
      depth += data.resolveSectionWidth(section);
    }
    return depth;
  }

  /// Stroke-centered radius per section, indexed to match
  /// [GaugeChartData.sections]: entry 0 is the innermost ring, the last
  /// entry is the outermost.
  List<double> _sectionStrokeCenters(Size viewSize, GaugeChartData data) {
    final outer = _outerArcRadius(viewSize, data);
    final innerEdge = outer - _totalRingsDepth(data);
    final centers = <double>[];
    var currentInner = innerEdge;
    for (var i = 0; i < data.sections.length; i++) {
      if (i > 0) currentInner += data.sectionsSpace;
      final width = data.resolveSectionWidth(data.sections[i]);
      centers.add(currentInner + width / 2);
      currentInner += width;
    }
    return centers;
  }

  /// Where ticks are drawn radially, relative to the gauge's center.
  double _tickRadius(Size viewSize, GaugeChartData data) {
    final outer = _outerArcRadius(viewSize, data);
    final inner = outer - _totalRingsDepth(data);
    final ticks = data.ticks!;
    final tickHalfSize = ticks.painter.getSize().height / 2;
    return switch (ticks.position) {
      GaugeTickPosition.outer => outer + ticks.margin + tickHalfSize,
      GaugeTickPosition.inner => inner - ticks.margin - tickHalfSize,
      GaugeTickPosition.center => (outer + inner) / 2,
    };
  }

  double _signedSweep(GaugeChartData data) =>
      data.direction == GaugeDirection.clockwise
          ? data.sweepAngle
          : -data.sweepAngle;

  /// Projects [touchDeg] onto the arc's local angular coordinate
  /// (0 at start, positive toward sweep end). Returns null when the
  /// touch is outside the angular range.
  double? _angleAlongSweep(double touchDeg, GaugeChartData data) {
    final dir = data.direction == GaugeDirection.clockwise ? 1 : -1;
    var rel = dir * (touchDeg - data.startDegreeOffset);
    rel = ((rel % 360) + 360) % 360;
    if (rel <= data.sweepAngle) return rel;
    return null;
  }
}
