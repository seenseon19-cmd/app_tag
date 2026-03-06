import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';
import 'hive_service.dart';

/// FirestoreService handles all Cloud Firestore CRUD operations.
/// This service works alongside HiveService to provide:
///   - Real-time cloud synchronization between devices
///   - Offline-first local storage via Hive
///   - Automatic data migration from Hive to Firestore
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The collection name for clients in Firestore
  static const String _collectionName = 'clients';

  /// Reference to the clients collection
  static CollectionReference<Map<String, dynamic>> get _clientsCollection =>
      _firestore.collection(_collectionName);

  // ========== CREATE / ADD ==========

  /// Add a new client to Cloud Firestore.
  /// Uses the client's UUID as the document ID to keep Hive and Firestore in sync.
  static Future<void> addClient(Client client) async {
    await _clientsCollection.doc(client.id).set(_clientToMap(client));
  }

  // ========== UPDATE ==========

  /// Update an existing client in Cloud Firestore.
  static Future<void> updateClient(Client client) async {
    await _clientsCollection.doc(client.id).update(_clientToMap(client));
  }

  // ========== DELETE ==========

  /// Delete a client from Cloud Firestore by ID.
  static Future<void> deleteClient(String id) async {
    await _clientsCollection.doc(id).delete();
  }

  // ========== READ (Real-Time Stream) ==========

  /// Returns a real-time stream of all clients, ordered by creation date (newest first).
  /// Use this with StreamBuilder for automatic UI updates when data changes on any device.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getClientsStream() {
    return _clientsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Returns a one-time fetch of all clients (not real-time).
  static Future<List<Client>> getAllClients() async {
    final snapshot = await _clientsCollection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => _mapToClient(doc.data())).toList();
  }

  // ========== SEARCH ==========

  /// Search clients by name (case-insensitive prefix search).
  /// Note: Full-text search in Firestore requires additional setup (e.g., Algolia).
  /// For local search, filter the StreamBuilder results instead.
  static Stream<QuerySnapshot<Map<String, dynamic>>> searchClientsStream(
      String query) {
    // Firestore doesn't support native contains/LIKE queries.
    // Return all and filter locally for best UX.
    return getClientsStream();
  }

  // ========== SYNC: Hive → Firestore ==========

  /// One-time migration: syncs all local Hive clients to Firestore.
  /// Only uploads clients that don't already exist in Firestore.
  /// Called on app startup to ensure no data is lost during the transition.
  static Future<void> syncLocalToCloud() async {
    try {
      final localClients = HiveService.getAllClients();
      if (localClients.isEmpty) return;

      final batch = _firestore.batch();
      int batchCount = 0;

      for (final client in localClients) {
        // Check if this client already exists in Firestore
        final docRef = _clientsCollection.doc(client.id);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          batch.set(docRef, _clientToMap(client));
          batchCount++;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // Silently fail on sync errors — app can still work locally
      // ignore: avoid_print
      print('Firestore sync error: $e');
    }
  }

  // ========== STATISTICS (Cloud-based) ==========

  /// Get total number of clients from Firestore.
  static Future<int> getTotalClientsCount() async {
    final snapshot = await _clientsCollection.count().get();
    return snapshot.count ?? 0;
  }

  // ========== CONVERTERS ==========

  /// Convert a Client object to a Firestore-compatible Map.
  static Map<String, dynamic> _clientToMap(Client client) {
    return {
      'id': client.id,
      'fullName': client.fullName,
      'phone': client.phone,
      'nationalId': client.nationalId,
      'bankCardNumber': client.bankCardNumber,
      'bankName': client.bankName,
      'purchaseDate': Timestamp.fromDate(client.purchaseDate),
      'note': client.note,
      'purchasePrice': client.purchasePrice,
      'deposit': client.deposit,
      'dollarAmount': client.dollarAmount,
      'currency': client.currency,
      'exchangeRate': client.exchangeRate,
      'profitLyd': client.profitLyd,
      'createdAt': Timestamp.fromDate(client.createdAt),
      'updatedAt': client.updatedAt != null
          ? Timestamp.fromDate(client.updatedAt!)
          : null,
    };
  }

  /// Convert a Firestore document Map back to a Client object.
  static Client _mapToClient(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      nationalId: map['nationalId'] ?? '',
      bankCardNumber: map['bankCardNumber'] ?? '',
      bankName: map['bankName'],
      purchaseDate: (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'],
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0.0,
      dollarAmount: (map['dollarAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'LYD',
      exchangeRate: (map['exchangeRate'] as num?)?.toDouble(),
      profitLyd: (map['profitLyd'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Public accessor for converting Firestore docs to Client objects.
  /// Useful in StreamBuilder widgets.
  static Client clientFromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return _mapToClient(doc.data()!);
  }
}
