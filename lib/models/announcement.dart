class AnnouncementItem {
  String id;
  String title;
  String body;
  String date;
  String priority; // "high" | "medium" | "low"
  String postedBy;
  String expires;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.priority,
    required this.postedBy,
    required this.expires,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) => AnnouncementItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    priority: json['priority']?.toString() ?? 'medium',
    postedBy: json['posted_by']?.toString() ?? '',
    expires: json['expires']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'date': date,
    'priority': priority,
    'posted_by': postedBy,
    'expires': expires,
  };

  AnnouncementItem copyWith({
    String? id,
    String? title,
    String? body,
    String? date,
    String? priority,
    String? postedBy,
    String? expires,
  }) {
    return AnnouncementItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      postedBy: postedBy ?? this.postedBy,
      expires: expires ?? this.expires,
    );
  }
}
