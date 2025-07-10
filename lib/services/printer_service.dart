import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import '../models/reg_data.dart';

class PrinterService {
  Future<void> printReceipt(RegData data) async {
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

    // 🔷 QR Code (ใช้ ID)
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printQRCode(
      data.id,
      size: 8,
    );
    await SunmiPrinter.lineWrap(1);

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
}
