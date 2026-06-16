import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/market_models.dart';
import '../../../../core/extensions/extensions.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = _sampleNotifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark All Read')),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Container(
                  decoration: BoxDecoration(
                    color: notif.isRead ? Theme.of(context).cardColor : AppTheme.primaryGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: notif.isRead ? Colors.grey.shade200 : AppTheme.primaryGreen.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _iconColor(notif.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconForType(notif.type), color: _iconColor(notif.type), size: 22),
                    ),
                    title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w600, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.body, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2),
                        const SizedBox(height: 4),
                        Text(notif.createdAt.timeAgo(), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                      ],
                    ),
                    trailing: notif.isRead ? null : Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGreen),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'price_alert': return Icons.trending_up;
      case 'order': return Icons.shopping_cart;
      case 'portfolio': return Icons.pie_chart;
      default: return Icons.campaign;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'price_alert': return AppTheme.infoColor;
      case 'order': return AppTheme.profitColor;
      case 'portfolio': return AppTheme.warningColor;
      default: return AppTheme.primaryGreen;
    }
  }
}

final List<NotificationModel> _sampleNotifications = [
  NotificationModel(id: 'N1', title: 'Price Alert: RELIANCE', body: 'Reliance Industries crossed ₹2,850. Target achieved!', type: 'price_alert', isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 1))),
  NotificationModel(id: 'N2', title: 'HDFCBANK hits 52-week low', body: 'HDFC Bank is trading near its 52-week low of ₹1,480.', type: 'price_alert', isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 3))),
  NotificationModel(id: 'N3', title: 'Buy Order Executed', body: 'Your order to buy 10 shares of TCS at ₹3,890 has been executed.', type: 'order', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 1))),
  NotificationModel(id: 'N4', title: 'Portfolio Update', body: 'Your portfolio crossed ₹5,75,000. Up 17.5% overall!', type: 'portfolio', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 2))),
  NotificationModel(id: 'N5', title: 'Market News: RBI Policy', body: 'RBI keeps repo rate unchanged at 6.50%. Markets react positively.', type: 'market', isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 6))),
  NotificationModel(id: 'N6', title: 'Sell Order Executed', body: 'Your order to sell 2 shares of TCS at ₹3,850 has been executed.', type: 'order', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 5))),
  NotificationModel(id: 'N7', title: 'Dividend Credited', body: 'ITC Ltd dividend of ₹1,750 credited to your account.', type: 'portfolio', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 7))),
];
