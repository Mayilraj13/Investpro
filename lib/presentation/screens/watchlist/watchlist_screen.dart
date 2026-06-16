import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/app_providers.dart';
import '../../widgets/stock_widgets.dart';
import '../../widgets/common_widgets.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: watchlist.stocks.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.visibility_off,
              title: 'Your watchlist is empty',
              subtitle: 'Add stocks to track their performance',
              buttonText: 'Browse Stocks',
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(marketDataNotifierProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: watchlist.stocks.length + 2,
                separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Text('${watchlist.stocks.length} stocks', style: TextStyle(color: Colors.grey.shade600)),
                          const Spacer(),
                          Text('Today\'s P&L: ${_calculateDayPL(watchlist.stocks).formatCurrency()}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: _calculateDayPL(watchlist.stocks) >= 0 ? AppTheme.profitColor : AppTheme.lossColor)),
                        ],
                      ),
                    );
                  }
                  if (index == watchlist.stocks.length + 1) {
                    return const SizedBox(height: 80);
                  }
                  return WatchlistStockTile(stock: watchlist.stocks[index - 1]);
                },
              ),
            ),
    );
  }

  double _calculateDayPL(List<dynamic> stocks) {
    return stocks.fold(0.0, (sum, s) {
      final stock = s as dynamic;
      return sum + (stock.change ?? 0);
    });
  }
}
