import '../services/db_helper.dart';
import '../models/reg_data.dart';

/// Unified service for managing stay records and related operations
/// This service centralizes stay-related logic to eliminate duplication
/// between ID card and manual registration flows
class StayService {
  static final StayService _instance = StayService._internal();
  factory StayService() => _instance;
  StayService._internal();


  /// Get the latest stay record for a visitor with prioritization:
  /// 1. Current stays that haven't ended yet (end_date >= today AND status='active')
  /// 2. Then latest stays by created_at timestamp
  /// 
  /// This implements the core requirement for unified registration logic
  static Future<StayRecord?> getLatestStay(String visitorId) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0]; // YYYY-MM-DD format

      final result = await db.rawQuery('''
        SELECT * FROM stays
        WHERE visitor_id = ?
        ORDER BY 
          (CASE 
            WHEN status='active' AND date(end_date) >= date(?) THEN 0 
            ELSE 1 
          END),
          datetime(created_at) DESC
        LIMIT 1
      ''', [visitorId, todayStr]);

      if (result.isNotEmpty) {
        return StayRecord.fromMap(result.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get latest stay: $e');
    }
  }

  /// Update stay and additional info in a single transaction
  /// This ensures data consistency when modifying existing stay records
  static Future<void> updateStayAndAdditionalInfo({
    required int stayId,
    required String visitorId,
    required DateTime newStart,
    required DateTime newEnd,
    required String visitId,
    required RegAdditionalInfo additionalInfo,
    String? note,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      await db.transaction((txn) async {
        // Update stays table
        await txn.update(
          'stays',
          {
            'start_date': newStart.toIso8601String(),
            'end_date': newEnd.toIso8601String(),
            'note': note,
          },
          where: 'id = ?',
          whereArgs: [stayId],
        );

        // Update or insert reg_additional_info
        final existingInfo = await txn.query(
          'reg_additional_info',
          where: 'regId = ? AND visitId = ?',
          whereArgs: [visitorId, visitId],
        );

        final additionalData = additionalInfo.toMap();
        additionalData['updatedAt'] = DateTime.now().toIso8601String();

        if (existingInfo.isNotEmpty) {
          // Update existing
          await txn.update(
            'reg_additional_info',
            additionalData,
            where: 'regId = ? AND visitId = ?',
            whereArgs: [visitorId, visitId],
          );
        } else {
          // Insert new
          await txn.insert('reg_additional_info', additionalData);
        }
      });
    } catch (e) {
      throw Exception('Failed to update stay and additional info: $e');
    }
  }

  /// Create new stay and additional info in a single transaction
  /// Used when no existing stay is found or when creating a new visit
  static Future<StayRecord> createStayAndAdditionalInfo({
    required String visitorId,
    required DateTime startDate,
    required DateTime endDate,
    required RegAdditionalInfo additionalInfo,
    String? note,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      late StayRecord createdStay;

      await db.transaction((txn) async {
        // Create stay record
        final newStay = StayRecord.create(
          visitorId: visitorId,
          startDate: startDate,
          endDate: endDate,
          note: note,
        );

        final stayId = await txn.insert('stays', newStay.toMap());

        // Create StayRecord with actual ID
        createdStay = StayRecord(
          id: stayId,
          visitorId: newStay.visitorId,
          startDate: newStay.startDate,
          endDate: newStay.endDate,
          status: newStay.status,
          note: newStay.note,
          createdAt: newStay.createdAt,
        );

        // Generate unique visitId using stay's timestamp
        final visitId = '${visitorId}_${createdStay.createdAt.millisecondsSinceEpoch}';

        // Update additional info with correct visitId
        final updatedAdditionalInfo = additionalInfo.copyWith(
          visitId: visitId,
          updatedAt: DateTime.now(),
        );

        // Insert additional info
        await txn.insert('reg_additional_info', updatedAdditionalInfo.toMap());
      });

      return createdStay;
    } catch (e) {
      throw Exception('Failed to create stay and additional info: $e');
    }
  }

  /// Check if visitor can create a new stay
  /// Returns false if there's an active stay that hasn't ended yet
  static Future<bool> canCreateNewStay(String visitorId) async {
    final latestStay = await getLatestStay(visitorId);
    if (latestStay == null) return true;

    // Check if the latest stay is still active and hasn't ended
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(
      latestStay.endDate.year,
      latestStay.endDate.month,
      latestStay.endDate.day,
    );

    return latestStay.status != 'active' || endDateOnly.isBefore(today);
  }

  /// Get stay status information for unified logic
  /// Returns comprehensive status info for both ID card and manual registration
  static Future<Map<String, dynamic>> getStayStatus(String visitorId) async {
    final latestStay = await getLatestStay(visitorId);
    final canCreate = await canCreateNewStay(visitorId);

    return {
      'hasStay': latestStay != null,
      'isActive': latestStay?.isActive ?? false,
      'canCreateNew': canCreate,
      'latestStay': latestStay,
      'isEditMode': latestStay != null && !canCreate, // Edit if has stay and can't create new
    };
  }

  /// Get additional info for a specific visit
  /// Used to load existing data when in edit mode
  static Future<RegAdditionalInfo?> getAdditionalInfoForStay(
    String visitorId,
    StayRecord stay,
  ) async {
    final dbHelper = DbHelper();

    try {
      // Try to find additional info using visitId pattern
      final visitId = '${visitorId}_${stay.createdAt.millisecondsSinceEpoch}';
      
      var additionalInfo = await dbHelper.fetchAdditionalInfoByVisitId(visitId);
      
      // If not found by visitId, get the latest one for this visitor
      additionalInfo ??= await dbHelper.fetchAdditionalInfoByRegId(visitorId);

      return additionalInfo;
    } catch (e) {
      throw Exception('Failed to get additional info for stay: $e');
    }
  }

  /// Update expired stays automatically
  /// Called before checking stay status to ensure data consistency
  static Future<void> updateExpiredStays() async {
    final dbHelper = DbHelper();
    await dbHelper.updateExpiredStays();
  }

  /// Get all stays for a visitor (for history display)
  static Future<List<StayRecord>> getAllStaysForVisitor(String visitorId) async {
    final dbHelper = DbHelper();
    return await dbHelper.fetchAllStays(visitorId);
  }

  /// Get active stays only for a visitor
  static Future<List<StayRecord>> getActiveStaysForVisitor(String visitorId) async {
    final dbHelper = DbHelper();
    return await dbHelper.fetchActiveStays(visitorId);
  }

  /// Complete a stay (set status to 'completed')
  static Future<void> completeStay(int stayId) async {
    final dbHelper = DbHelper();
    await dbHelper.completeStay(stayId);
  }

  /// Check for overlapping stays (validation helper)
  static Future<bool> hasOverlappingStay(
    String visitorId,
    DateTime startDate,
    DateTime endDate, {
    int? excludeStayId,
  }) async {
    final dbHelper = DbHelper();
    return await dbHelper.hasOverlappingStay(
      visitorId,
      startDate,
      endDate,
      excludeStayId: excludeStayId,
    );
  }
}