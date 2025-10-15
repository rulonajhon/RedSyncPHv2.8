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
    List<Map<String, String>> chatHistory, {
    String? userName,
    bool? isGuest,
  }) async {
    try {
      if (_apiKey == null ||
          _apiKey!.isEmpty ||
          _apiKey == 'your_openai_api_key_here') {
        print('❌ OpenAI API key not configured');
        throw Exception(
            'OpenAI service not initialized or API key not configured');
      }

      print('🤖 OpenAI: Making API request...');

      // Create personalized system message with hemophilia context and multilingual support
      final userInfo = userName != null && userName.isNotEmpty && !(isGuest == true)
          ? "You are speaking with $userName. Address them by name when appropriate to make the conversation more personal and engaging."
          : "You are speaking with a user. Be warm and friendly in your responses.";
      
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content':
              '''You are HemoAssistant, an AI assistant specialized in hemophilia care and management. 
        You provide helpful, accurate information about hemophilia, its symptoms, treatments, lifestyle management, 
        and support resources. Always encourage users to consult with their healthcare providers for medical advice. 
        Be empathetic, supportive, and provide evidence-based information.
        
        PERSONALIZATION: $userInfo
        
        IMPORTANT: You must support and respond fluently in multiple languages, particularly:
        - English
        - Tagalog/Filipino (for Philippine users)
        - Bisaya/Cebuano (for Davao City and Visayas region users)
        
        Language Guidelines:
        - Automatically detect the language of the user's input
        - Respond in the same language the user is using
        - If the user mixes languages, respond appropriately in the predominant language
        - For Bisaya users, use natural Cebuano/Bisaya dialect commonly spoken in Davao City
        - For Tagalog users, use Filipino/Tagalog that's easily understood
        - Maintain medical accuracy across all languages
        - Use culturally appropriate expressions and context
        
        Key areas you can help with:
        - Hemophilia types (A, B, C) and severity levels (Mga uri ng hemophilia)
        - Factor replacement therapy (Pagpapalit ng factor)
        - Bleeding prevention and management (Pagpigil sa pagdurugo)
        - Exercise and activity recommendations (Mga rekomendasyon sa ehersisyo)
        - Diet and nutrition (Pagkain at nutrisyon)
        - Emergency situations (Mga emergency na sitwasyon)
        - Emotional support and coping strategies (Emosyonal na suporta)
        - Insurance and financial resources (Insurance at pinansyal na tulong)
        
        Common Bisaya/Cebuano medical terms to use:
        - "Sakit" (disease/illness)
        - "Tambal" (medicine/treatment) 
        - "Dugo" (blood)
        - "Masakiton" (sickly person)
        - "Tambalan" (to treat/cure)
        - "Doktor" (doctor)
        - "Ospital" (hospital)
        - "Ayaw kabalaka" (don't worry)
        - "Pangutana" (question)
        - "Tubag" (answer)
        - "Tabang" (help)
        - "Kaayohan" (wellness/health)
        
        Davao City Healthcare Context:
        - Be aware that users are primarily from Davao City and surrounding areas
        - Reference Philippine healthcare system when relevant
        - Mention PhilHealth coverage for hemophilia treatments
        - Acknowledge the challenges of accessing specialized care in Mindanao
        - Be sensitive to economic constraints common in the region
        - Suggest local resources when appropriate (hospitals in Davao City)
        
        Cultural Sensitivity:
        - Use respectful and empathetic tone appropriate to Filipino culture
        - Acknowledge family-centered healthcare decisions common in the Philippines
        - Be understanding of traditional medicine practices alongside modern treatment
        - Show awareness of the importance of community support in Filipino culture
        
        Always remind users that your advice doesn't replace professional medical consultation.
        In Bisaya: "Hinumdomi nga ang akong tambag dili makapuli sa konsultasyon sa doktor."
        In Tagalog: "Tandaan na ang aking payo ay hindi makapapalit sa konsultasyon sa doktor."''',
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
