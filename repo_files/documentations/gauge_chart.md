### How to use
```dart
GaugeChart(
  GaugeChartData(
    // read about it in the GaugeChartData section
  ),
  duration: Duration(milliseconds: 150), // Optional
  curve: Curves.linear, // Optional
);
```

A gauge is drawn as a set of **concentric rings** along a shared arc. All rings share the same `minValue`/`maxValue` scale and stack **innermost-first** in list order — so `sections[0]` is the innermost ring, the last entry is the outermost — with an optional `sectionsSpace` radial gap between them.

Each ring is one of two shapes:

- **[GaugeProgressSection](#GaugeProgressSection)** — a ring that fills from `minValue` up to its own `value`, with an optional faded `backgroundColor` behind. Use this for measurements (battery level, goal progress, live reading).
- **[GaugeZonesSection](#GaugeZonesSection)** — a ring divided into fixed colored [GaugeZone](#GaugeZone) bands. Use this for threshold/level indicators (speedometer red-amber-green zones, status bands).

You can mix both kinds freely — a common pattern is an inner progress ring showing the current reading plus an outer zones ring showing threshold bands.

### Implicit Animations
When you change the chart's state, it animates to the new state internally (using [implicit animations](https://flutter.dev/docs/development/ui/animations/implicit-animations)). You can control the animation [duration](https://api.flutter.dev/flutter/dart-core/Duration-class.html) and [curve](https://api.flutter.dev/flutter/animation/Curves-class.html) using optional `duration` and `curve` properties. Lerping a ring to a different shape (`GaugeProgressSection` ↔ `GaugeZonesSection`) snaps to the target — same-shape transitions interpolate smoothly.

### Progress gauge shortcut
For the common "single ring filling from 0 to a value" case, use `GaugeChartData.progress`:

```dart
GaugeChart(
  GaugeChartData.progress(
    value: 0.73,
    color: Colors.blue,
    width: 30,
    backgroundColor: Colors.black12,
    // defaults: min=0, max=1, startDegreeOffset=-225, sweepAngle=270
  ),
);
```

### Multi-ring ("Apple Watch") gauge

```dart
GaugeChart(
  GaugeChartData(
    minValue: 0,
    maxValue: 100,
    startDegreeOffset: -225,
    sweepAngle: 270,
    defaultSectionWidth: 22,
    sectionsSpace: 4,
    sections: [
      // innermost
      GaugeProgressSection(
        value: 72,
        color: Colors.red,
        backgroundColor: Colors.red.withValues(alpha: 0.2),
      ),
      GaugeProgressSection(
        value: 48,
        color: Colors.green,
        backgroundColor: Colors.green.withValues(alpha: 0.2),
      ),
      // outermost
      GaugeProgressSection(
        value: 90,
        color: Colors.blue,
        backgroundColor: Colors.blue.withValues(alpha: 0.2),
      ),
    ],
  ),
);
```

### Speedometer with threshold zones

```dart
GaugeChart(
  GaugeChartData(
    minValue: 350,
    maxValue: 850,
    startDegreeOffset: 180,
    sweepAngle: 180,
    sectionsSpace: 4,
    sections: [
      // inner ring — current measurement
      GaugeProgressSection(
        value: 370,
        color: Colors.green,
        backgroundColor: Colors.grey,
        width: 30,
      ),
      // outer ring — colored threshold bands
      GaugeZonesSection(
        width: 10,
        zones: [
          GaugeZone(from: 350, to: 600, color: Colors.redAccent),
          GaugeZone(from: 600, to: 700, color: Colors.amber),
          GaugeZone(from: 700, to: 800, color: Colors.lightGreen),
          GaugeZone(from: 800, to: 850, color: Colors.green),
        ],
      ),
    ],
  ),
);
```

### GaugeChartData
|PropName|Description|default value|
|:-------|:----------|:------------|
|sections| list of [GaugeSection](#GaugeSection) rings, innermost first. All sections share the same `minValue`/`maxValue` scale|required|
|minValue| lower bound of the gauge scale (inclusive), shared by every section|0.0|
|maxValue| upper bound of the gauge scale (inclusive), shared by every section|1.0|
|startDegreeOffset| starting angle of the arc, in degrees. `0°` points right, same convention as [PieChartData.startDegreeOffset](pie_chart.md#PieChartData)|-225.0|
|sweepAngle| length of the arc in degrees, must be in `(0, 360]`|270.0|
|direction| whether the arc travels clockwise or counter-clockwise from `startDegreeOffset` — see [GaugeDirection](#GaugeDirection)|GaugeDirection.clockwise|
|strokeCap| stroke cap applied to every arc (filled, background, and zone)|StrokeCap.butt|
|defaultSectionWidth| width used for sections that don't specify their own `width`|10.0|
|sectionsSpace| radial pixel gap between adjacent rings|0.0|
|ticks| optional tick configuration; see [GaugeTicks](#GaugeTicks)|null|
|touchData| [GaugeTouchData](#GaugeTouchData) holds the touch interactivity details|GaugeTouchData()|
|borderData| shows a border around the chart, see [FlBorderData](base_chart.md#FlBorderData)|FlBorderData()|

### GaugeSection
`GaugeSection` is a sealed base type — every ring is one of the two concrete shapes below. You can pattern-match on the concrete type in touch callbacks.

### GaugeProgressSection
A ring filled from `GaugeChartData.minValue` up to `value`. The unfilled portion (`value..maxValue`) is painted in `backgroundColor` when provided.

|PropName|Description|default value|
|:-------|:----------|:------------|
|value| current progress on the gauge scale|required|
|color| stroke color of the filled portion|required|
|width| stroke width in pixels. If null, `GaugeChartData.defaultSectionWidth` is used|null|
|backgroundColor| optional stroke color for the unfilled portion. If null, no background is drawn|null|

### GaugeZonesSection
A ring divided into fixed colored [GaugeZone](#GaugeZone) bands. Zones are bounds-checked against the chart's `minValue`/`maxValue` but are not required to be sorted, contiguous, or non-overlapping — they're drawn in list order, so later zones paint on top of overlapping earlier ones.

|PropName|Description|default value|
|:-------|:----------|:------------|
|zones| list of [GaugeZone](#GaugeZone) bands painted along this ring's arc|required|
|width| stroke width in pixels. If null, `GaugeChartData.defaultSectionWidth` is used|null|

### GaugeZone
A single colored band within a [GaugeZonesSection](#GaugeZonesSection).

|PropName|Description|default value|
|:-------|:----------|:------------|
|from| lower bound of the zone on the gauge scale (inclusive)|required|
|to| upper bound of the zone on the gauge scale (inclusive); must be `>= from`|required|
|color| fill color of this band|required|

### GaugeDirection
|Value|Behavior|
|:----|:-------|
|`clockwise`| arc travels clockwise from `startDegreeOffset`.|
|`counterClockwise`| arc travels counter-clockwise from `startDegreeOffset`.|

### GaugeTicks
Ticks frame the gauge as a whole — they reference the outer edge of the outermost ring and the inner edge of the innermost ring — not a specific section.

|PropName|Description|default value|
|:-------|:----------|:------------|
|count| number of ticks drawn (includes endpoints); must be `>= 2`|3|
|position| where ticks sit — see [GaugeTickPosition](#GaugeTickPosition)|GaugeTickPosition.outer|
|margin| pixel gap between the nearest ring edge and the tick|3|
|painter| [GaugeTickPainter](#GaugeTickPainter) that renders each tick|GaugeTickCirclePainter()|

### GaugeTickPosition
|Value|Behavior|
|:----|:-------|
|`outer`| ticks are drawn just outside the outermost ring.|
|`inner`| ticks are drawn just inside the innermost ring.|
|`center`| ticks are centered radially between the outermost and innermost ring edges.|

### GaugeTickPainter
Interface for rendering individual tick marks. Subclass it to draw non-circular shapes, oriented marks (using the provided `angle`), or labels. Mirrors the [FlDotPainter](line_chart.md) pattern used by LineChart.

Built-in implementations:
- **GaugeTickCirclePainter** — a filled circle, optionally with a stroked outline. Properties: `radius` (default 3), `color` (default black), `strokeWidth` (default 0), `strokeColor` (default black).

### GaugeTouchData ([read about touch handling](handle_touches.md))
|PropName|Description|default value|
|:-------|:----------|:------------|
|enabled|determines whether to enable or disable touch behaviors|true|
|mouseCursorResolver|you can change the mouse cursor based on the provided [FlTouchEvent](base_chart.md#fltouchevent) and [GaugeTouchResponse](#GaugeTouchResponse)|MouseCursor.defer|
|touchCallback| listen to this callback to retrieve touch/pointer events and responses|null|
|longPressDuration| allows you to customize the duration of the longPress gesture. If null, the duration is [kLongPressTimeout](https://api.flutter.dev/flutter/gestures/kLongPressTimeout-constant.html)|null|

### GaugeTouchResponse
|PropName|Description|default value|
|:-------|:----------|:------------|
|touchLocation|the location of the touch event in device pixel coordinates|required|
|touchedSection|Instance of [GaugeTouchedSection](#GaugeTouchedSection) describing what the touch hit, or null when the touch fell entirely outside the arc's angular range|null|

### GaugeTouchedSection
A touch inside the arc's angular range always produces a `GaugeTouchedSection` — even when it falls in the gap between rings (`sectionsSpace`) or outside every ring's radial band. In those cases `touchedSection` is null and `touchedSectionIndex` is `-1`, but `touchValue` is still filled in.

When the hit ring is a [GaugeProgressSection](#GaugeProgressSection), `isOnValue` is `true` if the touch sits on the filled portion (`touchValue <= section.value`).

When the hit ring is a [GaugeZonesSection](#GaugeZonesSection), `touchedZone` / `touchedZoneIndex` report the specific band the touch angle falls into (or null when it's in a gap between zones).

|PropName|Description|default value|
|:-------|:----------|:------------|
|touchedSection|the [GaugeSection](#GaugeSection) (ring) that was hit, or null if the touch missed all rings|null|
|touchedSectionIndex| index of the hit ring, or `-1` when no ring was hit|required|
|touchAngle| angle of the touch in degrees (same convention as `startDegreeOffset`: 0° points right)|required|
|touchRadius| distance from the gauge's center to the touch in pixels|required|
|touchValue| touch position interpolated along the gauge's scale, in `[minValue, maxValue]`|required|
|isOnValue| true when a [GaugeProgressSection](#GaugeProgressSection) was hit AND the touch sits on its filled portion; false otherwise (including zones-section hits and misses)|required|
|touchedZone| the [GaugeZone](#GaugeZone) hit when the touched ring is a [GaugeZonesSection](#GaugeZonesSection) and the touch falls inside one of its bands|null|
|touchedZoneIndex| index of `touchedZone` in the hit ring's `zones` list, or `-1`|-1|
