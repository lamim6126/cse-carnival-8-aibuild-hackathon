import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/campus_database_service.dart';

class EventDialog {
  static void show(BuildContext context, {EventItem? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final venueCtrl = TextEditingController(text: item?.venue ?? '7A03');
    final orgCtrl = TextEditingController(text: item?.organizer ?? '');
    final dateCtrl = TextEditingController(text: item?.date ?? '2026-09-06');
    final startCtrl = TextEditingController(text: item?.startTime ?? '14:00');
    final endCtrl = TextEditingController(text: item?.endTime ?? '16:00');
    final capCtrl = TextEditingController(text: item != null ? item.capacity.toString() : '50');
    String selectedStatus = item?.status ?? 'upcoming';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Campus Event" : "Create New Event", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Event Name", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: "Venue Room", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: "Organizer", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Capacity", border: OutlineInputBorder()))),
                    ],
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
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                    items: ['upcoming', 'ongoing', 'completed', 'cancelled', 'full']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                final db = CampusDatabaseService();
                final cap = int.tryParse(capCtrl.text) ?? 50;

                if (isEdit) {
                  db.updateEvent(item.copyWith(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    venue: venueCtrl.text.trim(),
                    organizer: orgCtrl.text.trim(),
                    date: dateCtrl.text.trim(),
                    endDate: dateCtrl.text.trim(),
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                    capacity: cap,
                    status: selectedStatus,
                  ));
                } else {
                  db.addEvent(EventItem(
                    id: '',
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    date: dateCtrl.text.trim(),
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                    endDate: dateCtrl.text.trim(),
                    venue: venueCtrl.text.trim(),
                    organizer: orgCtrl.text.trim(),
                    capacity: cap,
                    registered: 0,
                    registrations: [],
                    status: selectedStatus,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? "Save Event" : "Create Event"),
            ),
          ],
        ),
      ),
    );
  }

  static void showRegister(BuildContext context, EventItem event) {
    final idCtrl = TextEditingController(text: '20-40532');
    final nameCtrl = TextEditingController(text: 'Mahir Ahmed');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Register: ${event.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: "Student ID (e.g. 20-40532)", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Student Name", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () {
              final db = CampusDatabaseService();
              final err = db.registerEvent(event.id, studentId: idCtrl.text.trim(), studentName: nameCtrl.text.trim());
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registered successfully for ${event.name}!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Confirm Registration"),
          ),
        ],
      ),
    );
  }
}
