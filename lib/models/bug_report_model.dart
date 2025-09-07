class BugReportModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String title;
  final String description;
  final String deviceInfo;
  final String appVersion;
  final String osVersion;
  final String? screenshotUrl;
  final BugReportStatus status;
  final BugReportPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminResponse;

  BugReportModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.title,
    required this.description,
    required this.deviceInfo,
    required this.appVersion,
    required this.osVersion,
    this.screenshotUrl,
    this.status = BugReportStatus.pending,
    this.priority = BugReportPriority.medium,
    required this.createdAt,
    required this.updatedAt,
    this.adminResponse,
  });

  factory BugReportModel.fromJson(Map<String, dynamic> json) {
    return BugReportModel(
      id: json['id'],
      userId: json['user_id'],
      userEmail: json['user_email'],
      userName: json['user_name'],
      title: json['title'],
      description: json['description'],
      deviceInfo: json['device_info'],
      appVersion: json['app_version'],
      osVersion: json['os_version'],
      screenshotUrl: json['screenshot_url'],
      status: BugReportStatus.fromString(json['status'] ?? 'pending'),
      priority: BugReportPriority.fromString(json['priority'] ?? 'medium'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      adminResponse: json['admin_response'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'title': title,
      'description': description,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'os_version': osVersion,
      'screenshot_url': screenshotUrl,
      'status': status.value,
      'priority': priority.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'admin_response': adminResponse,
    };
  }

  BugReportModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? title,
    String? description,
    String? deviceInfo,
    String? appVersion,
    String? osVersion,
    String? screenshotUrl,
    BugReportStatus? status,
    BugReportPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
  }) {
    return BugReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      description: description ?? this.description,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      osVersion: osVersion ?? this.osVersion,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
    );
  }
}

enum BugReportStatus {
  pending('pending', '対応待ち'),
  inProgress('in_progress', '対応中'),
  resolved('resolved', '解決済み'),
  closed('closed', 'クローズ');

  const BugReportStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static BugReportStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return BugReportStatus.pending;
      case 'in_progress':
        return BugReportStatus.inProgress;
      case 'resolved':
        return BugReportStatus.resolved;
      case 'closed':
        return BugReportStatus.closed;
      default:
        return BugReportStatus.pending;
    }
  }
}

enum BugReportPriority {
  low('low', '低'),
  medium('medium', '中'),
  high('high', '高'),
  critical('critical', '緊急');

  const BugReportPriority(this.value, this.displayName);

  final String value;
  final String displayName;

  static BugReportPriority fromString(String value) {
    switch (value) {
      case 'low':
        return BugReportPriority.low;
      case 'medium':
        return BugReportPriority.medium;
      case 'high':
        return BugReportPriority.high;
      case 'critical':
        return BugReportPriority.critical;
      default:
        return BugReportPriority.medium;
    }
  }
}
