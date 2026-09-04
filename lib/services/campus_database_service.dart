import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/schedule.dart';
import '../models/room.dart';
import '../models/event.dart';
import '../models/announcement.dart';
import '../models/assignment.dart';

class CampusDatabaseService extends ChangeNotifier {
  static final CampusDatabaseService _instance = CampusDatabaseService._internal();
  factory CampusDatabaseService() => _instance;
  CampusDatabaseService._internal();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<ScheduleItem> schedules = [];
  List<RoomItem> rooms = [];
  List<EventItem> events = [];
  List<AnnouncementItem> announcements = [];
  List<AssignmentItem> assignments = [];

  final _uuid = const Uuid();

  Future<void> init() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final bool isInitialized = prefs.getBool('campusos_initialized') ?? false;

    if (isInitialized) {
      // Load from persistent storage
      try {
        final schStr = prefs.getString('campusos_schedules');
        if (schStr != null) {
          final List list = jsonDecode(schStr);
          schedules = list.map((e) => ScheduleItem.fromJson(e)).toList();
        }

        final roomStr = prefs.getString('campusos_rooms');
        if (roomStr != null) {
          final List list = jsonDecode(roomStr);
          rooms = list.map((e) => RoomItem.fromJson(e)).toList();
        }

        final evtStr = prefs.getString('campusos_events');
        if (evtStr != null) {
          final List list = jsonDecode(evtStr);
          events = list.map((e) => EventItem.fromJson(e)).toList();
        }

        final annStr = prefs.getString('campusos_announcements');
        if (annStr != null) {
          final List list = jsonDecode(annStr);
          announcements = list.map((e) => AnnouncementItem.fromJson(e)).toList();
        }

        final asgnStr = prefs.getString('campusos_assignments');
        if (asgnStr != null) {
          final List list = jsonDecode(asgnStr);
          assignments = list.map((e) => AssignmentItem.fromJson(e)).toList();
        }

        _isLoaded = true;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint("Error loading from persistent storage, falling back to seed data: $e");
      }
    }

    // First time startup: Seed from bundled data
    await resetToSeedData();
  }

  Future<void> resetToSeedData() async {
    try {
      final schData = await rootBundle.loadString('data/schedules.json');
      final List schList = jsonDecode(schData);
      schedules = schList.map((e) => ScheduleItem.fromJson(e)).toList();

      final roomData = await rootBundle.loadString('data/rooms.json');
      final List roomList = jsonDecode(roomData);
      rooms = roomList.map((e) => RoomItem.fromJson(e)).toList();

      final evtData = await rootBundle.loadString('data/events.json');
      final List evtList = jsonDecode(evtData);
      events = evtList.map((e) => EventItem.fromJson(e)).toList();

      final annData = await rootBundle.loadString('data/announcements.json');
      final List annList = jsonDecode(annData);
      announcements = annList.map((e) => AnnouncementItem.fromJson(e)).toList();

      final asgnData = await rootBundle.loadString('data/assignments.json');
      final List asgnList = jsonDecode(asgnData);
      assignments = asgnList.map((e) => AssignmentItem.fromJson(e)).toList();

      await _persistAll();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading seed data: $e");
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('campusos_initialized', true);
    await prefs.setString('campusos_schedules', jsonEncode(schedules.map((e) => e.toJson()).toList()));
    await prefs.setString('campusos_rooms', jsonEncode(rooms.map((e) => e.toJson()).toList()));
    await prefs.setString('campusos_events', jsonEncode(events.map((e) => e.toJson()).toList()));
    await prefs.setString('campusos_announcements', jsonEncode(announcements.map((e) => e.toJson()).toList()));
    await prefs.setString('campusos_assignments', jsonEncode(assignments.map((e) => e.toJson()).toList()));
  }

  // ================== SCHEDULES CRUD ==================
  Future<void> addSchedule(ScheduleItem item) async {
    if (item.id.isEmpty) item.id = 'sch-${_uuid.v4().substring(0, 5)}';
    schedules.add(item);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateSchedule(ScheduleItem item) async {
    final idx = schedules.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      schedules[idx] = item;
      await _persistAll();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    schedules.removeWhere((e) => e.id == id);
    await _persistAll();
    notifyListeners();
  }

  // ================== ROOMS CRUD & BOOKINGS ==================
  Future<void> addRoom(RoomItem item) async {
    if (item.id.isEmpty) item.id = 'room-${_uuid.v4().substring(0, 5)}';
    rooms.add(item);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateRoom(RoomItem item) async {
    final idx = rooms.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      rooms[idx] = item;
      await _persistAll();
      notifyListeners();
    }
  }

  Future<void> deleteRoom(String id) async {
    rooms.removeWhere((e) => e.id == id);
    await _persistAll();
    notifyListeners();
  }

  String? bookRoom({
    required String roomNumber,
    required String bookedBy,
    required String date,
    required String startTime,
    required String endTime,
    required String purpose,
  }) {
    final cleanRoomNum = roomNumber.trim().toUpperCase();
    final roomIdx = rooms.indexWhere((r) => r.roomNumber.toUpperCase() == cleanRoomNum);
    if (roomIdx == -1) {
      return "Room '$roomNumber' not found on campus.";
    }

    final targetRoom = rooms[roomIdx];

    // Conflict detection: Same date & overlapping time
    for (final b in targetRoom.bookings) {
      if (b.date == date) {
        // Overlap: max(start1, start2) < min(end1, end2)
        if (startTime.compareTo(b.endTime) < 0 && endTime.compareTo(b.startTime) > 0) {
          return "Booking conflict! Room $roomNumber is already booked by ${b.bookedBy} on $date from ${b.startTime} to ${b.endTime} for '${b.purpose}'.";
        }
      }
    }

    final newBooking = BookingItem(
      bookingId: 'bk-${_uuid.v4().substring(0, 5)}',
      bookedBy: bookedBy.isEmpty ? "Student" : bookedBy,
      date: date,
      startTime: startTime,
      endTime: endTime,
      purpose: purpose.isEmpty ? "Study Session" : purpose,
    );

    targetRoom.bookings.add(newBooking);
    _persistAll();
    notifyListeners();
    return null; // Null means success
  }

  bool cancelBooking(String roomNumber, String bookingId) {
    final cleanRoomNum = roomNumber.trim().toUpperCase();
    final roomIdx = rooms.indexWhere((r) => r.roomNumber.toUpperCase() == cleanRoomNum);
    if (roomIdx == -1) return false;

    final beforeCount = rooms[roomIdx].bookings.length;
    rooms[roomIdx].bookings.removeWhere((b) => b.bookingId == bookingId);
    if (rooms[roomIdx].bookings.length != beforeCount) {
      _persistAll();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ================== EVENTS CRUD & REGISTRATION ==================
  Future<void> addEvent(EventItem item) async {
    if (item.id.isEmpty) item.id = 'evt-${_uuid.v4().substring(0, 5)}';
    events.add(item);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateEvent(EventItem item) async {
    final idx = events.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      events[idx] = item;
      await _persistAll();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    events.removeWhere((e) => e.id == id);
    await _persistAll();
    notifyListeners();
  }

  String? registerEvent(String eventNameOrId, {required String studentId, required String studentName}) {
    final cleanQuery = eventNameOrId.trim().toLowerCase();
    final eventIdx = events.indexWhere((e) =>
        e.id.toLowerCase() == cleanQuery ||
        e.name.toLowerCase().contains(cleanQuery));

    if (eventIdx == -1) {
      return "Event '$eventNameOrId' not found.";
    }

    final event = events[eventIdx];

    // Check if event is cancelled or completed
    if (event.status == "cancelled" || event.status == "completed") {
      return "Cannot register: Event '${event.name}' is currently ${event.status}.";
    }

    // Check capacity
    if (event.registered >= event.capacity) {
      event.status = "full";
      _persistAll();
      notifyListeners();
      return "Registration failed: Event '${event.name}' is completely full (${event.registered}/${event.capacity} seats taken).";
    }

    // Check duplicate registration
    final alreadyRegistered = event.registrations.any((r) => r.studentId == studentId);
    if (alreadyRegistered) {
      return "Student ID $studentId ($studentName) is already registered for '${event.name}'.";
    }

    event.registrations.add(RegistrationItem(studentId: studentId, name: studentName));
    event.registered = event.registrations.length;
    if (event.registered >= event.capacity) {
      event.status = "full";
    }
    _persistAll();
    notifyListeners();
    return null; // Null means success
  }

  bool cancelEventRegistration(String eventNameOrId, String studentId) {
    final cleanQuery = eventNameOrId.trim().toLowerCase();
    final eventIdx = events.indexWhere((e) =>
        e.id.toLowerCase() == cleanQuery ||
        e.name.toLowerCase().contains(cleanQuery));

    if (eventIdx == -1) return false;

    final event = events[eventIdx];
    final before = event.registrations.length;
    event.registrations.removeWhere((r) => r.studentId == studentId);
    if (event.registrations.length != before) {
      event.registered = event.registrations.length;
      if (event.status == "full" && event.registered < event.capacity) {
        event.status = "upcoming";
      }
      _persistAll();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ================== ANNOUNCEMENTS CRUD ==================
  Future<void> addAnnouncement(AnnouncementItem item) async {
    if (item.id.isEmpty) item.id = 'ann-${_uuid.v4().substring(0, 5)}';
    announcements.insert(0, item);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateAnnouncement(AnnouncementItem item) async {
    final idx = announcements.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      announcements[idx] = item;
      await _persistAll();
      notifyListeners();
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    announcements.removeWhere((e) => e.id == id);
    await _persistAll();
    notifyListeners();
  }

  // ================== ASSIGNMENTS CRUD ==================
  Future<void> addAssignment(AssignmentItem item) async {
    if (item.id.isEmpty) item.id = 'asgn-${_uuid.v4().substring(0, 5)}';
    assignments.add(item);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateAssignment(AssignmentItem item) async {
    final idx = assignments.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      assignments[idx] = item;
      await _persistAll();
      notifyListeners();
    }
  }

  Future<void> deleteAssignment(String id) async {
    assignments.removeWhere((e) => e.id == id);
    await _persistAll();
    notifyListeners();
  }
}
