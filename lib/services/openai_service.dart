import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static String? _apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1';

  static Future<void> initialize() async {
    try {
      // Don't load dotenv here since it's already loaded in main.dart
      _apiKey = dotenv.env['OPENAI_API_KEY'];

      if (_apiKey == null ||
          _apiKey!.isEmpty ||
          _apiKey == 'your_openai_api_key_here') {
        print('⚠️ OpenAI API key not found or not configured in .env file');
        throw Exception(
          'OpenAI API key not found or not configured in .env file',
        );
      }

      print('✅ OpenAI service initialized successfully');
    } catch (e) {
      print('❌ OpenAI initialization failed: $e');
      throw e;
    }
  }

  static Future<String> generateResponse(
    String prompt,
    List<Map<String, String>> chatHistory,
  ) async {
    try {
      if (_apiKey == null ||
          _apiKey!.isEmpty ||
          _apiKey == 'your_openai_api_key_here') {
        print('❌ OpenAI API key not configured');
        throw Exception(
            'OpenAI service not initialized or API key not configured');
      }

      print('🤖 OpenAI: Making API request...');

      // Create system message with hemophilia context
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content':
              '''You are HemoAssistant, an AI assistant specialized in hemophilia care and management. 
        You provide helpful, accurate information about hemophilia, its symptoms, treatments, lifestyle management, 
        and support resources. Always encourage users to consult with their healthcare providers for medical advice. 
        Be empathetic, supportive, and provide evidence-based information.
        
        Key areas you can help with:
        - Hemophilia types (A, B, C) and severity levels
        - Factor replacement therapy
        - Bleeding prevention and management
        - Exercise and activity recommendations
        - Diet and nutrition
        - Emergency situations
        - Emotional support and coping strategies
        - Insurance and financial resources
        
        Always remind users that your advice doesn't replace professional medical consultation.''',
        },
        ...chatHistory,
        {'role': 'user', 'content': prompt},
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': messages,
          'max_tokens': 800,
          'temperature': 0.3,
        }),
      );

      print('🤖 OpenAI: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('✅ OpenAI: Response generated successfully');
        return content;
      } else {
        print('❌ OpenAI API Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception(
          'I apologize, but I\'m having trouble connecting right now. Please check your internet connection and try again. If the problem persists, you may need to verify your API configuration.',
        );
      }
    } catch (e) {
      print('❌ OpenAI Exception: $e');
      if (e.toString().contains('API key') ||
          e.toString().contains('configuration')) {
        return 'I apologize, but I\'m having trouble connecting right now. Please check your internet connection and try again. If the problem persists, you may need to verify your API configuration.';
      }
      throw Exception(
          'I apologize, but I\'m having trouble connecting right now. Please check your internet connection and try again. If the problem persists, you may need to verify your API configuration.');
    }
  }
}
