import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../widgets/assignment_dialog.dart';

class AssignmentsView extends StatefulWidget {
  const AssignmentsView({super.key});

  @override
  State<AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<AssignmentsView> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final _db = CampusDatabaseService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _db,
      builder: (context, _) {
        final statuses = ['All', 'pending', 'submitted', 'graded', 'late'];

        final filtered = _db.assignments.where((a) {
          if (_selectedStatus != 'All' && a.status != _selectedStatus) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return a.course.toLowerCase().contains(q) ||
                a.title.toLowerCase().contains(q) ||
                a.description.toLowerCase().contains(q);
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
                        const Text("Course Assignments & Deadlines",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text("${_db.assignments.length} total assignments tracked",
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    icon: const Icon(Icons.add_task),
                    label: const Text("Add Assignment"),
                    onPressed: () => AssignmentDialog.show(context),
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
                        hintText: "Search assignments or courses...",
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
                    ? const Center(child: Text("No assignments found matching criteria."))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          final isPending = item.status == 'pending';
                          final isLate = item.status == 'late';

                          final Color statusColor = isPending
                              ? Colors.amber.shade800
                              : (isLate ? Colors.red : Colors.green.shade700);

                          return Card(
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                            color: Colors.blueGrey.shade100,
                                            borderRadius: BorderRadius.circular(6)),
                                        child: Text(item.course,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.blueGrey.shade900)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(item.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6)),
                                        child: Text(item.status.toUpperCase(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: statusColor)),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                                        tooltip: "Edit Assignment",
                                        onPressed: () => AssignmentDialog.show(context, item: item),
                                      ),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                        tooltip: "Delete Assignment",
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text("Delete Assignment?"),
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
                                          if (confirm == true) _db.deleteAssignment(item.id);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item.description,
                                      style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_month,
                                              size: 16, color: Colors.redAccent),
                                          const SizedBox(width: 6),
                                          Text("Due: ${item.deadline}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Colors.redAccent)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (item.submissionPlatform.isNotEmpty) ...[
                                            Icon(Icons.upload_rounded,
                                                size: 14, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(item.submissionPlatform,
                                                style: TextStyle(
                                                    fontSize: 12, color: Colors.grey.shade600)),
                                            const SizedBox(width: 12),
                                          ],
                                          if (item.marks > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                  color: Colors.indigo.shade50,
                                                  borderRadius: BorderRadius.circular(6)),
                                              child: Text("${item.marks} marks",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.indigo.shade700)),
                                            ),
                                        ],
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
