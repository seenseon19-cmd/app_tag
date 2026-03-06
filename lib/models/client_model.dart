import 'package:hive/hive.dart';

part 'client_model.g.dart';

@HiveType(typeId: 0)
class Client extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fullName; // الاسم الكامل

  @HiveField(2)
  String phone; // رقم الهاتف

  @HiveField(3)
  String nationalId; // الرقم الوطني

  @HiveField(4)
  String bankCardNumber; // رقم البطاقة البنكية

  @HiveField(5)
  DateTime purchaseDate; // تاريخ الشراء

  @HiveField(6)
  String? note; // ملاحظة

  @HiveField(7)
  double purchasePrice; // سعر الشراء (LYD)

  @HiveField(8)
  double deposit; // الإيداع (LYD)

  @HiveField(9)
  double dollarAmount; // مبلغ الدولار (USD)

  @HiveField(10)
  String currency; // العملة (LYD, USD, EUR, etc.)

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? updatedAt;

  // === NEW FIELDS ===

  @HiveField(13)
  String? bankName; // اسم المصرف

  @HiveField(14)
  double? exchangeRate; // سعر الصرف (LYD/USD)

  @HiveField(15)
  double? profitLyd; // الربح بالدينار الليبي

  Client({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.nationalId,
    required this.bankCardNumber,
    required this.purchaseDate,
    this.note,
    required this.purchasePrice,
    required this.deposit,
    required this.dollarAmount,
    this.currency = 'LYD',
    required this.createdAt,
    this.updatedAt,
    this.bankName,
    this.exchangeRate,
    this.profitLyd,
  });

  /// الربح = (مبلغ الدولار × سعر الصرف) - (سعر الشراء + الإيداع)
  /// profit = (usd_amount * exchange_rate) - (purchase_price + deposit)
  double get calculatedProfit {
    final rate = exchangeRate ?? 0.0;
    return (dollarAmount * rate) - (purchasePrice + deposit);
  }

  /// الربح المحفوظ أو المحسوب
  double get profit => profitLyd ?? calculatedProfit;

  /// الربح القديم (للتوافقية) = سعر الشراء - الإيداع
  double get netAmount => purchasePrice - deposit;
}
