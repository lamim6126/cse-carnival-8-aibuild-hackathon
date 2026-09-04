import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../services/campus_database_service.dart';

class AssignmentDialog {
  static void show(BuildContext context, {AssignmentItem? item}) {
    final isEdit = item != null;
    final courseCtrl = TextEditingController(text: item?.course ?? 'CSE 4113');
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final deadlineCtrl = TextEditingController(text: item?.deadline ?? '2026-09-10');
    String selectedStatus = item?.status ?? 'pending';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Assignment" : "Add Assignment", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: "Course Code", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Assignment Title", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Task Description", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: deadlineCtrl, decoration: const InputDecoration(labelText: "Deadline (YYYY-MM-DD)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.isEmpty) return;
                final db = CampusDatabaseService();
                if (isEdit) {
                  db.updateAssignment(item.copyWith(
                    course: courseCtrl.text.trim(),
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    deadline: deadlineCtrl.text.trim(),
                    status: selectedStatus,
                  ));
                } else {
                  db.addAssignment(AssignmentItem(
                    id: '',
                    course: courseCtrl.text.trim(),
                    courseTitle: courseCtrl.text.trim(),
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    assignedDate: '2026-09-04',
                    deadline: deadlineCtrl.text.trim(),
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
