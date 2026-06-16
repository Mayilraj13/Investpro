import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _biometricEnabled = true;
  bool _priceAlerts = true;
  bool _newsNotifications = true;
  bool _portfolioUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              children: [
            // User Card
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: const Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Aishwarya Selvaraju', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('aishwaryaselvaraju14@gmail.com', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('KYC Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // KYC Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your KYC Status', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.grey.shade200,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _kycStep('PAN', true),
                          _kycStep('Aadhaar', true),
                          _kycStep('Bank', true),
                          _kycStep('Photo', true),
                          _kycStep('Sign', true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Settings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            _settingsSection('Account', [
              _setting(Icons.person_outline, 'Personal Details', () {}),
              _setting(Icons.account_balance_wallet, 'Bank Accounts', () {}),
              _setting(Icons.verified_user, 'KYC Details', () {}),
            ]),
            const SizedBox(height: 8),
            _settingsSection('Security', [
              _setting(Icons.lock_outlined, 'Change Password', () {}),
              _switchSetting(Icons.fingerprint, 'Biometric Login', _biometricEnabled, (v) => setState(() => _biometricEnabled = v)),
              _setting(Icons.security, 'Two-Factor Authentication', () {}),
            ]),
            const SizedBox(height: 8),
            _settingsSection('Preferences', [
              _switchSetting(Icons.dark_mode, 'Dark Mode', _isDarkMode, (v) => {
                setState(() => _isDarkMode = v),
                context.showSnackBar('Theme will change on restart'),
              }),
              _setting(Icons.language, 'Language', () {}),
              _setting(Icons.currency_rupee, 'Currency', () {}),
            ]),
            const SizedBox(height: 8),
            _settingsSection('Notifications', [
              _switchSetting(Icons.trending_up, 'Price Alerts', _priceAlerts, (v) => setState(() => _priceAlerts = v)),
              _switchSetting(Icons.campaign, 'Market News', _newsNotifications, (v) => setState(() => _newsNotifications = v)),
              _switchSetting(Icons.pie_chart, 'Portfolio Updates', _portfolioUpdates, (v) => setState(() => _portfolioUpdates = v)),
            ]),
            const SizedBox(height: 8),
            _settingsSection('Support', [
              _setting(Icons.help_outline, 'Help & Support', () {}),
              _setting(Icons.description, 'Terms & Conditions', () {}),
              _setting(Icons.privacy_tip, 'Privacy Policy', () {}),
              _setting(Icons.info_outline, 'App Version', () {}, trailing: 'v1.0.0'),
            ]),
            const SizedBox(height: 16),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: AppTheme.lossColor),
                  label: const Text('Logout', style: TextStyle(color: AppTheme.lossColor)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.lossColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
    ),
    );
  }

  Widget _kycStep(String label, bool completed) {
    return Column(
      children: [
        Icon(completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? AppTheme.primaryGreen : Colors.grey.shade400, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: completed ? AppTheme.primaryGreen : Colors.grey.shade500, fontSize: 10)),
      ],
    );
  }

  Widget _settingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _setting(IconData icon, String title, VoidCallback onTap, {String? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: trailing != null
          ? Text(trailing, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _switchSetting(IconData icon, String title, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              const secureStorage = FlutterSecureStorage();
              await secureStorage.delete(key: 'session_active');
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.lossColor)),
          ),
        ],
      ),
    );
  }
}
