import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/models/watchlist_model.dart';
import '../../core/extensions/extensions.dart';
import '../../providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockListTile extends ConsumerWidget {
  final StockModel stock;
  final bool showAddButton;

  const StockListTile({
    super.key,
    required this.stock,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInWatchlist = ref.watch(watchlistProvider.select((w) => w.stocks.any((s) => s.symbol == stock.symbol)));

    return InkWell(
      onTap: () => context.push('/stocks/${stock.symbol}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stock.changePercent >= 0
                    ? AppTheme.profitColor.withValues(alpha: 0.1)
                    : AppTheme.lossColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  stock.symbol.substring(0, 2),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: stock.changePercent >= 0
                        ? AppTheme.profitColor
                        : AppTheme.lossColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(stock.name.truncate(25), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(stock.currentPrice.formatCurrency(showSymbol: true), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        stock.changePercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: stock.changePercent.profitLossColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        stock.changePercent.formatPercentage(),
                        style: TextStyle(
                          color: stock.changePercent.profitLossColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showAddButton) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                  color: isInWatchlist ? AppTheme.primaryGreen : null,
                  size: 22,
                ),
                onPressed: () {
                  ref.read(watchlistProvider.notifier).toggleStock(stock.symbol, stock.name);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HoldingTile extends StatelessWidget {
  final Holding holding;
  const HoldingTile({super.key, required this.holding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(holding.symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${holding.quantity} shares', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(holding.currentValue.formatCurrency(), style: const TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          Icon(holding.totalReturns >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: holding.totalReturns.profitLossColor),
                          const SizedBox(width: 2),
                          Text(holding.returnsPercent.formatPercentage(), style: TextStyle(color: holding.totalReturns.profitLossColor, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  _buildInfo('Avg Cost', holding.averagePrice.formatCurrency()),
                  const SizedBox(width: 24),
                  _buildInfo('LTP', holding.currentPrice.formatCurrency()),
                  const SizedBox(width: 24),
                  _buildInfo('P&L', holding.totalReturns.formatCurrency()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class WatchlistStockTile extends ConsumerWidget {
  final WatchlistStock stock;
  const WatchlistStockTile({super.key, required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/stocks/${stock.symbol}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(stock.companyName.truncate(25), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(stock.currentPrice.formatCurrency(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stock.changePercent >= 0
                          ? AppTheme.profitColor.withValues(alpha: 0.1)
                          : AppTheme.lossColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stock.changePercent.formatPercentage(),
                      style: TextStyle(
                        color: stock.changePercent.profitLossColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              onPressed: () {
                ref.read(watchlistProvider.notifier).removeStock(stock.symbol);
              },
            ),
          ],
        ),
      ),
    );
  }
}
