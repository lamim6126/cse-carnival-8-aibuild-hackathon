import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../widgets/event_dialog.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final _db = CampusDatabaseService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _db,
      builder: (context, _) {
        final statuses = ['All', 'upcoming', 'ongoing', 'completed', 'cancelled', 'full'];

        final filtered = _db.events.where((e) {
          if (_selectedStatus != 'All' && e.status != _selectedStatus) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return e.name.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q) ||
                e.organizer.toLowerCase().contains(q) ||
                e.venue.toLowerCase().contains(q);
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
                        const Text("Campus Events & Workshops",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text("${_db.events.length} campus events listed",
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    icon: const Icon(Icons.add),
                    label: const Text("Create Event"),
                    onPressed: () => EventDialog.show(context),
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
                        hintText: "Search event name, venue, organizer...",
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
                      initialValue: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: statuses
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s == 'All' ? 'All Statuses' : s.toUpperCase())))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text("No events found matching criteria."))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) {
                          final event = filtered[i];
                          final isFull = event.registered >= event.capacity;
                          final pct = event.capacity > 0
                              ? (event.registered / event.capacity).clamp(0.0, 1.0)
                              : 0.0;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(event.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 18)),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isFull
                                              ? Colors.red.shade100
                                              : Colors.purple.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (isFull ? "FULL" : event.status).toUpperCase(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isFull
                                                  ? Colors.red.shade900
                                                  : Colors.purple.shade900),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blueAccent, size: 20),
                                        tooltip: "Edit Event",
                                        onPressed: () => EventDialog.show(context, item: event),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent, size: 20),
                                        tooltip: "Delete Event",
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text("Delete Event?"),
                                              content: Text(
                                                  "Are you sure you want to delete '${event.name}'?"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () => Navigator.pop(c, false),
                                                    child: const Text("Cancel")),
                                                ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red,
                                                        foregroundColor: Colors.white),
                                                    onPressed: () => Navigator.pop(c, true),
                                                    child: const Text("Delete")),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) _db.deleteEvent(event.id);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(event.description,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    children: [
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.event, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(event.date)
                                      ]),
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text("${event.startTime} - ${event.endTime}")
                                      ]),
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.place, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text("Venue: ${event.venue}")
                                      ]),
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.group, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text("Organizer: ${event.organizer}")
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                    "Seats: ${event.registered} / ${event.capacity} registered",
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600, fontSize: 12)),
                                                Text("${(pct * 100).toInt()}% filled",
                                                    style: const TextStyle(
                                                        color: Colors.grey, fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                minHeight: 8,
                                                backgroundColor: Colors.grey.shade200,
                                                color: isFull ? Colors.red : Colors.purple,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFull ? Colors.grey : Colors.purple,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(Icons.how_to_reg, size: 16),
                                        label: Text(isFull ? "Event Full" : "Register Now"),
                                        onPressed: isFull
                                            ? null
                                            : () => EventDialog.showRegister(context, event),
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
      },
    );
  }
}
