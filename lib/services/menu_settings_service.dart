import 'db_helper.dart';

class MenuSettingsService {
  static final MenuSettingsService _instance = MenuSettingsService._internal();
  factory MenuSettingsService() => _instance;
  MenuSettingsService._internal();

  // Keys for database settings
  static const String _whiteRobeEnabledKey = 'menu_white_robe_enabled';
  static const String _bookingEnabledKey = 'menu_booking_enabled';
  static const String _scheduleEnabledKey = 'menu_schedule_enabled';
  static const String _summaryEnabledKey = 'menu_summary_enabled';
  static const String _debugRoomMenuEnabledKey = 'menu_debug_room_enabled';

  // Menu visibility getters
  Future<bool> get isWhiteRobeEnabled async {
    final dbHelper = DbHelper();
    return await dbHelper.getBoolSetting(_whiteRobeEnabledKey, defaultValue: false);
  }

  Future<bool> get isBookingEnabled async {
    final dbHelper = DbHelper();
    return await dbHelper.getBoolSetting(_bookingEnabledKey, defaultValue: false);
  }

  Future<bool> get isScheduleEnabled async {
    final dbHelper = DbHelper();
    return await dbHelper.getBoolSetting(_scheduleEnabledKey, defaultValue: true);
  }

  Future<bool> get isSummaryEnabled async {
    final dbHelper = DbHelper();
    return await dbHelper.getBoolSetting(_summaryEnabledKey, defaultValue: true);
  }

  Future<bool> get isDebugRoomMenuEnabled async {
    final dbHelper = DbHelper();
    return await dbHelper.getBoolSetting(_debugRoomMenuEnabledKey, defaultValue: false);
  }

  // Menu visibility setters
  Future<void> setWhiteRobeEnabled(bool enabled) async {
    final dbHelper = DbHelper();
    await dbHelper.setBoolSetting(_whiteRobeEnabledKey, enabled);
  }

  Future<void> setBookingEnabled(bool enabled) async {
    final dbHelper = DbHelper();
    await dbHelper.setBoolSetting(_bookingEnabledKey, enabled);
  }

  Future<void> setScheduleEnabled(bool enabled) async {
    final dbHelper = DbHelper();
    await dbHelper.setBoolSetting(_scheduleEnabledKey, enabled);
  }

  Future<void> setSummaryEnabled(bool enabled) async {
    final dbHelper = DbHelper();
    await dbHelper.setBoolSetting(_summaryEnabledKey, enabled);
  }

  Future<void> setDebugRoomMenuEnabled(bool enabled) async {
    final dbHelper = DbHelper();
    await dbHelper.setBoolSetting(_debugRoomMenuEnabledKey, enabled);
  }

  // Get all menu settings at once
  Future<Map<String, bool>> getAllMenuSettings() async {
    final dbHelper = DbHelper();
    return await dbHelper.getAllMenuSettings();
  }

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    final dbHelper = DbHelper();
    await dbHelper.setBoolSetting(_whiteRobeEnabledKey, false);
    await dbHelper.setBoolSetting(_bookingEnabledKey, false);
    await dbHelper.setBoolSetting(_scheduleEnabledKey, true);
    await dbHelper.setBoolSetting(_summaryEnabledKey, true);
    await dbHelper.setBoolSetting(_debugRoomMenuEnabledKey, false);
  }
}