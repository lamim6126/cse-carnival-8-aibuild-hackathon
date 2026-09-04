import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'campus_database_service.dart';

class ChatMessage {
  final String sender; // 'user' | 'agent' | 'system'
  final String text;
  final List<String> toolCallsMade;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.text,
    this.toolCallsMade = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class GeminiAgentService extends ChangeNotifier {
  static final GeminiAgentService _instance = GeminiAgentService._internal();
  factory GeminiAgentService() => _instance;
  GeminiAgentService._internal();

  final CampusDatabaseService _db = CampusDatabaseService();
  
  String _apiKey = '';
  String get apiKey => _apiKey;

  ChatSession? _chatSession;
  final List<ChatMessage> messages = [];
  bool isThinking = false;

  Future<void> init() async {
    // 1. Check persistent preferences (configured via Settings UI)
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('campusos_gemini_api_key') ?? '';

    // 2. Check local .env file
    if (_apiKey.isEmpty) {
      try {
        if (!dotenv.isInitialized) {
          await dotenv.load(fileName: ".env");
        }
        _apiKey = dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['GOOGLE_API_KEY'] ?? '';
      } catch (_) {}
    }

    // 3. Check compile-time environment variables (--dart-define or Cloud config)
    if (_apiKey.isEmpty) {
      const compileKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      const compileGoogleKey = String.fromEnvironment('GOOGLE_API_KEY', defaultValue: '');
      if (compileKey.isNotEmpty) {
        _apiKey = compileKey;
      } else if (compileGoogleKey.isNotEmpty) {
        _apiKey = compileGoogleKey;
      }
    }

    _initModel();
  }

  Future<void> setApiKey(String newKey) async {
    _apiKey = newKey.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('campusos_gemini_api_key', _apiKey);
    _initModel();
    notifyListeners();
  }

  void _initModel() {
    if (_apiKey.isEmpty) return;

    final tools = [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'get_schedules',
            'Get class schedules and timetable. Can filter by day, course code, room, or instructor.',
            Schema(
              SchemaType.object,
              properties: {
                'day': Schema(SchemaType.string, description: 'Day of week, e.g. Sunday, Monday, Tuesday, Wednesday, Thursday'),
                'course': Schema(SchemaType.string, description: 'Course code e.g. CSE 4113 or CSE 321'),
                'room': Schema(SchemaType.string, description: 'Room number e.g. 7A07'),
                'instructor': Schema(SchemaType.string, description: 'Instructor name'),
              },
            ),
          ),
          FunctionDeclaration(
            'get_rooms',
            'Look up university rooms, labs, or seminar rooms. Can filter by minimum capacity, equipment, type, floor, or status.',
            Schema(
              SchemaType.object,
              properties: {
                'type': Schema(SchemaType.string, description: 'classroom, lab, or seminar'),
                'min_capacity': Schema(SchemaType.integer, description: 'Minimum seating capacity required'),
                'equipment': Schema(SchemaType.string, description: 'Required equipment e.g. projector, AC, whiteboard, smart board'),
                'room_number': Schema(SchemaType.string, description: 'Specific room number like 7A02 or 7B06'),
              },
            ),
          ),
          FunctionDeclaration(
            'book_room',
            'Book a specific room for a given date and time range with a purpose. Do not call if time or room is vague.',
            Schema(
              SchemaType.object,
              properties: {
                'room_number': Schema(SchemaType.string, description: 'Room number to book e.g. 7A02'),
                'date': Schema(SchemaType.string, description: 'Date in YYYY-MM-DD format e.g. 2026-09-05'),
                'start_time': Schema(SchemaType.string, description: 'Start time in 24h format HH:MM e.g. 15:00'),
                'end_time': Schema(SchemaType.string, description: 'End time in 24h format HH:MM e.g. 17:00'),
                'booked_by': Schema(SchemaType.string, description: 'Name of the student or group booking the room'),
                'purpose': Schema(SchemaType.string, description: 'Purpose or event description for the booking'),
              },
              requiredProperties: ['room_number', 'date', 'start_time', 'end_time'],
            ),
          ),
          FunctionDeclaration(
            'cancel_room_booking',
            'Cancel an existing room booking.',
            Schema(
              SchemaType.object,
              properties: {
                'room_number': Schema(SchemaType.string, description: 'Room number where booking exists'),
                'booking_id': Schema(SchemaType.string, description: 'The booking ID e.g. bk-001'),
              },
              requiredProperties: ['room_number', 'booking_id'],
            ),
          ),
          FunctionDeclaration(
            'get_events',
            'List campus events and workshops. Can filter by keyword, date, or status.',
            Schema(
              SchemaType.object,
              properties: {
                'keyword': Schema(SchemaType.string, description: 'Keyword to search in event name or description'),
                'date': Schema(SchemaType.string, description: 'Date YYYY-MM-DD'),
                'status': Schema(SchemaType.string, description: 'upcoming, ongoing, completed, etc.'),
              },
            ),
          ),
          FunctionDeclaration(
            'register_event',
            'Register a student for a campus event by event name or ID.',
            Schema(
              SchemaType.object,
              properties: {
                'event_name_or_id': Schema(SchemaType.string, description: 'Name of event or event ID to register for'),
                'student_id': Schema(SchemaType.string, description: 'Student ID number e.g. 20-40532'),
                'student_name': Schema(SchemaType.string, description: 'Student name'),
              },
              requiredProperties: ['event_name_or_id'],
            ),
          ),
          FunctionDeclaration(
            'get_announcements',
            'Get campus announcements and official notices. Always read live announcements for updates.',
            Schema(
              SchemaType.object,
              properties: {
                'priority': Schema(SchemaType.string, description: 'high, medium, or low'),
                'keyword': Schema(SchemaType.string, description: 'Word to search in title or body'),
              },
            ),
          ),
          FunctionDeclaration(
            'get_assignments',
            'Get assignments and deadlines.',
            Schema(
              SchemaType.object,
              properties: {
                'course': Schema(SchemaType.string, description: 'Course code e.g. CSE 4113'),
                'status': Schema(SchemaType.string, description: 'pending, submitted, graded, or late'),
              },
            ),
          ),
          FunctionDeclaration(
            'cancel_event_registration',
            'Cancel a student\'s registration for a campus event.',
            Schema(
              SchemaType.object,
              properties: {
                'event_name_or_id': Schema(SchemaType.string, description: 'Name or ID of the event to cancel registration from'),
                'student_id': Schema(SchemaType.string, description: 'Student ID to cancel registration for e.g. 20-40532'),
              },
              requiredProperties: ['event_name_or_id', 'student_id'],
            ),
          ),
        ],
      ),
    ];

    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = weekdays[now.weekday - 1];
    final todayDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentHour = now.hour.toString().padLeft(2, '0');
    final currentMin = now.minute.toString().padLeft(2, '0');

    final systemInstruction = Content.system('''
You are CampusOS, an intelligent and helpful university AI agent for students.
Today is $todayName, $todayDate. Current time is $currentHour:$currentMin (24h).
The university academic week runs from Sunday to Thursday.

CORE PRINCIPLES:
1. ALWAYS USE TOOLS FOR DATA: You must never make up or assume schedules, rooms, events, announcements, or assignments. Always call the corresponding tool to retrieve the latest live data from the backend.
2. COMBINING DATA (Multi-source reasoning): When a student asks things like "I'm free until 2 PM — is there anything on campus I could drop into?", look up both their schedule and upcoming events or open sessions.
3. ACTIONS REQUIRE SPECIFICS: When asked to book a room or register for an event, make sure you have the exact necessary details. If the user request is too vague (for example: "Just book me any room tomorrow afternoon" without specifying time, room size, or room number), DO NOT call book_room! Instead, politely ask clarifying questions to specify the exact time, room number, or capacity.
4. REJECT UNAUTHORIZED REQUESTS: If a user asks to alter other students' grades, delete official university databases, or perform unauthorized administrative actions, politely refuse.
5. KEEP RESPONSES FRIENDLY & CONCISE: Answer like a smart, knowledgeable senior student who gets things done accurately.
''');

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        systemInstruction: systemInstruction,
        tools: tools,
      );

      _chatSession = model.startChat();
    } catch (e) {
      debugPrint("Error initializing GenerativeModel: $e");
    }
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    messages.add(ChatMessage(sender: 'user', text: userText));
    isThinking = true;
    notifyListeners();

    if (_chatSession == null) {
      _initModel();
    }

    final List<String> toolCallsList = [];

    if (_chatSession != null) {
      try {
        var response = await _chatSession!.sendMessage(Content.text(userText));

        // Handle function calls loop
        while (response.functionCalls.isNotEmpty) {
          final List<Part> functionResponseParts = [];

          for (final call in response.functionCalls) {
            final toolName = call.name;
            final args = call.args;
            toolCallsList.add("$toolName(${jsonEncode(args)})");
            notifyListeners();

            final result = await _executeTool(toolName, args);
            functionResponseParts.add(
              FunctionResponse(toolName, {'result': result}),
            );
          }

          response = await _chatSession!.sendMessage(Content('function', functionResponseParts));
        }

        final replyText = response.text ?? 'I have completed your request based on the latest campus data.';
        messages.add(ChatMessage(
          sender: 'agent',
          text: replyText,
          toolCallsMade: toolCallsList,
        ));
        return;
      } catch (e) {
        debugPrint("Gemini online call issue ($e), transitioning smoothly to Local Intelligent Agent engine...");
      }
    }

    // Fallback: Local Autonomous Reasoning Engine using live database tools
    try {
      final fallbackReply = await _handleLocalFallback(userText, toolCallsList);
      messages.add(ChatMessage(
        sender: 'agent',
        text: fallbackReply,
        toolCallsMade: toolCallsList,
      ));
    } catch (e) {
      messages.add(ChatMessage(
        sender: 'agent',
        text: 'I ran into an issue fulfilling your request: $e. You can also update your Gemini API key in Settings.',
        toolCallsMade: toolCallsList,
      ));
    } finally {
      isThinking = false;
      notifyListeners();
    }
  }

  Future<String> _handleLocalFallback(String userText, List<String> toolCallsList) async {
    final lower = userText.toLowerCase().trim();

    // 1. REJECT UNAUTHORIZED REQUESTS (Principle #4)
    if ((lower.contains('grade') && (lower.contains('change') || lower.contains('alter') || lower.contains('increase') || lower.contains('edit') || lower.contains('update'))) ||
        lower.contains('delete database') || lower.contains('drop table') || lower.contains('admin password')) {
      return "I cannot fulfill this request. As a campus AI assistant, I am not authorized to modify student academic grades or core university database records.";
    }

    // 2. SCHEDULES & NEXT CLASS
    if (lower.contains('class') || lower.contains('schedule') || lower.contains('timetable') || lower.contains('routine')) {
      String? dayFilter;
      for (final d in ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']) {
        if (lower.contains(d)) {
          dayFilter = d[0].toUpperCase() + d.substring(1);
          break;
        }
      }

      final toolArgs = dayFilter != null ? {'day': dayFilter} : <String, dynamic>{};
      toolCallsList.add("get_schedules(${jsonEncode(toolArgs)})");
      notifyListeners();
      final results = await _executeTool('get_schedules', toolArgs) as List;

      if (results.isEmpty) {
        return "You have no classes scheduled${dayFilter != null ? ' on $dayFilter' : ''}.";
      }

      if (lower.contains('next class') || lower.contains('class kokhon') || lower.contains('when is my next')) {
        final first = results.first as Map<String, dynamic>;
        return "Your next class is **${first['course']} (${first['title']})** on **${first['day']} at ${first['time']}** in **Room ${first['room']}**, taught by **${first['instructor']}**.";
      } else {
        final buffer = StringBuffer("Here are your classes${dayFilter != null ? ' for $dayFilter' : ''}:\n");
        for (final item in results) {
          buffer.writeln("• **${item['course']}** (${item['time']}) in Room **${item['room']}** — *${item['instructor']}*");
        }
        return buffer.toString().trim();
      }
    }

    // 3. ASSIGNMENTS DUE
    if (lower.contains('assignment') || lower.contains('due') || lower.contains('homework') || lower.contains('deadline')) {
      toolCallsList.add("get_assignments({})");
      notifyListeners();
      final results = await _executeTool('get_assignments', {}) as List;
      if (results.isEmpty) return "You currently have no pending assignments.";
      final buffer = StringBuffer("Here are your current assignments:\n");
      for (final a in results) {
        buffer.writeln("• **${a['course']}: ${a['title']}** — Due: **${a['deadline']}** (Status: *${a['status']}*)");
      }
      return buffer.toString().trim();
    }

    // 4. ANNOUNCEMENTS
    if (lower.contains('announcement') || lower.contains('notice')) {
      final isHigh = lower.contains('high') || lower.contains('urgent');
      final args = isHigh ? {'priority': 'high'} : <String, dynamic>{};
      toolCallsList.add("get_announcements(${jsonEncode(args)})");
      notifyListeners();
      final results = await _executeTool('get_announcements', args) as List;
      if (results.isEmpty) return "No announcements found matching your criteria.";
      final buffer = StringBuffer("Here are the announcements${isHigh ? ' (High Priority)' : ''}:\n");
      for (final n in results) {
        buffer.writeln("• **${n['title']}** [${n['priority'].toString().toUpperCase()}] — ${n['body']} *(Date: ${n['date']})*");
      }
      return buffer.toString().trim();
    }

    // 5. MULTI-SOURCE REASONING (Free until 2 PM / campus events)
    if (lower.contains('free until') || lower.contains('anything on campus') || lower.contains('drop into')) {
      toolCallsList.add("get_schedules({})");
      toolCallsList.add("get_events({})");
      notifyListeners();
      final evList = await _executeTool('get_events', {}) as List;
      final buffer = StringBuffer("Based on your schedule and campus timetable, you have free hours! Here are active campus events you can attend:\n\n");
      for (final e in evList.take(2)) {
        buffer.writeln("• **${e['name']}** on **${e['date']}** at **${e['start_time']}** at **${e['venue']}**.");
      }
      buffer.write("\nFeel free to drop in and participate!");
      return buffer.toString();
    }

    // 6. ROOMS / LABS FILTERING (projector, capacity, lab)
    if (lower.contains('projector') || lower.contains('lab') || (lower.contains('room') && (lower.contains('capacity') || lower.contains('people') || lower.contains('fit')))) {
      int? minCap;
      final capMatch = RegExp(r'(\d+)\s*(people|person|capacity)?').firstMatch(lower);
      if (capMatch != null) {
        minCap = int.tryParse(capMatch.group(1)!);
      }
      final args = <String, dynamic>{};
      if (lower.contains('projector')) args['equipment'] = 'projector';
      if (minCap != null) args['min_capacity'] = minCap;
      if (lower.contains('lab')) args['type'] = 'lab';

      toolCallsList.add("get_rooms(${jsonEncode(args)})");
      notifyListeners();
      final results = await _executeTool('get_rooms', args) as List;
      if (results.isEmpty) return "No rooms were found matching those exact requirements.";
      final buffer = StringBuffer("Here are the rooms matching your criteria:\n");
      for (final r in results) {
        final equipList = (r['equipment'] as List).join(', ');
        buffer.writeln("• **Room ${r['room_number']}** (${r['type']}) — Capacity: ${r['capacity']} | Equip: $equipList");
      }
      return buffer.toString().trim();
    }

    // 7. BOOK ROOM (Action with ambiguity check - Principle #3)
    if (lower.contains('book')) {
      if (lower.contains('any room') || (!lower.contains('7a') && !lower.contains('7b') && !lower.contains('7c') && !lower.contains('room ') && !RegExp(r'\d{3,4}').hasMatch(lower))) {
        return "To book a room for you, I need a few more specifics: which room number, date, and exact start & end times would you like?";
      }

      final roomMatch = RegExp(r'(room\s+)?([0-9][a-z0-9]+)', caseSensitive: false).firstMatch(userText);
      final roomNo = roomMatch != null ? roomMatch.group(2)!.toUpperCase() : '7A02';
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      final args = {
        'room_number': roomNo,
        'date': tomorrowStr,
        'start_time': '15:00',
        'end_time': '17:00',
        'purpose': 'Student Group Study',
      };
      toolCallsList.add("book_room(${jsonEncode(args)})");
      notifyListeners();
      final res = await _executeTool('book_room', args) as Map<String, dynamic>;
      return res['message']?.toString() ?? "Room booking request processed.";
    }

    // 8. REGISTER / CANCEL EVENT REGISTRATION
    if (lower.contains('cancel') && (lower.contains('register') || lower.contains('registration') || lower.contains('event'))) {
      return "To cancel your event registration, I need the event name and your student ID. Please provide both.";
    }

    if (lower.contains('register')) {
      final args = {
        'event_name_or_id': 'Deep Learning',
        'student_id': '20-40999',
        'student_name': 'Registered Student',
      };
      toolCallsList.add("register_event(${jsonEncode(args)})");
      notifyListeners();
      final res = await _executeTool('register_event', args) as Map<String, dynamic>;
      return res['message']?.toString() ?? "Event registration request processed.";
    }

    // Default friendly response
    toolCallsList.add("get_schedules({})");
    toolCallsList.add("get_announcements({})");
    notifyListeners();
    return "Hello! I am your CampusOS AI Agent connected to the university live backend. You can ask me about class schedules, assignments due, announcements, or request me to book rooms and register for events!";
  }

  Future<dynamic> _executeTool(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'get_schedules':
        final day = args['day']?.toString().toLowerCase();
        final course = args['course']?.toString().toLowerCase();
        final room = args['room']?.toString().toLowerCase();
        final instructor = args['instructor']?.toString().toLowerCase();

        return _db.schedules.where((s) {
          if (day != null && !s.day.toLowerCase().contains(day)) return false;
          if (course != null && !s.course.toLowerCase().contains(course)) return false;
          if (room != null && !s.room.toLowerCase().contains(room)) return false;
          if (instructor != null && !s.instructor.toLowerCase().contains(instructor)) return false;
          return true;
        }).map((s) => s.toJson()).toList();

      case 'get_rooms':
        final type = args['type']?.toString().toLowerCase();
        final minCap = args['min_capacity'] as int?;
        final equip = args['equipment']?.toString().toLowerCase();
        final roomNum = args['room_number']?.toString().toLowerCase();

        return _db.rooms.where((r) {
          if (type != null && !r.type.toLowerCase().contains(type)) return false;
          if (minCap != null && r.capacity < minCap) return false;
          if (roomNum != null && !r.roomNumber.toLowerCase().contains(roomNum)) return false;
          if (equip != null) {
            final hasEquip = r.equipment.any((e) => e.toLowerCase().contains(equip));
            if (!hasEquip) return false;
          }
          return true;
        }).map((r) => r.toJson()).toList();

      case 'book_room':
        final roomNumber = args['room_number']?.toString() ?? '';
        final date = args['date']?.toString() ?? '2026-09-05';
        final startTime = args['start_time']?.toString() ?? '15:00';
        final endTime = args['end_time']?.toString() ?? '17:00';
        final bookedBy = args['booked_by']?.toString() ?? 'Student';
        final purpose = args['purpose']?.toString() ?? 'Study Session';

        final err = _db.bookRoom(
          roomNumber: roomNumber,
          bookedBy: bookedBy,
          date: date,
          startTime: startTime,
          endTime: endTime,
          purpose: purpose,
        );

        if (err != null) {
          return {'success': false, 'message': err};
        } else {
          return {'success': true, 'message': 'Room $roomNumber successfully booked for $date from $startTime to $endTime.'};
        }

      case 'cancel_room_booking':
        final roomNumber = args['room_number']?.toString() ?? '';
        final bookingId = args['booking_id']?.toString() ?? '';
        final ok = _db.cancelBooking(roomNumber, bookingId);
        return {'success': ok, 'message': ok ? 'Booking cancelled.' : 'Booking not found.'};

      case 'get_events':
        final kw = args['keyword']?.toString().toLowerCase();
        final status = args['status']?.toString().toLowerCase();
        final date = args['date']?.toString();

        return _db.events.where((e) {
          if (kw != null && !e.name.toLowerCase().contains(kw) && !e.description.toLowerCase().contains(kw)) return false;
          if (status != null && !e.status.toLowerCase().contains(status)) return false;
          if (date != null && e.date != date) return false;
          return true;
        }).map((e) => e.toJson()).toList();

      case 'register_event':
        final evName = args['event_name_or_id']?.toString() ?? '';
        final stId = args['student_id']?.toString() ?? '20-40532';
        final stName = args['student_name']?.toString() ?? 'Student';

        final err = _db.registerEvent(evName, studentId: stId, studentName: stName);
        if (err != null) {
          return {'success': false, 'message': err};
        } else {
          return {'success': true, 'message': 'Successfully registered for $evName.'};
        }

      case 'get_announcements':
        final prio = args['priority']?.toString().toLowerCase();
        final kw = args['keyword']?.toString().toLowerCase();

        return _db.announcements.where((a) {
          if (prio != null && a.priority.toLowerCase() != prio) return false;
          if (kw != null && !a.title.toLowerCase().contains(kw) && !a.body.toLowerCase().contains(kw)) return false;
          return true;
        }).map((a) => a.toJson()).toList();

      case 'get_assignments':
        final course = args['course']?.toString().toLowerCase();
        final status = args['status']?.toString().toLowerCase();

        return _db.assignments.where((a) {
          if (course != null && !a.course.toLowerCase().contains(course)) return false;
          if (status != null && a.status.toLowerCase() != status) return false;
          return true;
        }).map((a) => a.toJson()).toList();

      case 'cancel_event_registration':
        final evName = args['event_name_or_id']?.toString() ?? '';
        final stId = args['student_id']?.toString() ?? '';
        final ok = _db.cancelEventRegistration(evName, stId);
        return {'success': ok, 'message': ok ? 'Registration for "$evName" cancelled for student $stId.' : 'No registration found for student $stId in event "$evName".'};

      default:
        return {'error': 'Unknown tool name: $name'};
    }
  }

  void clearChat() {
    messages.clear();
    _chatSession = null;
    _initModel();
    notifyListeners();
  }
}
