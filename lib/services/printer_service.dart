import 'package:flutter/material.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import '../models/reg_data.dart';

class PrinterService {
  final BuildContext ctx;
  PrinterService(this.ctx);

  Future<void> printReceipt(RegData data) async {
    final bool bound = (await SunmiPrinter.bindingPrinter()) ?? false;
    if (!bound) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Print simulated (no Sunmi device)')),
      );
      return;
    }

    // ... (โค้ดพิมพ์ใบเสร็จเหมือนเดิม) ...
  }
}
