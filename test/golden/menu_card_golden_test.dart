import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_petchbumpen_register/widgets/menu_card.dart';

void main() {
  group('MenuCard Golden Tests', () {
    testGoldens('should render menu card with different states', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
        ..addScenario(
          widget: const MenuCard(
            title: 'ลงทะเบียน',
            icon: Icons.person_add,
            color: Colors.blue,
            onTap: null,
          ),
          name: 'registration_card',
        )
        ..addScenario(
          widget: const MenuCard(
            title: 'เบิกชุดขาว',
            icon: Icons.qr_code_scanner,
            color: Colors.orange,
            onTap: null,
          ),
          name: 'white_robe_card',
        )
        ..addScenario(
          widget: const MenuCard(
            title: 'สรุปผลประจำวัน',
            icon: Icons.summarize,
            color: Colors.green,
            onTap: null,
          ),
          name: 'daily_summary_card',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'menu_card_variants');
    });

    testGoldens('should render menu card with long title', (tester) async {
      await tester.pumpWidgetBuilder(
        const MenuCard(
          title: 'ลงทะเบียนผู้มาปฏิบัติธรรมและจัดการข้อมูลส่วนตัว',
          icon: Icons.person_add_outlined,
          color: Colors.purple,
          onTap: null,
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
        surfaceSize: const Size(300, 200),
      );
      await screenMatchesGolden(tester, 'menu_card_long_title');
    });

    testGoldens('should render menu card in dark theme', (tester) async {
      await tester.pumpWidgetBuilder(
        const MenuCard(
          title: 'ตารางกิจกรรม',
          icon: Icons.schedule,
          color: Colors.teal,
          onTap: null,
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.dark(),
        ),
      );
      await screenMatchesGolden(tester, 'menu_card_dark_theme');
    });

    testGoldens('should render disabled menu card', (tester) async {
      await tester.pumpWidgetBuilder(
        MenuCard(
          title: 'ปิดการใช้งาน',
          icon: Icons.block,
          color: Colors.grey.shade400,
          onTap: null, // Disabled state
        ),
        wrapper: materialAppWrapper(),
      );
      await screenMatchesGolden(tester, 'menu_card_disabled');
    });

    testGoldens('should render menu cards in grid layout', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: Scaffold(
            backgroundColor: Colors.grey.shade100,
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  MenuCard(
                    title: 'ลงทะเบียน',
                    icon: Icons.person_add,
                    color: Colors.blue,
                    onTap: null,
                  ),
                  MenuCard(
                    title: 'เบิกชุดขาว',
                    icon: Icons.qr_code_scanner,
                    color: Colors.orange,
                    onTap: null,
                  ),
                  MenuCard(
                    title: 'จองที่พัก',
                    icon: Icons.bed,
                    color: Colors.purple,
                    onTap: null,
                  ),
                  MenuCard(
                    title: 'สรุปผลประจำวัน',
                    icon: Icons.summarize,
                    color: Colors.green,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ),
          name: 'menu_grid_layout',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'menu_card_grid_layout');
    });
  });
}