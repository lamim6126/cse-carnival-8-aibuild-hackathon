import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/campus_database_service.dart';

class RoomDialog {
  static void show(BuildContext context, {RoomItem? item}) {
    final isEdit = item != null;
    final numCtrl = TextEditingController(text: item?.roomNumber ?? '');
    final capCtrl = TextEditingController(text: item != null ? item.capacity.toString() : '40');
    final floorCtrl = TextEditingController(text: item != null ? item.floor.toString() : '7');
    final equipCtrl = TextEditingController(text: item?.equipment.join(', ') ?? 'projector, AC, whiteboard');
    String selectedType = item?.type ?? 'classroom';
    String selectedStatus = item?.status ?? 'available';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Room / Lab" : "Add Room / Lab", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: numCtrl, decoration: const InputDecoration(labelText: "Room Number (e.g. 7A05)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: "Room Type", border: OutlineInputBorder()),
                    items: ['classroom', 'lab', 'seminar']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Capacity", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: floorCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Floor", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: equipCtrl, decoration: const InputDecoration(labelText: "Equipment (comma separated)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                    items: ['available', 'unavailable']
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () {
                if (numCtrl.text.isEmpty) return;
                final db = CampusDatabaseService();
                final equipList = equipCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                final cap = int.tryParse(capCtrl.text) ?? 40;
                final floor = int.tryParse(floorCtrl.text) ?? 7;

                if (isEdit) {
                  db.updateRoom(item.copyWith(
                    roomNumber: numCtrl.text.trim(),
                    type: selectedType,
                    capacity: cap,
                    floor: floor,
                    equipment: equipList,
                    status: selectedStatus,
                  ));
                } else {
                  db.addRoom(RoomItem(
                    id: '',
                    roomNumber: numCtrl.text.trim(),
                    type: selectedType,
                    capacity: cap,
                    equipment: equipList,
                    floor: floor,
                    status: selectedStatus,
                    bookings: [],
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? "Save Changes" : "Add Room"),
            ),
          ],
        ),
      ),
    );
  }

  static void showBook(BuildContext context, RoomItem room) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    final byCtrl = TextEditingController(text: 'Student');
    final purposeCtrl = TextEditingController(text: 'Project Discussion');
    final dateCtrl = TextEditingController(text: tomorrowStr);
    final startCtrl = TextEditingController(text: '15:00');
    final endCtrl = TextEditingController(text: '17:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Book Room ${room.roomNumber}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: byCtrl, decoration: const InputDecoration(labelText: "Booked By (Name/Club)", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: "Purpose", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: "Start (HH:MM)", border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: "End (HH:MM)", border: OutlineInputBorder()))),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              final db = CampusDatabaseService();
              final err = db.bookRoom(
                roomNumber: room.roomNumber,
                bookedBy: byCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                startTime: startCtrl.text.trim(),
                endTime: endCtrl.text.trim(),
                purpose: purposeCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Room ${room.roomNumber} successfully booked!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Confirm Booking"),
          ),
        ],
      ),
    );
  }
}
