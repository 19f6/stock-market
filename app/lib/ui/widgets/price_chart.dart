import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/candle.dart';

/// Historical closing-price line chart for one stock.
class PriceChart extends StatelessWidget {
  final History history;
  final bool intraday;
  const PriceChart({super.key, required this.history, this.intraday = false});

  @override
  Widget build(BuildContext context) {
    final candles = history.candles;
    if (candles.length < 2) {
      return const Center(child: Text('Not enough data to chart.'));
    }
    final color = AppTheme.trend(history.changePct);
    final spots = <FlSpot>[
      for (var i = 0; i < candles.length; i++)
        FlSpot(i.toDouble(), candles[i].close),
    ];

    var lo = candles.first.close, hi = candles.first.close;
    for (final c in candles) {
      if (c.low < lo) lo = c.low;
      if (c.high > hi) hi = c.high;
    }
    final pad = (hi - lo) * 0.08;

    return LineChart(
      LineChartData(
        minY: lo - pad,
        maxY: hi + pad,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (hi - lo) <= 0 ? null : (hi - lo) / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, meta) => Text(
                moneyCompact(v),
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (candles.length / 4).floorToDouble().clamp(1, 1e9),
              getTitlesWidget: (v, meta) {
                final i = v.round();
                // Skip out-of-range and the last ~8% to avoid edge clipping.
                if (i < 0 || i >= candles.length * 0.92) {
                  return const SizedBox();
                }
                return Text(
                  intraday
                      ? fmtTimeShort(candles[i].time)
                      : fmtDateShort(candles[i].time),
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white54),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final c = candles[s.x.round().clamp(0, candles.length - 1)];
              return LineTooltipItem(
                '${money(c.close)}\n${intraday ? fmtDateTime(c.time) : fmtDate(c.time)}',
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 1.8,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
