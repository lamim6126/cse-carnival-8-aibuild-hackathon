import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../widgets/room_dialog.dart';

class RoomsView extends StatefulWidget {
  const RoomsView({super.key});

  @override
  State<RoomsView> createState() => _RoomsViewState();
}

class _RoomsViewState extends State<RoomsView> {
  String _selectedType = 'All';
  String _searchQuery = '';
  String _selectedEquipment = 'All';

  @override
  Widget build(BuildContext context) {
    final db = CampusDatabaseService();
    final types = ['All', 'classroom', 'lab', 'seminar'];
    final equipments = ['All', 'projector', 'AC', 'whiteboard', 'smart board'];

    final filtered = db.rooms.where((r) {
      if (_selectedType != 'All' && r.type != _selectedType) return false;
      if (_selectedEquipment != 'All') {
        if (!r.equipment.any((e) => e.toLowerCase().contains(_selectedEquipment.toLowerCase()))) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return r.roomNumber.toLowerCase().contains(q) ||
            r.type.toLowerCase().contains(q) ||
            r.equipment.any((e) => e.toLowerCase().contains(q));
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rooms & Laboratories", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("${db.rooms.length} campus rooms available for classes, labs & bookings", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                icon: const Icon(Icons.add),
                label: const Text("Add Room / Lab"),
                onPressed: () => RoomDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search room (e.g. 7A01, lab)...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All Types' : t.toUpperCase()))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedEquipment,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: equipments.map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? 'All Equipment' : e.toUpperCase()))).toList(),
                  onChanged: (val) => setState(() => _selectedEquipment = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No rooms found matching filters."))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 440,
                      mainAxisExtent: 260,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final room = filtered[i];
                      final isAvail = room.status == 'available';

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text("Room ${room.roomNumber}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAvail ? Colors.green.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      room.status.toUpperCase(),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAvail ? Colors.green.shade800 : Colors.red.shade800),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                                    tooltip: "Edit Room",
                                    onPressed: () => RoomDialog.show(context, item: room),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                    tooltip: "Delete Room",
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text("Delete Room?"),
                                          content: Text("Are you sure you want to delete Room ${room.roomNumber}?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(c, true), child: const Text("Delete")),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) db.deleteRoom(room.id);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text("Type: ${room.type.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(width: 14),
                                  Text("Capacity: ${room.capacity}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(width: 14),
                                  Text("Floor: ${room.floor}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                children: room.equipment
                                    .map((eq) => Chip(
                                          label: Text(eq, style: const TextStyle(fontSize: 10)),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: Colors.grey.shade100,
                                        ))
                                    .toList(),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${room.bookings.length} Booking(s)",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: room.bookings.isNotEmpty ? Colors.orange.shade800 : Colors.grey),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.bookmark_add, size: 16),
                                    label: const Text("Book Room"),
                                    onPressed: () => RoomDialog.showBook(context, room),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
