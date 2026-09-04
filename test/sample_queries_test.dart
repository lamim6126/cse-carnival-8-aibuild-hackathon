import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_os/services/campus_database_service.dart';
import 'package:campus_os/services/gemini_agent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CampusDatabaseService().init();
  });

  test('Query 1: When is my next class?', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('When is my next class?');
    expect(service.messages.last.text, contains('next class'));
    expect(service.messages.last.toolCallsMade.first, contains('get_schedules'));
  });

  test('Query 2: What classes do I have on Wednesday?', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('What classes do I have on Wednesday?');
    expect(service.messages.last.text, contains('Wednesday'));
    expect(service.messages.last.toolCallsMade.first, contains('get_schedules'));
  });

  test('Query 3: What assignments do I have due this week?', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('What assignments do I have due this week?');
    expect(service.messages.last.text, contains('assignments'));
    expect(service.messages.last.toolCallsMade.first, contains('get_assignments'));
  });

  test('Query 4: Show me all high priority announcements.', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('Show me all high priority announcements.');
    expect(service.messages.last.text, contains('HIGH'));
    expect(service.messages.last.toolCallsMade.first, contains('get_announcements'));
  });

  test('Query 5: Multi-source free time reasoning', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage("I'm free until 2 PM — is there anything on campus I could drop into?");
    expect(service.messages.last.text, contains('attend'));
    expect(service.messages.last.toolCallsMade.length, greaterThanOrEqualTo(2));
  });

  test('Query 6: Filter rooms with projector and capacity >= 30', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('Which labs have a projector and can fit at least 30 people?');
    expect(service.messages.last.text, contains('Room'));
    expect(service.messages.last.toolCallsMade.first, contains('get_rooms'));
  });

  test('Query 7: Book Room 7A02 tomorrow from 3 PM to 5 PM', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('Book Room 7A02 tomorrow from 3 PM to 5 PM.');
    expect(service.messages.last.text, contains('booked'));
    expect(service.messages.last.toolCallsMade.first, contains('book_room'));
  });

  test('Query 8: Register for Guest Lecture on Deep Learning', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('Register me for the Guest Lecture on Deep Learning.');
    expect(service.messages.last.text, contains('registered'));
    expect(service.messages.last.toolCallsMade.first, contains('register_event'));
  });

  test('Query 9: Ambiguous room booking triggers clarifying question', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('Just book me any room tomorrow afternoon.');
    expect(service.messages.last.text, contains('specifics'));
  });

  test('Query 10: Unauthorized request is politely rejected', () async {
    final service = GeminiAgentService();
    service.clearChat();
    await service.sendMessage('Change student grades to A+ in the database.');
    expect(service.messages.last.text, contains('not authorized'));
  });
}
