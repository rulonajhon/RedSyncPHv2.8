import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIEmergencyService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Get API key from environment variables for security
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Generate AI-powered emergency guidance for bleeding episodes
  static Future<Map<String, dynamic>> generateEmergencyGuidance({
    required String severity,
    required String bodyRegion,
    required String notes,
    required DateTime dateTime,
    String? patientAge,
    String? patientWeight,
    List<String>? medications,
    String? medicalHistory,
  }) async {
    try {
      // Build comprehensive context for the AI
      final context = _buildPromptContext(
        severity: severity,
        bodyRegion: bodyRegion,
        notes: notes,
        dateTime: dateTime,
        patientAge: patientAge,
        patientWeight: patientWeight,
        medications: medications,
        medicalHistory: medicalHistory,
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Using cost-effective model
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': context,
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.3, // Low temperature for medical accuracy
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        final guidanceData = jsonDecode(aiResponse);

        return _formatAIResponse(guidanceData, severity);
      } else {
        print('OpenAI API Error: ${response.statusCode} - ${response.body}');
        return _getFallbackGuidance(severity, bodyRegion);
      }
    } catch (e) {
      print('AI Emergency Service Error: $e');
      return _getFallbackGuidance(severity, bodyRegion);
    }
  }

  /// Build detailed context for AI prompt
  static String _buildPromptContext({
    required String severity,
    required String bodyRegion,
    required String notes,
    required DateTime dateTime,
    String? patientAge,
    String? patientWeight,
    List<String>? medications,
    String? medicalHistory,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('BLEEDING EPISODE DETAILS:');
    buffer.writeln('- Severity: $severity');
    buffer.writeln('- Body Region: $bodyRegion');
    buffer.writeln('- Date/Time: ${dateTime.toString()}');
    buffer.writeln('- Additional Notes: ${notes.isEmpty ? "None" : notes}');

    if (patientAge != null) buffer.writeln('- Patient Age: $patientAge');
    if (patientWeight != null)
      buffer.writeln('- Patient Weight: $patientWeight');

    if (medications != null && medications.isNotEmpty) {
      buffer.writeln('- Current Medications: ${medications.join(", ")}');
    }

    if (medicalHistory != null && medicalHistory.isNotEmpty) {
      buffer.writeln('- Medical History: $medicalHistory');
    }

    buffer.writeln(
        '\nPlease provide specific emergency guidance for this hemophilia bleeding episode.');

    return buffer.toString();
  }

  /// System prompt for medical accuracy and structure
  static String _getSystemPrompt() {
    return '''You are an AI medical assistant specializing in hemophilia emergency care. Provide concise, targeted first aid guidance for bleeding episodes.

CRITICAL REQUIREMENTS:
- Keep advice SHORT and ACTIONABLE (2-3 items per section)
- Prioritize IMMEDIATE actions based on severity and location
- Consider time of day, body region, and patient notes
- Focus on ESSENTIAL steps only
- Always include clear medical help indicators

RESPONSE FORMAT (JSON):
{
  "urgency_level": "low|moderate|high|critical",
  "immediate_actions": ["2-3 essential immediate steps"],
  "first_aid_steps": ["2-3 core treatment steps"],
  "when_to_seek_help": ["2-3 clear warning signs"],
  "key_monitoring": ["1-2 critical things to watch"],
  "estimated_recovery_time": "brief timeframe",
  "ai_confidence": "percentage"
}

Keep each instruction under 15 words. Focus on what matters most for THIS specific episode.''';
  }

  /// Format AI response into app-compatible structure
  static Map<String, dynamic> _formatAIResponse(
      Map<String, dynamic> aiData, String severity) {
    // Determine UI colors based on AI urgency assessment
    final urgencyLevel = aiData['urgency_level'] ?? 'moderate';
    final urgencyColor = _getUrgencyColor(urgencyLevel);
    final urgencyIcon = _getUrgencyIcon(urgencyLevel);

    return {
      'urgencyColor': urgencyColor,
      'icon': urgencyIcon,
      'title': _getUrgencyTitle(urgencyLevel, severity),
      'subtitle': _getUrgencySubtitle(urgencyLevel),
      'immediateActions': List<String>.from(aiData['immediate_actions'] ?? []),
      'firstAidSteps': List<String>.from(aiData['first_aid_steps'] ?? []),
      'whenToSeekHelp': List<String>.from(aiData['when_to_seek_help'] ?? []),
      'additionalTips': List<String>.from(aiData['key_monitoring'] ?? []),
      'estimatedRecovery': aiData['estimated_recovery_time'] ?? 'Variable',
      'aiGenerated': true,
      'confidence': aiData['ai_confidence'] ?? '95%',
    };
  }

  /// Get urgency color based on AI assessment
  static dynamic _getUrgencyColor(String urgencyLevel) {
    switch (urgencyLevel) {
      case 'critical':
        return const Color(0xFFD32F2F); // Red
      case 'high':
        return const Color(0xFFF57C00); // Orange
      case 'moderate':
        return const Color(0xFFFBC02D); // Yellow
      case 'low':
        return const Color(0xFF388E3C); // Green
      default:
        return const Color(0xFFF57C00); // Orange default
    }
  }

  /// Get urgency icon based on AI assessment
  static dynamic _getUrgencyIcon(String urgencyLevel) {
    switch (urgencyLevel) {
      case 'critical':
        return Icons.medical_services;
      case 'high':
        return Icons.warning;
      case 'moderate':
        return Icons.info;
      case 'low':
        return Icons.healing;
      default:
        return Icons.info;
    }
  }

  /// Get urgency title
  static String _getUrgencyTitle(String urgencyLevel, String severity) {
    final severityUpper = severity.toUpperCase();
    switch (urgencyLevel) {
      case 'critical':
        return 'CRITICAL - $severityUpper Bleeding';
      case 'high':
        return 'HIGH PRIORITY - $severityUpper Bleeding';
      case 'moderate':
        return 'MODERATE - $severityUpper Bleeding';
      case 'low':
        return 'MILD - $severityUpper Bleeding';
      default:
        return '$severityUpper Bleeding Episode';
    }
  }

  /// Get urgency subtitle
  static String _getUrgencySubtitle(String urgencyLevel) {
    switch (urgencyLevel) {
      case 'critical':
        return 'Seek immediate emergency medical attention';
      case 'high':
        return 'Requires prompt medical evaluation';
      case 'moderate':
        return 'Monitor closely and follow guidance';
      case 'low':
        return 'Apply first aid and monitor symptoms';
      default:
        return 'AI-generated personalized guidance';
    }
  }

  /// Fallback guidance when AI is unavailable
  static Map<String, dynamic> _getFallbackGuidance(
      String severity, String bodyRegion) {
    // Return basic guidance structure as fallback
    return {
      'urgencyColor': _getUrgencyColor('moderate'),
      'icon': _getUrgencyIcon('moderate'),
      'title': '${severity.toUpperCase()} Bleeding Episode',
      'subtitle': 'Essential guidance',
      'immediateActions': [
        'Stop activity and rest immediately',
        'Apply ice wrapped in cloth for 15-20 minutes',
      ],
      'firstAidSteps': [
        'Keep affected area elevated when possible',
        'Take prescribed clotting factor if available',
      ],
      'whenToSeekHelp': [
        'If bleeding persists beyond 30 minutes',
        'If pain or swelling increases significantly',
      ],
      'additionalTips': [
        'Monitor for changes in color or temperature',
      ],
      'estimatedRecovery': 'Depends on severity and location',
      'aiGenerated': false,
      'confidence': 'N/A',
    };
  }
}
