import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../widgets/schedule_dialog.dart';

class SchedulesView extends StatefulWidget {
  const SchedulesView({super.key});

  @override
  State<SchedulesView> createState() => _SchedulesViewState();
}

class _SchedulesViewState extends State<SchedulesView> {
  String _selectedDay = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final db = CampusDatabaseService();
    final days = ['All', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

    final filtered = db.schedules.where((s) {
      if (_selectedDay != 'All' && s.day != _selectedDay) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return s.course.toLowerCase().contains(q) ||
            s.title.toLowerCase().contains(q) ||
            s.room.toLowerCase().contains(q) ||
            s.instructor.toLowerCase().contains(q);
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
                    const Text("Class Schedules & Timetable", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Total ${db.schedules.length} class periods configured", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                icon: const Icon(Icons.add),
                label: const Text("Add Class Schedule"),
                onPressed: () => ScheduleDialog.show(context),
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
                    hintText: "Search by course, instructor, or room...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: days.map((d) => DropdownMenuItem(value: d, child: Text(d == 'All' ? 'All Days' : d))).toList(),
                  onChanged: (val) => setState(() => _selectedDay = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No schedule records found matching criteria."))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Colors.indigo,
                            child: const Icon(Icons.school),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(6)),
                                child: Text(item.course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 4), Text("${item.day} ${item.startTime} - ${item.endTime}")]),
                                Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.meeting_room, size: 14, color: Colors.grey), const SizedBox(width: 4), Text("Room ${item.room} (Sec: ${item.section})")]),
                                Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(item.instructor)]),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                tooltip: "Edit Class",
                                onPressed: () => ScheduleDialog.show(context, item: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: "Delete Class",
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text("Delete Class Schedule?"),
                                      content: Text("Are you sure you want to delete ${item.course} - ${item.title}?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(c, true), child: const Text("Delete")),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    db.deleteSchedule(item.id);
                                  }
                                },
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
