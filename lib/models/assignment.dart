class AssignmentItem {
  String id;
  String course;
  String courseTitle;
  String title;
  String description;
  String assignedDate;
  String deadline;
  String submissionPlatform;
  String status; // "pending" | "submitted" | "graded" | "late"
  int marks;

  AssignmentItem({
    required this.id,
    required this.course,
    required this.courseTitle,
    required this.title,
    required this.description,
    required this.assignedDate,
    required this.deadline,
    this.submissionPlatform = '',
    required this.status,
    this.marks = 0,
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> json) => AssignmentItem(
    id: json['id']?.toString() ?? '',
    course: json['course']?.toString() ?? '',
    courseTitle: json['course_title']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    assignedDate: json['assigned_date']?.toString() ?? '',
    deadline: json['deadline']?.toString() ?? '',
    submissionPlatform: json['submission_platform']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
    marks: (json['marks'] is num)
        ? (json['marks'] as num).toInt()
        : int.tryParse(json['marks']?.toString() ?? '0') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'course': course,
    'course_title': courseTitle,
    'title': title,
    'description': description,
    'assigned_date': assignedDate,
    'deadline': deadline,
    'submission_platform': submissionPlatform,
    'status': status,
    'marks': marks,
  };

  AssignmentItem copyWith({
    String? id,
    String? course,
    String? courseTitle,
    String? title,
    String? description,
    String? assignedDate,
    String? deadline,
    String? submissionPlatform,
    String? status,
    int? marks,
  }) {
    return AssignmentItem(
      id: id ?? this.id,
      course: course ?? this.course,
      courseTitle: courseTitle ?? this.courseTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedDate: assignedDate ?? this.assignedDate,
      deadline: deadline ?? this.deadline,
      submissionPlatform: submissionPlatform ?? this.submissionPlatform,
      status: status ?? this.status,
      marks: marks ?? this.marks,
    );
  }
}
