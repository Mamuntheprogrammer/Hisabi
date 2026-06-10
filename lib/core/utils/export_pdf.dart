import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/debt.dart';
import '../../models/bazar_list.dart';
import '../../models/bazar_item.dart';

class ReportData {
  final DateTime startDate;
  final DateTime endDate;
  final List<Transaction> transactions;
  final Map<int, Category> categoryMap;
  final Map<int, Account> accountMap;
  final List<Account> accounts;
  final List<MonthlyData> monthlyData;
  final List<CategoryBreakdown> categoryBreakdown;

  ReportData({
    required this.startDate,
    required this.endDate,
    required this.transactions,
    required this.categoryMap,
    required this.accountMap,
    required this.accounts,
    required this.monthlyData,
    required this.categoryBreakdown,
  });
}

class MonthlyData {
  final int month;
  final int year;
  final double income;
  final double expense;
  MonthlyData(this.month, this.year, this.income, this.expense);
}

class CategoryBreakdown {
  final String name;
  final int color;
  final double amount;
  CategoryBreakdown(this.name, this.color, this.amount);
}

Future<void> exportPdf(BuildContext context, ReportData data) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => _buildHeader(data.startDate, data.endDate),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('Page ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ),
      build: (ctx) => [
        _buildSummary(data),
        pw.SizedBox(height: 20),
        pw.Text('Monthly Overview', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
        pw.SizedBox(height: 8),
        _buildBarChart(data),
        pw.SizedBox(height: 20),
        pw.Text('Expense Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
        pw.SizedBox(height: 8),
        _buildCategoryTable(data),
        pw.SizedBox(height: 20),
        pw.Text('Account Balances', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
        pw.SizedBox(height: 8),
        _buildAccountTable(data),
        pw.SizedBox(height: 20),
        pw.Text('Transactions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
        pw.SizedBox(height: 8),
        _buildTransactionTable(data),
      ],
    ),
  );

  final pdfBytes = await doc.save();

  final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
  final result = await FilePicker.saveFile(
    dialogTitle: 'Save PDF report',
    fileName: 'hisabi_report_$dateStr.pdf',
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    bytes: pdfBytes,
  );

  if (result == null) return;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF report saved')),
    );
  }
}

pw.Widget _buildHeader(DateTime start, DateTime end) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Hisabi', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
      pw.Text('Financial Report', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
      pw.Text('${start.toString().substring(0, 10)} to ${end.toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      pw.SizedBox(height: 4),
      pw.Divider(color: PdfColor.fromInt(0xFF00695C)),
    ],
  );
}

pw.Widget _buildSummary(ReportData data) {
  final income = data.transactions.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
  final expense = data.transactions.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
  final net = income - expense;
  final totalBalance = data.accounts.fold(0.0, (s, a) => s + a.balance);

  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF5F7FA),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem('Income', _fmt(income), PdfColors.green700),
            _summaryItem('Expense', _fmt(expense), PdfColors.red700),
            _summaryItem('Net', _fmt(net), net >= 0 ? PdfColors.green700 : PdfColors.red700),
            _summaryItem('Total Balance', _fmt(totalBalance), PdfColor.fromInt(0xFF00695C)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text('Total transactions: ${data.transactions.length}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ),
  );
}

pw.Widget _summaryItem(String label, String value, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
    ],
  );
}

pw.Widget _buildBarChart(ReportData data) {
  if (data.monthlyData.isEmpty) return pw.Container();

  double maxVal = 0;
  for (final m in data.monthlyData) {
    maxVal = [maxVal, m.income, m.expense].reduce((a, b) => a > b ? a : b);
  }
  if (maxVal == 0) maxVal = 1000;

  final chartHeight = 140.0;
  final barWidth = 6.0;
  final gap = 3.0;
  final monthWidth = 35.0;

  final bars = <pw.Widget>[];
  for (int i = 0; i < data.monthlyData.length; i++) {
    final m = data.monthlyData[i];
    final incH = (m.income / maxVal) * chartHeight;
    final expH = (m.expense / maxVal) * chartHeight;

    bars.add(
      pw.Container(
        width: monthWidth,
        child: pw.Column(
          children: [
            pw.SizedBox(
              height: chartHeight,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    bottom: 0,
                    child: pw.Container(
                      width: barWidth,
                      height: expH > 0 ? expH : 0,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red700,
                        borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left: barWidth + gap,
                    bottom: 0,
                    child: pw.Container(
                      width: barWidth,
                      height: incH > 0 ? incH : 0,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green700,
                        borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(_monthAbbr(m.month), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
          ],
        ),
      ),
    );
  }

  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF5F7FA),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _legendItem('Income', PdfColors.green700),
            pw.SizedBox(width: 16),
            _legendItem('Expense', PdfColors.red700),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: bars,
        ),
      ],
    ),
  );
}

pw.Widget _legendItem(String label, PdfColor color) {
  return pw.Row(
    children: [
      pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)))),
      pw.SizedBox(width: 4),
      pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
    ],
  );
}

String _monthAbbr(int m) {
  const abbr = ['', 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
  return abbr[m];
}

pw.Widget _buildCategoryTable(ReportData data) {
  final hStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white);
  final cStyle = const pw.TextStyle(fontSize: 9);

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF00695C)),
      children: ['Category', 'Amount', '%'].map((h) =>
        pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: hStyle))
      ).toList(),
    ),
  ];

  final total = data.categoryBreakdown.fold(0.0, (s, c) => s + c.amount);
  for (final c in data.categoryBreakdown) {
    final pct = total > 0 ? (c.amount / total * 100) : 0.0;
    rows.add(pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Row(
            children: [
              pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(c.color & 0xFFFFFF | 0xFF000000),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              )),
              pw.SizedBox(width: 6),
              pw.Text(c.name, style: cStyle),
            ],
          ),
        ),
        pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text(_fmt(c.amount), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text('${pct.toStringAsFixed(0)}%', style: cStyle)),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: const {0: pw.FlexColumnWidth(4), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1)},
    children: rows,
  );
}

pw.Widget _buildAccountTable(ReportData data) {
  final hStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white);
  final cStyle = const pw.TextStyle(fontSize: 9);

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF00695C)),
      children: ['Account', 'Type', 'Balance'].map((h) =>
        pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: hStyle))
      ).toList(),
    ),
  ];

  for (final a in data.accounts) {
    rows.add(pw.TableRow(
      children: [
        pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text(a.name, style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text(a.type, style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text(_fmt(a.balance), style: cStyle)),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(2)},
    children: rows,
  );
}

pw.Widget _buildTransactionTable(ReportData data) {
  final hStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white);
  final cStyle = const pw.TextStyle(fontSize: 8);
  final incStyle = pw.TextStyle(fontSize: 8, color: PdfColors.green700);
  final expStyle = pw.TextStyle(fontSize: 8, color: PdfColors.red700);

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF00695C)),
      children: ['Date', 'Type', 'Category', 'Account', 'Amount', 'Note'].map((h) =>
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text(h, style: hStyle))
      ).toList(),
    ),
  ];

  for (final t in data.transactions) {
    final catId = t.categoryId;
    final catName = catId != null ? (data.categoryMap[catId]?.name ?? '$catId') : '';
    final accName = data.accountMap[t.accountId]?.name ?? '${t.accountId}';
    final isInc = t.type == 'income';
    rows.add(pw.TableRow(
      children: [
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text(t.date.toString().substring(0, 10), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text(t.type.toUpperCase(), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text(catName, style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text(accName, style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text(_fmt(t.amount), style: isInc ? incStyle : expStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text(t.note ?? '', style: cStyle)),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.8),
      1: pw.FlexColumnWidth(1.2),
      2: pw.FlexColumnWidth(2),
      3: pw.FlexColumnWidth(1.8),
      4: pw.FlexColumnWidth(1.5),
      5: pw.FlexColumnWidth(2.5),
    },
    children: rows,
  );
}

String _fmt(double amount) {
  return amount.toStringAsFixed(0);
}

Future<void> exportDebtPdf(BuildContext context, List<Debt> debts) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Hisabi', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
          pw.Text('Debt Report', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColor.fromInt(0xFF00695C)),
        ],
      ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('Page ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ),
      build: (ctx) => [
        _buildDebtSummary(debts),
        pw.SizedBox(height: 20),
        if (debts.where((d) => d.type == 'owe').isNotEmpty) ...[
          pw.Text('I Owe', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
          pw.SizedBox(height: 8),
          _buildDebtTable(debts.where((d) => d.type == 'owe').toList()),
          pw.SizedBox(height: 20),
        ],
        if (debts.where((d) => d.type == 'owed').isNotEmpty) ...[
          pw.Text("I'm Owed", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
          pw.SizedBox(height: 8),
          _buildDebtTable(debts.where((d) => d.type == 'owed').toList()),
        ],
      ],
    ),
  );

  final pdfBytes = await doc.save();

  final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
  final result = await FilePicker.saveFile(
    dialogTitle: 'Save Debt PDF report',
    fileName: 'hisabi_debt_report_$dateStr.pdf',
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    bytes: pdfBytes,
  );

  if (result == null) return;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debt PDF report saved')),
    );
  }
}

pw.Widget _buildDebtSummary(List<Debt> debts) {
  final totalOwe = debts.where((d) => d.type == 'owe').fold(0.0, (s, d) => s + d.remaining);
  final totalOwed = debts.where((d) => d.type == 'owed').fold(0.0, (s, d) => s + d.remaining);
  final totalAmount = debts.fold(0.0, (s, d) => s + d.amount);
  final totalPaid = debts.fold(0.0, (s, d) => s + d.amountPaid);

  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF5F7FA),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem('Total Debt', _fmt(totalAmount), PdfColor.fromInt(0xFF00695C)),
            _summaryItem('Total Paid', _fmt(totalPaid), PdfColors.green700),
            _summaryItem('I Owe', _fmt(totalOwe), PdfColors.red700),
            _summaryItem("I'm Owed", _fmt(totalOwed), PdfColors.green700),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text('Total debts: ${debts.length}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ),
  );
}

pw.Widget _buildDebtTable(List<Debt> debts) {
  final hStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white);
  final cStyle = const pw.TextStyle(fontSize: 8);

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF00695C)),
      children: ['Person', 'Amount', 'Paid', 'Remaining', 'Status', 'Due Date'].map((h) =>
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: hStyle))
      ).toList(),
    ),
  ];

  for (final d in debts) {
    final statusColor = d.isCleared ? PdfColors.green700 : (d.status == 'partial' ? PdfColors.orange : PdfColors.red700);
    rows.add(pw.TableRow(
      children: [
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(d.personName, style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(_fmt(d.amount), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(_fmt(d.amountPaid), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(_fmt(d.remaining), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(d.status.toUpperCase(), style: pw.TextStyle(fontSize: 8, color: statusColor))),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(d.dueDate?.toString().substring(0, 10) ?? '-', style: cStyle)),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: const {
      0: pw.FlexColumnWidth(2.5),
      1: pw.FlexColumnWidth(1.5),
      2: pw.FlexColumnWidth(1.5),
      3: pw.FlexColumnWidth(1.5),
      4: pw.FlexColumnWidth(1.5),
      5: pw.FlexColumnWidth(1.5),
    },
    children: rows,
  );
}

Future<void> exportBazarListPdf(BuildContext context, BazarList list, List<BazarItem> items) async {
  final doc = pw.Document();

  final actualTotal = items.fold(0.0, (s, i) => s + (i.priceActual ?? (i.priceEstimated * i.quantity)));
  final estTotal = items.fold(0.0, (s, i) => s + (i.priceEstimated * i.quantity));
  final boughtCount = items.where((i) => i.isBought).length;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Hisabi', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
          pw.Text('Bazar List: ${list.name}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
          pw.Text('Date: ${DateFormat('dd MMM yyyy').format(list.date)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColor.fromInt(0xFF00695C)),
        ],
      ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('Page ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ),
      build: (ctx) => [
        _buildBazarSummary(list, estTotal, actualTotal, boughtCount, items.length),
        pw.SizedBox(height: 20),
        pw.Text('Items', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00695C))),
        pw.SizedBox(height: 8),
        _buildBazarItemTable(items),
      ],
    ),
  );

  final pdfBytes = await doc.save();

  final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
  final sanitizedName = list.name.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
  final result = await FilePicker.saveFile(
    dialogTitle: 'Save Bazar list PDF',
    fileName: 'bazar_${sanitizedName}_$dateStr.pdf',
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    bytes: pdfBytes,
  );

  if (result == null) return;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bazar list PDF saved')),
    );
  }
}

pw.Widget _buildBazarSummary(BazarList list, double estTotal, double actualTotal, int boughtCount, int totalItems) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF5F7FA),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem('Items', '$totalItems', PdfColor.fromInt(0xFF00695C)),
            _summaryItem('Bought', '$boughtCount', PdfColors.green700),
            _summaryItem('Estimated', _fmt(estTotal), PdfColors.blue700),
            _summaryItem('Actual', _fmt(actualTotal), PdfColors.red700),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text('Status: ${list.isCompleted ? "Completed" : "In Progress"}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ),
  );
}

pw.Widget _buildBazarItemTable(List<BazarItem> items) {
  final hStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white);
  final cStyle = const pw.TextStyle(fontSize: 8);

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF00695C)),
      children: ['#', 'Item', 'Qty', 'Unit', 'Est. Price', 'Actual', 'Status'].map((h) =>
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: hStyle))
      ).toList(),
    ),
  ];

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    final estTotal = item.priceEstimated * item.quantity;
    final actTotal = item.priceActual != null ? item.priceActual! * item.quantity : null;
    final status = item.isBought ? '✓' : '✗';
    final statusColor = item.isBought ? PdfColors.green700 : PdfColors.red700;

    rows.add(pw.TableRow(
      children: [
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.name, style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.quantity}'.replaceAll('.0', ''), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.unit, style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(_fmt(estTotal), style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(actTotal != null ? _fmt(actTotal) : '-', style: cStyle)),
        pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(status, style: pw.TextStyle(fontSize: 8, color: statusColor))),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: const {
      0: pw.FlexColumnWidth(0.5),
      1: pw.FlexColumnWidth(2.5),
      2: pw.FlexColumnWidth(1),
      3: pw.FlexColumnWidth(1.2),
      4: pw.FlexColumnWidth(1.2),
      5: pw.FlexColumnWidth(1.2),
      6: pw.FlexColumnWidth(0.8),
    },
    children: rows,
  );
}
