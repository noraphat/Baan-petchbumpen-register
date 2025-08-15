import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ← ต้อง import
import 'package:flutter_petchbumpen_register/screen/home_screen.dart';
import 'package:flutter_petchbumpen_register/services/backup_scheduler_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null); // โหลด pattern ไทย

  // Initialize backup scheduler for auto backup functionality
  try {
    await BackupSchedulerService.instance.initialize();
    print('✅ Backup scheduler initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize backup scheduler: $e');
    // Continue app startup even if backup scheduler fails
  }

  // ล้างข้อมูลฐานข้อมูลใน Debug Mode (ปิดการใช้งานแล้ว)
  // if (const bool.fromEnvironment('dart.vm.product') == false) {
  //   try {
  //     await DbHelper().clearAllData();
  //     print('🗑️ Debug Mode: ล้างข้อมูลฐานข้อมูลเรียบร้อยแล้ว');
  //   } catch (e) {
  //     print('❌ Debug Mode: ไม่สามารถล้างข้อมูลฐานข้อมูลได้: $e');
  //   }
  // }

  runApp(const DhammaReg());
}

class DhammaReg extends StatefulWidget {
  const DhammaReg({super.key});

  @override
  State<DhammaReg> createState() => _DhammaRegState();
}

class _DhammaRegState extends State<DhammaReg> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // แอปกลับมาจาก background
        BackupSchedulerService.instance.onAppResumed();
        break;
      case AppLifecycleState.paused:
        // แอปจะไป background
        BackupSchedulerService.instance.onAppPaused();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // ไม่ต้องทำอะไร
        break;
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'DhammaReg',

    // ───────── 1) เพิ่ม delegates & locales ─────────
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [
      Locale('th', 'TH'), // ไทย
      Locale('en', 'US'), // สำรองอังกฤษ
    ],

    // ───────── 2) ธีมหลัก ─────────
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.purple, // เปลี่ยนเป็นสีม่วง
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ), // เปลี่ยนเป็นสีม่วง
      ),
    ),

    home: const HomeScreen(),
  );
}
