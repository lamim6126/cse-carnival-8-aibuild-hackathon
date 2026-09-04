import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_os/services/gemini_agent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('GeminiAgentService updates and stores API key dynamically via settings', () async {
    SharedPreferences.setMockInitialValues({});
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
}
