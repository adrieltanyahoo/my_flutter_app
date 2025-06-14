import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 0)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime start;

  @HiveField(3)
  final DateTime end;

  @HiveField(4)
  final String color;

  @HiveField(5)
  final bool isAllDay;

  @HiveField(6)
  final String? location;

  @HiveField(7)
  final String? description;

  @HiveField(8)
  final bool isVideoCall;

  @HiveField(9)
  final List<String> participants;

  @HiveField(10)
  final String? teamName;

  @HiveField(11)
  final EventType eventType;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    this.isAllDay = false,
    this.location,
    this.description,
    this.isVideoCall = false,
    this.participants = const [],
    this.teamName,
    this.eventType = EventType.meeting,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      color: json['color'],
      isAllDay: json['isAllDay'] ?? false,
      location: json['location'],
      description: json['description'],
      isVideoCall: json['isVideoCall'] ?? false,
      participants: List<String>.from(json['participants'] ?? []),
      teamName: json['teamName'],
      eventType: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['eventType'],
        orElse: () => EventType.meeting,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'color': color,
      'isAllDay': isAllDay,
      'location': location,
      'description': description,
      'isVideoCall': isVideoCall,
      'participants': participants,
      'teamName': teamName,
      'eventType': eventType.toString().split('.').last,
    };
  }

  Duration get duration => end.difference(start);

  bool get isToday {
    final now = DateTime.now();
    return start.day == now.day &&
        start.month == now.month &&
        start.year == now.year;
  }

  bool overlapsWithHour(int hour) {
    final hourStart = DateTime(start.year, start.month, start.day, hour);
    final hourEnd = hourStart.add(const Duration(hours: 1));
    
    return start.isBefore(hourEnd) && end.isAfter(hourStart);
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    String? color,
    bool? isAllDay,
    String? location,
    String? description,
    bool? isVideoCall,
    List<String>? participants,
    String? teamName,
    EventType? eventType,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      description: description ?? this.description,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      participants: participants ?? this.participants,
      teamName: teamName ?? this.teamName,
      eventType: eventType ?? this.eventType,
    );
  }
}

@HiveType(typeId: 1)
enum EventType {
  @HiveField(0)
  meeting,
  @HiveField(1)
  task,
}

@HiveType(typeId: 2)
enum ViewType {
  @HiveField(0)
  day,
  @HiveField(1)
  month,
  @HiveField(2)
  year,
} 