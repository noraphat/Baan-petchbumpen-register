import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

class WhiteRobeScanner extends StatelessWidget {
  const WhiteRobeScanner({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('สแกน QR ใบเสร็จ')),
        body: Stack(
  children: [
    MobileScanner(
      onDetect: (capture) {
        final code = capture.barcodes.first.rawValue ?? '';
        _handlePayload(context, code);
      },
    ),
    // ----- กรอบนำทาง -----
    IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal, width: 4),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  ],
),

      );

  void _handlePayload(BuildContext ctx, String payload) {
    final idRegex = RegExp(r'^\d{1}\s?\d{4}\s?\d{5}\s?\d{2}\s?\d{1}$');
    if (idRegex.hasMatch(payload)) {
      showDialog(context: ctx, builder: (_) => const _Success());
    } else {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('QR ไม่ถูกต้อง')));
    }
  }
}

class _Success extends StatelessWidget {
  const _Success();
  @override
  Widget build(BuildContext context) => AlertDialog(
        content: const Text('✅ ตรวจสอบสำเร็จ รับชุดขาวได้เลย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      );
}
