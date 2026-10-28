import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';

typedef CaChart = CaChartWidget;

class CaChartWidget extends StatelessWidget {
  final List<CaChartPoint> data;

  const CaChartWidget({
    super.key,
    List<CaChartPoint>? data,
    List<CaChartPoint>? chartData,
  }) : data = data ?? chartData ?? const [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée de CA pour le moment',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < data.length; i++) {
      final val = data[i].total.toDouble();
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    if (maxY == 0) maxY = 5000;
    final topLimit = maxY * 1.25;

    final primaryColor = const Color(0xFF061449);
    final tealColor = const Color(0xFF006A61);
    final borderColor = isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF);
    final cardBg = isDark ? const Color(0xFF0F172E) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0B1C30).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF202646) : tealColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: isDark ? const Color(0xFF2CE5A7) : tealColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Évolution du Chiffre d\'Affaires',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0B1C30),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 3) : 1000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF252A4A) : const Color(0xFFE5EEFF),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final label = data[index].mois;
                        final shortLabel = label.contains('-')
                            ? label.split('-').last
                            : label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            shortLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF45464F),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY > 0 ? (maxY / 3) : 1000,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final valStr = value >= 1000
                            ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k'
                            : '${value.toInt()}';
                        return Text(
                          valStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF45464F),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble() > 0
                    ? (data.length - 1).toDouble()
                    : 1,
                minY: 0,
                maxY: topLimit,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: isDark ? const Color(0xFF2CE5A7) : primaryColor,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                       show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isDark ? const Color(0xFF0F172E) : Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: isDark ? const Color(0xFF2CE5A7) : primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDark ? const Color(0xFF2CE5A7) : primaryColor).withValues(alpha: isDark ? 0.25 : 0.28),
                          (isDark ? const Color(0xFF2CE5A7) : primaryColor).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final month = (idx >= 0 && idx < data.length)
                            ? data[idx].mois
                            : '';
                        return LineTooltipItem(
                          '$month\n${spot.y.toInt()} DZD',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
