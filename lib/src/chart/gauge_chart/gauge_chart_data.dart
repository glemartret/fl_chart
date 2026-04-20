import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/utils/lerp.dart';
import 'package:flutter/widgets.dart';

/// [GaugeChart] needs this class to render itself.
///
/// A gauge chart is a set of concentric rings drawn along a shared arc.
/// Each [GaugeSection] is one ring on a scale shared by every section.
/// Sections are stacked innermost-first in list order — so `sections[0]`
/// is the innermost ring and the last entry is the outermost — separated
/// by [sectionsSpace] pixels.
///
/// A section is one of two shapes:
/// - [GaugeProgressSection] — a ring filled from [minValue] up to its
///   `value`, with an optional `backgroundColor` behind.
/// - [GaugeZonesSection] — a ring divided into fixed colored [GaugeZone]s
///   (threshold bands). Useful for speedometer-style level indicators.
class GaugeChartData extends BaseChartData with EquatableMixin {
  GaugeChartData({
    required List<GaugeSection> sections,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.startDegreeOffset = -225.0,
    this.sweepAngle = 270.0,
    this.direction = GaugeDirection.clockwise,
    this.strokeCap = StrokeCap.butt,
    this.defaultSectionWidth = 10.0,
    this.sectionsSpace = 0.0,
    this.ticks,
    GaugeTouchData? touchData,
    super.borderData,
  })  : sections = List.unmodifiable(sections),
        gaugeTouchData = touchData ?? GaugeTouchData(),
        assert(sections.isNotEmpty, 'sections must not be empty'),
        assert(maxValue > minValue, 'maxValue must be greater than minValue'),
        assert(
          sweepAngle > 0 && sweepAngle <= 360,
          'sweepAngle must be in (0, 360]',
        ),
        assert(sectionsSpace >= 0, 'sectionsSpace must be >= 0') {
    for (final section in sections) {
      switch (section) {
        case GaugeProgressSection():
          assert(
            section.value >= minValue && section.value <= maxValue,
            'GaugeProgressSection.value ${section.value} is outside '
            '[$minValue, $maxValue]',
          );
        case GaugeZonesSection():
          assert(
            section.zones.isNotEmpty,
            'GaugeZonesSection.zones must not be empty',
          );
          for (final zone in section.zones) {
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
  /// [GaugeChartData] with one [GaugeProgressSection].
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
    GaugeTicks? ticks,
    GaugeTouchData? touchData,
    FlBorderData? borderData,
  }) =>
      GaugeChartData(
        minValue: min,
        maxValue: max,
        sections: [
          GaugeProgressSection(
            value: value.clamp(min, max),
            color: color,
            width: width,
            backgroundColor: backgroundColor,
          ),
        ],
        defaultSectionWidth: width,
        startDegreeOffset: startDegreeOffset,
        sweepAngle: sweepAngle,
        direction: direction,
        strokeCap: strokeCap,
        ticks: ticks,
        touchData: touchData,
        borderData: borderData,
      );

  /// The rings drawn by the chart, innermost first.
  final List<GaugeSection> sections;

  /// Lower bound of the gauge scale (inclusive). Shared by every section.
  final double minValue;

  /// Upper bound of the gauge scale (inclusive). Shared by every section.
  final double maxValue;

  /// Starting angle of the arc, in degrees. 0° points right, matching
  /// [PieChartData.startDegreeOffset] and [Canvas.drawArc].
  final double startDegreeOffset;

  /// Length of the arc, in degrees. Must be in (0, 360].
  final double sweepAngle;

  /// Whether the arc travels clockwise or counter-clockwise from
  /// [startDegreeOffset].
  final GaugeDirection direction;

  /// Stroke cap applied to every arc (filled, background, and zone).
  final StrokeCap strokeCap;

  /// Width used for sections that don't specify their own
  /// [GaugeSection.width].
  final double defaultSectionWidth;

  /// Radial gap in pixels between adjacent rings.
  final double sectionsSpace;

  /// Optional tick marks drawn along the gauge.
  final GaugeTicks? ticks;

  /// Touch configuration and callback.
  final GaugeTouchData gaugeTouchData;

  /// Resolves the width for [section], falling back to
  /// [defaultSectionWidth] when the section doesn't specify one.
  double resolveSectionWidth(GaugeSection section) =>
      section.width ?? defaultSectionWidth;

  @override
  List<Object?> get props => [
        sections,
        minValue,
        maxValue,
        startDegreeOffset,
        sweepAngle,
        direction,
        strokeCap,
        defaultSectionWidth,
        sectionsSpace,
        ticks,
        gaugeTouchData,
        borderData,
      ];

  GaugeChartData copyWith({
    List<GaugeSection>? sections,
    double? minValue,
    double? maxValue,
    double? startDegreeOffset,
    double? sweepAngle,
    GaugeDirection? direction,
    StrokeCap? strokeCap,
    double? defaultSectionWidth,
    double? sectionsSpace,
    GaugeTicks? ticks,
    GaugeTouchData? touchData,
    FlBorderData? borderData,
  }) =>
      GaugeChartData(
        sections: sections ?? this.sections,
        minValue: minValue ?? this.minValue,
        maxValue: maxValue ?? this.maxValue,
        startDegreeOffset: startDegreeOffset ?? this.startDegreeOffset,
        sweepAngle: sweepAngle ?? this.sweepAngle,
        direction: direction ?? this.direction,
        strokeCap: strokeCap ?? this.strokeCap,
        defaultSectionWidth: defaultSectionWidth ?? this.defaultSectionWidth,
        sectionsSpace: sectionsSpace ?? this.sectionsSpace,
        ticks: ticks ?? this.ticks,
        touchData: touchData ?? gaugeTouchData,
        borderData: borderData ?? this.borderData,
      );

  @override
  GaugeChartData lerp(BaseChartData a, BaseChartData b, double t) {
    if (a is GaugeChartData && b is GaugeChartData) {
      return GaugeChartData(
        sections: lerpGaugeSectionList(a.sections, b.sections, t)!,
        minValue: lerpDouble(a.minValue, b.minValue, t)!,
        maxValue: lerpDouble(a.maxValue, b.maxValue, t)!,
        startDegreeOffset:
            lerpDouble(a.startDegreeOffset, b.startDegreeOffset, t)!,
        sweepAngle: lerpDouble(a.sweepAngle, b.sweepAngle, t)!,
        direction: b.direction,
        strokeCap: b.strokeCap,
        defaultSectionWidth:
            lerpDouble(a.defaultSectionWidth, b.defaultSectionWidth, t)!,
        sectionsSpace: lerpDouble(a.sectionsSpace, b.sectionsSpace, t)!,
        ticks: GaugeTicks.lerp(a.ticks, b.ticks, t),
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
/// Sealed hierarchy — a ring is always either a [GaugeProgressSection]
/// (filled up to a value) or a [GaugeZonesSection] (divided into fixed
/// [GaugeZone]s). The [GaugeChartPainter] dispatches on the concrete
/// type; the hierarchy is closed to ensure that never changes silently.
sealed class GaugeSection with EquatableMixin {
  const GaugeSection({this.width});

  /// Stroke width in pixels. If null,
  /// [GaugeChartData.defaultSectionWidth] is used.
  final double? width;

  /// Lerps this section against another. Cross-type lerps snap to [b]
  /// (matches the [FlDotPainter.lerp] fallback pattern).
  static GaugeSection lerp(GaugeSection a, GaugeSection b, double t) {
    if (a is GaugeProgressSection && b is GaugeProgressSection) {
      return GaugeProgressSection.lerp(a, b, t);
    }
    if (a is GaugeZonesSection && b is GaugeZonesSection) {
      return GaugeZonesSection.lerp(a, b, t);
    }
    return b;
  }
}

/// A ring showing progress from [GaugeChartData.minValue] up to [value].
///
/// The unfilled portion of the ring (from [value] to
/// [GaugeChartData.maxValue]) is painted in [backgroundColor] when
/// provided; otherwise it's left empty.
final class GaugeProgressSection extends GaugeSection {
  const GaugeProgressSection({
    required this.value,
    required this.color,
    this.backgroundColor,
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

  GaugeProgressSection copyWith({
    double? value,
    Color? color,
    double? width,
    Color? backgroundColor,
  }) =>
      GaugeProgressSection(
        value: value ?? this.value,
        color: color ?? this.color,
        width: width ?? this.width,
        backgroundColor: backgroundColor ?? this.backgroundColor,
      );

  static GaugeProgressSection lerp(
    GaugeProgressSection a,
    GaugeProgressSection b,
    double t,
  ) =>
      GaugeProgressSection(
        value: lerpDouble(a.value, b.value, t)!,
        color: Color.lerp(a.color, b.color, t)!,
        width: lerpDouble(a.width, b.width, t),
        backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      );

  @override
  List<Object?> get props => [value, color, width, backgroundColor];
}

/// A ring displaying one or more fixed colored [GaugeZone]s along the
/// arc — useful for threshold / level indicators (e.g. a speedometer's
/// red/amber/green bands).
///
/// Zones are bounds-checked against [GaugeChartData.minValue] /
/// [GaugeChartData.maxValue] but not required to be sorted, contiguous,
/// or non-overlapping. They're drawn in list order, so later zones paint
/// on top of overlapping earlier ones.
final class GaugeZonesSection extends GaugeSection {
  const GaugeZonesSection({
    required this.zones,
    super.width,
  }) : assert(width == null || width > 0, 'width must be > 0 when provided');

  /// The colored bands drawn along this ring's arc.
  final List<GaugeZone> zones;

  GaugeZonesSection copyWith({
    List<GaugeZone>? zones,
    double? width,
  }) =>
      GaugeZonesSection(
        zones: zones ?? this.zones,
        width: width ?? this.width,
      );

  static GaugeZonesSection lerp(
    GaugeZonesSection a,
    GaugeZonesSection b,
    double t,
  ) =>
      GaugeZonesSection(
        zones: lerpGaugeZoneList(a.zones, b.zones, t)!,
        width: lerpDouble(a.width, b.width, t),
      );

  @override
  List<Object?> get props => [zones, width];
}

/// A single colored band within a [GaugeZonesSection]. [from] and [to]
/// are positions on the shared [GaugeChartData.minValue] /
/// [GaugeChartData.maxValue] scale; [to] must be `>= from`.
@immutable
class GaugeZone with EquatableMixin {
  const GaugeZone({
    required this.from,
    required this.to,
    required this.color,
  }) : assert(to >= from, 'to must be >= from');

  final double from;
  final double to;
  final Color color;

  GaugeZone copyWith({
    double? from,
    double? to,
    Color? color,
  }) =>
      GaugeZone(
        from: from ?? this.from,
        to: to ?? this.to,
        color: color ?? this.color,
      );

  static GaugeZone lerp(GaugeZone a, GaugeZone b, double t) => GaugeZone(
        from: lerpDouble(a.from, b.from, t)!,
        to: lerpDouble(a.to, b.to, t)!,
        color: Color.lerp(a.color, b.color, t)!,
      );

  @override
  List<Object?> get props => [from, to, color];
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

/// Position of a tick mark relative to the gauge's overall outer/inner
/// radial bounds.
enum GaugeTickPosition {
  /// Inside the innermost ring.
  inner,

  /// Outside the outermost ring.
  outer,

  /// Radially centered on the gauge's rings as a group.
  center,
}

/// Configuration for the ticks drawn along a [GaugeChartData]'s arc.
///
/// Ticks frame the gauge as a whole (outer edge of the outermost ring
/// to inner edge of the innermost ring), not an individual section.
@immutable
class GaugeTicks with EquatableMixin {
  const GaugeTicks({
    this.count = 3,
    this.position = GaugeTickPosition.outer,
    this.margin = 3,
    this.painter = const GaugeTickCirclePainter(),
  }) : assert(count >= 2, 'count should be >= 2');

  /// Number of ticks drawn, including the arc's endpoints. Minimum 2.
  final int count;

  /// Where ticks sit relative to the gauge's outer/inner bounds.
  final GaugeTickPosition position;

  /// Distance in pixels between the nearest ring edge and the tick.
  final double margin;

  /// Painter used to render each tick. Defaults to
  /// [GaugeTickCirclePainter].
  final GaugeTickPainter painter;

  @override
  List<Object?> get props => [count, position, margin, painter];

  static GaugeTicks? lerp(GaugeTicks? a, GaugeTicks? b, double t) {
    if (a == null || b == null) return b;
    return GaugeTicks(
      count: lerpInt(a.count, b.count, t),
      position: b.position,
      margin: lerpDouble(a.margin, b.margin, t)!,
      painter: a.painter.lerp(a.painter, b.painter, t),
    );
  }
}

/// Interface for rendering individual tick marks on a [GaugeChart].
///
/// Mirrors the [FlDotPainter] / [FlDotCirclePainter] pattern used by
/// [LineChart].
abstract class GaugeTickPainter with EquatableMixin {
  const GaugeTickPainter();

  /// Draws a single tick. [center] is the tick's center in canvas
  /// coordinates, [angle] is the tangent angle in radians.
  void draw(Canvas canvas, Offset center, double angle);

  /// Returns the painted size of a tick.
  Size getSize();

  /// Lerps between two painter configurations; falls back to [b] when
  /// the types differ.
  GaugeTickPainter lerp(GaugeTickPainter a, GaugeTickPainter b, double t);
}

/// Default [GaugeTickPainter] implementation: draws each tick as a
/// filled circle, optionally with a stroked outline.
class GaugeTickCirclePainter extends GaugeTickPainter {
  const GaugeTickCirclePainter({
    this.radius = 3.0,
    this.color = const Color(0xFF000000),
    this.strokeWidth = 0.0,
    this.strokeColor = const Color(0xFF000000),
  }) : assert(radius > 0, 'radius should be > 0');

  final double radius;
  final Color color;
  final double strokeWidth;
  final Color strokeColor;

  @override
  void draw(Canvas canvas, Offset center, double angle) {
    if (strokeWidth > 0 && strokeColor.a != 0) {
      canvas.drawCircle(
        center,
        radius + strokeWidth / 2,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  Size getSize() => Size.fromRadius(radius + strokeWidth);

  GaugeTickCirclePainter _lerp(
    GaugeTickCirclePainter a,
    GaugeTickCirclePainter b,
    double t,
  ) =>
      GaugeTickCirclePainter(
        radius: lerpDouble(a.radius, b.radius, t)!,
        color: Color.lerp(a.color, b.color, t)!,
        strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t)!,
        strokeColor: Color.lerp(a.strokeColor, b.strokeColor, t)!,
      );

  @override
  GaugeTickPainter lerp(GaugeTickPainter a, GaugeTickPainter b, double t) {
    if (a is! GaugeTickCirclePainter || b is! GaugeTickCirclePainter) {
      return b;
    }
    return _lerp(a, b, t);
  }

  @override
  List<Object?> get props => [radius, color, strokeWidth, strokeColor];
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
/// [GaugeTouchedSection] — even when it falls in the gap between rings
/// (`sectionsSpace`) or outside every ring's radial band. In those
/// cases [touchedSection] is null and [touchedSectionIndex] is -1, but
/// [touchValue] is still filled in. Touches entirely outside the
/// angular range produce null [GaugeTouchResponse.touchedSection].
///
/// When the hit ring is a [GaugeZonesSection], [touchedZone] and
/// [touchedZoneIndex] are populated with the specific band that
/// contains the touch angle. For a [GaugeProgressSection], [isOnValue]
/// tells you whether the touch sits on the filled portion (`touchValue
/// <= section.value`) or the background.
@immutable
class GaugeTouchedSection with EquatableMixin {
  const GaugeTouchedSection({
    required this.touchedSection,
    required this.touchedSectionIndex,
    required this.touchAngle,
    required this.touchRadius,
    required this.touchValue,
    required this.isOnValue,
    this.touchedZone,
    this.touchedZoneIndex = -1,
  });

  /// The ring that was touched, or null if the touch fell between /
  /// outside rings.
  final GaugeSection? touchedSection;

  /// Index of the touched ring in [GaugeChartData.sections], or -1 if
  /// no ring was hit.
  final int touchedSectionIndex;

  /// Angle of the touch in degrees, using the same convention as
  /// [GaugeChartData.startDegreeOffset] (0° points right).
  final double touchAngle;

  /// Distance from the gauge's center to the touch, in pixels.
  final double touchRadius;

  /// Touch position interpolated along the shared gauge scale, in
  /// [[GaugeChartData.minValue], [GaugeChartData.maxValue]].
  final double touchValue;

  /// True when a [GaugeProgressSection] was hit AND the touch sits on
  /// its filled portion (`touchValue <= section.value`). False
  /// otherwise, including for [GaugeZonesSection] hits and misses.
  final bool isOnValue;

  /// The zone that was touched when the hit ring is a
  /// [GaugeZonesSection] and the touch angle falls inside one of its
  /// zones. Null for progress-section hits and for touches in gaps
  /// between zones.
  final GaugeZone? touchedZone;

  /// Index of [touchedZone] in the hit ring's `zones` list, or -1.
  final int touchedZoneIndex;

  @override
  List<Object?> get props => [
        touchedSection,
        touchedSectionIndex,
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
    required this.touchedSection,
  });

  /// Details of the touch, or null if the touch fell entirely outside
  /// the arc's angular range.
  final GaugeTouchedSection? touchedSection;

  GaugeTouchResponse copyWith({
    Offset? touchLocation,
    GaugeTouchedSection? touchedSection,
  }) =>
      GaugeTouchResponse(
        touchLocation: touchLocation ?? this.touchLocation,
        touchedSection: touchedSection ?? this.touchedSection,
      );
}
