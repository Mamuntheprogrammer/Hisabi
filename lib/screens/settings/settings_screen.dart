import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/backup_manager.dart';
import '../../core/theme/app_theme.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(icon: Icons.account_balance, value: '${db.accounts.length}', label: 'Accounts'),
                  _StatItem(icon: Icons.receipt_long, value: '${db.transactions.length}', label: 'Transactions'),
                  _StatItem(icon: Icons.savings, value: settings.formatAmount(db.totalBalance), label: 'Total'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preferences
          Text('Preferences', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primaryColor, size: 20),
                  ),
                  title: const Text('Dark Mode'),
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.language, color: Colors.orange, size: 20),
                  ),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showComingSoon(context, 'Language settings coming soon'),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.monetization_on, color: Colors.green, size: 20),
                  ),
                  title: const Text('Currency'),
                  subtitle: Text('${settings.currencyCode} (${settings.currencySymbol})'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showCurrencyPicker(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Security
          Text('Security', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.lock_outline, color: Colors.indigo, size: 20),
                  ),
                  title: Text(settings.pinEnabled ? 'Change PIN' : 'Set PIN'),
                  subtitle: Text(settings.pinEnabled ? 'PIN lock is active' : 'Protect your data with a PIN'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (settings.pinEnabled)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _confirmRemovePin(context, settings),
                        ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PinScreen(isSetup: true),
                    ));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Data
          Text('Data', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.backup, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Save a copy of all your data'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _createBackup(context),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.restore, color: Colors.orange, size: 20),
                  ),
                  title: const Text('Restore Backup'),
                  subtitle: const Text('Restore data from a previous backup'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showRestoreDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Recurring Transactions
          Text('Recurring Transactions', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: db.recurringRules.where((r) => r.isActive).isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No recurring transactions', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  )
                : Column(
                    children: db.recurringRules.where((r) => r.isActive).map((rule) {
                      final tx = db.transactions.where((t) => t.id == rule.transactionId).firstOrNull;
                      final cat = tx != null ? db.getCategory(tx.categoryId) : null;
                      final isIncome = tx?.type == 'income';
                      return Column(
                        children: [
                          if (rule != db.recurringRules.where((r) => r.isActive).first) const Divider(height: 1, indent: 72, endIndent: 16),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? AppColors.income : AppColors.expense, size: 20),
                            ),
                            title: Text(cat?.name ?? tx?.type ?? 'Unknown', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              '${tx != null ? settings.formatAmount(tx.amount) : ''} • ${rule.frequency} • Next: ${DateFormat('dd MMM').format(rule.nextDate)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => db.deleteRecurringRule(rule.id!),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          // About
          Text('About', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                  ),
                  title: const Text('Hisabi'),
                  subtitle: const Text('Version 1.0.0'),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.description, color: Colors.purple, size: 20),
                  ),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Data stays on your device'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showComingSoon(context, 'Privacy Policy:\n\nHisabi stores all data locally on your device.\nNo data is collected, shared, or transmitted.\n100% offline, 100% private.'),
                ),
              ],
            ),
          ),
          _DeveloperCard(),
          const SizedBox(height: 32),
          Center(
            child: Text('Made with ❤️ for Bangladesh', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final path = await BackupManager.createBackup();
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Backup created: $path')));
      }
    } catch (e) {
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final files = await BackupManager.getBackupFiles();
    if (!context.mounted) return;

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backups found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (_, i) {
              final f = files[i];
              final stat = f.statSync();
              final name = f.path.split('/').last;
              final size = stat.size;
              final modified = stat.modified;
              final sizeStr = size > 1024 * 1024
                  ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
                  : '${(size / 1024).toStringAsFixed(0)} KB';
              return ListTile(
                title: Text(name),
                subtitle: Text('$sizeStr • ${DateFormat('dd MMM yyyy HH:mm').format(modified)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.orange),
                      tooltip: 'Restore',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmRestore(context, f.path);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () async {
                        await BackupManager.deleteBackup(f.path);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showRestoreDialog(context);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, String backupPath) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text('This will replace ALL current data with the backup. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final scaffold = ScaffoldMessenger.of(context);
              try {
                await BackupManager.restoreBackup(backupPath);
                if (context.mounted) {
                  context.read<DatabaseProvider>().loadAll();
                  scaffold.showSnackBar(const SnackBar(content: Text('Data restored successfully')));
                }
              } catch (e) {
                if (context.mounted) {
                  scaffold.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: SettingsProvider.currencies.entries.map((e) {
              final isSelected = settings.currencyCode == e.key;
              return ListTile(
                selected: isSelected,
                leading: Text(e.value, style: const TextStyle(fontSize: 24)),
                title: Text(e.key),
                subtitle: Text(_currencyName(e.key)),
                trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setCurrency(e.key);
                  CurrencyFormatter.symbol = e.value;
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  String _currencyName(String code) {
    final names = {
      'BDT': 'Bangladeshi Taka',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'INR': 'Indian Rupee',
      'JPY': 'Japanese Yen',
      'CNY': 'Chinese Yuan',
      'AED': 'UAE Dirham',
      'SAR': 'Saudi Riyal',
      'MYR': 'Malaysian Ringgit',
      'SGD': 'Singapore Dollar',
      'AUD': 'Australian Dollar',
      'CAD': 'Canadian Dollar',
    };
    return names[code] ?? code;
  }

  void _confirmRemovePin(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove the PIN lock?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              settings.removePin();
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showComingSoon(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.08),
              AppTheme.primaryColor.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Md. Abdullah Al Mamun', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Flutter Developer', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialIcon(
                    icon: Icons.email_outlined,
                    color: Colors.red,
                    tooltip: 'Email',
                    onTap: () => _launchUri(context, 'mailto:a.a.mamunbu@gmail.com'),
                  ),
                  const SizedBox(width: 12),
                  _SocialIcon(
                    icon: Icons.link,
                    color: const Color(0xFF0A66C2),
                    tooltip: 'LinkedIn',
                    onTap: () => _launchUri(context, 'https://www.linkedin.com/in/mamuntheprogrammer'),
                  ),
                  const SizedBox(width: 12),
                  _SocialIcon(
                    icon: Icons.code,
                    color: Colors.black87,
                    tooltip: 'GitHub',
                    onTap: () => _launchUri(context, 'https://github.com/Mamuntheprogrammer'),
                  ),
                  const SizedBox(width: 12),
                  _SocialIcon(
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF25D366),
                    tooltip: 'WhatsApp',
                    onTap: () => _launchUri(context, 'https://wa.me/8801924121313'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUri(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
