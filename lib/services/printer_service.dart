import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import '../models/reg_data.dart';

class PrinterService {
  Future<void> printReceipt(RegData data, {RegAdditionalInfo? additionalInfo, StayRecord? stayRecord}) async {
    final bool bound = (await SunmiPrinter.bindingPrinter()) ?? false;
    if (!bound) return;

    await SunmiPrinter.initPrinter();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);

    // เว้นบรรทัดก่อนหัวกระดาษ
    await SunmiPrinter.lineWrap(1);

    // 🔶 หัวสลิป: แยกเป็น 2 บรรทัด
    await SunmiPrinter.printText(
      'สถานปฏิบัติธรรม',
      style: SunmiStyle(
        fontSize: SunmiFontSize.LG,
        bold: true,
        align: SunmiPrintAlign.CENTER,
      ),
    );
    await SunmiPrinter.printText(
      'บ้านเพชรบำเพ็ญ',
      style: SunmiStyle(
        fontSize: SunmiFontSize.LG,
        bold: true,
        align: SunmiPrintAlign.CENTER,
      ),
    );

    // 🔸 ข้อความขออนุโมทนาบุญ → font ขนาดเล็ก
    await SunmiPrinter.printText(
      'ขออนุโมทนาบุญในการเข้าปฏิบัติธรรม',
      style: SunmiStyle(
        fontSize: SunmiFontSize.SM,
        align: SunmiPrintAlign.CENTER,
      ),
    );

    await SunmiPrinter.line();

    // 🔷 เวลาทำรายการ (แทนเลขประจำตัว)
    final now = DateTime.now();
    final buddhistYear = now.year + 543;
    final formattedTime =
        '${DateFormat('dd/MM/').format(now)}$buddhistYear - ${DateFormat('HH:mm').format(now)}';

    await SunmiPrinter.printText(
      'เวลาทำรายการ: $formattedTime',
      style: SunmiStyle(
        fontSize: SunmiFontSize.SM, // ลดขนาด font จาก MD → SM
        align: SunmiPrintAlign.CENTER,
      ),
    );

    // 🔷 ชื่อ-นามสกุล
    await SunmiPrinter.printText(
      '${data.first} ${data.last}',
      style: SunmiStyle(
        fontSize: SunmiFontSize.MD,
        align: SunmiPrintAlign.CENTER,
      ),
    );

    // 🔷 ข้อมูลวันที่เข้าพัก (ถ้ามี)
    if (stayRecord != null) {
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      
      // แปลงวันที่เป็นรูปแบบภาษาไทย
      final startDateThai = _formatDateThai(stayRecord.startDate);
      final endDateThai = _formatDateThai(stayRecord.endDate);
      
      // คำนวณจำนวนวัน
      final daysDiff = stayRecord.endDate.difference(stayRecord.startDate).inDays + 1;
      
      if (stayRecord.startDate.day == stayRecord.endDate.day &&
          stayRecord.startDate.month == stayRecord.endDate.month &&
          stayRecord.startDate.year == stayRecord.endDate.year) {
        // กรณีเข้าพักวันเดียว
        await SunmiPrinter.printText(
          'วันที่เข้าพัก-วันที่สิ้นสุด: $startDateThai',
          style: SunmiStyle(
            fontSize: SunmiFontSize.SM,
            align: SunmiPrintAlign.CENTER,
          ),
        );
      } else {
        // กรณีเข้าพักหลายวัน
        await SunmiPrinter.printText(
          'วันที่เข้าพัก: $startDateThai',
          style: SunmiStyle(
            fontSize: SunmiFontSize.SM,
            align: SunmiPrintAlign.CENTER,
          ),
        );
        await SunmiPrinter.printText(
          'วันที่สิ้นสุด: $endDateThai',
          style: SunmiStyle(
            fontSize: SunmiFontSize.SM,
            align: SunmiPrintAlign.CENTER,
          ),
        );
      }
      
      await SunmiPrinter.printText(
        'จำนวนวันที่เข้าพัก: $daysDiff วัน',
        style: SunmiStyle(
          fontSize: SunmiFontSize.SM,
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ),
      );
    }

    // 🔷 รายการอุปกรณ์ที่รับ
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
    
    await SunmiPrinter.printText(
      'อุปกรณ์ที่รับ:',
      style: SunmiStyle(
        fontSize: SunmiFontSize.MD,
        bold: true,
        align: SunmiPrintAlign.LEFT,
      ),
    );
    
    // แสดงจำนวนอุปกรณ์จาก additionalInfo หรือใช้ค่าเริ่มต้น
    final shirtCount = additionalInfo?.shirtCount ?? 0;
    final pantsCount = additionalInfo?.pantsCount ?? 0;
    final matCount = additionalInfo?.matCount ?? 0;
    final pillowCount = additionalInfo?.pillowCount ?? 0;
    final blanketCount = additionalInfo?.blanketCount ?? 0;
    
    String equipmentList = '';
    if (shirtCount > 0) equipmentList += '• เสื้อ $shirtCount ตัว\n';
    if (pantsCount > 0) equipmentList += '• กางเกง $pantsCount ตัว\n';
    if (matCount > 0) equipmentList += '• เสื่อ $matCount ผืน\n';
    if (pillowCount > 0) equipmentList += '• หมอน $pillowCount ใบ\n';
    if (blanketCount > 0) equipmentList += '• ผ้าห่ม $blanketCount ผืน\n';
    
    // ถ้าไม่มีอุปกรณ์ใดเลย ให้แสดงรายการทั่วไป
    if (equipmentList.isEmpty) {
      equipmentList = '• เสื้อ\n• กางเกง\n• เสื่อ\n• หมอน\n• ผ้าห่ม';
    } else {
      // ลบ \n ตัวสุดท้าย
      equipmentList = equipmentList.trim();
    }
    
    await SunmiPrinter.printText(
      equipmentList,
      style: SunmiStyle(
        fontSize: SunmiFontSize.SM,
        align: SunmiPrintAlign.LEFT,
      ),
    );
    
    // QR Code
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printQRCode(
      data.id,
      size: 7,
    );
    
    await SunmiPrinter.lineWrap(2);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);

    // 🔷 ข้อความขอรับชุดขาว
    await SunmiPrinter.printText(
      'โปรดแสดง QR นี้เพื่อรับชุดขาว',
      style: SunmiStyle(
        fontSize: SunmiFontSize.MD,
        bold: true,
        align: SunmiPrintAlign.CENTER,
      ),
    );

    // 🔚 จบบรรทัดท้าย
    await SunmiPrinter.lineWrap(4);
    await SunmiPrinter.unbindingPrinter();
  }

  // ฟังก์ชันแปลงวันที่เป็นภาษาไทย
  String _formatDateThai(DateTime date) {
    const List<String> thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    
    final buddhistYear = date.year + 543;
    final monthName = thaiMonths[date.month - 1];
    
    return '${date.day} $monthName $buddhistYear';
  }
}
