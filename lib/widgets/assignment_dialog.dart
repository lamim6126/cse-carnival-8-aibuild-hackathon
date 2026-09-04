import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../services/campus_database_service.dart';

class AssignmentDialog {
  static void show(BuildContext context, {AssignmentItem? item}) {
    final isEdit = item != null;
    final now = DateTime.now();
    final defaultDeadline =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day + 7).toString().padLeft(2, '0')}';

    final courseCtrl = TextEditingController(text: item?.course ?? 'CSE 4113');
    final courseTitleCtrl = TextEditingController(text: item?.courseTitle ?? '');
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final deadlineCtrl = TextEditingController(text: item?.deadline ?? defaultDeadline);
    final platformCtrl = TextEditingController(text: item?.submissionPlatform ?? 'Google Classroom');
    final marksCtrl = TextEditingController(text: item != null ? item.marks.toString() : '10');
    String selectedStatus = item?.status ?? 'pending';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Assignment" : "Add Assignment",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: courseCtrl,
                          decoration: const InputDecoration(
                            labelText: "Course Code (e.g. CSE 4113)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: marksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Marks", border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courseTitleCtrl,
                    decoration: const InputDecoration(labelText: "Course Title", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Assignment Title", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Task Description", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: platformCtrl,
                    decoration: const InputDecoration(
                      labelText: "Submission Platform (e.g. Google Classroom)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: deadlineCtrl,
                          decoration: const InputDecoration(
                            labelText: "Deadline (YYYY-MM-DD)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                          items: ['pending', 'submitted', 'graded', 'late']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                              .toList(),
                          onChanged: (val) => setState(() => selectedStatus = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.isEmpty) return;
                final db = CampusDatabaseService();
                final today =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                if (isEdit) {
                  db.updateAssignment(item.copyWith(
                    course: courseCtrl.text.trim(),
                    courseTitle: courseTitleCtrl.text.trim().isNotEmpty
                        ? courseTitleCtrl.text.trim()
                        : item.courseTitle,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    deadline: deadlineCtrl.text.trim(),
                    submissionPlatform: platformCtrl.text.trim(),
                    marks: int.tryParse(marksCtrl.text) ?? item.marks,
                    status: selectedStatus,
                  ));
                } else {
                  db.addAssignment(AssignmentItem(
                    id: '',
                    course: courseCtrl.text.trim(),
                    courseTitle: courseTitleCtrl.text.trim(),
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    assignedDate: today,
                    deadline: deadlineCtrl.text.trim(),
                    submissionPlatform: platformCtrl.text.trim(),
                    marks: int.tryParse(marksCtrl.text) ?? 10,
                    status: selectedStatus,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? "Save Assignment" : "Add Assignment"),
            ),
          ],
        ),
      ),
    );
  }
}
