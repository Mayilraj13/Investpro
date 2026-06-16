import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/shimmer_widgets.dart';

class StockDetailsScreen extends ConsumerWidget {
  final String symbol;
  const StockDetailsScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockQuoteProvider(symbol));
    final isWatchlist = ref.watch(watchlistProvider.select((w) => w.stocks.any((s) => s.symbol == symbol)));

    return stockAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(symbol)),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text(symbol)),
        body: Center(child: Text('Error loading stock quote: $err')),
      ),
      data: (stock) {
        if (stock == null) return const Scaffold(body: Center(child: Text('Stock not found')));

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.symbol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(stock.sector, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(isWatchlist ? Icons.bookmark : Icons.bookmark_border, color: isWatchlist ? AppTheme.primaryGreen : null),
                onPressed: () => ref.read(watchlistProvider.notifier).toggleStock(stock.symbol, stock.name),
              ),
              IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(stock.currentPrice.formatCurrency(showSymbol: true),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: stock.changePercent >= 0
                                  ? AppTheme.profitColor.withValues(alpha: 0.1)
                                  : AppTheme.lossColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(stock.changePercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 16, color: stock.changePercent.profitLossColor),
                                const SizedBox(width: 4),
                                Text(stock.change.formatCurrency(),
                                    style: TextStyle(color: stock.changePercent.profitLossColor, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Text('(${stock.changePercent.formatPercentage()})',
                                    style: TextStyle(color: stock.changePercent.profitLossColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Volume: ${stock.volume.formatCompactCurrency(showSymbol: false)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),

                // Chart Section
                StockChartWidget(
                  symbol: stock.symbol,
                  currentPrice: stock.currentPrice,
                  changePercent: stock.changePercent,
                ),
                const SizedBox(height: 16),

                // Buy/Sell Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showOrderDialog(context, stock.symbol, 'BUY', stock.currentPrice, AppTheme.profitColor),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('BUY'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.profitColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showOrderDialog(context, stock.symbol, 'SELL', stock.currentPrice, AppTheme.lossColor),
                          icon: const Icon(Icons.trending_down),
                          label: const Text('SELL'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.lossColor,
                            side: const BorderSide(color: AppTheme.lossColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Key Statistics
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Key Statistics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _statRow('P/E Ratio', stock.peRatio?.toStringAsFixed(2) ?? 'N/A', 'Industry Avg: ${stock.peRatio != null ? (stock.peRatio! - 5).toStringAsFixed(2) : 'N/A'}'),
                          _divider(),
                          _statRow('EPS (TTM)', stock.eps?.formatCurrency() ?? 'N/A', ''),
                          _divider(),
                          _statRow('P/B Ratio', stock.pbRatio?.toStringAsFixed(2) ?? 'N/A', ''),
                          _divider(),
                          _statRow('ROE', stock.roe?.formatPercentage() ?? 'N/A', ''),
                          _divider(),
                          _statRow('ROCE', stock.roce?.formatPercentage() ?? 'N/A', ''),
                          _divider(),
                          _statRow('Debt/Equity', stock.debtToEquity?.toStringAsFixed(2) ?? 'N/A', ''),
                          _divider(),
                          _statRow('Dividend Yield', stock.dividendYield?.formatPercentage() ?? 'N/A', ''),
                          _divider(),
                          _statRow('Market Cap', stock.marketCap.formatCompactCurrency(), ''),
                          _divider(),
                          _statRow('52W High', stock.high52Week?.formatCurrency() ?? 'N/A', ''),
                          _divider(),
                          _statRow('52W Low', stock.low52Week?.formatCurrency() ?? 'N/A', ''),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Company Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('About Company', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stock.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 8),
                          Text(stock.description ?? 'Leading Indian company in the ${stock.industry} sector.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _infoChip('CEO', stock.ceo ?? 'N/A'),
                              const SizedBox(width: 16),
                              _infoChip('Sector', stock.sector),
                              const SizedBox(width: 16),
                              _infoChip('Industry', stock.industry),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Fundamentals
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Growth Fundamentals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _statRow('Revenue Growth', stock.revenueGrowth?.formatPercentage() ?? 'N/A', '5-Year CAGR'),
                          _divider(),
                          _statRow('Profit Growth', stock.profitGrowth?.formatPercentage() ?? 'N/A', '5-Year CAGR'),
                          _divider(),
                          _statRow('Profit Margin', stock.profitMargin?.formatPercentage() ?? 'N/A', ''),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statRow(String label, String value, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);

  Widget _infoChip(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  void _showOrderDialog(BuildContext context, String symbol, String type, double price, Color color) {
    final qtyController = TextEditingController(text: '1');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final qty = int.tryParse(qtyController.text) ?? 1;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('$type $symbol', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  Text('Quantity', style: TextStyle(color: Colors.grey.shade600)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 1 ? () {
                          qtyController.text = '${qty - 1}';
                          setSheetState(() {});
                        } : null,
                      ),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: qtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 8)),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          qtyController.text = '${qty + 1}';
                          setSheetState(() {});
                        },
                      ),
                      const Spacer(),
                      Text('= ${(price * qty).formatCurrency()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.showSnackBar('$type order placed for $qty shares of $symbol');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      child: Text('$type $qty shares', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class StockChartWidget extends ConsumerWidget {
  final String symbol;
  final double currentPrice;
  final double changePercent;

  const StockChartWidget({
    super.key,
    required this.symbol,
    required this.currentPrice,
    required this.changePercent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider(symbol));
    final chartAsync = ref.watch(stockChartProvider((symbol, period)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: ['1D', '1W', '1M', '3M', '1Y', '5Y'].map((p) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(p, style: const TextStyle(fontSize: 11)),
                    selected: period == p,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedPeriodProvider(symbol).notifier).state = p;
                      }
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: chartAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: ShimmerLoading(height: 180, borderRadius: 12),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Could not load chart: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ),
              data: (points) {
                if (points.isEmpty) {
                  return const Center(child: Text('No historical data available'));
                }

                final cleanPoints = points.where((p) => p.close > 0).toList();
                if (cleanPoints.isEmpty) {
                  return const Center(child: Text('No price points available'));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(cleanPoints.length, (i) {
                          return FlSpot(i.toDouble(), cleanPoints[i].close);
                        }),
                        isCurved: true,
                        color: changePercent >= 0 ? AppTheme.profitColor : AppTheme.lossColor,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: (changePercent >= 0 ? AppTheme.profitColor : AppTheme.lossColor).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
