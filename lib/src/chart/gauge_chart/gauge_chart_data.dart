import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/utils/lerp.dart';
import 'package:flutter/widgets.dart';

/// [GaugeChart] needs this class to render itself.
///
/// A gauge chart is a set of concentric rings drawn along a shared arc.
/// Each [GaugeRing] is one ring on a scale shared by every ring.
/// Sections are stacked innermost-first in list order — so `rings[0]`
/// is the innermost ring and the last entry is the outermost — separated
/// by [ringsSpace] pixels.
///
/// A ring is one of two shapes:
/// - [GaugeProgressRing] — a ring filled from [minValue] up to its
///   `value`, with an optional `backgroundColor` behind.
/// - [GaugeZonesRing] — a ring divided into fixed colored [GaugeZone]s
///   (threshold bands). Useful for speedometer-style level indicators.
class GaugeChartData extends BaseChartData with EquatableMixin {
  GaugeChartData({
    required List<GaugeRing> rings,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.startDegreeOffset = -225.0,
    this.sweepAngle = 270.0,
    this.direction = GaugeDirection.clockwise,
    this.defaultRingWidth = 10.0,
    this.ringsSpace = 0.0,
    GaugeTouchData? touchData,
    super.borderData,
  })  : rings = List.unmodifiable(rings),
        gaugeTouchData = touchData ?? GaugeTouchData(),
        assert(maxValue > minValue, 'maxValue must be greater than minValue'),
        assert(
          sweepAngle > 0 && sweepAngle <= 360,
          'sweepAngle must be in (0, 360]',
        ),
        assert(ringsSpace >= 0, 'ringsSpace must be >= 0') {
    for (final ring in rings) {
      switch (ring) {
        case GaugeProgressRing():
          assert(
            ring.value >= minValue && ring.value <= maxValue,
            'GaugeProgressRing.value ${ring.value} is outside '
            '[$minValue, $maxValue]',
          );
        case GaugeZonesRing():
          assert(
            ring.zones.isNotEmpty,
            'GaugeZonesRing.zones must not be empty',
          );
          for (final zone in ring.zones) {
            assert(
              zone.from >= minValue && zone.to <= maxValue,
              'GaugeZone [${zone.from}, ${zone.to}] is outside '
              '[$minValue, $maxValue]',
            );
          }
      }
    }
  }

  /// Convenience factory for the single-ring progress bar use case
  /// (battery meter, loading indicator, etc.). Shorthand for a
  /// [GaugeChartData] with one [GaugeProgressRing].
  factory GaugeChartData.progress({
    required double value,
    required Color color,
    required double width,
    Color? backgroundColor,
    double min = 0.0,
    double max = 1.0,
    StrokeCap strokeCap = StrokeCap.butt,
    double startDegreeOffset = -225.0,
    double sweepAngle = 270.0,
    GaugeDirection direction = GaugeDirection.clockwise,
    GaugeTouchData? touchData,
    FlBorderData? borderData,
  }) =>
      GaugeChartData(
        minValue: min,
        maxValue: max,
        rings: [
          GaugeProgressRing(
            value: value.clamp(min, max),
            color: color,
            width: width,
            backgroundColor: backgroundColor,
            strokeCap: strokeCap,
          ),
        ],
        defaultRingWidth: width,
        startDegreeOffset: startDegreeOffset,
        sweepAngle: sweepAngle,
        direction: direction,
        touchData: touchData,
        borderData: borderData,
      );

  /// The rings drawn by the chart, innermost first.
  final List<GaugeRing> rings;

  /// Lower bound of the gauge scale (inclusive). Shared by every ring.
  /// default is 0.0
  final double minValue;

  /// Upper bound of the gauge scale (inclusive). Shared by every ring.
  /// default is 1.0
  final double maxValue;

  /// Starting angle of the arc, in degrees. 0° points right, matching
  /// [PieChartData.startDegreeOffset] and [Canvas.drawArc].
  final double startDegreeOffset;

  /// Length of the arc, in degrees. Must be in (0, 360].
  final double sweepAngle;

  /// Whether the arc travels clockwise or counter-clockwise from
  /// [startDegreeOffset].
  final GaugeDirection direction;

  /// Width used for rings that don't specify their own
  /// [GaugeRing.width].
  final double defaultRingWidth;

  /// Radial gap in pixels between adjacent rings.
  final double ringsSpace;

  /// Touch configuration and callback.
  final GaugeTouchData gaugeTouchData;

  /// Resolves the width for [ring], falling back to
  /// [defaultRingWidth] when the ring doesn't specify one.
  double resolveRingWidth(GaugeRing ring) => ring.width ?? defaultRingWidth;

  @override
  List<Object?> get props => [
        rings,
        minValue,
        maxValue,
        startDegreeOffset,
        sweepAngle,
        direction,
        defaultRingWidth,
        ringsSpace,
        gaugeTouchData,
        borderData,
      ];

  GaugeChartData copyWith({
    List<GaugeRing>? rings,
    double? minValue,
    double? maxValue,
    double? startDegreeOffset,
    double? sweepAngle,
    GaugeDirection? direction,
    double? defaultRingWidth,
    double? ringsSpace,
    GaugeTouchData? touchData,
    FlBorderData? borderData,
  }) =>
      GaugeChartData(
        rings: rings ?? this.rings,
        minValue: minValue ?? this.minValue,
        maxValue: maxValue ?? this.maxValue,
        startDegreeOffset: startDegreeOffset ?? this.startDegreeOffset,
        sweepAngle: sweepAngle ?? this.sweepAngle,
        direction: direction ?? this.direction,
        defaultRingWidth: defaultRingWidth ?? this.defaultRingWidth,
        ringsSpace: ringsSpace ?? this.ringsSpace,
        touchData: touchData ?? gaugeTouchData,
        borderData: borderData ?? this.borderData,
      );

  @override
  GaugeChartData lerp(BaseChartData a, BaseChartData b, double t) {
    if (a is GaugeChartData && b is GaugeChartData) {
      return GaugeChartData(
        rings: lerpGaugeRingList(a.rings, b.rings, t)!,
        minValue: lerpDouble(a.minValue, b.minValue, t)!,
        maxValue: lerpDouble(a.maxValue, b.maxValue, t)!,
        startDegreeOffset:
            lerpDouble(a.startDegreeOffset, b.startDegreeOffset, t)!,
        sweepAngle: lerpDouble(a.sweepAngle, b.sweepAngle, t)!,
        direction: b.direction,
        defaultRingWidth:
            lerpDouble(a.defaultRingWidth, b.defaultRingWidth, t)!,
        ringsSpace: lerpDouble(a.ringsSpace, b.ringsSpace, t)!,
        touchData: b.gaugeTouchData,
        borderData: FlBorderData.lerp(a.borderData, b.borderData, t),
      );
    } else {
      throw Exception('Illegal State');
    }
  }
}

/// Base type for a single concentric ring of a [GaugeChartData].
///
/// Sealed hierarchy — a ring is always either a [GaugeProgressRing]
/// (filled up to a value) or a [GaugeZonesRing] (divided into fixed
/// [GaugeZone]s). The [GaugeChartPainter] dispatches on the concrete
/// type; the hierarchy is closed to ensure that never changes silently.
sealed class GaugeRing with EquatableMixin {
  const GaugeRing({this.width});

  /// Stroke width in pixels. If null,
  /// [GaugeChartData.defaultRingWidth] is used.
  final double? width;

  /// Lerps this ring against another. Cross-type lerps snap to [b]
  /// (matches the [FlDotPainter.lerp] fallback pattern).
  static GaugeRing lerp(GaugeRing a, GaugeRing b, double t) {
    if (a is GaugeProgressRing && b is GaugeProgressRing) {
      return GaugeProgressRing.lerp(a, b, t);
    }
    if (a is GaugeZonesRing && b is GaugeZonesRing) {
      return GaugeZonesRing.lerp(a, b, t);
    }
    return b;
  }
}

/// A ring showing progress from [GaugeChartData.minValue] up to [value].
///
/// The unfilled portion of the ring (from [value] to
/// [GaugeChartData.maxValue]) is painted in [backgroundColor] when
/// provided; otherwise it's left empty.
final class GaugeProgressRing extends GaugeRing {
  const GaugeProgressRing({
    required this.value,
    required this.color,
    this.backgroundColor,
    this.strokeCap = StrokeCap.butt,
    super.width,
  }) : assert(width == null || width > 0, 'width must be > 0 when provided');

  /// Current value on the gauge scale. The ring fills from
  /// [GaugeChartData.minValue] up to this value.
  final double value;

  /// Stroke color for the filled portion of the ring.
  final Color color;

  /// Optional stroke color for the unfilled portion. When null, no
  /// background is drawn for this ring.
  final Color? backgroundColor;

  /// Cap style applied to the ends of both the background and filled
  /// arcs of this ring. For the typical battery-meter / progress-bar
  /// look, use [StrokeCap.round].
  final StrokeCap strokeCap;

  GaugeProgressRing copyWith({
    double? value,
    Color? color,
    double? width,
    Color? backgroundColor,
    StrokeCap? strokeCap,
  }) =>
      GaugeProgressRing(
        value: value ?? this.value,
        color: color ?? this.color,
        width: width ?? this.width,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        strokeCap: strokeCap ?? this.strokeCap,
      );

  static GaugeProgressRing lerp(
    GaugeProgressRing a,
    GaugeProgressRing b,
    double t,
  ) =>
      GaugeProgressRing(
        value: lerpDouble(a.value, b.value, t)!,
        color: Color.lerp(a.color, b.color, t)!,
        width: lerpDouble(a.width, b.width, t),
        backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
        strokeCap: b.strokeCap,
      );

  @override
  List<Object?> get props => [value, color, width, backgroundColor, strokeCap];
}

/// A ring displaying one or more fixed colored [GaugeZone]s along the
/// arc — useful for threshold / level indicators (e.g. a speedometer's
/// red/amber/green bands).
///
/// Zones are bounds-checked against [GaugeChartData.minValue] /
/// [GaugeChartData.maxValue] but not required to be sorted, contiguous,
/// or non-overlapping. They're drawn in list order, so later zones paint
/// on top of overlapping earlier ones.
final class GaugeZonesRing extends GaugeRing {
  const GaugeZonesRing({
    required this.zones,
    this.zonesSpace = 0.0,
    super.width,
  })  : assert(width == null || width > 0, 'width must be > 0 when provided'),
        assert(zonesSpace >= 0, 'zonesSpace must be >= 0');

  /// The colored bands drawn along this ring's arc. Each band controls
  /// its own [GaugeZone.strokeCap].
  final List<GaugeZone> zones;

  /// Visible gap between adjacent zones, in pixels along this ring's
  /// arc (measured at its stroke-center radius).
  ///
  /// Applied only *between* zones (in list order): each internal
  /// boundary shrinks by `zonesSpace / 2` from the zones on either
  /// side, leaving a `zonesSpace`-wide gap. The first zone's leading
  /// edge and the last zone's trailing edge are not shrunk, so zones
  /// stay flush to the gauge's angular extremes. Zones whose arc
  /// collapses to zero or less are skipped.
  ///
  /// When using `StrokeCap.round` or `StrokeCap.square` on a zone, each
  /// cap extends `width / 2` beyond the arc, so the effective visible
  /// gap between two capped neighbors is `zonesSpace − width`. Set
  /// `zonesSpace > width` to keep a visible gap when caps are rounded.
  final double zonesSpace;

  GaugeZonesRing copyWith({
    List<GaugeZone>? zones,
    double? zonesSpace,
    double? width,
  }) =>
      GaugeZonesRing(
        zones: zones ?? this.zones,
        zonesSpace: zonesSpace ?? this.zonesSpace,
        width: width ?? this.width,
      );

  static GaugeZonesRing lerp(
    GaugeZonesRing a,
    GaugeZonesRing b,
    double t,
  ) =>
      GaugeZonesRing(
        zones: lerpGaugeZoneList(a.zones, b.zones, t)!,
        zonesSpace: lerpDouble(a.zonesSpace, b.zonesSpace, t)!,
        width: lerpDouble(a.width, b.width, t),
      );

  @override
  List<Object?> get props => [zones, zonesSpace, width];
}

/// A single colored band within a [GaugeZonesRing]. [from] and [to]
/// are positions on the shared [GaugeChartData.minValue] /
/// [GaugeChartData.maxValue] scale; [to] must be `>= from`.
@immutable
class GaugeZone with EquatableMixin {
  const GaugeZone({
    required this.from,
    required this.to,
    required this.color,
    this.strokeCap = StrokeCap.butt,
  }) : assert(to >= from, 'to must be >= from');

  final double from;
  final double to;
  final Color color;

  /// Cap style applied to this band's two ends. Independent per zone —
  /// adjacent zones paint in list order, so a later zone's butt start
  /// paints over an earlier zone's rounded end-cap bulge.
  final StrokeCap strokeCap;

  GaugeZone copyWith({
    double? from,
    double? to,
    Color? color,
    StrokeCap? strokeCap,
  }) =>
      GaugeZone(
        from: from ?? this.from,
        to: to ?? this.to,
        color: color ?? this.color,
        strokeCap: strokeCap ?? this.strokeCap,
      );

  static GaugeZone lerp(GaugeZone a, GaugeZone b, double t) => GaugeZone(
        from: lerpDouble(a.from, b.from, t)!,
        to: lerpDouble(a.to, b.to, t)!,
        color: Color.lerp(a.color, b.color, t)!,
        strokeCap: b.strokeCap,
      );

  @override
  List<Object?> get props => [from, to, color, strokeCap];
}

/// It lerps a [GaugeChartData] to another [GaugeChartData] (handles
/// animation for updating values).
class GaugeChartDataTween extends Tween<GaugeChartData> {
  GaugeChartDataTween({
    required GaugeChartData begin,
    required GaugeChartData end,
  }) : super(begin: begin, end: end);

  /// Lerps a [GaugeChartData] based on [t] value, check [Tween.lerp].
  @override
  GaugeChartData lerp(double t) => begin!.lerp(begin!, end!, t);
}

/// Direction the arc travels from [GaugeChartData.startDegreeOffset].
enum GaugeDirection {
  clockwise,
  counterClockwise,
}

class GaugeTouchData extends FlTouchData<GaugeTouchResponse>
    with EquatableMixin {
  GaugeTouchData({
    bool? enabled,
    BaseTouchCallback<GaugeTouchResponse>? touchCallback,
    MouseCursorResolver<GaugeTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
  }) : super(
          enabled ?? true,
          touchCallback,
          mouseCursorResolver,
          longPressDuration,
        );

  @override
  List<Object?> get props => [
        enabled,
        touchCallback,
        mouseCursorResolver,
        longPressDuration,
      ];
}

/// Describes the state of a touch on a [GaugeChart].
///
/// A touch inside the arc's angular range always produces a
/// [GaugeTouchedRing] — even when it falls in the gap between rings
/// (`ringsSpace`) or outside every ring's radial band. In those
/// cases [touchedRing] is null and [touchedRingIndex] is -1, but
/// [touchValue] is still filled in. Touches entirely outside the
/// angular range produce null [GaugeTouchResponse.touchedRing].
///
/// When the hit ring is a [GaugeZonesRing], [touchedZone] and
/// [touchedZoneIndex] are populated with the specific band that
/// contains the touch angle. For a [GaugeProgressRing], [isOnValue]
/// tells you whether the touch sits on the filled portion (`touchValue
/// <= ring.value`) or the background.
@immutable
class GaugeTouchedRing with EquatableMixin {
  const GaugeTouchedRing({
    required this.touchedRing,
    required this.touchedRingIndex,
    required this.touchAngle,
    required this.touchRadius,
    required this.touchValue,
    required this.isOnValue,
    this.touchedZone,
    this.touchedZoneIndex = -1,
  });

  /// The ring that was touched, or null if the touch fell between /
  /// outside rings.
  final GaugeRing? touchedRing;

  /// Index of the touched ring in [GaugeChartData.rings], or -1 if
  /// no ring was hit.
  final int touchedRingIndex;

  /// Angle of the touch in degrees, using the same convention as
  /// [GaugeChartData.startDegreeOffset] (0° points right).
  final double touchAngle;

  /// Distance from the gauge's center to the touch, in pixels.
  final double touchRadius;

  /// Touch position interpolated along the shared gauge scale, in
  /// [[GaugeChartData.minValue], [GaugeChartData.maxValue]].
  final double touchValue;

  /// True when a [GaugeProgressRing] was hit AND the touch sits on
  /// its filled portion (`touchValue <= ring.value`). False
  /// otherwise, including for [GaugeZonesRing] hits and misses.
  final bool isOnValue;

  /// The zone that was touched when the hit ring is a
  /// [GaugeZonesRing] and the touch angle falls inside one of its
  /// zones. Null for progress-ring hits and for touches in gaps
  /// between zones.
  final GaugeZone? touchedZone;

  /// Index of [touchedZone] in the hit ring's `zones` list, or -1.
  final int touchedZoneIndex;

  @override
  List<Object?> get props => [
        touchedRing,
        touchedRingIndex,
        touchAngle,
        touchRadius,
        touchValue,
        isOnValue,
        touchedZone,
        touchedZoneIndex,
      ];
}

class GaugeTouchResponse extends BaseTouchResponse {
  GaugeTouchResponse({
    required super.touchLocation,
    required this.touchedRing,
  });

  /// Details of the touch, or null if the touch fell entirely outside
  /// the arc's angular range.
  final GaugeTouchedRing? touchedRing;

  GaugeTouchResponse copyWith({
    Offset? touchLocation,
    GaugeTouchedRing? touchedRing,
  }) =>
      GaugeTouchResponse(
        touchLocation: touchLocation ?? this.touchLocation,
        touchedRing: touchedRing ?? this.touchedRing,
      );
}
