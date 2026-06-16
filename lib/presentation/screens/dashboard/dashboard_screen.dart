import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/stock_widgets.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final topGainers = ref.watch(topGainersProvider);
    final topLosers = ref.watch(topLosersProvider);
    final trendingStocks = ref.watch(trendingStocksProvider);
    final newsList = ref.watch(newsProvider);
    final marketOverview = ref.watch(marketOverviewProvider);
    final watchlist = ref.watch(watchlistProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
          onRefresh: () => ref.read(marketDataNotifierProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          const Text('Investor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications_outlined, color: Colors.grey.shade600),
                            onPressed: () => context.push('/notifications'),
                          ),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Data Freshness Indicator
                ref.watch(isDataStaleProvider)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Using cached data — real-time server not connected',
                                style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 8),

                // Market Status Chip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: marketOverview.isMarketOpen
                              ? AppTheme.profitColor.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: marketOverview.isMarketOpen ? AppTheme.profitColor : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              marketOverview.isMarketOpen ? 'Market Open' : 'Market Closed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: marketOverview.isMarketOpen ? AppTheme.profitColor : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Portfolio Value Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Portfolio Value', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.push('/portfolio'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('View All', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          portfolio.currentValue.formatCurrency(),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: portfolio.returnsPercentage >= 0
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    portfolio.returnsPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                                    color: Colors.white, size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${portfolio.returnsPercentage >= 0 ? '+' : ''}${portfolio.returnsPercentage.formatPercentage()}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Total Investment: ${portfolio.totalInvestment.formatCurrency()}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Market Overview Mini
                const SectionHeader(title: 'Market Overview'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMarketCard(context, 'NIFTY 50', marketOverview.currentValue.formatCurrency(),
                            marketOverview.changePercent.formatPercentage(), marketOverview.change >= 0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMarketCard(
                          context, 'SENSEX',
                          marketOverview.sensexValue > 0
                              ? marketOverview.sensexValue.formatCurrency()
                              : '—',
                          marketOverview.sensexChange >= 0
                              ? '+${marketOverview.sensexChange.toStringAsFixed(2)}%'
                              : '${marketOverview.sensexChange.toStringAsFixed(2)}%',
                          marketOverview.sensexChange >= 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMarketCard(
                          context, 'BANK NIFTY',
                          marketOverview.bankNiftyValue > 0
                              ? marketOverview.bankNiftyValue.formatCurrency()
                              : '—',
                          marketOverview.bankNiftyChange >= 0
                              ? '+${marketOverview.bankNiftyChange.toStringAsFixed(2)}%'
                              : '${marketOverview.bankNiftyChange.toStringAsFixed(2)}%',
                          marketOverview.bankNiftyChange >= 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mini Portfolio Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(12, (i) => FlSpot(i.toDouble(), 1.0 + (i * 0.15) + (i % 3 == 0 ? 0.2 : 0))),
                            isCurved: true,
                            color: AppTheme.primaryGreen,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildQuickAction(context, Icons.search, 'Search', () => context.push('/search')),
                      const SizedBox(width: 16),
                      _buildQuickAction(context, Icons.add, 'Buy', () {}),
                      const SizedBox(width: 16),
                      _buildQuickAction(context, Icons.account_balance_wallet, 'Add Money', () => context.push('/wallet')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Watchlist Quick Preview
                if (watchlist.stocks.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Watchlist',
                    actionText: 'See All',
                    onActionTap: () => context.go('/watchlist'),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: watchlist.stocks.length,
                      itemBuilder: (context, index) {
                        final stock = watchlist.stocks[index];
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const Spacer(),
                              Text(stock.currentPrice.formatCurrency(showSymbol: true), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(
                                stock.changePercent.formatPercentage(),
                                style: TextStyle(color: stock.changePercent.profitLossColor, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Trending Stocks
                if (trendingStocks.isNotEmpty) ...[
                  const SectionHeader(title: 'Trending Stocks', actionText: 'See All', onActionTap: null),
                  SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: trendingStocks.length,
                    itemBuilder: (context, index) {
                      final stock = trendingStocks[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/stocks/${stock.symbol}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: stock.changePercent >= 0
                                          ? AppTheme.profitColor.withValues(alpha: 0.1)
                                          : AppTheme.lossColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Text(stock.symbol.substring(0, 2), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stock.changePercent.profitLossColor))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(stock.name.truncate(18), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                              const Spacer(),
                              Text(stock.currentPrice.formatCurrency(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(stock.changePercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: stock.changePercent.profitLossColor),
                                  const SizedBox(width: 2),
                                  Text(stock.changePercent.formatPercentage(), style: TextStyle(color: stock.changePercent.profitLossColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ],
                const SizedBox(height: 16),

                // Top Gainers & Losers
                if (topGainers.isNotEmpty || topLosers.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeader(title: 'Top Gainers'),
                                  if (topGainers.isNotEmpty)
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: topGainers.length,
                                      itemBuilder: (context, index) => StockListTile(stock: topGainers[index]),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                                      child: Text('No data yet', style: TextStyle(color: Colors.grey.shade500)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeader(title: 'Top Losers'),
                                  if (topLosers.isNotEmpty)
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: topLosers.length,
                                      itemBuilder: (context, index) => StockListTile(stock: topLosers[index]),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                                      child: Text('No data yet', style: TextStyle(color: Colors.grey.shade500)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Top Gainers'),
                            if (topGainers.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: topGainers.length,
                                itemBuilder: (context, index) => StockListTile(stock: topGainers[index]),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                                child: Text('No data yet', style: TextStyle(color: Colors.grey.shade500)),
                              ),
                            const SizedBox(height: 16),
                            const SectionHeader(title: 'Top Losers'),
                            if (topLosers.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: topLosers.length,
                                itemBuilder: (context, index) => StockListTile(stock: topLosers[index]),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                                child: Text('No data yet', style: TextStyle(color: Colors.grey.shade500)),
                              ),
                          ],
                        );
                      }
                    },
                  ),
                const SizedBox(height: 16),

                // News Feed
                if (newsList.isNotEmpty) ...[
                  const SectionHeader(title: 'Market News'),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final article = newsList[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(article.category.toUpperCase(), style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                                const Spacer(),
                                Text(article.source, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            Text(article.publishedAt.timeAgo(), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildMarketCard(BuildContext context, String name, String value, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(change, style: TextStyle(color: isPositive ? AppTheme.profitColor : AppTheme.lossColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
