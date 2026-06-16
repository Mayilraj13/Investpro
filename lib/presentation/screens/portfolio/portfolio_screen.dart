import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/stock_widgets.dart';
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final holdings = ref.watch(holdingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(marketDataNotifierProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Portfolio Summary Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Portfolio Value', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(portfolio.currentValue.formatCurrency(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _summaryChip('Total Invested', portfolio.totalInvestment.formatCurrency()),
                          const SizedBox(width: 16),
                          _summaryChip('Total Returns', '${portfolio.returnsPercentage >= 0 ? '+' : ''}${portfolio.returnsPercentage.formatPercentage()}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(portfolio.returnsPercentage >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text('${portfolio.returnsPercentage >= 0 ? '+' : ''}${portfolio.totalReturns.formatCurrency()}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                          const SizedBox(width: 8),
                          Text('Today', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Today's P&L
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.profitColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Day P&L', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(portfolio.todayProfitLoss.formatCurrency(),
                                style: TextStyle(color: AppTheme.profitColor, fontWeight: FontWeight.w700, fontSize: 16)),
                            Text(portfolio.todayProfitLossPercent.formatPercentage(),
                                style: TextStyle(color: AppTheme.profitColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invested', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(portfolio.totalInvestment.formatCurrency(),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            Text('in ${holdings.length} stocks', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Asset Allocation Chart
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Asset Allocation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: holdings.take(6).map((h) {
                              return PieChartSectionData(
                                value: h.weight,
                                title: h.weight > 5 ? h.symbol : '',
                                radius: 30,
                                titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white),
                                color: _chartColors[holdings.indexOf(h) % _chartColors.length],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: holdings.take(6).map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 10, height: 10, decoration: BoxDecoration(
                                  color: _chartColors[holdings.indexOf(h) % _chartColors.length],
                                  borderRadius: BorderRadius.circular(2),
                                )),
                                const SizedBox(width: 6),
                                Text('${h.symbol} ${h.weight.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Holdings
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Holdings (${holdings.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Transaction History'),
                    ),
                  ],
                ),
              ),
              ...holdings.map((h) => HoldingTile(holding: h)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  static const _chartColors = [
    Color(0xFF00C853), Color(0xFF2979FF), Color(0xFFFF6D00),
    Color(0xFFD500F9), Color(0xFF00BCD4), Color(0xFFFFAB00),
  ];
}
