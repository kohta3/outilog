class ScheduleModel {
  final String? id; // Firestore用のIDフィールドを追加
  final String title;
  final bool isAllDay;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? memo;
  final String? color;
  final bool fiveMinutesBefore;
  final bool tenMinutesBefore;
  final bool thirtyMinutesBefore;
  final bool oneHourBefore;
  final bool threeHoursBefore;
  final bool sixHoursBefore;
  final bool twelveHoursBefore;
  final bool oneDayBefore;
  final Map<String, bool> participationList;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  ScheduleModel({
    this.id, // IDフィールドを追加
    required this.title,
    required this.isAllDay,
    required this.startDateTime,
    required this.endDateTime,
    this.memo,
    this.color,
    required this.fiveMinutesBefore,
    required this.tenMinutesBefore,
    required this.thirtyMinutesBefore,
    required this.oneHourBefore,
    required this.threeHoursBefore,
    required this.sixHoursBefore,
    required this.twelveHoursBefore,
    required this.oneDayBefore,
    required this.participationList,
    this.createdAt,
    this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      title: json['title'],
      isAllDay: json['isAllDay'],
      startDateTime: json['startDateTime'].toDate(),
      endDateTime: json['endDateTime'].toDate(),
      memo: json['memo'],
      color: json['color'],
      fiveMinutesBefore: json['fiveMinutesBefore'],
      tenMinutesBefore: json['tenMinutesBefore'],
      thirtyMinutesBefore: json['thirtyMinutesBefore'],
      oneHourBefore: json['oneHourBefore'],
      threeHoursBefore: json['threeHoursBefore'],
      sixHoursBefore: json['sixHoursBefore'],
      twelveHoursBefore: json['twelveHoursBefore'],
      oneDayBefore: json['oneDayBefore'],
      participationList: Map<String, bool>.from(json['participationList']),
      createdAt: json['createdAt'].toDate(),
      updatedAt: json['updatedAt'].toDate(),
    );
  }

  // Firestore形式からScheduleModelを作成
  factory ScheduleModel.fromFirestore(Map<String, dynamic> data) {
    return ScheduleModel(
      id: data['id'],
      title: data['title'] ?? '',
      isAllDay: data['is_all_day'] ?? false,
      startDateTime: (data['start_time'] as dynamic).toDate(),
      endDateTime: (data['end_time'] as dynamic).toDate(),
      memo: data['description'] ?? '',
      fiveMinutesBefore: false,
      tenMinutesBefore: false,
      thirtyMinutesBefore: false,
      oneHourBefore: false,
      threeHoursBefore: false,
      sixHoursBefore: false,
      twelveHoursBefore: false,
      oneDayBefore: false,
      participationList: {},
      createdAt: (data['created_at'] as dynamic)?.toDate(),
      updatedAt: (data['updated_at'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isAllDay': isAllDay,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'memo': memo,
      'color': color,
      'fiveMinutesBefore': fiveMinutesBefore,
      'tenMinutesBefore': tenMinutesBefore,
      'thirtyMinutesBefore': thirtyMinutesBefore,
      'oneHourBefore': oneHourBefore,
      'threeHoursBefore': threeHoursBefore,
      'sixHoursBefore': sixHoursBefore,
      'twelveHoursBefore': twelveHoursBefore,
      'oneDayBefore': oneDayBefore,
      'participationList': participationList,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }
}
