import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/campus_database_service.dart';

class ScheduleDialog {
  static void show(BuildContext context, {ScheduleItem? item}) {
    final isEdit = item != null;
    final courseCtrl = TextEditingController(text: item?.course ?? '');
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final instructorCtrl = TextEditingController(text: item?.instructor ?? '');
    final roomCtrl = TextEditingController(text: item?.room ?? '');
    final sectionCtrl = TextEditingController(text: item?.section ?? 'A');
    final startCtrl = TextEditingController(text: item?.startTime ?? '09:00');
    final endCtrl = TextEditingController(text: item?.endTime ?? '10:00');
    String selectedDay = item?.day ?? 'Sunday';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Class Schedule" : "Add New Class Schedule", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: "Course Code (e.g. CSE 4113)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Course Title", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: "Day of Week", border: OutlineInputBorder()),
                    items: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: "Start (HH:MM)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: "End (HH:MM)", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: "Room (e.g. 7A03)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: "Section (e.g. A, B)", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: instructorCtrl, decoration: const InputDecoration(labelText: "Instructor Name", border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (courseCtrl.text.isEmpty || titleCtrl.text.isEmpty) return;
                final db = CampusDatabaseService();
                if (isEdit) {
                  db.updateSchedule(item.copyWith(
                    course: courseCtrl.text.trim(),
                    title: titleCtrl.text.trim(),
                    day: selectedDay,
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                    room: roomCtrl.text.trim(),
                    section: sectionCtrl.text.trim(),
                    instructor: instructorCtrl.text.trim(),
                  ));
                } else {
                  db.addSchedule(ScheduleItem(
                    id: '',
                    course: courseCtrl.text.trim(),
                    title: titleCtrl.text.trim(),
                    day: selectedDay,
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                    room: roomCtrl.text.trim(),
                    section: sectionCtrl.text.trim(),
                    instructor: instructorCtrl.text.trim(),
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? "Save Changes" : "Add Schedule"),
            ),
          ],
        ),
      ),
    );
  }
}
