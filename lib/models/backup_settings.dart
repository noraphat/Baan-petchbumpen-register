/// Data model for backup system settings
class BackupSettings {
  final bool autoBackupEnabled;
  final DateTime? lastBackupTime;
  final int maxBackupDays;
  final String backupDirectory;
  
  const BackupSettings({
    required this.autoBackupEnabled,
    this.lastBackupTime,
    this.maxBackupDays = 31,
    required this.backupDirectory,
  });
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'autoBackupEnabled': autoBackupEnabled,
      'lastBackupTime': lastBackupTime?.toIso8601String(),
      'maxBackupDays': maxBackupDays,
      'backupDirectory': backupDirectory,
    };
  }
  
  /// Create from JSON
  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      autoBackupEnabled: json['autoBackupEnabled'] as bool,
      lastBackupTime: json['lastBackupTime'] != null 
          ? DateTime.parse(json['lastBackupTime'] as String)
          : null,
      maxBackupDays: json['maxBackupDays'] as int? ?? 31,
      backupDirectory: json['backupDirectory'] as String,
    );
  }
  
  /// Create a copy with updated values
  BackupSettings copyWith({
    bool? autoBackupEnabled,
    DateTime? lastBackupTime,
    int? maxBackupDays,
    String? backupDirectory,
  }) {
    return BackupSettings(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      maxBackupDays: maxBackupDays ?? this.maxBackupDays,
      backupDirectory: backupDirectory ?? this.backupDirectory,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupSettings &&
        other.autoBackupEnabled == autoBackupEnabled &&
        other.lastBackupTime == lastBackupTime &&
        other.maxBackupDays == maxBackupDays &&
        other.backupDirectory == backupDirectory;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      autoBackupEnabled,
      lastBackupTime,
      maxBackupDays,
      backupDirectory,
    );
  }
  
  @override
  String toString() {
    return 'BackupSettings(autoBackupEnabled: $autoBackupEnabled, '
           'lastBackupTime: $lastBackupTime, maxBackupDays: $maxBackupDays, '
           'backupDirectory: $backupDirectory)';
  }
}