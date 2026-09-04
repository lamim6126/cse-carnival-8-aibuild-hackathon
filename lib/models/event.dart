class RegistrationItem {
  String studentId;
  String name;

  RegistrationItem({required this.studentId, required this.name});

  factory RegistrationItem.fromJson(Map<String, dynamic> json) => RegistrationItem(
    studentId: json['student_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'name': name,
  };
}

class EventItem {
  String id;
  String name;
  String description;
  String date;
  String startTime;
  String endTime;
  String endDate;
  String venue;
  String organizer;
  int capacity;
  int registered;
  List<RegistrationItem> registrations;
  String status; // "upcoming" | "ongoing" | "completed" | "cancelled" | "full"

  EventItem({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.endDate,
    required this.venue,
    required this.organizer,
    required this.capacity,
    required this.registered,
    required this.registrations,
    required this.status,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) => EventItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    startTime: json['start_time']?.toString() ?? '',
    endTime: json['end_time']?.toString() ?? '',
    endDate: json['end_date']?.toString() ?? json['date']?.toString() ?? '',
    venue: json['venue']?.toString() ?? '',
    organizer: json['organizer']?.toString() ?? '',
    capacity: (json['capacity'] is num)
        ? (json['capacity'] as num).toInt()
        : int.tryParse(json['capacity'].toString()) ?? 0,
    registered: (json['registered'] is num)
        ? (json['registered'] as num).toInt()
        : int.tryParse(json['registered'].toString()) ?? 0,
    registrations: (json['registrations'] as List<dynamic>?)
            ?.map((e) => RegistrationItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    status: json['status']?.toString() ?? 'upcoming',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'end_date': endDate,
    'venue': venue,
    'organizer': organizer,
    'capacity': capacity,
    'registered': registered,
    'registrations': registrations.map((r) => r.toJson()).toList(),
    'status': status,
  };

  EventItem copyWith({
    String? id,
    String? name,
    String? description,
    String? date,
    String? startTime,
    String? endTime,
    String? endDate,
    String? venue,
    String? organizer,
    int? capacity,
    int? registered,
    List<RegistrationItem>? registrations,
    String? status,
  }) {
    return EventItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      organizer: organizer ?? this.organizer,
      capacity: capacity ?? this.capacity,
      registered: registered ?? this.registered,
      registrations: registrations ?? this.registrations,
      status: status ?? this.status,
    );
  }
}
