import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/client_model.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> _filterClients(List<Client> clients) {
    if (_searchQuery.isEmpty) return clients;
    final query = _searchQuery.toLowerCase();
    return clients.where((c) {
      return c.fullName.toLowerCase().contains(query) ||
          c.phone.contains(query) ||
          c.nationalId.contains(query) ||
          c.bankCardNumber.contains(query) ||
          (c.bankName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder with Cloud Firestore for real-time sync across devices.
    // When data is added/updated/deleted from ANY device, the UI updates instantly.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.getClientsStream(),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for first data
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: AppColors.darkGradient),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        }

        // Handle errors gracefully — fall back to local Hive data
        List<Client> allClients;
        if (snapshot.hasError || !snapshot.hasData) {
          // Fallback: read from local Hive storage
          allClients = HiveService.getAllClients();
          allClients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else {
          // Convert Firestore documents to Client objects
          allClients = snapshot.data!.docs
              .map((doc) => FirestoreService.clientFromSnapshot(doc))
              .toList();
        }

        final clients = _filterClients(allClients);

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.darkGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.gold.withAlpha(60)),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.gold,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المعاملات 📋',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(fontSize: 20),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${allClients.length} معاملة',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 8),
                                  // Cloud sync indicator
                                  Icon(
                                    snapshot.hasData
                                        ? Icons.cloud_done_rounded
                                        : Icons.cloud_off_rounded,
                                    size: 14,
                                    color: snapshot.hasData
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    snapshot.hasData ? 'متصل' : 'غير متصل',
                                    style: TextStyle(
                                      color: snapshot.hasData
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Export All
                        if (allClients.isNotEmpty)
                          IconButton(
                            onPressed: () async {
                              await PdfService.generateAllClientsReport(
                                  allClients);
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: AppColors.gold,
                                size: 20,
                              ),
                            ),
                            tooltip: 'تصدير الكل PDF',
                          ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),

                  // Search Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: SearchField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      hintText: 'البحث بالاسم، رقم الهاتف، البطاقة، المصرف...',
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  // Clients List
                  Expanded(
                    child: clients.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.person_search_rounded,
                            title: 'لا توجد معاملات',
                            subtitle:
                                'اضغط + لإضافة معاملة جديدة',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: clients.length,
                            itemBuilder: (context, index) {
                              final client = clients[index];
                              return _buildClientCard(context, client)
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(
                                        milliseconds:
                                            40 * (index.clamp(0, 12))),
                                    duration: 350.ms,
                                  )
                                  .slideY(
                                    begin: 0.05,
                                    end: 0,
                                    delay: Duration(
                                        milliseconds:
                                            40 * (index.clamp(0, 12))),
                                  );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddClientScreen()),
              );
            },
            backgroundColor: AppColors.gold,
            child: const Icon(Icons.add_rounded,
                color: AppColors.backgroundDark),
          ),
        );
      },
    );
  }

  Widget _buildClientCard(BuildContext context, Client client) {
    return GlassCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(clientId: client.id),
          ),
        );
      },
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withAlpha(50),
                  AppColors.gold.withAlpha(20),
                ],
              ),
              border: Border.all(color: AppColors.gold.withAlpha(60)),
            ),
            child: Center(
              child: Text(
                client.fullName.isNotEmpty ? client.fullName[0] : '?',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Client Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.credit_card_rounded,
                        size: 12,
                        color: AppColors.textMuted.withAlpha(150)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        client.bankCardNumber,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (client.bankName != null &&
                        client.bankName!.isNotEmpty) ...[
                      Icon(Icons.account_balance_rounded,
                          size: 11,
                          color: AppColors.textMuted.withAlpha(120)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          client.bankName!,
                          style: TextStyle(
                            color: AppColors.textMuted.withAlpha(180),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.calendar_today_outlined,
                        size: 11,
                        color: AppColors.textMuted.withAlpha(120)),
                    const SizedBox(width: 3),
                    Text(
                      Formatters.date(client.purchaseDate),
                      style: TextStyle(
                        color: AppColors.textMuted.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profit
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(client.profit, symbol: 'د.ل'),
                style: TextStyle(
                  color: client.profit >= 0
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '\$${Formatters.number(client.dollarAmount)}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
