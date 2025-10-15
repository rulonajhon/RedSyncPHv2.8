/*
 * AI-Powered Emergency Guidance System - OPTIMIZED VERSION
 * 
 * ✅ STREAMLINED & CONTEXTUAL GUIDANCE:
 * 
 * 1. ENHANCED AI PROMPTING:
 *    - Considers date/time, body region, severity level, and additional notes
 *    - Generates SHORT, actionable advice (2-3 items per section)  
 *    - Focuses on ESSENTIAL steps for specific episodes
 *    - Medical accuracy through specialized hemophilia prompts
 * 
 * 2. COMPACT USER INTERFACE:
 *    - Reduced padding and font sizes for mobile optimization
 *    - Horizontal header layout with AI indicators
 *    - Single "Got it" button (removed emergency help button)
 *    - Streamlined sections: Actions → First Aid → Seek Help → Monitor
 * 
 * 3. CONTEXTUAL INTELLIGENCE:
 *    - Date/time consideration for appropriate care timing
 *    - Body region specific advice (joints vs muscles vs head)
 *    - Severity-appropriate urgency levels with color coding
 *    - Patient notes integration for personalized responses
 * 
 * EXAMPLE API REQUEST TO OPENAI:
 * 
 * {
 *   "model": "gpt-4o-mini",
 *   "messages": [
 *     {
 *       "role": "system",
 *       "content": "You are an AI medical assistant specializing in hemophilia emergency care..."
 *     },
 *     {
 *       "role": "user", 
 *       "content": "BLEEDING EPISODE DETAILS:
 *                  - Severity: Moderate
 *                  - Body Region: Left knee joint
 *                  - Date/Time: 2025-10-13 15:30:00
 *                  - Additional Notes: Fell during basketball, immediate swelling
 *                  
 *                  Please provide specific emergency guidance for this hemophilia bleeding episode."
 *     }
 *   ],
 *   "response_format": {"type": "json_object"},
 *   "temperature": 0.3
 * }
 * 
 * OPTIMIZED AI RESPONSE (CONCISE FORMAT):
 * 
 * {
 *   "urgency_level": "moderate",
 *   "immediate_actions": [
 *     "Stop activity immediately - this is a joint bleed",
 *     "Apply ice for 15-20 minutes, elevate leg"
 *   ],
 *   "first_aid_steps": [
 *     "No weight on affected leg until swelling stops",
 *     "Take prescribed clotting factor if available"
 *   ],
 *   "when_to_seek_help": [
 *     "If swelling increases significantly in 2 hours",
 *     "If unable to bear any weight on leg"
 *   ],
 *   "key_monitoring": [
 *     "Watch for numbness or tingling in foot",
 *     "Monitor knee size every hour for 6 hours"
 *   ],
 *   "estimated_recovery_time": "3-7 days with proper care",
 *   "ai_confidence": "94%"
 * }
 * 
 * KEY OPTIMIZATIONS:
 * ✅ Shorter instructions (under 15 words each)
 * ✅ Reduced sections (6 instead of 10+)
 * ✅ Essential-only guidance
 * ✅ Context-aware timing considerations
 * ✅ Mobile-optimized compact UI
 * 
 * IMPLEMENTATION FEATURES:
 * 
 * ✅ Loading indicator while AI generates response
 * ✅ Fallback to static guidance if AI fails
 * ✅ Visual indicators for AI-generated content  
 * ✅ Confidence scoring display
 * ✅ Enhanced sections (monitoring, follow-up, risk factors)
 * ✅ Context-aware advice based on activity and timing
 * ✅ Medical accuracy through specialized prompting
 * ✅ Emergency contact integration
 * ✅ Severity-appropriate urgency levels
 * ✅ Professional medical disclaimer
 * 
 * USAGE IN APP:
 * 
 * 1. User logs bleeding episode with details
 * 2. System calls AIEmergencyService.generateEmergencyGuidance()
 * 3. Shows loading spinner while AI processes
 * 4. Displays personalized guidance with AI indicators
 * 5. Includes confidence score and enhanced medical sections
 * 6. Falls back to static guidance if AI unavailable
 * 
 * SECURITY:
 * 
 * - API key stored in .env file (not committed to version control)
 * - Rate limiting and error handling
 * - Medical disclaimers and emergency contact prominence
 * - No patient data stored externally (only sent for guidance generation)
 */

// This file serves as documentation for the AI Emergency Guidance System
// The actual implementation is in:
// - lib/services/ai_emergency_service.dart
// - Enhanced guidance modals in log_bleed.dart and log_bleed_new.dart
