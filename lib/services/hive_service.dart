import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../models/client_model.dart';

class HiveService {
  static const String _clientsBoxName = 'clients';
  static const String _settingsBoxName = 'settings';
  static const _uuid = Uuid();

  static late Box<Client> _clientsBox;
  static late Box _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClientAdapter());
    }

    // Open Boxes
    _clientsBox = await Hive.openBox<Client>(_clientsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Initialize default admin credentials if not set
    if (_settingsBox.get('admin_username') == null) {
      await _settingsBox.put('admin_username', 'admin');
      await _settingsBox.put('admin_password', '1234');
    }
  }

  // ========== Authentication ==========
  static bool verifyLogin(String username, String password) {
    final storedUsername =
        _settingsBox.get('admin_username', defaultValue: 'admin');
    final storedPassword =
        _settingsBox.get('admin_password', defaultValue: '1234');
    return username == storedUsername && password == storedPassword;
  }

  static Future<void> changePassword(String newPassword) async {
    await _settingsBox.put('admin_password', newPassword);
  }

  static String getAdminUsername() {
    return _settingsBox.get('admin_username', defaultValue: 'admin');
  }

  static Future<void> setRecoveryEmail(String email) async {
    await _settingsBox.put('recovery_email', email);
  }

  static String? getRecoveryEmail() {
    return _settingsBox.get('recovery_email');
  }

  // ========== Remember Me ==========
  static Future<void> setRememberMe(bool value) async {
    await _settingsBox.put('remember_me', value);
  }

  static bool getRememberMe() {
    return _settingsBox.get('remember_me', defaultValue: false) as bool;
  }

  static Future<void> setLoggedIn(bool value) async {
    await _settingsBox.put('is_logged_in', value);
  }

  static bool isLoggedIn() {
    return _settingsBox.get('is_logged_in', defaultValue: false) as bool;
  }

  static Future<void> logout() async {
    await _settingsBox.put('is_logged_in', false);
  }

  // ========== Client CRUD ==========
  static String generateId() => _uuid.v4();

  static Future<void> addClient(Client client) async {
    await _clientsBox.put(client.id, client);
  }

  static Future<void> updateClient(Client client) async {
    client.updatedAt = DateTime.now();
    await _clientsBox.put(client.id, client);
  }

  static Future<void> deleteClient(String id) async {
    await _clientsBox.delete(id);
  }

  static Client? getClient(String id) {
    return _clientsBox.get(id);
  }

  static List<Client> getAllClients() {
    return _clientsBox.values.toList();
  }

  static List<Client> searchClients(String query) {
    final lowerQuery = query.toLowerCase();
    return _clientsBox.values.where((client) {
      return client.fullName.toLowerCase().contains(lowerQuery) ||
          client.phone.contains(query) ||
          client.nationalId.contains(query) ||
          client.bankCardNumber.contains(query) ||
          (client.bankName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ========== Statistics ==========
  static double getTotalPurchases() {
    return _clientsBox.values.fold(0.0, (sum, c) => sum + c.purchasePrice);
  }

  static double getTotalDeposits() {
    return _clientsBox.values.fold(0.0, (sum, c) => sum + c.deposit);
  }

  static double getTotalNetAmount() {
    return _clientsBox.values.fold(0.0, (sum, c) => sum + c.netAmount);
  }

  static double getTotalDollarAmount() {
    return _clientsBox.values.fold(0.0, (sum, c) => sum + c.dollarAmount);
  }

  static double getTotalProfit() {
    return _clientsBox.values.fold(0.0, (sum, c) => sum + c.profit);
  }

  static int getTotalClientsCount() {
    return _clientsBox.values.length;
  }

  // ========== Reports - Date Filtered ==========
  static List<Client> getClientsByDateRange(DateTime from, DateTime to) {
    final fromStart = DateTime(from.year, from.month, from.day);
    final toEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _clientsBox.values.where((client) {
      return client.purchaseDate.isAfter(fromStart.subtract(const Duration(seconds: 1))) &&
          client.purchaseDate.isBefore(toEnd.add(const Duration(seconds: 1)));
    }).toList();
  }

  static double getProfitByDateRange(DateTime from, DateTime to) {
    final clients = getClientsByDateRange(from, to);
    return clients.fold(0.0, (sum, c) => sum + c.profit);
  }

  static int getTransactionCountByDateRange(DateTime from, DateTime to) {
    return getClientsByDateRange(from, to).length;
  }

  static int getCardCountByDateRange(DateTime from, DateTime to) {
    final clients = getClientsByDateRange(from, to);
    final uniqueCards = clients.map((c) => c.bankCardNumber).toSet();
    return uniqueCards.length;
  }

  // ========== Export ==========
  static Future<String> exportToCsv() async {
    final clients = getAllClients();
    final buffer = StringBuffer();
    // BOM for Arabic support in Excel
    buffer.write('\uFEFF');
    buffer.writeln(
        'الاسم,رقم البطاقة,المصرف,سعر الشراء,الإيداع,مبلغ الدولار,سعر الصرف,الربح,تاريخ الشراء');
    for (final c in clients) {
      buffer.writeln(
          '"${c.fullName}","${c.bankCardNumber}","${c.bankName ?? ''}",${c.purchasePrice},${c.deposit},${c.dollarAmount},${c.exchangeRate ?? 0},${c.profit},"${c.purchaseDate.toIso8601String()}"');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/taj_exchange_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString(), encoding: utf8);
    return file.path;
  }

  // ========== Settings ==========
  static Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  // ========== Listenable ==========
  static Box<Client> get clientsBox => _clientsBox;
}
