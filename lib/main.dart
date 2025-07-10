import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';  // ← ต้อง import
import 'package:flutter_petchbumpen_register/screen/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);     // โหลด pattern ไทย
  runApp(const DhammaReg());
}

class DhammaReg extends StatelessWidget {
  const DhammaReg({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DhammaReg',

        // ───────── 1) เพิ่ม delegates & locales ─────────
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('th', 'TH'),         // ไทย
          Locale('en', 'US'),         // สำรองอังกฤษ
        ],

        // ───────── 2) ธีมหลัก ─────────
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
          ),
        ),

        home: const HomeScreen(),
      );
}
