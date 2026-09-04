import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../widgets/settings_dialog.dart';
import 'overview_view.dart';
import 'schedules_view.dart';
import 'rooms_view.dart';
import 'events_view.dart';
import 'announcements_view.dart';
import 'assignments_view.dart';
import 'agent_chat_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final CampusDatabaseService _db = CampusDatabaseService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _db,
      builder: (context, _) {
        final views = [
          OverviewView(onNavigate: (idx) => setState(() => _currentIndex = idx)),
          const SchedulesView(),
          const RoomsView(),
          const EventsView(),
          const AnnouncementsView(),
          const AssignmentsView(),
          const AgentChatView(),
        ];

        final isWide = MediaQuery.of(context).size.width >= 800;

        return Scaffold(
          appBar: AppBar(
            elevation: 0.5,
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo.shade900,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.school, color: Colors.indigo),
                ),
                const SizedBox(width: 10),
                const Text("CampusOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(4)),
                  child: const Text("AUST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: "Settings & API Key",
                onPressed: () => SettingsDialog.show(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox(height: 10),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text("Overview")),
                    NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text("Schedules")),
                    NavigationRailDestination(icon: Icon(Icons.meeting_room_outlined), selectedIcon: Icon(Icons.meeting_room), label: Text("Rooms")),
                    NavigationRailDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: Text("Events")),
                    NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text("Notices")),
                    NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text("Assignments")),
                    NavigationRailDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: Text("AI Agent")),
                  ],
                ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: views,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (idx) => setState(() => _currentIndex = idx),
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.indigo,
                  unselectedItemColor: Colors.grey,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Overview"),
                    BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Schedule"),
                    BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: "Rooms"),
                    BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
                    BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "Notices"),
                    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Tasks"),
                    BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "AI Agent"),
                  ],
                ),
          floatingActionButton: _currentIndex != 6
              ? FloatingActionButton.extended(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.smart_toy),
                  label: const Text("Ask AI Agent"),
                  onPressed: () => setState(() => _currentIndex = 6),
                )
              : null,
        );
      },
    );
  }
}
