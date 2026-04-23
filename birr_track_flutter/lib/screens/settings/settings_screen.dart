import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/security_provider.dart';
import '../../core/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _showSetPinDialog(BuildContext context) {
    _pinController.clear();
    _confirmPinController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Lock PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a 4-digit PIN to secure your app.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'New PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final pin = _pinController.text;
                final confirm = _confirmPinController.text;
                if (pin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be 4 digits')),
                  );
                  return;
                }
                if (pin != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PINs do not match')),
                  );
                  return;
                }
                context.read<SecurityProvider>().setPin(pin);
                context.read<SecurityProvider>().setAppLockEnabled(true);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDisablePinDialog(BuildContext context) {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disable App Lock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your PIN to verify identity.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Enter PIN',
                  counterText: '',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = _pinController.text;
                final ok = await context.read<SecurityProvider>().verifyPin(pin);
                if (ok) {
                  context.read<SecurityProvider>().setAppLockEnabled(false);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect PIN')),
                  );
                }
              },
              child: const Text('Disable'),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'More currencies coming soon.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇪🇹', style: TextStyle(fontSize: 24)),
                title: const Text('Ethiopian Birr'),
                subtitle: const Text('ETB'),
                trailing: const Icon(Icons.check_circle, color: AppColors.primary),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data', style: TextStyle(color: AppColors.expense)),
          content: const Text(
            'This will permanently delete all your transactions, bank accounts, budgets, and categories. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().clearAll();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared successfully')),
                );
              },
              child: const Text('Clear All', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final securityProvider = context.watch<SecurityProvider>();
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),

            // Scrollable list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Header
                    _buildSectionHeader('SECURITY'),
                    _buildSectionContainer(
                      isDark: isDark,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                          title: const Text('App Lock', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Lock app with biometrics or PIN when backgrounded', style: TextStyle(fontSize: 12)),
                          trailing: Switch(
                            value: securityProvider.appLockEnabled,
                            onChanged: (val) {
                              if (val) {
                                _showSetPinDialog(context);
                              } else {
                                if (securityProvider.hasPin) {
                                  _showDisablePinDialog(context);
                                } else {
                                  securityProvider.setAppLockEnabled(false);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // SMS Import Header
                    _buildSectionHeader('SMS IMPORT'),
                    _buildSectionContainer(
                      isDark: isDark,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                          title: const Text('SMS Sync', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Configure automatic bank SMS message scanning (Android)', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Configure SMS permissions in android settings, and toggle individual banks on home screen')),
                            );
                          },
                        ),
                      ],
                    ),

                    // Data Header
                    _buildSectionHeader('DATA'),
                    _buildSectionContainer(
                      isDark: isDark,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.download_outlined, color: AppColors.primary),
                          title: const Text('Export Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Export filtered data as a PDF report', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          onTap: () {
                            if (appProvider.transactions.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No transactions to export')),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF Export service is configured under Settings data actions')),
                            );
                          },
                        ),
                        Divider(color: isDark ? AppColors.darkBorder : AppColors.borderLight, height: 1),
                        ListTile(
                          leading: const Icon(Icons.refresh_outlined, color: AppColors.primary),
                          title: const Text('Refresh Data', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Reload all database records from device storage', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          onTap: () async {
                            await appProvider.refreshData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Database reloaded')),
                            );
                          },
                        ),
                      ],
                    ),

                    // Appearance Header
                    _buildSectionHeader('APPEARANCE'),
                    _buildSectionContainer(
                      isDark: isDark,
                      children: [
                        ListTile(
                          leading: Icon(
                            themeProvider.isDark(context) ? Icons.nightlight_outlined : Icons.wb_sunny_outlined,
                            color: AppColors.primary,
                          ),
                          title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            themeProvider.mode == AppThemeMode.system
                                ? 'System default'
                                : themeProvider.mode == AppThemeMode.dark
                                    ? 'Dark Mode'
                                    : 'Light Mode',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              _buildThemeOption(AppThemeMode.system, 'System', Icons.phone_android),
                              const SizedBox(width: 8),
                              _buildThemeOption(AppThemeMode.light, 'Light', Icons.wb_sunny_outlined),
                              const SizedBox(width: 8),
                              _buildThemeOption(AppThemeMode.dark, 'Dark', Icons.nightlight_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // General Header
                    _buildSectionHeader('GENERAL'),
                    _buildSectionContainer(
                      isDark: isDark,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.monetization_on_outlined, color: AppColors.primary),
                          title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Ethiopian Birr (ETB)', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          onTap: () => _showCurrencyDialog(context),
                        ),
                        Divider(color: isDark ? AppColors.darkBorder : AppColors.borderLight, height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: AppColors.primary),
                          title: const Text('About App', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Birr Track v1.0.0 info', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          onTap: () => context.push('/about'),
                        ),
                      ],
                    ),

                    // Danger Zone Header
                    _buildSectionHeader('DANGER ZONE'),
                    _buildSectionContainer(
                      isDark: isDark,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete_forever_outlined, color: AppColors.expense),
                          title: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense)),
                          subtitle: const Text('Permanently factory reset and delete all local records', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          onTap: () => _confirmClearData(context),
                        ),
                      ],
                    ),

                    // Footer
                    const SizedBox(height: 36),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Birr Track',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ethiopian Expense Tracker',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Version 1.0.0',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Built by ', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                              GestureDetector(
                                onTap: () => launchUrl(Uri.parse('https://henokenyew.me')),
                                child: const Text(
                                  'Henok Enyew',
                                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required bool isDark, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(AppThemeMode m, String label, IconData icon) {
    final themeProvider = context.read<ThemeProvider>();
    final active = themeProvider.mode == m;

    return Expanded(
      child: GestureDetector(
        onTap: () => themeProvider.setMode(m),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceSecondary,
            border: Border.all(
              color: active ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
