class AppLimit {
  final String packageName;
  final String appName;
  final int limitMinutes;
  final int usedMinutes;
  final bool isBlocked;
  final String blockingMode; // 'shorts_reels' or 'all'
  final bool isCuriousMode;
  final int maxScrolls;
  final String actionType; // 'close_player', 'exit_app', 'lock_screen'

  AppLimit({
    required this.packageName,
    required this.appName,
    required this.limitMinutes,
    this.usedMinutes = 0,
    this.isBlocked = false,
    this.blockingMode = 'shorts_reels',
    this.isCuriousMode = false,
    this.maxScrolls = 3,
    this.actionType = 'close_player',
  });

  double get progress => limitMinutes > 0 ? (usedMinutes / limitMinutes).clamp(0.0, 1.0) : 0.0;

  AppLimit copyWith({
    String? packageName,
    String? appName,
    int? limitMinutes,
    int? usedMinutes,
    bool? isBlocked,
    String? blockingMode,
    bool? isCuriousMode,
    int? maxScrolls,
    String? actionType,
  }) {
    return AppLimit(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      isBlocked: isBlocked ?? this.isBlocked,
      blockingMode: blockingMode ?? this.blockingMode,
      isCuriousMode: isCuriousMode ?? this.isCuriousMode,
      maxScrolls: maxScrolls ?? this.maxScrolls,
      actionType: actionType ?? this.actionType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'limitMinutes': limitMinutes,
      'usedMinutes': usedMinutes,
      'isBlocked': isBlocked,
      'blockingMode': blockingMode,
      'isCuriousMode': isCuriousMode,
      'maxScrolls': maxScrolls,
      'actionType': actionType,
    };
  }

  factory AppLimit.fromJson(Map<String, dynamic> json) {
    return AppLimit(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      limitMinutes: json['limitMinutes'] as int,
      usedMinutes: json['usedMinutes'] as int? ?? 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockingMode: json['blockingMode'] as String? ?? 'shorts_reels',
      isCuriousMode: json['isCuriousMode'] as bool? ?? false,
      maxScrolls: json['maxScrolls'] as int? ?? 3,
      actionType: json['actionType'] as String? ?? 'close_player',
    );
  }
}
