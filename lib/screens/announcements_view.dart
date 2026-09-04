import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../widgets/announcement_dialog.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  String _selectedPriority = 'All';
  String _searchQuery = '';
  final _db = CampusDatabaseService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _db,
      builder: (context, _) {
        final priorities = ['All', 'high', 'medium', 'low'];

        final filtered = _db.announcements.where((a) {
          if (_selectedPriority != 'All' && a.priority != _selectedPriority) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return a.title.toLowerCase().contains(q) ||
                a.body.toLowerCase().contains(q) ||
                a.postedBy.toLowerCase().contains(q);
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
                        const Text("Campus Announcements & Notices",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text("${_db.announcements.length} official notices posted",
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    icon: const Icon(Icons.add_alert),
                    label: const Text("Post Announcement"),
                    onPressed: () => AnnouncementDialog.show(context),
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
                        hintText: "Search notices...",
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
                      initialValue: _selectedPriority,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: priorities
                          .map((p) => DropdownMenuItem(
                              value: p, child: Text(p == 'All' ? 'All Priorities' : p.toUpperCase())))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedPriority = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text("No notices found matching search criteria."))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          final isHigh = item.priority == 'high';
                          final isMed = item.priority == 'medium';
                          final Color badgeColor =
                              isHigh ? Colors.red : (isMed ? Colors.orange : Colors.blue);

                          return Card(
                            elevation: isHigh ? 3 : 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isHigh
                                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          item.priority.toUpperCase(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 11, color: badgeColor),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(item.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                                        tooltip: "Edit Notice",
                                        onPressed: () => AnnouncementDialog.show(context, item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                        tooltip: "Delete Notice",
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text("Delete Announcement?"),
                                              content:
                                                  Text("Are you sure you want to delete '${item.title}'?"),
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
                                          if (confirm == true) _db.deleteAnnouncement(item.id);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item.body,
                                      style: TextStyle(
                                          color: Colors.grey.shade800, fontSize: 14, height: 1.4)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Posted by: ${item.postedBy}",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500)),
                                      Text("Posted: ${item.date}  |  Expires: ${item.expires}",
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
