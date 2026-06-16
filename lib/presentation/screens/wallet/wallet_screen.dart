import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';
import '../../widgets/common_widgets.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  double _balance = 45280.50;
  final List<Map<String, dynamic>> _transactions = [
    {'type': 'credit', 'amount': 25000.0, 'note': 'Added from Bank Account', 'date': DateTime.now().subtract(const Duration(days: 2))},
    {'type': 'debit', 'amount': 15000.0, 'note': 'Bought 10 RELIANCE', 'date': DateTime.now().subtract(const Duration(days: 5))},
    {'type': 'credit', 'amount': 45280.50, 'note': 'Opening Balance', 'date': DateTime.now().subtract(const Duration(days: 30))},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_balance.formatCurrency(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddMoneySheet(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Money'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showWithdrawSheet(context),
                            icon: const Icon(Icons.remove, size: 18),
                            label: const Text('Withdraw'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bank Accounts
            const SectionHeader(title: 'Linked Bank Accounts'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance, color: Colors.blue),
                  ),
                  title: const Text('HDFC Bank Savings', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('XXXX1234'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Primary', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),

            // Quick Actions
            const SectionHeader(title: 'Quick Actions'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _actionChip(Icons.upgrade, 'UPI Transfer'),
                  const SizedBox(width: 12),
                  _actionChip(Icons.receipt_long, 'Statement'),
                  const SizedBox(width: 12),
                  _actionChip(Icons.add_card, 'Add Bank'),
                ],
              ),
            ),

            // Transaction History
            const SectionHeader(title: 'Transactions'),
            ..._transactions.map((t) => ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: t['type'] == 'credit'
                          ? AppTheme.profitColor.withValues(alpha: 0.1)
                          : AppTheme.lossColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      t['type'] == 'credit' ? Icons.arrow_downward : Icons.arrow_upward,
                      color: t['type'] == 'credit' ? AppTheme.profitColor : AppTheme.lossColor,
                      size: 20,
                    ),
                  ),
                  title: Text(t['note'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text((t['date'] as DateTime).timeAgo(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  trailing: Text(
                    '${t['type'] == 'credit' ? '+' : '-'} ${(t['amount'] as double).formatCurrency()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: t['type'] == 'credit' ? AppTheme.profitColor : AppTheme.lossColor,
                    ),
                  ),
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label) {
    return Expanded(
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
    );
  }

  void _showAddMoneySheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 16),
              Row(
                children: [500, 1000, 2000, 5000].map((amt) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => controller.text = amt.toString(),
                        child: Text(amt.formatCurrency(), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(controller.text) ?? 0;
                    if (amount > 0) {
                      setState(() => _balance += amount);
                      _transactions.insert(0, {'type': 'credit', 'amount': amount, 'note': 'Added from Bank Account', 'date': DateTime.now()});
                      Navigator.pop(ctx);
                      context.showSnackBar('₹${amount.toStringAsFixed(0)} added successfully!');
                    }
                  },
                  child: Text('Add ₹${controller.text.isEmpty ? '0' : controller.text}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Withdraw Money', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: 8),
              Text('Available: ${_balance.formatCurrency()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(controller.text) ?? 0;
                    if (amount > 0 && amount <= _balance) {
                      setState(() => _balance -= amount);
                      _transactions.insert(0, {'type': 'debit', 'amount': amount, 'note': 'Withdrawn to Bank Account', 'date': DateTime.now()});
                      Navigator.pop(ctx);
                      context.showSnackBar('₹${amount.toStringAsFixed(0)} withdrawn successfully!');
                    } else {
                      context.showSnackBar('Insufficient balance!', isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.lossColor),
                  child: Text('Withdraw ₹${controller.text.isEmpty ? '0' : controller.text}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
