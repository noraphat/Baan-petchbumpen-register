import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reg_data.dart';
import '../services/menu_settings_service.dart';
import '../services/printer_service.dart';
import '../services/db_helper.dart';

/// Shared Registration Dialog extracted from Manual Form
/// This dialog is used by both Manual Form and ID Card registration flows
/// Contains fields for: เสื้อขาว, กางเกงขาว, เสื่อ, หมอน, ผ้าห่ม and other details
class SharedRegistrationDialog extends StatefulWidget {
  final String regId;
  final RegAdditionalInfo? existingInfo;
  final StayRecord? latestStay;
  final bool canCreateNew;
  final Function()? onCompleted;

  const SharedRegistrationDialog({
    super.key,
    required this.regId,
    this.existingInfo,
    this.latestStay,
    this.canCreateNew = true,
    this.onCompleted,
  });

  @override
  State<SharedRegistrationDialog> createState() => _SharedRegistrationDialogState();
}

class _SharedRegistrationDialogState extends State<SharedRegistrationDialog> {
  DateTime? startDate;
  DateTime? endDate;
  late final TextEditingController shirtCtrl;
  late final TextEditingController pantsCtrl;
  late final TextEditingController matCtrl;
  late final TextEditingController pillowCtrl;
  late final TextEditingController blanketCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController childrenCtrl;
  bool withChildren = false;

  @override
  void initState() {
    super.initState();

    // สร้าง controllers
    shirtCtrl = TextEditingController();
    pantsCtrl = TextEditingController();
    matCtrl = TextEditingController();
    pillowCtrl = TextEditingController();
    blanketCtrl = TextEditingController();
    locationCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    childrenCtrl = TextEditingController();

    // โหลดข้อมูลการเข้าพัก - อ่านจาก stays table เสมอ
    if (widget.latestStay != null && !widget.canCreateNew) {
      // กรณีแก้ไขการเข้าพักที่มีอยู่ - ใช้ข้อมูลจาก stays table
      final stay = widget.latestStay!;
      startDate = stay.startDate;
      endDate = stay.endDate;
      notesCtrl.text = stay.note ?? '';
    } else {
      // กรณีสร้างการเข้าพักใหม่ - ตั้งค่าเริ่มต้นเป็นวันเดียวกัน
      final today = DateTime.now();
      startDate = today;
      endDate = today; // เริ่มต้นเป็นวันเดียวกัน (1 วัน)
    }

    // โหลดข้อมูลอุปกรณ์ที่มีอยู่แล้ว
    if (widget.existingInfo != null) {
      final info = widget.existingInfo!;
      shirtCtrl.text = info.shirtCount?.toString() ?? '0';
      pantsCtrl.text = info.pantsCount?.toString() ?? '0';
      matCtrl.text = info.matCount?.toString() ?? '0';
      pillowCtrl.text = info.pillowCount?.toString() ?? '0';
      blanketCtrl.text = info.blanketCount?.toString() ?? '0';
      locationCtrl.text = info.location ?? '';
      withChildren = info.withChildren;
      childrenCtrl.text = info.childrenCount?.toString() ?? '0';

      // หมายเหตุ: ถ้าไม่มี stays record ให้ใช้จาก additional_info
      if (notesCtrl.text.isEmpty && info.notes?.isNotEmpty == true) {
        notesCtrl.text = info.notes!;
      }
    } else {
      // ตั้งค่าเริ่มต้น
      shirtCtrl.text = '0';
      pantsCtrl.text = '0';
      matCtrl.text = '0';
      pillowCtrl.text = '0';
      blanketCtrl.text = '0';
      childrenCtrl.text = '1'; // ค่าเริ่มต้นเป็น 1
    }
  }

  @override
  void dispose() {
    shirtCtrl.dispose();
    pantsCtrl.dispose();
    matCtrl.dispose();
    pillowCtrl.dispose();
    blanketCtrl.dispose();
    locationCtrl.dispose();
    notesCtrl.dispose();
    childrenCtrl.dispose();
    super.dispose();
  }

  void _updateNumberField(
    TextEditingController controller,
    int change, {
    int min = 0,
    int max = 9,
  }) {
    final currentValue = int.tryParse(controller.text) ?? min;
    final newValue = (currentValue + change).clamp(min, max);
    setState(() {
      controller.text = newValue.toString();
    });
  }

  // ตรวจสอบความถูกต้องของวันที่
  String? _validateDates() {
    if (startDate == null || endDate == null) {
      return 'กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDateOnly = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);

    // 1. วันที่เริ่มต้น ต้องไม่มากกว่าวันที่ปัจจุบัน
    if (startDateOnly.isAfter(today)) {
      return 'วันที่เริ่มต้นต้องไม่มากกว่าวันที่ปัจจุบัน';
    }

    // 2. วันที่เริ่มต้น ต้องไม่มากกว่าวันที่สิ้นสุด (สามารถเป็นวันเดียวกันได้)
    if (startDateOnly.isAfter(endDateOnly)) {
      return 'วันที่เริ่มต้นต้องไม่มากกว่าวันที่สิ้นสุด';
    }

    // 3. วันที่สิ้นสุด ต้องไม่น้อยกว่าวันที่ปัจจุบัน (ถ้าเป็นการสร้างใหม่หรือแก้ไข active stay)
    if (!widget.canCreateNew || (widget.latestStay?.isActive ?? false)) {
      if (endDateOnly.isBefore(today)) {
        return 'วันที่สิ้นสุดต้องไม่น้อยกว่าวันที่ปัจจุบัน';
      }
    }

    return null;
  }

  // ตรวจสอบว่าผู้ปฏิบัติธรรมมีการจองห้องหรือไม่
  Future<bool> _hasRoomBooking(String regId) async {
    try {
      final db = await DbHelper().db;

      final result = await db.query(
        'room_bookings',
        where: 'visitor_id = ? AND status != ?',
        whereArgs: [regId, 'cancelled'],
        orderBy: 'check_in_date DESC',
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking room booking: $e');
      return false;
    }
  }

  // ✅ ฟังก์ชันตรวจสอบว่าช่วงวันที่ใหม่ "ครอบคลุม" การจองห้องไว้ครบหรือไม่
  bool _isBookingOutsideNewStayRange({
    required DateTime bookingStart,
    required DateTime bookingEnd,
    required DateTime newStayStart,
    required DateTime newStayEnd,
  }) {
    // หากการจองเริ่มก่อนหรือสิ้นสุดหลังช่วงใหม่ → แสดงว่าช่วงใหม่ไม่ครอบคลุม
    debugPrint('📌 bookingStart: $bookingStart, bookingEnd: $bookingEnd');
    return bookingStart.isBefore(newStayStart) ||
        bookingEnd.isAfter(newStayEnd);
  }

  // ✅ ดึงช่วงวันที่ของการจองห้อง
  Future<DateTimeRange?> _getBookingDateRange(String regId) async {
    try {
      final db = await DbHelper().db;

      final result = await db.query(
        'room_bookings',
        where: 'visitor_id = ? AND status != ?',
        whereArgs: [regId, 'cancelled'],
        orderBy: 'check_in_date ASC',
      );

      if (result.isEmpty) return null;

      final start = result
          .map((b) => DateTime.parse(b['check_in_date'] as String))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final end = result
          .map((b) => DateTime.parse(b['check_out_date'] as String))
          .reduce((a, b) => a.isAfter(b) ? a : b);

      return DateTimeRange(start: start, end: end);
    } catch (e) {
      debugPrint('Error getting booking date range: $e');
      return null;
    }
  }

  // ✅ ตรวจสอบ validation เพิ่มเติมสำหรับการจองห้อง
  Future<String?> _validateDatesWithRoomBooking() async {
    // ตรวจสอบค่าพื้นฐานก่อน เช่น null หรือ start > end
    final basicValidation = _validateDates();
    if (basicValidation != null) {
      return basicValidation;
    }

    // ตรวจสอบเฉพาะกรณี "แก้ไขข้อมูลเดิม"
    if (!widget.canCreateNew && widget.regId.isNotEmpty) {
      final hasBooking = await _hasRoomBooking(widget.regId);

      if (hasBooking) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final newStart = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
        );
        final newEnd = DateTime(endDate!.year, endDate!.month, endDate!.day);

        // ❌ ห้ามแก้ไขวันที่เริ่มต้นย้อนหลังจากวันนี้
        if (newStart.isBefore(today)) {
          return 'ไม่สามารถแก้ไขวันที่เริ่มต้นย้อนหลังได้ เนื่องจากมีการจองห้องพักแล้ว';
        }

        // ✅ ตรวจสอบว่าช่วงวันที่ใหม่ "ครอบคลุม" ช่วงจองห้องไว้ทั้งหมด
        final bookingRange = await _getBookingDateRange(widget.regId);
        if (bookingRange != null) {
          final bookingStart = DateTime(
            bookingRange.start.year,
            bookingRange.start.month,
            bookingRange.start.day,
          );
          final bookingEnd = DateTime(
            bookingRange.end.year,
            bookingRange.end.month,
            bookingRange.end.day,
          );

          final isOutside = _isBookingOutsideNewStayRange(
            bookingStart: bookingStart,
            bookingEnd: bookingEnd,
            newStayStart: newStart,
            newStayEnd: newEnd,
          );

          if (isOutside) {
            return 'ไม่สามารถลดช่วงวันปฏิบัติธรรมให้ขัดกับช่วงวันที่จองห้องพักไว้ได้ กรุณาแก้ไขช่วงวันจองห้องพักก่อน';
          }
        }
      }
    }

    return null;
  }

  // บันทึกข้อมูล
  Future<void> _saveStayData() async {
    debugPrint('🔄 เริ่มบันทึกข้อมูลการเข้าพัก...');
    debugPrint('📅 วันที่เริ่มต้น: $startDate');
    debugPrint('📅 วันที่สิ้นสุด: $endDate');
    debugPrint('👤 RegId: ${widget.regId}');
    debugPrint('🆕 canCreateNew: ${widget.canCreateNew}');
    debugPrint('📝 latestStay: ${widget.latestStay?.id}');

    final dateValidation = await _validateDatesWithRoomBooking();
    if (dateValidation != null) {
      debugPrint('❌ Validation failed: $dateValidation');
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ข้อผิดพลาด',
                    style: TextStyle(color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Text(dateValidation, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      debugPrint('✅ Validation ผ่านแล้ว เริ่มบันทึกข้อมูล...');
      // บันทึกหรืออัพเดต Stay record
      StayRecord? stayRecordForPrint;
      if (widget.canCreateNew) {
        debugPrint('🆕 สร้าง Stay ใหม่...');
        // สร้าง Stay ใหม่
        final newStay = StayRecord.create(
          visitorId: widget.regId,
          startDate: startDate!,
          endDate: endDate!,
          note: notesCtrl.text.trim(),
        );
        debugPrint('📝 Stay record ที่จะบันทึก: ${newStay.toMap()}');
        final stayId = await DbHelper().insertStay(newStay);
        debugPrint('✅ บันทึก Stay สำเร็จ ID: $stayId');
        // สร้าง StayRecord ใหม่ที่มี ID ที่ได้จากฐานข้อมูล
        stayRecordForPrint = StayRecord(
          id: stayId,
          visitorId: newStay.visitorId,
          startDate: newStay.startDate,
          endDate: newStay.endDate,
          status: newStay.status,
          note: newStay.note,
          createdAt: newStay.createdAt,
        );
      } else if (widget.latestStay != null) {
        debugPrint('🔄 อัพเดต Stay ที่มีอยู่...');
        // อัพเดต Stay ที่มีอยู่
        final updatedStay = widget.latestStay!.copyWith(
          startDate: startDate,
          endDate: endDate,
          note: notesCtrl.text.trim(),
        );
        await DbHelper().updateStay(updatedStay);
        debugPrint('✅ อัพเดต Stay สำเร็จ');
        stayRecordForPrint = updatedStay;
      }

      // บันทึกข้อมูลอุปกรณ์แยกสำหรับแต่ละการมาปฏิบัติธรรม
      // สร้าง unique visitId โดยใช้ createdAt ของ stay record
      final visitId =
          '${widget.regId}_${stayRecordForPrint!.createdAt.millisecondsSinceEpoch}';
      debugPrint('🆔 สร้าง visitId: $visitId');

      final additionalInfo = RegAdditionalInfo.create(
        regId: widget.regId,
        visitId: visitId, // ใช้ unique visitId สำหรับครั้งนี้
        startDate: null, // ไม่เก็บในนี้แล้ว ให้อ่านจาก stays table
        endDate: null, // ไม่เก็บในนี้แล้ว ให้อ่านจาก stays table
        shirtCount: int.tryParse(shirtCtrl.text) ?? 0,
        pantsCount: int.tryParse(pantsCtrl.text) ?? 0,
        matCount: int.tryParse(matCtrl.text) ?? 0,
        pillowCount: int.tryParse(pillowCtrl.text) ?? 0,
        blanketCount: int.tryParse(blanketCtrl.text) ?? 0,
        location: locationCtrl.text.trim(),
        withChildren: withChildren,
        childrenCount: withChildren
            ? (int.tryParse(childrenCtrl.text) ?? 0)
            : null,
        notes: '', // หมายเหตุย้ายไป stays table แล้ว
      );

      debugPrint('📦 ข้อมูลอุปกรณ์ที่จะบันทึก: ${additionalInfo.toMap()}');
      await DbHelper().insertAdditionalInfo(additionalInfo);
      debugPrint('✅ บันทึกข้อมูลอุปกรณ์สำเร็จ');

      // ตรวจสอบสถานะเมนูเบิกชุดขาว
      final isWhiteRobeEnabled = await MenuSettingsService().isWhiteRobeEnabled;
      debugPrint('🖨️ เมนูเบิกชุดขาวเปิดอยู่: $isWhiteRobeEnabled');

      if (isWhiteRobeEnabled) {
        debugPrint('🖨️ เริ่มพิมพ์ใบเสร็จ...');
        // สร้าง QR Code จากข้อมูลการเข้าพัก และพิมพ์ใบเสร็จ
        final regData = await DbHelper().fetchById(widget.regId);
        if (regData != null) {
          await PrinterService().printReceipt(
            regData,
            additionalInfo: additionalInfo,
            stayRecord: stayRecordForPrint,
          );
          debugPrint('✅ พิมพ์ใบเสร็จสำเร็จ');
        } else {
          debugPrint('❌ ไม่พบข้อมูลผู้ลงทะเบียน');
        }
      } else {
        debugPrint('ℹ️ เมนูเบิกชุดขาวปิดอยู่ ไม่พิมพ์ใบเสร็จ');
      }

      debugPrint('✅ บันทึกข้อมูลเสร็จสิ้น ปิด dialog');
      if (mounted) {
        Navigator.of(context).pop();
        // เรียก callback ถ้ามี
        widget.onCompleted?.call();
      }
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Text(
              'ไม่สามารถบันทึกข้อมูลได้: $e',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // ปุ่มลดค่า (-)
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: onDecrease,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.remove, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Field แสดงตัวเลข
          Expanded(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              readOnly: true,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // ปุ่มเพิ่มค่า (+)
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: onIncrease,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.canCreateNew ? 'ลงทะเบียนเข้าพักใหม่' : 'แก้ไขข้อมูลการเข้าพัก',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // กำหนดความกว้าง
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0), // เพิ่ม padding รอบๆ
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // วันที่เริ่มต้น
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันที่เริ่มต้น',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startDate == null
                                    ? 'เลือกวันที่'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(startDate!),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // วันที่สิ้นสุด
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => endDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันที่สิ้นสุด',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endDate == null
                                    ? 'เลือกวันที่'
                                    : DateFormat('dd/MM/yyyy').format(endDate!),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ส่วนของอุปกรณ์
                _buildNumberField(
                  label: 'จำนวนเสื้อขาว',
                  controller: shirtCtrl,
                  onDecrease: () => _updateNumberField(shirtCtrl, -1),
                  onIncrease: () => _updateNumberField(shirtCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนกางเกงขาว',
                  controller: pantsCtrl,
                  onDecrease: () => _updateNumberField(pantsCtrl, -1),
                  onIncrease: () => _updateNumberField(pantsCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนเสื่อ',
                  controller: matCtrl,
                  onDecrease: () => _updateNumberField(matCtrl, -1),
                  onIncrease: () => _updateNumberField(matCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนหมอน',
                  controller: pillowCtrl,
                  onDecrease: () => _updateNumberField(pillowCtrl, -1),
                  onIncrease: () => _updateNumberField(pillowCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนผ้าห่ม',
                  controller: blanketCtrl,
                  onDecrease: () => _updateNumberField(blanketCtrl, -1),
                  onIncrease: () => _updateNumberField(blanketCtrl, 1),
                ),
                // ข้อมูลเพิ่มเติม
                const SizedBox(height: 8),
                TextFormField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ห้อง/ศาลา/สถานที่พัก',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: withChildren,
                      onChanged: (v) =>
                          setState(() => withChildren = v ?? false),
                    ),
                    const Text('มากับเด็ก'),
                  ],
                ),
                if (withChildren) ...[
                  const SizedBox(height: 8),
                  _buildNumberField(
                    label: 'จำนวนเด็ก',
                    controller: childrenCtrl,
                    onDecrease: () =>
                        _updateNumberField(childrenCtrl, -1, min: 1, max: 9),
                    onIncrease: () =>
                        _updateNumberField(childrenCtrl, 1, min: 1, max: 9),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุ',
                    hintText: 'โรคประจำตัว, ไม่ทานเนื้อสัตว์ ฯลฯ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saveStayData, child: const Text('บันทึก')),
        TextButton(
          onPressed: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}