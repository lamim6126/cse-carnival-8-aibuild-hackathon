class AssignmentItem {
  String id;
  String course;
  String courseTitle;
  String title;
  String description;
  String assignedDate;
  String deadline;
  String status; // "pending" | "submitted" | "graded" | "late"

  AssignmentItem({
    required this.id,
    required this.course,
    required this.courseTitle,
    required this.title,
    required this.description,
    required this.assignedDate,
    required this.deadline,
    required this.status,
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> json) => AssignmentItem(
    id: json['id']?.toString() ?? '',
    course: json['course']?.toString() ?? '',
    courseTitle: json['course_title']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    assignedDate: json['assigned_date']?.toString() ?? '',
    deadline: json['deadline']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'course': course,
    'course_title': courseTitle,
    'title': title,
    'description': description,
    'assigned_date': assignedDate,
    'deadline': deadline,
    'status': status,
  };

  AssignmentItem copyWith({
    String? id,
    String? course,
    String? courseTitle,
    String? title,
    String? description,
    String? assignedDate,
    String? deadline,
    String? status,
  }) {
    return AssignmentItem(
      id: id ?? this.id,
      course: course ?? this.course,
      courseTitle: courseTitle ?? this.courseTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedDate: assignedDate ?? this.assignedDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
    );
  }
}
