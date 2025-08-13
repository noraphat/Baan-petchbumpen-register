/// Enum for backup file types
enum BackupType { json, sql }

/// Data model for backup file information
class BackupInfo {
  final String fileName;
  final DateTime createdAt;
  final int fileSize;
  final BackupType type;
  final bool isValid;
  
  const BackupInfo({
    required this.fileName,
    required this.createdAt,
    required this.fileSize,
    required this.type,
    required this.isValid,
  });
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
      'fileSize': fileSize,
      'type': type.name,
      'isValid': isValid,
    };
  }
  
  /// Create from JSON
  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      fileName: json['fileName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fileSize: json['fileSize'] as int,
      type: BackupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackupType.json,
      ),
      isValid: json['isValid'] as bool,
    );
  }
  
  /// Create a copy with updated values
  BackupInfo copyWith({
    String? fileName,
    DateTime? createdAt,
    int? fileSize,
    BackupType? type,
    bool? isValid,
  }) {
    return BackupInfo(
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      type: type ?? this.type,
      isValid: isValid ?? this.isValid,
    );
  }
  
  /// Get file extension based on type
  String get fileExtension {
    switch (type) {
      case BackupType.json:
        return '.json';
      case BackupType.sql:
        return '.sql';
    }
  }
  
  /// Get human readable file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupInfo &&
        other.fileName == fileName &&
        other.createdAt == createdAt &&
        other.fileSize == fileSize &&
        other.type == type &&
        other.isValid == isValid;
  }
  
  @override
  int get hashCode {
    return Object.hash(fileName, createdAt, fileSize, type, isValid);
  }
  
  @override
  String toString() {
    return 'BackupInfo(fileName: $fileName, createdAt: $createdAt, '
           'fileSize: $fileSize, type: $type, isValid: $isValid)';
  }
}