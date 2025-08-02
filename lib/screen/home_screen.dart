import 'package:flutter/material.dart';
import 'package:flutter_petchbumpen_register/screen/white_robe_scaner.dart';
import 'registration/registration_menu.dart';
import '../services/menu_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'admin_settings.dart';
import 'daily_summary.dart';
import 'visitor_management.dart';
import 'about_page.dart';
import 'schedule_screen.dart';
import 'accommodation_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Secret Developer Mode variables
  int _logoTapCount = 0;
  Timer? _tapTimer;
  
  // Menu visibility states
  bool _whiteRobeEnabled = false;
  bool _bookingEnabled = true;  // เปิดเมนูจองที่พักให้แสดง
  bool _scheduleEnabled = true;
  bool _summaryEnabled = true;


  // Secret Developer Mode activation
  void _onLogoTap() {
    _logoTapCount++;
    
    // Reset timer if it exists
    _tapTimer?.cancel();
    
    // Start new timer - reset count after 5 seconds
    _tapTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _logoTapCount = 0;
        });
      }
    });
    
    // Check if reached 12 taps
    if (_logoTapCount >= 12) {
      _activateSecretMode();
    }
  }

  void _activateSecretMode() {
    _logoTapCount = 0; // Reset counter
    _tapTimer?.cancel();
    
    // Show toast message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Secret Developer Mode unlocked!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Navigate to Admin Settings after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _navigateToAdminSettings();
      }
    });
  }

  void _navigateToAdminSettings() async {
    // Navigate to Admin Settings screen
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminSettings()),
    );
    
    // Refresh menu settings when returning from Admin Settings
    _loadMenuSettings();
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _loadMenuSettings();
  }
  
  Future<void> _loadMenuSettings() async {
    final menuService = MenuSettingsService();
    final whiteRobeEnabled = await menuService.isWhiteRobeEnabled;
    final bookingEnabled = await menuService.isBookingEnabled;
    final scheduleEnabled = await menuService.isScheduleEnabled;
    final summaryEnabled = await menuService.isSummaryEnabled;
    
    debugPrint('Loading menu settings:');
    debugPrint('White Robe: $whiteRobeEnabled');
    debugPrint('Booking: $bookingEnabled');
    debugPrint('Schedule: $scheduleEnabled');
    debugPrint('Summary: $summaryEnabled');
    
    setState(() {
      _whiteRobeEnabled = whiteRobeEnabled;
      _bookingEnabled = bookingEnabled;
      _scheduleEnabled = scheduleEnabled;
      _summaryEnabled = summaryEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build menu items based on visibility settings
    final List<Map<String, dynamic>> allItems = [
      {
        'label': 'ลงทะเบียน',
        'icon': Icons.app_registration,
        'enabled': true, // Always enabled
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationMenu()),
        ),
      },
      {
        'label': 'ข้อมูลผู้ปฏิบัติธรรม',
        'icon': Icons.people_outline,
        'enabled': true, // Always enabled
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VisitorManagementScreen()),
        ),
      },
      {
        'label': 'เบิกชุดขาว',
        'icon': Icons.checkroom,
        'enabled': _whiteRobeEnabled,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WhiteRobeScanner()),
        ),
      },
      {
        'label': 'จองที่พัก',
        'icon': Icons.bed_outlined,
        'enabled': _bookingEnabled,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccommodationBookingScreen()),
        ),
      },
      {
        'label': 'ตารางกิจกรรม',
        'icon': Icons.event_note,
        'enabled': _scheduleEnabled,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        ),
      },
      {
        'label': 'สรุปผลประจำวัน',
        'icon': Icons.bar_chart,
        'enabled': _summaryEnabled,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailySummaryScreen()),
        ),
      },
    ];
    
    // Filter items to only show enabled ones
    final items = allItems.where((item) => item['enabled'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7), // สีพื้นหลังอ่อน
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onLogoTap,
          child: Row(
            children: [
              Icon(
                Icons.spa,
                color: Colors.purple,
                size: 32,
              ), // โลโก้เดิม
              const SizedBox(width: 8),
              const Text(
                'บ้านเพชรบำเพ็ญ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
              // Show tap count for debugging in debug mode
              if (kDebugMode && _logoTapCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_logoTapCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid based on screen width
                  final screenWidth = constraints.maxWidth;
                  final crossAxisCount = screenWidth < 600 ? 2 : 3;
                  final childAspectRatio = screenWidth < 400 ? 0.9 : 1.1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                    shrinkWrap: true,
                children: items.map((item) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: item['onTap'] as void Function(),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: screenWidth < 400 ? 32 : 40,
                              color: Colors.purple,
                            ),
                            SizedBox(height: screenWidth < 400 ? 8 : 12),
                            Flexible(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth < 400 ? 13 : 16,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
