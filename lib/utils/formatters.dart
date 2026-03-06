import 'package:intl/intl.dart';

class Formatters {
  static final _numberFormat = NumberFormat('#,##0.00');
  static final _dateFormat = DateFormat('yyyy/MM/dd');
  static final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

  static String currency(double amount, {String symbol = 'د.ل'}) {
    return '${_numberFormat.format(amount)} $symbol';
  }

  static String number(double amount) {
    return _numberFormat.format(amount);
  }

  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  static String dateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'LYD':
        return 'د.ل';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SAR':
        return 'ر.س';
      case 'AED':
        return 'د.إ';
      case 'EGP':
        return 'ج.م';
      case 'TND':
        return 'د.ت';
      case 'TRY':
        return '₺';
      default:
        return currencyCode;
    }
  }

  static const List<String> supportedCurrencies = [
    'LYD', 'USD', 'EUR', 'GBP', 'SAR', 'AED', 'EGP', 'TND', 'TRY',
  ];

  static const Map<String, String> currencyNames = {
    'LYD': 'دينار ليبي',
    'USD': 'دولار أمريكي',
    'EUR': 'يورو',
    'GBP': 'جنيه إسترليني',
    'SAR': 'ريال سعودي',
    'AED': 'درهم إماراتي',
    'EGP': 'جنيه مصري',
    'TND': 'دينار تونسي',
    'TRY': 'ليرة تركية',
  };
}
