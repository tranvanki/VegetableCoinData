# Market Chart

## Workflow
1. Parent (coin detail) passes `coinId`, current `range`, and `points`.
2. Data source: `GET /coins/{id}/market_chart?vs_currency=usd&days={days}`.
3. Parser reads `prices: [[timestampMs, price], ...]` → `List<ChartPoint>`.
4. Widget normalizes prices to `0..1` against min/max → maps to canvas height.
5. Range change → parent calls `CoinDetailProvider.setRange` → new points → repaint.
6. Horizontal drag → nearest index → crosshair + tooltip (`time`, `price`).
7. No data → `EmptyView(compact)`; loading → `ShimmerBox(height: 220)`.
8. Chart is display-only: no network, no state mutation.

## Files
| File | Purpose |
|---|---|
| `lib/views/widgets/market_chart.dart` | **Empty.** `MarketChart` widget + `_ChartPainter`. |
| `lib/data/model/crypto/market_chart.dart` | **Planned.** `ChartPoint(time, price)`, `listFromJson`. |
| `lib/providers/coin_detail_provider.dart` | **Planned.** Owns points + range. |
| `lib/data/repository/coin_repository.dart` | Add `getMarketChart(id, days)`. |
| `lib/app/theme/app_colors.dart` | `success` / `error` line color by trend. |

## Functions (planned)
| Symbol | Purpose | Logic |
|---|---|---|
| `MarketChart.build()` | Layout | `LayoutBuilder` → `SizedBox(height:)` → `GestureDetector` → `CustomPaint`. |
| `_ChartPainter.paint()` | Draw | Build `Path` from normalized points; stroke + gradient fill; grid lines. |
| `_ChartPainter.shouldRepaint()` | Perf | Repaint only when `points`, `range`, or `selectedIndex` change. |
| `_nearestIndex(dx, width)` | Hit test | `((dx / width) * (points.length - 1)).round()`. |
| `_formatAxis(double)` | Labels | `Formatters.price` or compact form for large values. |

## Widgets / Syntax
- `CustomPaint` + `CustomPainter` (`paint`, `shouldRepaint`).
- `Canvas.drawPath` + `Paint()..shader = LinearGradient(...).createShader(rect)` for area fill.
- `PathMetrics` / `Path().computeMetrics()` optional for stroke animation.
- `GestureDetector(onHorizontalDragStart/Update/End)`; `setState` only for crosshair.
- `LayoutBuilder` for width/height.
- `RepaintBoundary` around the chart.
- Range chips: `ChoiceChip` in a `Wrap`.
