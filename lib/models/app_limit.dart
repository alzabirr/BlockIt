class AppLimit {
  final String packageName;
  final String appName;
  final int limitMinutes;
  final int usedMinutes;
  final bool isBlocked;

  AppLimit({
    required this.packageName,
    required this.appName,
    required this.limitMinutes,
    this.usedMinutes = 0,
    this.isBlocked = false,
  });

  double get progress => limitMinutes > 0 ? (usedMinutes / limitMinutes).clamp(0.0, 1.0) : 0.0;

  AppLimit copyWith({
    String? packageName,
    String? appName,
    int? limitMinutes,
    int? usedMinutes,
    bool? isBlocked,
  }) {
    return AppLimit(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'limitMinutes': limitMinutes,
      'usedMinutes': usedMinutes,
      'isBlocked': isBlocked,
    };
  }

  factory AppLimit.fromJson(Map<String, dynamic> json) {
    return AppLimit(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      limitMinutes: json['limitMinutes'] as int,
      usedMinutes: json['usedMinutes'] as int? ?? 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }
}
