import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/campus_database_service.dart';

class AnnouncementDialog {
  static void show(BuildContext context, {AnnouncementItem? item}) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final bodyCtrl = TextEditingController(text: item?.body ?? '');
    final byCtrl = TextEditingController(text: item?.postedBy ?? 'Department of CSE');
    final dateCtrl = TextEditingController(text: item?.date ?? '2026-09-04');
    final expCtrl = TextEditingController(text: item?.expires ?? '2026-09-15');
    String selectedPriority = item?.priority ?? 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Notice" : "Post Notice / Announcement", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Headline / Title", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Notice Body", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: "Priority Level", border: OutlineInputBorder()),
                    items: ['high', 'medium', 'low']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setState(() => selectedPriority = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date Posted", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: expCtrl, decoration: const InputDecoration(labelText: "Expiry Date", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: byCtrl, decoration: const InputDecoration(labelText: "Posted By", border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.isEmpty) return;
                final db = CampusDatabaseService();
                if (isEdit) {
                  db.updateAnnouncement(item.copyWith(
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                    priority: selectedPriority,
                    date: dateCtrl.text.trim(),
                    expires: expCtrl.text.trim(),
                    postedBy: byCtrl.text.trim(),
                  ));
                } else {
                  db.addAnnouncement(AnnouncementItem(
                    id: '',
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                    priority: selectedPriority,
                    date: dateCtrl.text.trim(),
                    expires: expCtrl.text.trim(),
                    postedBy: byCtrl.text.trim(),
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? "Update Notice" : "Post Notice"),
            ),
          ],
        ),
      ),
    );
  }
}
