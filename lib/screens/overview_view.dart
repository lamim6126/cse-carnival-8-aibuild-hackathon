import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../widgets/announcement_dialog.dart';
import '../widgets/room_dialog.dart';
import '../widgets/schedule_dialog.dart';

class OverviewView extends StatelessWidget {
  final Function(int) onNavigate;
  const OverviewView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final db = CampusDatabaseService();
    final availRooms = db.rooms.where((r) => r.status == 'available').length;
    final highNotices = db.announcements.where((a) => a.priority == 'high').length;
    final pendingAsgn = db.assignments.where((a) => a.status == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade600]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome to CampusOS", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("Real-Time Campus Operating System & Autonomous AI Agent", style: TextStyle(color: Colors.indigo.shade100, fontSize: 14)),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade400, foregroundColor: Colors.indigo.shade900),
                        icon: const Icon(Icons.smart_toy),
                        label: const Text("Talk to CampusOS AI Agent", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => onNavigate(6),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.school, size: 80, color: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Live Campus Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
                _buildMetricCard("Classes", "${db.schedules.length} Total", Icons.schedule, Colors.indigo, () => onNavigate(1)),
                _buildMetricCard("Rooms & Labs", "$availRooms / ${db.rooms.length} Free", Icons.meeting_room, Colors.teal, () => onNavigate(2)),
                _buildMetricCard("Events", "${db.events.length} Listed", Icons.event, Colors.purple, () => onNavigate(3)),
                _buildMetricCard("Notices", "$highNotices Urgent", Icons.campaign, Colors.orange, () => onNavigate(4)),
                _buildMetricCard("Assignments", "$pendingAsgn Pending", Icons.assignment, Colors.blueGrey, () => onNavigate(5)),
              ],
          ),
          const SizedBox(height: 24),
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text("Add Class Schedule"), onPressed: () => ScheduleDialog.show(context)),
              OutlinedButton.icon(icon: const Icon(Icons.add_alert), label: const Text("Post Notice"), onPressed: () => AnnouncementDialog.show(context)),
              OutlinedButton.icon(icon: const Icon(Icons.meeting_room), label: const Text("Add Room"), onPressed: () => RoomDialog.show(context)),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 700;

              Widget announcementsCard = Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text("Latest Announcements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          TextButton(onPressed: () => onNavigate(4), child: const Text("View All")),
                        ],
                      ),
                      const Divider(),
                      ...db.announcements.take(3).map((a) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.circle, size: 10, color: a.priority == 'high' ? Colors.red : Colors.orange),
                            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text("${a.date}  •  ${a.postedBy}", style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                  ),
                ),
              );

              Widget eventsCard = Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text("Upcoming Campus Events", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          TextButton(onPressed: () => onNavigate(3), child: const Text("View All")),
                        ],
                      ),
                      const Divider(),
                      ...db.events.take(3).map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_available, color: Colors.purple),
                            title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text("${e.date} (${e.startTime})  •  ${e.venue}", style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  children: [
                    announcementsCard,
                    const SizedBox(height: 16),
                    eventsCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: announcementsCard),
                  const SizedBox(width: 16),
                  Expanded(child: eventsCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
