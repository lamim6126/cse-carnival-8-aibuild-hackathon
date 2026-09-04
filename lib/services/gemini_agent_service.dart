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
        ],
      ),
    ];

    final systemInstruction = Content.system('''
You are CampusOS, an intelligent and helpful university AI agent for students.
Today's date is Friday, September 4, 2026. Current time is approximately 16:00 (4:00 PM).
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

    if (_chatSession == null) {
      messages.add(ChatMessage(
        sender: 'agent',
        text: 'Please set a valid Gemini API Key in Settings to enable the AI Agent.',
      ));
      isThinking = false;
      notifyListeners();
      return;
    }

    final List<String> toolCallsList = [];

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
    } catch (e) {
      debugPrint("Error in AI Agent chat: $e");
      messages.add(ChatMessage(
        sender: 'agent',
        text: 'I ran into an issue contacting the campus AI service: $e. You can verify your API key in Settings.',
        toolCallsMade: toolCallsList,
      ));
    } finally {
      isThinking = false;
      notifyListeners();
    }
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
