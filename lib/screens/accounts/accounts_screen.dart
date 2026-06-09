import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/database_provider.dart';
import '../../models/account.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);
    final accounts = db.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAccountSheet(context),
          ),
        ],
      ),
      body: accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 64,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No accounts yet',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddAccountSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => db.loadAll(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Balance',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimaryContainer)),
                          const SizedBox(height: 8),
                          Text(
                              CurrencyFormatter.format(db.totalBalance),
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme
                                          .onPrimaryContainer)),
                          const SizedBox(height: 4),
                          Text(
                              '${accounts.length} account${accounts.length > 1 ? 's' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme
                                      .onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...accounts.map(
                      (account) => _AccountCard(account: account, db: db)),
                ],
              ),
            ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _AddAccountSheet(),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final DatabaseProvider db;
  const _AccountCard({required this.account, required this.db});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(account.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAccountDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(_getIcon(), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    if (account.nameBn != null)
                      Text(account.nameBn!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    if (account.bankName != null)
                      Text(account.bankName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    Text(account.type,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(account.balance),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (account.icon) {
      case 'account_balance':
        return Icons.account_balance;
      case 'smartphone':
        return Icons.smartphone;
      case 'payments':
        return Icons.payments;
      case 'savings':
        return Icons.savings;
      case 'piggy_bank':
        return Icons.savings;
      default:
        return Icons.account_balance;
    }
  }

  void _showAccountDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.name, style: Theme.of(ctx).textTheme.titleLarge),
            if (account.nameBn != null) ...[
              const SizedBox(height: 4),
              Text(account.nameBn!,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _InfoTile(label: 'Type', value: account.type)),
                if (account.bankName != null)
                  Expanded(
                      child:
                          _InfoTile(label: 'Bank', value: account.bankName!)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _editAccount(context);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context);
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Edit Account')),
          body: _AddAccountSheet(existingAccount: account),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Delete "${account.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      db.deleteAccount(account.id!);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  final Account? existingAccount;
  const _AddAccountSheet({this.existingAccount});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  String _selectedType = 'Savings';
  int _selectedColor = 0xFF006B5E;

  String? _selectedPredefined;
  bool _isCustom = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.existingAccount?.name ?? '');
    _balanceCtrl = TextEditingController(
        text: widget.existingAccount != null
            ? widget.existingAccount!.balance.toString()
            : '');
    if (widget.existingAccount != null) {
      _selectedType = widget.existingAccount!.type;
      _selectedColor = widget.existingAccount!.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  List<_PredefinedOption> _buildPredefinedOptions() {
    final options = <_PredefinedOption>[
      const _PredefinedOption('Custom', Icons.edit, null, null, null),
    ];
    for (final bank in AppConstants.bankAccounts) {
      options.add(_PredefinedOption(
        bank['name']!,
        Icons.account_balance,
        bank['name']!,
        bank['nameBn'],
        null,
      ));
    }
    for (final mb in AppConstants.mobileBanking) {
      options.add(_PredefinedOption(
        mb['name']!,
        Icons.smartphone,
        mb['name']!,
        mb['nameBn'],
        'Mobile Banking',
      ));
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingAccount != null;
    final predefinedOptions = _buildPredefinedOptions();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Account' : 'Add Account',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              if (!isEdit) ...[
                DropdownButtonFormField<String>(
                  value: _selectedPredefined,
                  decoration: const InputDecoration(
                    labelText: 'Select Account',
                    hintText: 'Choose or Custom',
                  ),
                  isExpanded: true,
                  items: predefinedOptions.map((opt) {
                    final icon = opt.icon;
                    return DropdownMenuItem<String>(
                      value: opt.name,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedPredefined = v;
                      _isCustom = v == 'Custom';
                      if (!_isCustom) {
                        _nameCtrl.text = v!;
                        _selectedColor = AppTheme.accentColors[0].value;
                        final opt = predefinedOptions.firstWhere((o) => o.name == v);
                        if (opt.forceType != null) {
                          _selectedType = opt.forceType!;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g., বাসার টাকা',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration:
                    const InputDecoration(labelText: 'Account Type'),
                items: AppConstants.accountTypes
                    .map((t) => DropdownMenuItem(
                        value: t['name'],
                        child: Text(t['name']!)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Opening Balance (৳)',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              Text('Color', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppTheme.accentColors
                    .map((c) => GestureDetector(
                          onTap: () => setState(
                              () => _selectedColor = c.value),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: _selectedColor == c.value
                                  ? Border.all(
                                      color: theme
                                          .colorScheme.onSurface,
                                      width: 2)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Update' : 'Add Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = context.read<DatabaseProvider>();
    final account = Account(
      id: widget.existingAccount?.id,
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      balance: double.tryParse(_balanceCtrl.text) ?? 0,
      color: _selectedColor,
      icon: _selectedType == 'Mobile Banking'
          ? 'smartphone'
          : 'account_balance',
    );
    if (widget.existingAccount != null) {
      await db.updateAccount(account);
    } else {
      await db.insertAccount(account);
    }
    if (mounted) Navigator.pop(context);
  }
}

class _PredefinedOption {
  final String name;
  final IconData icon;
  final String? accountName;
  final String? nameBn;
  final String? forceType;
  const _PredefinedOption(this.name, this.icon, this.accountName, this.nameBn, this.forceType);
}
