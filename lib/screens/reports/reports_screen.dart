import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/export_pdf.dart';
import '../../core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  int _selectedPeriod = 0;

  DateTime? _pdfStart;
  DateTime? _pdfEnd;

  Future<void> _pickDateRange(BuildContext context, DatabaseProvider db) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDate: _pdfStart ?? DateTime(now.year, now.month, 1),
      helpText: 'Select start date',
    );
    if (start == null || !context.mounted) return;
    final end = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: now,
      initialDate: _pdfEnd ?? now,
      helpText: 'Select end date',
    );
    if (end == null || !context.mounted) return;
    setState(() { _pdfStart = start; _pdfEnd = end; });
    _exportReport(context, db, start, end);
  }

  Future<void> _exportReport(BuildContext context, DatabaseProvider db, DateTime start, DateTime end) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final txList = db.transactions.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();

      final catMap = <int, Category>{};
      for (final c in db.categories) {
        final id = c.id;
        if (id != null) catMap[id] = c;
      }
      final accMap = <int, Account>{};
      for (final a in db.allAccounts) {
        final id = a.id;
        if (id != null) accMap[id] = a;
      }

      final monthlyData = <MonthlyData>[];
      final months = <String>{};
      for (final t in txList) {
        months.add('${t.date.year}-${t.date.month}');
      }
      final sortedMonths = months.toList()..sort();
      for (final m in sortedMonths) {
        final parts = m.split('-');
        final yr = int.parse(parts[0]);
        final mo = int.parse(parts[1]);
        monthlyData.add(MonthlyData(
          mo, yr,
          txList.where((t) => t.type == 'income' && t.date.year == yr && t.date.month == mo).fold(0.0, (s, t) => s + t.amount),
          txList.where((t) => t.type == 'expense' && t.date.year == yr && t.date.month == mo).fold(0.0, (s, t) => s + t.amount),
        ));
      }

      final expenseTx = txList.where((t) => t.type == 'expense').toList();
      final catTotals = <int, double>{};
      for (final t in expenseTx) {
        if (t.categoryId != null) {
          catTotals.update(t.categoryId!, (v) => v + t.amount, ifAbsent: () => t.amount);
        }
      }
      final sortedCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final categoryBreakdown = sortedCats.map((e) {
        final cat = catMap[e.key];
        return CategoryBreakdown(cat?.name ?? '$e.key', cat?.color ?? 0xFF00695C, e.value);
      }).toList();

      final reportData = ReportData(
        startDate: start,
        endDate: end,
        transactions: txList,
        categoryMap: catMap,
        accountMap: accMap,
        accounts: db.allAccounts,
        monthlyData: monthlyData,
        categoryBreakdown: categoryBreakdown,
      );

      await exportPdf(context, reportData);
      if (context.mounted) {
        scaffold.showSnackBar(const SnackBar(content: Text('PDF report generated')));
      }
    } catch (e) {
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);
    final now = DateTime.now();

    final income = db.getIncomeForMonth(now.month, now.year);
    final expense = db.getExpensesForMonth(now.month, now.year);
    final savings = income - expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF Report',
            onPressed: () => _pickDateRange(context, db),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pdfStart != null && _pdfEnd != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFF00695C)),
                    const SizedBox(width: 8),
                    Text(
                      'PDF: ${DateFormat('dd/MM/yy').format(_pdfStart!)} – ${DateFormat('dd/MM/yy').format(_pdfEnd!)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF00695C)),
                    ),
                  ],
                ),
              ),
            Text('${DateFormat('MMMM yyyy').format(now)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Income', amount: income, color: AppColors.income, theme: theme)),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(label: 'Expense', amount: expense, color: AppColors.expense, theme: theme)),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(label: 'Savings', amount: savings, color: savings >= 0 ? AppColors.income : AppColors.expense, theme: theme)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Monthly Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _MonthlyChart(db: db, year: now.year),
            ),
            const SizedBox(height: 24),
            Text('Expense Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _ExpensePieChart(db: db, month: now.month, year: now.year),
            ),
            const SizedBox(height: 16),
            ...db.getTopExpenseCategories(now.month, now.year, limit: 5).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(e.key.color), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.key.name, style: theme.textTheme.bodyMedium)),
                  Text('${((e.value / (expense > 0 ? expense : 1)) * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Text(CurrencyFormatter.format(e.value), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            )),
            const SizedBox(height: 24),
            Text('Account Balances', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...db.accounts.map((a) => Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Color(a.color).withOpacity(0.1), child: Icon(Icons.account_balance, color: Color(a.color), size: 20)),
                title: Text(a.name),
                trailing: Text(CurrencyFormatter.format(a.balance), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
            )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final ThemeData theme;
  const _SummaryCard({required this.label, required this.amount, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(CurrencyFormatter.format(amount), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final DatabaseProvider db;
  final int year;
  const _MonthlyChart({required this.db, required this.year});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = List.generate(12, (i) => i + 1);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text('${v.toInt()}', style: const TextStyle(fontSize: 10))))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: months.map((m) {
          final inc = db.getIncomeForMonth(m, year);
          final exp = db.getExpensesForMonth(m, year);
          return BarChartGroupData(x: m, barRods: [
            BarChartRodData(toY: inc, color: AppColors.income, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            BarChartRodData(toY: exp, color: AppColors.expense, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          ]);
        }).toList(),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (int m = 1; m <= 12; m++) {
      max = [max, db.getIncomeForMonth(m, year), db.getExpensesForMonth(m, year)].reduce((a, b) => a > b ? a : b);
    }
    return max > 0 ? max * 1.2 : 1000;
  }
}

class _ExpensePieChart extends StatelessWidget {
  final DatabaseProvider db;
  final int month, year;
  const _ExpensePieChart({required this.db, required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    final topCats = db.getTopExpenseCategories(month, year, limit: 5);
    final total = db.getExpensesForMonth(month, year);

    if (total == 0) {
      return Center(child: Text('No expenses this month', style: Theme.of(context).textTheme.bodyMedium));
    }

    return PieChart(
      PieChartData(
        sections: topCats.asMap().entries.map((e) {
          final pct = e.value.value / total;
          return PieChartSectionData(
            value: pct * 100,
            title: '${(pct * 100).toStringAsFixed(0)}%',
            color: Color(e.value.key.color),
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}
