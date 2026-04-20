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
  }

  /// Draws every ring. Dispatches on the concrete [GaugeRing] type
  /// so progress rings (`GaugeProgressRing`) and zones rings
  /// (`GaugeZonesRing`) paint with their own logic.
  @visibleForTesting
  void drawSections(
    CanvasWrapper canvasWrapper,
    PaintHolder<GaugeChartData> holder,
  ) {
    final data = holder.data;
    final strokeCenters = _sectionStrokeCenters(canvasWrapper.size, data);
    for (var i = 0; i < data.rings.length; i++) {
      final ring = data.rings[i];
      final width = data.resolveRingWidth(ring);
      final radius = strokeCenters[i];
      final rect =
          Rect.fromCircle(center: center(canvasWrapper.size), radius: radius);

      switch (ring) {
        case GaugeProgressRing():
          _drawProgressSection(canvasWrapper, data, ring, rect, width);
        case GaugeZonesRing():
          _drawZonesSection(canvasWrapper, data, ring, rect, width, radius);
      }
    }
  }

  void _drawProgressSection(
    CanvasWrapper canvasWrapper,
    GaugeChartData data,
    GaugeProgressRing ring,
    Rect rect,
    double width,
  ) {
    final signedSweep = _signedSweep(data);
    final range = data.maxValue - data.minValue;

    if (ring.backgroundColor != null) {
      _arcPaint
        ..color = ring.backgroundColor!
        ..strokeWidth = width
        ..strokeCap = ring.strokeCap
        ..style = PaintingStyle.stroke;
      canvasWrapper.drawArc(
        rect,
        Utils().radians(data.startDegreeOffset),
        Utils().radians(signedSweep),
        false,
        _arcPaint,
      );
    }

    final filledSweep = signedSweep * ((ring.value - data.minValue) / range);
    _arcPaint
      ..color = ring.color
      ..strokeWidth = width
      ..strokeCap = ring.strokeCap
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
    GaugeZonesRing ring,
    Rect rect,
    double width,
    double strokeCenterRadius,
  ) {
    final dir = data.direction == GaugeDirection.clockwise ? 1 : -1;
    final degreesPerUnit = data.sweepAngle / (data.maxValue - data.minValue);

    void drawZoneArc(GaugeZone zone) {
      final startDeg = data.startDegreeOffset +
          dir * (zone.from - data.minValue) * degreesPerUnit;
      final sweepDeg = dir * (zone.to - zone.from) * degreesPerUnit;
      _arcPaint
        ..color = zone.color
        ..strokeWidth = width
        ..strokeCap = zone.strokeCap
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver;
      canvasWrapper.drawArc(
        rect,
        Utils().radians(startDeg),
        Utils().radians(sweepDeg),
        false,
        _arcPaint,
      );
    }

    // No spacing needed — draw each zone full-angular.
    if (ring.zonesSpace == 0 || ring.zones.length < 2) {
      ring.zones.forEach(drawZoneArc);
      return;
    }

    // Draw each zone full-angular, then carve a perpendicular
    // rectangular strip at each internal boundary. The strip has a
    // constant perpendicular width of `zonesSpace`, so the visible gap
    // stays uniform across the ring's thickness (no wedge effect).
    // `saveLayer` + `BlendMode.clear` is the standard technique for
    // erasing already-painted pixels without leaking to the background.
    final c = center(canvasWrapper.size);
    final layerBounds = Rect.fromCircle(
      center: c,
      radius: strokeCenterRadius + width,
    );
    canvasWrapper.saveLayer(layerBounds, Paint());
    ring.zones.forEach(drawZoneArc);
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (var i = 0; i < ring.zones.length - 1; i++) {
      final boundaryDeg = data.startDegreeOffset +
          dir * (ring.zones[i].to - data.minValue) * degreesPerUnit;
      final strip = _perpendicularStripPath(
        center: c,
        angleRad: Utils().radians(boundaryDeg),
        strokeCenterRadius: strokeCenterRadius,
        strokeWidth: width,
        zonesSpace: ring.zonesSpace,
      );
      canvasWrapper.drawPath(strip, clearPaint);
    }
    canvasWrapper.restore();
  }

  /// Builds a rectangular path centered on the radial line at
  /// [angleRad], perpendicular to it, used to carve a uniform-width
  /// gap between two adjacent zones.
  ///
  /// - Perpendicular extent (across the gap): [zonesSpace].
  /// - Radial extent (along the ring): `strokeWidth * 2`, centered on
  ///   [strokeCenterRadius] so the strip fully clears the ring plus
  ///   any round/square caps on the adjacent zones.
  Path _perpendicularStripPath({
    required Offset center,
    required double angleRad,
    required double strokeCenterRadius,
    required double strokeWidth,
    required double zonesSpace,
  }) {
    final cosA = math.cos(angleRad);
    final sinA = math.sin(angleRad);
    // Tangent unit vector = radial rotated 90° CCW.
    final tx = -sinA;
    final ty = cosA;
    final half = zonesSpace / 2;
    final rOuter = strokeCenterRadius + strokeWidth;
    final rInner = math.max<double>(0, strokeCenterRadius - strokeWidth);
    Offset corner(double r, double s) => Offset(
          center.dx + cosA * r + tx * half * s,
          center.dy + sinA * r + ty * half * s,
        );
    final p1 = corner(rOuter, 1);
    final p2 = corner(rOuter, -1);
    final p3 = corner(rInner, -1);
    final p4 = corner(rInner, 1);
    return Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
  }

  /// Returns a [GaugeTouchedRing] describing what the touch hit, or
  /// null when the touch was entirely outside the gauge's angular range.
  ///
  /// When the touch is on-arc but falls in the gap between rings (or
  /// outside every ring's radial band) the returned ring has
  /// [GaugeTouchedRing.touchedRingIndex] == -1 while still carrying
  /// a valid [GaugeTouchedRing.touchValue].
  GaugeTouchedRing? handleTouch(
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
    for (var i = 0; i < data.rings.length; i++) {
      final ring = data.rings[i];
      final width = data.resolveRingWidth(ring);
      if ((distance - strokeCenters[i]).abs() > width / 2) continue;

      switch (ring) {
        case GaugeProgressRing():
          return GaugeTouchedRing(
            touchedRing: ring,
            touchedRingIndex: i,
            touchAngle: touchAngleDeg,
            touchRadius: distance,
            touchValue: touchValue,
            isOnValue: touchValue <= ring.value,
          );
        case GaugeZonesRing():
          var zoneIndex = -1;
          GaugeZone? zone;
          for (var j = 0; j < ring.zones.length; j++) {
            final z = ring.zones[j];
            if (touchValue >= z.from && touchValue <= z.to) {
              zoneIndex = j;
              zone = z;
              // Later zones paint on top in drawZonesSection, so the
              // visually-topmost zone is the last match — keep iterating.
            }
          }
          return GaugeTouchedRing(
            touchedRing: ring,
            touchedRingIndex: i,
            touchAngle: touchAngleDeg,
            touchRadius: distance,
            touchValue: touchValue,
            isOnValue: false,
            touchedZone: zone,
            touchedZoneIndex: zoneIndex,
          );
      }
    }

    return GaugeTouchedRing(
      touchedRing: null,
      touchedRingIndex: -1,
      touchAngle: touchAngleDeg,
      touchRadius: distance,
      touchValue: touchValue,
      isOnValue: false,
    );
  }

  /// Outer radius available for the gauge's rings.
  double _outerArcRadius(Size viewSize) => viewSize.shortestSide / 2;

  /// Total radial thickness consumed by all rings plus the gaps between
  /// them.
  double _totalRingsDepth(GaugeChartData data) {
    var depth = data.ringsSpace * (data.rings.length - 1);
    for (final ring in data.rings) {
      depth += data.resolveRingWidth(ring);
    }
    return depth;
  }

  /// Stroke-centered radius per ring, indexed to match
  /// [GaugeChartData.rings]: entry 0 is the innermost ring, the last
  /// entry is the outermost.
  List<double> _sectionStrokeCenters(Size viewSize, GaugeChartData data) {
    final outer = _outerArcRadius(viewSize);
    final innerEdge = outer - _totalRingsDepth(data);
    final centers = <double>[];
    var currentInner = innerEdge;
    for (var i = 0; i < data.rings.length; i++) {
      if (i > 0) currentInner += data.ringsSpace;
      final width = data.resolveRingWidth(data.rings[i]);
      centers.add(currentInner + width / 2);
      currentInner += width;
    }
    return centers;
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
