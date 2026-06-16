import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

extension NumberFormatting on num {
  String formatCurrency({bool showSymbol = true}) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '${showSymbol ? AppConstants.currencySymbol : ''}${formatter.format(this)}';
  }

  String formatCompactCurrency({bool showSymbol = true}) {
    if (this >= 10000000) {
      final val = (this / 10000000);
      return '${showSymbol ? AppConstants.currencySymbol : ''}${val.toStringAsFixed(2)}Cr';
    } else if (this >= 100000) {
      final val = (this / 100000);
      return '${showSymbol ? AppConstants.currencySymbol : ''}${val.toStringAsFixed(2)}L';
    } else if (this >= 1000) {
      final val = (this / 1000);
      return '${showSymbol ? AppConstants.currencySymbol : ''}${val.toStringAsFixed(1)}K';
    }
    return '${showSymbol ? AppConstants.currencySymbol : ''}${toStringAsFixed(0)}';
  }

  String formatPercentage() {
    final sign = this >= 0 ? '+' : '';
    return '$sign${toStringAsFixed(2)}${AppConstants.percentageSymbol}';
  }

  Color get profitLossColor => this >= 0 ? AppTheme.profitColor : AppTheme.lossColor;
}

extension DateFormatting on DateTime {
  String timeAgo() => formatRelative();

  String formatRelative() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  String formatDate({String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern, 'en_IN').format(this);
  }

  String formatTime({String pattern = 'hh:mm a'}) {
    return DateFormat(pattern).format(this);
  }
}

extension StringFormatting on String {
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  bool get isValidPhone => length == 10 && int.tryParse(this) != null;
  bool get isValidPassword => length >= 8;
}

extension ContextExtensions on BuildContext {
  void showSnackBar(String message, {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.lossColor : null,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }
}
