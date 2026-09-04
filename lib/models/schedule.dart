class ScheduleItem {
  String id;
  String course;
  String title;
  String day;
  String startTime;
  String endTime;
  String room;
  String instructor;
  String section;

  ScheduleItem({
    required this.id,
    required this.course,
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.instructor,
    required this.section,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    id: json['id']?.toString() ?? '',
    course: json['course']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    day: json['day']?.toString() ?? '',
    startTime: json['start_time']?.toString() ?? '',
    endTime: json['end_time']?.toString() ?? '',
    room: json['room']?.toString() ?? '',
    instructor: json['instructor']?.toString() ?? 'TBA',
    section: json['section']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'course': course,
    'title': title,
    'day': day,
    'start_time': startTime,
    'end_time': endTime,
    'room': room,
    'instructor': instructor,
    'section': section,
  };

  ScheduleItem copyWith({
    String? id,
    String? course,
    String? title,
    String? day,
    String? startTime,
    String? endTime,
    String? room,
    String? instructor,
    String? section,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      course: course ?? this.course,
      title: title ?? this.title,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      section: section ?? this.section,
    );
  }
}
