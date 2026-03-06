import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_theme.dart';
import '../models/client_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class AddClientScreen extends StatefulWidget {
  final Client? client; // null = add, non-null = edit

  const AddClientScreen({super.key, this.client});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _bankCardController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _depositController = TextEditingController();
  final _dollarAmountController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  String _selectedCurrency = 'LYD';
  bool _isSaving = false;

  bool get _isEditing => widget.client != null;

  /// الربح = (مبلغ الدولار × سعر الصرف) - (سعر الشراء + الإيداع)
  double get _profit {
    final usdAmount = double.tryParse(_dollarAmountController.text) ?? 0;
    final rate = double.tryParse(_exchangeRateController.text) ?? 0;
    final price = double.tryParse(_purchasePriceController.text) ?? 0;
    final deposit = double.tryParse(_depositController.text) ?? 0;
    return (usdAmount * rate) - (price + deposit);
  }

  // Common bank names in Libya
  static const List<String> _commonBanks = [
    'مصرف الجمهورية',
    'مصرف التجارة والتنمية',
    'مصرف الصحاري',
    'المصرف الأهلي التجاري',
    'مصرف ليبيا المركزي',
    'مصرف الوحدة',
    'المصرف التجاري الوطني',
    'مصرف الأمان',
    'مصرف شمال أفريقيا',
    'مصرف المتحد',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.client!;
      _nameController.text = c.fullName;
      _phoneController.text = c.phone;
      _nationalIdController.text = c.nationalId;
      _bankCardController.text = c.bankCardNumber;
      _bankNameController.text = c.bankName ?? '';
      _noteController.text = c.note ?? '';
      _purchasePriceController.text = c.purchasePrice.toString();
      _depositController.text = c.deposit.toString();
      _dollarAmountController.text = c.dollarAmount.toString();
      _exchangeRateController.text =
          c.exchangeRate != null ? c.exchangeRate.toString() : '';
      _purchaseDate = c.purchaseDate;
      _selectedCurrency = c.currency;
    }

    // Listen for changes to update profit
    _purchasePriceController.addListener(_updateUI);
    _depositController.addListener(_updateUI);
    _dollarAmountController.addListener(_updateUI);
    _exchangeRateController.addListener(_updateUI);
  }

  void _updateUI() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _bankCardController.dispose();
    _bankNameController.dispose();
    _noteController.dispose();
    _purchasePriceController.dispose();
    _depositController.dispose();
    _dollarAmountController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.backgroundElevated,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.backgroundElevated,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  void _showBankPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر المصرف',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _commonBanks.length,
                  itemBuilder: (context, index) {
                    final bank = _commonBanks[index];
                    final isSelected = _bankNameController.text == bank;
                    return GlassCard(
                      onTap: () {
                        if (bank == 'أخرى') {
                          _bankNameController.clear();
                        } else {
                          _bankNameController.text = bank;
                        }
                        setState(() {});
                        Navigator.of(ctx).pop();
                      },
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.account_balance_rounded,
                            color: isSelected
                                ? AppColors.success
                                : AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            bank,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final exchangeRate =
          double.tryParse(_exchangeRateController.text);
      final profit = _profit;

      if (_isEditing) {
        final client = widget.client!;
        client.fullName = _nameController.text.trim();
        client.phone = _phoneController.text.trim();
        client.nationalId = _nationalIdController.text.trim();
        client.bankCardNumber = _bankCardController.text.trim();
        client.bankName = _bankNameController.text.isNotEmpty
            ? _bankNameController.text.trim()
            : null;
        client.note = _noteController.text.isNotEmpty
            ? _noteController.text.trim()
            : null;
        client.purchasePrice =
            double.tryParse(_purchasePriceController.text) ?? 0;
        client.deposit =
            double.tryParse(_depositController.text) ?? 0;
        client.dollarAmount =
            double.tryParse(_dollarAmountController.text) ?? 0;
        client.exchangeRate = exchangeRate;
        client.profitLyd = profit;
        client.purchaseDate = _purchaseDate;
        client.currency = _selectedCurrency;

        // Save to Hive (local)
        await HiveService.updateClient(client);
        // Sync to Cloud Firestore
        await FirestoreService.updateClient(client);
      } else {
        final client = Client(
          id: HiveService.generateId(),
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          bankCardNumber: _bankCardController.text.trim(),
          bankName: _bankNameController.text.isNotEmpty
              ? _bankNameController.text.trim()
              : null,
          note: _noteController.text.isNotEmpty
              ? _noteController.text.trim()
              : null,
          purchasePrice:
              double.tryParse(_purchasePriceController.text) ?? 0,
          deposit: double.tryParse(_depositController.text) ?? 0,
          dollarAmount:
              double.tryParse(_dollarAmountController.text) ?? 0,
          exchangeRate: exchangeRate,
          profitLyd: profit,
          purchaseDate: _purchaseDate,
          currency: _selectedCurrency,
          createdAt: DateTime.now(),
        );

        // Save to Hive (local)
        await HiveService.addClient(client);
        // Sync to Cloud Firestore
        await FirestoreService.addClient(client);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success),
                const SizedBox(width: 10),
                Text(
                  _isEditing
                      ? 'تم تحديث البيانات بنجاح ✓'
                      : 'تم إضافة المعاملة بنجاح ✓',
                ),
              ],
            ),
            backgroundColor: AppColors.backgroundElevated,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 10),
                Text('حدث خطأ: $e'),
              ],
            ),
            backgroundColor: AppColors.backgroundElevated,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل المعاملة' : 'إضافة معاملة جديدة',
          style: const TextStyle(color: AppColors.gold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Column(
          children: [
            // Scrollable form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  children: [
                    // ===== Client Info =====
                    _buildSectionHeader(
                        'معلومات العميل', Icons.person_outline_rounded),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _nameController,
                      label: 'اسم العميل *',
                      icon: Icons.person_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف *',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'رقم الهاتف مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _nationalIdController,
                      label: 'الرقم الوطني *',
                      icon: Icons.badge_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الرقم الوطني مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Card Number
                    _buildTextField(
                      controller: _bankCardController,
                      label: 'رقم البطاقة *',
                      icon: Icons.credit_card_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'رقم البطاقة مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Bank Name (Picker + Text)
                    GestureDetector(
                      onTap: _showBankPicker,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _bankNameController,
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'اسم المصرف',
                            prefixIcon: const Icon(
                                Icons.account_balance_rounded,
                                color: AppColors.gold),
                            suffixIcon: const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: AppColors.gold),
                            hintText: 'اختر المصرف',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Purchase Date
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'تاريخ الشراء',
                            prefixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.gold),
                            suffixIcon: const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: AppColors.gold),
                            hintText: DateFormat('yyyy/MM/dd')
                                .format(_purchaseDate),
                          ),
                          controller: TextEditingController(
                            text: DateFormat('yyyy/MM/dd')
                                .format(_purchaseDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _noteController,
                      label: 'ملاحظة',
                      icon: Icons.note_alt_outlined,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // ===== Financial Info =====
                    _buildSectionHeader(
                        'المعلومات المالية', Icons.account_balance_rounded),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _purchasePriceController,
                      label: 'سعر الشراء (LYD) *',
                      icon: Icons.monetization_on_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'سعر الشراء مطلوب';
                        }
                        if (double.tryParse(v) == null) {
                          return 'أدخل رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _depositController,
                      label: 'الإيداع (LYD) *',
                      icon: Icons.payments_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'الإيداع مطلوب';
                        }
                        if (double.tryParse(v) == null) {
                          return 'أدخل رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _dollarAmountController,
                      label: 'مبلغ الدولار (USD) *',
                      icon: Icons.attach_money_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'مبلغ الدولار مطلوب';
                        }
                        if (double.tryParse(v) == null) {
                          return 'أدخل رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Exchange Rate
                    _buildTextField(
                      controller: _exchangeRateController,
                      label: 'سعر الصرف (LYD/USD) *',
                      icon: Icons.currency_exchange_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'سعر الصرف مطلوب';
                        }
                        if (double.tryParse(v) == null) {
                          return 'أدخل رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Profit (auto-calculated)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _profit >= 0
                                  ? AppColors.success.withAlpha(20)
                                  : AppColors.error.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _profit >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: _profit >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'الربح (محسوب تلقائياً)',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '( USD × سعر الصرف ) - ( الشراء + الإيداع )',
                                  style: TextStyle(
                                    color: AppColors.textMuted.withAlpha(120),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.currency(
                                    _profit,
                                    symbol: 'د.ل',
                                  ),
                                  style: TextStyle(
                                    color: _profit >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Currency Selector
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        dropdownColor: AppColors.backgroundElevated,
                        decoration: const InputDecoration(
                          labelText: 'العملة',
                          prefixIcon: Icon(Icons.currency_exchange_rounded,
                              color: AppColors.gold),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        items: Formatters.supportedCurrencies.map((currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(
                              '$currency - ${Formatters.currencyNames[currency] ?? currency}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCurrency = value);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ===== SAVE BUTTON (Always visible at bottom) =====
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                border: Border(
                  top: BorderSide(color: AppColors.gold.withAlpha(30)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveClient,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.backgroundDark,
                            ),
                          )
                        : Icon(_isEditing
                            ? Icons.save_rounded
                            : Icons.check_circle_rounded),
                    label: Text(
                      _isEditing ? 'حفظ التعديلات' : 'حفظ المعاملة',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.backgroundDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: AppColors.gold.withAlpha(80),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: AppColors.gold.withAlpha(30)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.gold),
      ),
    );
  }
}
