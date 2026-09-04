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

  test('GeminiAgentService updates and stores API key dynamically via settings', () async {
    final service = GeminiAgentService();
    await service.setApiKey('test_key_12345');
    expect(service.apiKey, equals('test_key_12345'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('campusos_gemini_api_key'), equals('test_key_12345'));
  });

  test('GeminiAgentService clears chat and handles empty key gracefully', () async {
    final service = GeminiAgentService();
    service.clearChat();
    expect(service.messages, isEmpty);
    expect(service.isThinking, isFalse);
  });

  test('GeminiAgentService handles queries via intelligent fallback and executes tools', () async {
    final service = GeminiAgentService();
    service.clearChat();

    await service.sendMessage('next class kokhon?');
    expect(service.messages.length, equals(2));
    expect(service.messages.last.sender, equals('agent'));
    expect(service.messages.last.text, contains('next class'));
    expect(service.messages.last.toolCallsMade, isNotEmpty);
    expect(service.messages.last.toolCallsMade.first, contains('get_schedules'));
  });
}
