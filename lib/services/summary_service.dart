import 'db_helper.dart';

class SummaryService {
  final DbHelper _dbHelper = DbHelper();

  // สถิติรายวัน
  Future<DailySummary> getDailySummary({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = _formatDate(targetDate);

    final db = await _dbHelper.db;

    // ผู้เข้าพักทั้งหมดวันนี้ (active stays) - ใช้ stays table
    final activeStaysResult = await db.rawQuery(
      '''
      SELECT r.gender, COUNT(*) as count
      FROM regs r
      INNER JOIN stays s ON r.id = s.visitor_id
      WHERE s.start_date <= ? AND s.end_date >= ? AND s.status = 'active'
      GROUP BY r.gender
    ''',
      [dateStr, dateStr],
    );

    // ผู้ลงทะเบียนใหม่วันนี้
    final newRegistrationsResult = await db.rawQuery(
      '''
      SELECT r.gender, COUNT(*) as count
      FROM regs r
      WHERE DATE(r.createdAt) = DATE(?)
      GROUP BY r.gender
    ''',
      [targetDate.toIso8601String()],
    );

    // ผู้เช็คเอาท์วันนี้
    final checkoutsResult = await db.rawQuery(
      '''
      SELECT r.gender, COUNT(*) as count
      FROM regs r
      INNER JOIN stays s ON r.id = s.visitor_id
      WHERE s.end_date = ? AND s.status = 'active'
      GROUP BY r.gender
    ''',
      [dateStr],
    );

    // สรุปอุปกรณ์ที่แจกจ่าย (รายวัน) - ดึงจากผู้ที่ลงทะเบียนในวันนั้น
    final equipmentResult = await db.rawQuery(
      '''
      SELECT 
        SUM(ai.shirtCount) as totalShirts,
        SUM(ai.pantsCount) as totalPants,
        SUM(ai.matCount) as totalMats,
        SUM(ai.pillowCount) as totalPillows,
        SUM(ai.blanketCount) as totalBlankets
      FROM reg_additional_info ai
      INNER JOIN regs r ON ai.regId = r.id
      WHERE DATE(r.createdAt) = DATE(?)
    ''',
      [targetDate.toIso8601String()],
    );

    // ผู้ที่มากับเด็ก - ดึงจากผู้ที่ลงทะเบียนในวันนั้น
    final childrenResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as familiesWithChildren,
        SUM(ai.childrenCount) as totalChildren
      FROM reg_additional_info ai
      INNER JOIN regs r ON ai.regId = r.id
      WHERE ai.withChildren = 1 AND DATE(r.createdAt) = DATE(?)
    ''',
      [targetDate.toIso8601String()],
    );

    return DailySummary(
      date: targetDate,
      activeStaysByGender: _parseGenderCounts(activeStaysResult),
      newRegistrationsByGender: _parseGenderCounts(newRegistrationsResult),
      checkoutsByGender: _parseGenderCounts(checkoutsResult),
      equipmentSummary: _parseEquipmentSummary(equipmentResult),
      childrenInfo: _parseChildrenInfo(childrenResult),
    );
  }

  // สถิติช่วงเวลา
  Future<PeriodSummary> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.db;
    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);

    // จำนวนผู้เข้าพักในช่วงเวลา แยกตามเพศ - ใช้ stays table
    final staysByGenderResult = await db.rawQuery(
      '''
      SELECT r.gender, COUNT(DISTINCT r.id) as count
      FROM regs r
      INNER JOIN stays s ON r.id = s.visitor_id
      WHERE s.start_date <= ? AND s.end_date >= ? AND s.status = 'active'
      GROUP BY r.gender
    ''',
      [endDateStr, startDateStr],
    );

    // ผู้ลงทะเบียนใหม่ในช่วงเวลา แยกตามเพศ
    final newRegsByGenderResult = await db.rawQuery(
      '''
      SELECT r.gender, COUNT(*) as count
      FROM regs r
      WHERE DATE(r.createdAt) >= DATE(?) AND DATE(r.createdAt) <= DATE(?)
      GROUP BY r.gender
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // จำนวนผู้เข้าพักในช่วงเวลา (รวม) - ใช้ stays table
    final totalStaysResult = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT r.id) as totalStays
      FROM regs r
      INNER JOIN stays s ON r.id = s.visitor_id
      WHERE s.start_date <= ? AND s.end_date >= ? AND s.status = 'active'
    ''',
      [endDateStr, startDateStr],
    );

    // ระยะเวลาเข้าพักเฉลี่ย - ใช้ stays table
    final avgStayResult = await db.rawQuery(
      '''
      SELECT AVG(
        JULIANDAY(s.end_date) - JULIANDAY(s.start_date) + 1
      ) as avgStayDuration
      FROM stays s
      WHERE s.start_date >= ? AND s.start_date <= ? AND s.status = 'active'
    ''',
      [startDateStr, endDateStr],
    );

    // ผู้เข้าพักระยะยาว - ใช้ stays table
    final longStaysResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(CASE WHEN duration > 7 THEN 1 END) as moreThan7Days,
        COUNT(CASE WHEN duration > 14 THEN 1 END) as moreThan14Days,
        COUNT(CASE WHEN duration > 30 THEN 1 END) as moreThan30Days
      FROM (
        SELECT (JULIANDAY(s.end_date) - JULIANDAY(s.start_date) + 1) as duration
        FROM stays s
        WHERE s.start_date >= ? AND s.start_date <= ? AND s.status = 'active'
      )
    ''',
      [startDateStr, endDateStr],
    );

    // สรุปอุปกรณ์ที่แจกจ่ายในช่วงเวลา - ดึงจากผู้ที่ลงทะเบียนในช่วงเวลานั้น
    final periodEquipmentResult = await db.rawQuery(
      '''
      SELECT 
        SUM(ai.shirtCount) as totalShirts,
        SUM(ai.pantsCount) as totalPants,
        SUM(ai.matCount) as totalMats,
        SUM(ai.pillowCount) as totalPillows,
        SUM(ai.blanketCount) as totalBlankets
      FROM reg_additional_info ai
      INNER JOIN regs r ON ai.regId = r.id
      WHERE DATE(r.createdAt) >= DATE(?) AND DATE(r.createdAt) <= DATE(?)
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // การกระจายตัวตามจังหวัด (top 10) - ใช้ stays table
    final provinceResult = await db.rawQuery(
      '''
      SELECT 
        SUBSTR(r.addr, 1, INSTR(r.addr, ',') - 1) as province,
        COUNT(*) as count
      FROM regs r
      INNER JOIN stays s ON r.id = s.visitor_id
      WHERE s.start_date >= ? AND s.start_date <= ? AND s.status = 'active'
        AND r.addr LIKE '%,%'
      GROUP BY province
      ORDER BY count DESC
      LIMIT 10
    ''',
      [startDateStr, endDateStr],
    );

    // แนวโน้มรายวัน - ใช้ stays table
    final dailyTrendResult = await db.rawQuery(
      '''
      SELECT 
        s.start_date as date,
        COUNT(*) as checkins
      FROM stays s
      WHERE s.start_date >= ? AND s.start_date <= ? AND s.status = 'active'
      GROUP BY s.start_date
      ORDER BY s.start_date
    ''',
      [startDateStr, endDateStr],
    );

    return PeriodSummary(
      startDate: startDate,
      endDate: endDate,
      totalStays: totalStaysResult.first['totalStays'] as int? ?? 0,
      staysByGender: _parseGenderCounts(staysByGenderResult),
      newRegistrationsByGender: _parseGenderCounts(newRegsByGenderResult),
      averageStayDuration:
          avgStayResult.first['avgStayDuration'] as double? ?? 0.0,
      longStaysSummary: _parseLongStays(longStaysResult),
      equipmentSummary: _parseEquipmentSummary(periodEquipmentResult),
      topProvinces: _parseProvinces(provinceResult),
      dailyTrend: _parseDailyTrend(dailyTrendResult),
    );
  }

  // อัตราการกลับมาเข้าพักซ้ำ
  Future<RepeatVisitorStats> getRepeatVisitorStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.db;
    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);

    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(DISTINCT r.id) as totalVisitors,
        COUNT(DISTINCT CASE WHEN visit_count > 1 THEN r.id END) as repeatVisitors
      FROM regs r
      INNER JOIN (
        SELECT 
          visitor_id as regId,
          COUNT(*) as visit_count
        FROM stays
        WHERE start_date >= ? AND start_date <= ? AND status = 'active'
        GROUP BY visitor_id
      ) vc ON r.id = vc.regId
    ''',
      [startDateStr, endDateStr],
    );

    final data = result.first;
    final totalVisitors = data['totalVisitors'] as int? ?? 0;
    final repeatVisitors = data['repeatVisitors'] as int? ?? 0;

    return RepeatVisitorStats(
      totalVisitors: totalVisitors,
      repeatVisitors: repeatVisitors,
      repeatRate: totalVisitors > 0
          ? (repeatVisitors / totalVisitors) * 100
          : 0.0,
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, int> _parseGenderCounts(List<Map<String, Object?>> results) {
    final Map<String, int> counts = {
      'พระ': 0,
      'สามเณร': 0,
      'แม่ชี': 0,
      'ชาย': 0,
      'หญิง': 0,
      'อื่นๆ': 0,
    };

    for (final row in results) {
      final gender = row['gender'] as String? ?? 'อื่นๆ';
      final count = row['count'] as int? ?? 0;
      counts[gender] = count;
    }

    return counts;
  }

  EquipmentSummary _parseEquipmentSummary(List<Map<String, Object?>> results) {
    if (results.isEmpty) {
      return EquipmentSummary(
        totalShirts: 0,
        totalPants: 0,
        totalMats: 0,
        totalPillows: 0,
        totalBlankets: 0,
      );
    }

    final data = results.first;
    return EquipmentSummary(
      totalShirts: data['totalShirts'] as int? ?? 0,
      totalPants: data['totalPants'] as int? ?? 0,
      totalMats: data['totalMats'] as int? ?? 0,
      totalPillows: data['totalPillows'] as int? ?? 0,
      totalBlankets: data['totalBlankets'] as int? ?? 0,
    );
  }

  ChildrenInfo _parseChildrenInfo(List<Map<String, Object?>> results) {
    if (results.isEmpty) {
      return ChildrenInfo(familiesWithChildren: 0, totalChildren: 0);
    }

    final data = results.first;
    return ChildrenInfo(
      familiesWithChildren: data['familiesWithChildren'] as int? ?? 0,
      totalChildren: data['totalChildren'] as int? ?? 0,
    );
  }

  LongStaysSummary _parseLongStays(List<Map<String, Object?>> results) {
    if (results.isEmpty) {
      return LongStaysSummary(
        moreThan7Days: 0,
        moreThan14Days: 0,
        moreThan30Days: 0,
      );
    }

    final data = results.first;
    return LongStaysSummary(
      moreThan7Days: data['moreThan7Days'] as int? ?? 0,
      moreThan14Days: data['moreThan14Days'] as int? ?? 0,
      moreThan30Days: data['moreThan30Days'] as int? ?? 0,
    );
  }

  List<ProvinceCount> _parseProvinces(List<Map<String, Object?>> results) {
    return results
        .map(
          (row) => ProvinceCount(
            province: row['province'] as String? ?? 'ไม่ระบุ',
            count: row['count'] as int? ?? 0,
          ),
        )
        .toList();
  }

  List<DailyTrendPoint> _parseDailyTrend(List<Map<String, Object?>> results) {
    return results
        .map(
          (row) => DailyTrendPoint(
            date:
                DateTime.tryParse(row['date'] as String? ?? '') ??
                DateTime.now(),
            checkins: row['checkins'] as int? ?? 0,
          ),
        )
        .toList();
  }
}

// Data classes
class DailySummary {
  final DateTime date;
  final Map<String, int> activeStaysByGender;
  final Map<String, int> newRegistrationsByGender;
  final Map<String, int> checkoutsByGender;
  final EquipmentSummary equipmentSummary;
  final ChildrenInfo childrenInfo;

  DailySummary({
    required this.date,
    required this.activeStaysByGender,
    required this.newRegistrationsByGender,
    required this.checkoutsByGender,
    required this.equipmentSummary,
    required this.childrenInfo,
  });

  int get totalActiveStays =>
      activeStaysByGender.values.fold(0, (sum, count) => sum + count);
  int get totalNewRegistrations =>
      newRegistrationsByGender.values.fold(0, (sum, count) => sum + count);
  int get totalCheckouts =>
      checkoutsByGender.values.fold(0, (sum, count) => sum + count);
}

class PeriodSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalStays;
  final Map<String, int> staysByGender;
  final Map<String, int> newRegistrationsByGender;
  final double averageStayDuration;
  final LongStaysSummary longStaysSummary;
  final EquipmentSummary equipmentSummary;
  final List<ProvinceCount> topProvinces;
  final List<DailyTrendPoint> dailyTrend;

  PeriodSummary({
    required this.startDate,
    required this.endDate,
    required this.totalStays,
    required this.staysByGender,
    required this.newRegistrationsByGender,
    required this.averageStayDuration,
    required this.longStaysSummary,
    required this.equipmentSummary,
    required this.topProvinces,
    required this.dailyTrend,
  });

  // Helper methods สำหรับจำนวนรวม
  int get totalStaysByGender =>
      staysByGender.values.fold(0, (sum, count) => sum + count);
  int get totalNewRegistrations =>
      newRegistrationsByGender.values.fold(0, (sum, count) => sum + count);
}

class EquipmentSummary {
  final int totalShirts;
  final int totalPants;
  final int totalMats;
  final int totalPillows;
  final int totalBlankets;

  EquipmentSummary({
    required this.totalShirts,
    required this.totalPants,
    required this.totalMats,
    required this.totalPillows,
    required this.totalBlankets,
  });
}

class ChildrenInfo {
  final int familiesWithChildren;
  final int totalChildren;

  ChildrenInfo({
    required this.familiesWithChildren,
    required this.totalChildren,
  });
}

class LongStaysSummary {
  final int moreThan7Days;
  final int moreThan14Days;
  final int moreThan30Days;

  LongStaysSummary({
    required this.moreThan7Days,
    required this.moreThan14Days,
    required this.moreThan30Days,
  });
}

class ProvinceCount {
  final String province;
  final int count;

  ProvinceCount({required this.province, required this.count});
}

class DailyTrendPoint {
  final DateTime date;
  final int checkins;

  DailyTrendPoint({required this.date, required this.checkins});
}

class RepeatVisitorStats {
  final int totalVisitors;
  final int repeatVisitors;
  final double repeatRate;

  RepeatVisitorStats({
    required this.totalVisitors,
    required this.repeatVisitors,
    required this.repeatRate,
  });
}
