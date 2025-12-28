// lib/presentation/widgets/price_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/models/token.dart';

enum ChartTimeRange { day, week, month, all }

class PriceChart extends StatelessWidget {
  final Token token;
  final ChartTimeRange timeRange;
  final double height;

  const PriceChart({
    super.key,
    required this.token,
    required this.timeRange,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    final priceData = _getPriceDataForRange();
    
    if (priceData.isEmpty) {
      return Container(
        height: height,
        color: AppTheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: AppTheme.muted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No price data available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
              if (timeRange != ChartTimeRange.day) ...[
                const SizedBox(height: 8),
                Text(
                  'Try selecting 1D view',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Calculate price change for the selected period
    final firstPrice = priceData.first.price;
    final lastPrice = priceData.last.price;
    final periodChange = firstPrice != 0 ? ((lastPrice - firstPrice) / firstPrice) * 100 : 0.0;
    final isPositive = periodChange >= 0;
    final chartColor = isPositive ? AppTheme.success : AppTheme.error;
    
    // Sort data by timestamp to ensure proper ordering
    final sortedData = List<PricePoint>.from(priceData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return Container(
      height: height,
      color: AppTheme.surface,
      child: Column(
        children: [
          // Period stats header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimeRangeLabel(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          PriceFormatter.formatPercentage(periodChange),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: chartColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: chartColor,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'High',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PriceFormatter.formatPrice(_getMaxPrice(sortedData)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Low',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PriceFormatter.formatPrice(_getMinPrice(sortedData)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getHorizontalInterval(sortedData),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.muted.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getHorizontalInterval(sortedData),
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              _formatPrice(value),
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getTimeInterval(sortedData),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedData.length) return const SizedBox();
                          
                          final date = sortedData[index].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatDate(date),
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: sortedData.length.toDouble() - 1,
                  minY: _getMinY(sortedData),
                  maxY: _getMaxY(sortedData),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.price);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: chartColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            chartColor.withOpacity(0.3),
                            chartColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppTheme.surface.withOpacity(0.95),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(12),
                      tooltipBorder: BorderSide(
                        color: AppTheme.muted.withOpacity(0.2),
                        width: 1,
                      ),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final price = spot.y;
                          final date = sortedData[spot.x.toInt()].timestamp;
                          
                          return LineTooltipItem(
                            '${PriceFormatter.formatPrice(price)}\n${_formatTooltipDate(date)}',
                            TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: chartColor.withOpacity(0.3),
                            strokeWidth: 2,
                            dashArray: [5, 5],
                          ),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: chartColor,
                                strokeWidth: 2,
                                strokeColor: AppTheme.primary,
                              );
                            },
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
  
  List<PricePoint> _getPriceDataForRange() {
    switch (timeRange) {
      case ChartTimeRange.day:
        // Use 24h hourly data
        final hourlyData = token.hourlyPriceHistory ?? [];
        return hourlyData;
        
      case ChartTimeRange.week:
        // Use 7d hourly data (NEW!)
        final sevenDayData = token.sevenDayPriceHistory ?? [];
        return sevenDayData;
        
      case ChartTimeRange.month:
        // Use daily data, filter last 30 days
        final daily = token.dailyPriceHistory ?? [];
        if (daily.isEmpty) {
          return [];
        }
        
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        final filtered = daily.where((p) => p.timestamp.isAfter(cutoff)).toList();
        return filtered;
        
      case ChartTimeRange.all:
        // Use all daily data
        final daily = token.dailyPriceHistory ?? [];
        return daily;
    }
  }
  
  String _getTimeRangeLabel() {
    switch (timeRange) {
      case ChartTimeRange.day:
        return '24 HOUR CHANGE';
      case ChartTimeRange.week:
        return '7 DAY CHANGE';
      case ChartTimeRange.month:
        return '30 DAY CHANGE';
      case ChartTimeRange.all:
        return 'ALL TIME CHANGE';
    }
  }
  
  double _getMinPrice(List<PricePoint> data) {
    if (data.isEmpty) return 0;
    return data.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }
  
  double _getMaxPrice(List<PricePoint> data) {
    if (data.isEmpty) return 0;
    return data.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }
  
  double _getMinY(List<PricePoint> data) {
    if (data.isEmpty) return 0;
    final min = _getMinPrice(data);
    final max = _getMaxPrice(data);
    if (min == max) {
      if (min < 0.000001) {
        return 0;
      }
      return min * 0.95;
    }
    return min * 0.98;
  }
  
  double _getMaxY(List<PricePoint> data) {
    if (data.isEmpty) return 1;
    final max = _getMaxPrice(data);
    final min = _getMinPrice(data);
    if (min == max) {
      if (max < 0.000001) {
        return 0.000001;
      }
      return max * 1.05;
    }
    return max * 1.02;
  }
  
  double _getHorizontalInterval(List<PricePoint> data) {
    if (data.isEmpty) return 1;
    
    final minY = _getMinY(data);
    final maxY = _getMaxY(data);
    final range = maxY - minY;
    
    if (range < 0.0000000001) {
      final maxPrice = _getMaxPrice(data);
      if (maxPrice < 0.0000000001) {
        return 0.0000000001;
      }
      return maxPrice * 0.2;
    }
    
    return range / 5;
  }
  
  double _getTimeInterval(List<PricePoint> data) {
    if (data.isEmpty) return 1;
    
    // For hourly data (1D and 7D), show more labels
    if (timeRange == ChartTimeRange.day || timeRange == ChartTimeRange.week) {
      return (data.length / 6).ceilToDouble().clamp(1, data.length.toDouble());
    }
    
    // For daily data (30D and All), show fewer labels
    return (data.length / 5).ceilToDouble().clamp(1, data.length.toDouble());
  }
  
  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(1)}k';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else if (price >= 0.01) {
      return '\$${price.toStringAsFixed(4)}';
    } else if (price >= 0.0001) {
      return '\$${price.toStringAsFixed(6)}';
    } else if (price >= 0.000001) {
      return '\$${price.toStringAsFixed(8)}';
    } else if (price > 0) {
      return '\$${price.toStringAsExponential(2)}';
    } else {
      return '\$0.00';
    }
  }
  
  String _formatDate(DateTime date) {
    switch (timeRange) {
      case ChartTimeRange.day:
        return DateFormat('HH:mm').format(date);
      case ChartTimeRange.week:
        // For 7D hourly data, show day and hour
        final now = DateTime.now();
        final diff = now.difference(date).inDays;
        if (diff == 0) {
          return DateFormat('HH:mm').format(date);
        } else if (diff == 1) {
          return 'Yesterday';
        } else if (diff < 7) {
          return DateFormat('EEE HH:mm').format(date);
        } else {
          return DateFormat('MMM d').format(date);
        }
      case ChartTimeRange.month:
        return DateFormat('MMM d').format(date);
      case ChartTimeRange.all:
        return DateFormat('MMM yy').format(date);
    }
  }
  
  String _formatTooltipDate(DateTime date) {
    switch (timeRange) {
      case ChartTimeRange.day:
        return DateFormat('MMM d, HH:mm').format(date);
      case ChartTimeRange.week:
        // For 7D hourly data, show full date and time
        return DateFormat('EEE, MMM d, HH:mm').format(date);
      case ChartTimeRange.month:
        return DateFormat('EEE, MMM d').format(date);
      case ChartTimeRange.all:
        return DateFormat('MMM d, yyyy').format(date);
    }
  }
}