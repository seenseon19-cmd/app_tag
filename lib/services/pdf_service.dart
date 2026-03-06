import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/client_model.dart';
import '../utils/formatters.dart';

class PdfService {
  static pw.Font? _cachedArabicFont;

  // ===== Load Arabic Font (Embedded from assets) =====
  static Future<pw.Font> _loadArabicFont() async {
    if (_cachedArabicFont != null) return _cachedArabicFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      _cachedArabicFont = pw.Font.ttf(fontData);
      return _cachedArabicFont!;
    } catch (_) {
      // Fallback to Google Fonts if asset not found
      _cachedArabicFont = await PdfGoogleFonts.cairoRegular();
      return _cachedArabicFont!;
    }
  }

  // ===== Single Client PDF (print/save) =====
  static Future<void> generateClientReport(Client client) async {
    final pdf = await _buildClientPdf(client);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_${client.fullName}_${Formatters.date(DateTime.now())}',
    );
  }

  // ===== Single Client PDF (share via WhatsApp) =====
  static Future<void> shareClientPdf(Client client) async {
    final pdf = await _buildClientPdf(client);
    final bytes = await pdf.save();

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/تقرير_${client.fullName}_${Formatters.date(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '💎 تقرير العميل: ${client.fullName} - تاج الصرافة',
      ),
    );
  }

  // ===== All Clients PDF =====
  static Future<void> generateAllClientsReport(List<Client> clients) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        header: (context) => _buildAllClientsHeader(arabicFont),
        footer: (context) => _buildFooter(context, arabicFont),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildAllClientsSummary(clients, arabicFont),
          pw.SizedBox(height: 20),
          _buildAllClientsTable(clients, arabicFont),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'جميع_المعاملات_${Formatters.date(DateTime.now())}',
    );
  }

  // ===== Share All Clients PDF =====
  static Future<void> shareAllClientsPdf(List<Client> clients) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        header: (context) => _buildAllClientsHeader(arabicFont),
        footer: (context) => _buildFooter(context, arabicFont),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildAllClientsSummary(clients, arabicFont),
          pw.SizedBox(height: 20),
          _buildAllClientsTable(clients, arabicFont),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/جميع_المعاملات_${Formatters.date(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '💎 تقرير جميع المعاملات - تاج الصرافة',
      ),
    );
  }

  // ===== Build Single Client PDF =====
  static Future<pw.Document> _buildClientPdf(Client client) async {
    final pdf = pw.Document();
    final currencySymbol = Formatters.getCurrencySymbol(client.currency);
    final arabicFont = await _loadArabicFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildSingleClientHeader(client, arabicFont),
              pw.SizedBox(height: 24),

              // Client Info
              _buildSectionTitle('معلومات العميل', arabicFont),
              pw.SizedBox(height: 8),
              _buildInfoRow('الاسم الكامل', client.fullName, arabicFont),
              _buildInfoRow('رقم الهاتف', client.phone, arabicFont),
              _buildInfoRow('الرقم الوطني', client.nationalId, arabicFont),
              _buildInfoRow(
                  'رقم البطاقة البنكية', client.bankCardNumber, arabicFont),
              if (client.bankName != null && client.bankName!.isNotEmpty)
                _buildInfoRow('المصرف', client.bankName!, arabicFont),
              _buildInfoRow('تاريخ الشراء',
                  Formatters.date(client.purchaseDate), arabicFont),
              if (client.note != null && client.note!.isNotEmpty)
                _buildInfoRow('ملاحظة', client.note!, arabicFont),

              pw.SizedBox(height: 20),

              // Financial Info
              _buildSectionTitle('المعلومات المالية', arabicFont),
              pw.SizedBox(height: 8),
              _buildFinancialBox(client, currencySymbol, arabicFont),

              pw.Spacer(),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(
                      color: PdfColor.fromInt(0xFFDDDDDD),
                    ),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      Formatters.dateTime(DateTime.now()),
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 8,
                        color: const PdfColor.fromInt(0xFF999999),
                      ),
                    ),
                    pw.Text(
                      'تاج الصرافة - سري',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 8,
                        color: const PdfColor.fromInt(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSingleClientHeader(
      Client client, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD4AF37),
            width: 2,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'تاج الصرافة',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFFD4AF37),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'تقرير معاملة عميل',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 11,
                  color: const PdfColor.fromInt(0xFF888888),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'التاريخ: ${Formatters.date(DateTime.now())}',
                style: pw.TextStyle(font: arabicFont, fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                client.fullName,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font arabicFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF8E1),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: arabicFont,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFFD4AF37),
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(
      String label, String value, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFFEEEEEE),
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              value,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: arabicFont, fontSize: 10),
            ),
          ),
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialBox(
      Client client, String symbol, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFD4AF37),
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildFinancialItem(
                'الإيداع',
                Formatters.currency(client.deposit, symbol: symbol),
                const PdfColor.fromInt(0xFFFF9800),
                arabicFont,
              ),
              _buildFinancialItem(
                'سعر الشراء',
                Formatters.currency(client.purchasePrice, symbol: symbol),
                const PdfColor.fromInt(0xFF333333),
                arabicFont,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildFinancialItem(
                'سعر الصرف',
                client.exchangeRate != null
                    ? '${Formatters.number(client.exchangeRate!)} د.ل/\$'
                    : 'غير محدد',
                const PdfColor.fromInt(0xFF9C27B0),
                arabicFont,
              ),
              _buildFinancialItem(
                'مبلغ الدولار',
                Formatters.currency(client.dollarAmount, symbol: '\$'),
                const PdfColor.fromInt(0xFF2196F3),
                arabicFont,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          // Profit row (highlighted)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFE8F5E9),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'الربح: ',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF4CAF50),
                  ),
                ),
                pw.Text(
                  Formatters.currency(client.profit, symbol: 'د.ل'),
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: client.profit >= 0
                        ? const PdfColor.fromInt(0xFF4CAF50)
                        : const PdfColor.fromInt(0xFFFF5252),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialItem(
      String label, String value, PdfColor color, pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: arabicFont,
            fontSize: 9,
            color: const PdfColor.fromInt(0xFF888888),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: arabicFont,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ===== All Clients Helpers =====
  static pw.Widget _buildAllClientsHeader(pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD4AF37),
            width: 2,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            Formatters.date(DateTime.now()),
            style: pw.TextStyle(font: arabicFont, fontSize: 10),
          ),
          pw.Text(
            'تاج الصرافة - جميع المعاملات',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFDDDDDD)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 8,
              color: const PdfColor.fromInt(0xFF999999),
            ),
          ),
          pw.Text(
            'تاج الصرافة - سري',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 8,
              color: const PdfColor.fromInt(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAllClientsSummary(
      List<Client> clients, pw.Font arabicFont) {
    double totalPurchases = 0;
    double totalDeposits = 0;
    double totalProfit = 0;

    for (final c in clients) {
      totalPurchases += c.purchasePrice;
      totalDeposits += c.deposit;
      totalProfit += c.profit;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E1),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD4AF37)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildFinancialItem(
            'إجمالي الربح',
            Formatters.currency(totalProfit),
            const PdfColor.fromInt(0xFF4CAF50),
            arabicFont,
          ),
          _buildFinancialItem(
            'إجمالي الإيداع',
            Formatters.number(totalDeposits),
            const PdfColor.fromInt(0xFFFF9800),
            arabicFont,
          ),
          _buildFinancialItem(
            'إجمالي المشتريات',
            Formatters.number(totalPurchases),
            const PdfColor.fromInt(0xFF333333),
            arabicFont,
          ),
          _buildFinancialItem(
            'عدد المعاملات',
            '${clients.length}',
            const PdfColor.fromInt(0xFFD4AF37),
            arabicFont,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAllClientsTable(
      List<Client> clients, pw.Font arabicFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFEEEEEE)),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.4), // #
        1: const pw.FlexColumnWidth(1.4), // الاسم
        2: const pw.FlexColumnWidth(1.0), // البطاقة
        3: const pw.FlexColumnWidth(0.8), // المصرف
        4: const pw.FlexColumnWidth(0.8), // الشراء
        5: const pw.FlexColumnWidth(0.8), // الإيداع
        6: const pw.FlexColumnWidth(0.7), // الدولار
        7: const pw.FlexColumnWidth(0.8), // الربح
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFFF8E1),
          ),
          children:
              ['الربح', 'الدولار', 'الإيداع', 'الشراء', 'المصرف', 'البطاقة', 'الاسم', '#']
                  .map((h) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                h,
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            );
          }).toList(),
        ),
        // Data
        ...clients.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final c = entry.value;
          return pw.TableRow(
            decoration: idx.isOdd
                ? const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFAFAFA))
                : null,
            children: [
              _tableCell(Formatters.number(c.profit), arabicFont,
                  color: c.profit >= 0
                      ? const PdfColor.fromInt(0xFF4CAF50)
                      : const PdfColor.fromInt(0xFFFF5252)),
              _tableCell(Formatters.number(c.dollarAmount), arabicFont),
              _tableCell(Formatters.number(c.deposit), arabicFont),
              _tableCell(Formatters.number(c.purchasePrice), arabicFont),
              _tableCell(c.bankName ?? '-', arabicFont),
              _tableCell(c.bankCardNumber, arabicFont),
              _tableCell(c.fullName, arabicFont),
              _tableCell('$idx', arabicFont),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(String text, pw.Font arabicFont,
      {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: arabicFont,
          fontSize: 8,
          color: color,
        ),
      ),
    );
  }
}
