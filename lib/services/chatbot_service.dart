import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatbotService {
  // Replace with your actual Gemini API key
  static const String _apiKey = 'AIzaSyAomApJ4vZvjA1yUZSsvo0oWcMCsNM2jJA';
  
  // Updated API endpoint with correct model name
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  Future<String> getBotResponse(String userMessage, List<ChatMessage> chatHistory) async {
    try {
      // Validate API key
      if (_apiKey == 'AIzaSyAomApJ4vZvjA1yUZSsvo0oWcMCsNM2jJAE' || _apiKey.isEmpty) {
        return _getFallbackResponse(userMessage);
      }

      // Create context for bus-related queries
      String context = '''
You are BusBot, a helpful assistant for BusSeva - a smart bus booking and tracking app in India. 
You help users with:
- Bus routes and schedules
- Ticket booking guidance  
- Live bus tracking
- Transit information
- App features and usage
- Bus fare information
- Safety tips while traveling

Keep responses helpful, concise (under 100 words), and related to public transportation in India.
User query: $userMessage
''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': context}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 100,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      print('Making API request to: $_baseUrl?key=***');
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final botResponse = candidate['content']['parts'][0]['text'];
            return botResponse?.toString() ?? _getFallbackResponse(userMessage);
          }
        }
        
        return _getFallbackResponse(userMessage);
      } else if (response.statusCode == 400) {
        print('Bad request error: ${response.body}');
        return _getFallbackResponse(userMessage);
      } else if (response.statusCode == 403) {
        print('API access denied: ${response.body}');
        return 'API access issue. Using offline responses.';
      } else if (response.statusCode == 404) {
        print('Model not found: ${response.body}');
        return _getFallbackResponse(userMessage);
      } else {
        print('HTTP Error ${response.statusCode}: ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Chatbot error details: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  // Enhanced fallback responses for common queries
  String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Greeting responses
    if (message.contains('hello') || message.contains('hi') || message.contains('hey') || 
        message.contains('namaste') || message.contains('good morning') || 
        message.contains('good evening') || message.contains('good afternoon')) {
      return '🙏 Namaste! I\'m BusBot, your travel companion for BusSeva. I can help you with:\n\n🎫 Booking tickets\n📍 Tracking buses\n🚌 Finding routes\n💳 Payment options\n🛡️ Safety features\n\nHow can I assist you today?';
    }
    
    // Booking related
    if (message.contains('book') || message.contains('ticket') || message.contains('reservation') || 
        message.contains('seat') || message.contains('reserve')) {
      return '🎫 **How to book a bus ticket:**\n\n1️⃣ Tap "Start Your Journey" on home screen\n2️⃣ Enter departure & destination cities\n3️⃣ Select your preferred date & time\n4️⃣ Choose from available buses\n5️⃣ Select seats (if available)\n6️⃣ Enter passenger details\n7️⃣ Make secure payment\n\n✅ Get instant confirmation via SMS/Email!\n\nNeed help with any specific step?';
    }
    
    // Tracking related
    if (message.contains('track') || message.contains('location') || message.contains('where') || 
        message.contains('live') || message.contains('gps') || message.contains('position')) {
      return '📍 **Track your bus in real-time:**\n\n🔍 **Method 1: Quick Track**\n• Use "Quick Track" on home screen\n• Enter your bus number (found on ticket)\n• View live location on map\n\n📱 **Method 2: QR Scan**\n• Scan QR code on your ticket\n• Get instant tracking\n\n⏰ **Get Updates:**\n• Real-time ETA\n• Delay notifications\n• Route progress\n\nYour bus number format: DL-1234 or similar!';
    }
    
    // Routes and schedules
    if (message.contains('route') || message.contains('schedule') || message.contains('time') || 
        message.contains('timing') || message.contains('departure') || message.contains('arrival')) {
      return '🚌 **Find routes & schedules:**\n\n🔍 **Search Options:**\n• City to city routes\n• Popular destinations\n• Direct & connecting buses\n\n⏰ **Live Information:**\n• Real-time schedules\n• Current delays\n• Next available buses\n• Seat availability\n\n💡 **Pro Tip:** Book during off-peak hours for better prices!\n\nWhich route are you looking for?';
    }
    
    // Payment related
    if (message.contains('payment') || message.contains('pay') || message.contains('money') || 
        message.contains('fare') || message.contains('price') || message.contains('cost')) {
      return '💳 **Safe & Easy Payment Options:**\n\n📱 **Digital Payments:**\n• UPI (Google Pay, PhonePe, Paytm)\n• Debit/Credit Cards\n• Net Banking\n• Digital Wallets\n\n💵 **Other Options:**\n• Cash payment at counter\n• Cash on bus (select routes)\n\n🔒 **Security Features:**\n• SSL encrypted transactions\n• No card details stored\n• Instant payment confirmation\n• Refund protection\n\nAll payments are 100% secure! 🛡️';
    }
    
    // Safety and emergency
    if (message.contains('safe') || message.contains('security') || message.contains('emergency') || 
        message.contains('sos') || message.contains('help') || message.contains('danger')) {
      return '🛡️ **Your Safety is Our Priority:**\n\n🆘 **Emergency Features:**\n• SOS button for immediate help\n• Share live location with family\n• 24/7 customer support helpline\n• Emergency contact alerts\n\n✅ **Safety Measures:**\n• Verified drivers with ID\n• GPS tracking on all buses\n• Regular vehicle maintenance\n• Insurance coverage\n• Speed monitoring\n\n📞 **Emergency Helpline:** Available in app\n\nFeel safe, travel smart! 🚌';
    }
    
    // App features and help
    if (message.contains('feature') || message.contains('app') || message.contains('how') || 
        message.contains('use') || message.contains('guide') || message.contains('tutorial')) {
      return '📱 **BusSeva App Features:**\n\n🎯 **Smart Features:**\n🔍 AI-powered route search\n📍 Live GPS bus tracking\n🎫 Quick ticket booking\n💰 Best fare comparison\n⚡ Real-time updates\n🔔 Smart notifications\n\n🛠️ **Helpful Tools:**\n📊 Trip history\n⭐ Rate & review system\n🆘 Emergency SOS\n💬 24/7 chat support\n📱 Offline ticket access\n\n❓ **Need specific help with any feature?** Just ask!';
    }
    
    // Cancellation and refunds
    if (message.contains('cancel') || message.contains('refund') || message.contains('return') || 
        message.contains('money back') || message.contains('modification')) {
      return '↩️ **Cancellation & Refunds:**\n\n⏰ **Cancellation Rules:**\n• Cancel up to 1 hour before departure\n• Emergency cancellations accepted\n• Weather-related cancellations free\n\n💰 **Refund Process:**\n• Instant refund to original payment method\n• Processing time: 3-5 business days\n• Convenience fee may apply (₹10-50)\n• Full refund for bus breakdowns\n\n📝 **How to Cancel:**\n1. Go to "My Trips" section\n2. Select your booking\n3. Tap "Cancel Ticket"\n4. Confirm cancellation\n\nCheck your ticket for specific terms! 📄';
    }
    
    // Contact and support
    if (message.contains('contact') || message.contains('support') || message.contains('phone') || 
        message.contains('email') || message.contains('customer care')) {
      return '📞 **24/7 Customer Support:**\n\n🆘 **Emergency Help:**\n• In-app SOS button\n• Immediate response team\n• Live chat support\n\n📱 **Contact Options:**\n• Customer care helpline\n• Email support\n• Live chat (in app)\n• WhatsApp support\n\n🕐 **Support Hours:**\n• Emergency: 24/7\n• General queries: 6 AM - 11 PM\n• Average response time: <5 minutes\n\nWe\'re here to help! 💪';
    }
    
    // Fare and pricing
    if (message.contains('fare') || message.contains('price') || message.contains('cost') || 
        message.contains('charge') || message.contains('rate')) {
      return '💰 **Bus Fare Information:**\n\n🎯 **Dynamic Pricing:**\n• Based on distance & demand\n• Off-peak discounts available\n• Festival season pricing\n• Advance booking discounts\n\n🏷️ **Fare Types:**\n• Regular seats: ₹1-3 per km\n• AC buses: ₹2-5 per km\n• Sleeper buses: ₹3-6 per km\n• Luxury coaches: ₹4-8 per km\n\n💡 **Money Saving Tips:**\n• Book 2-3 days in advance\n• Travel during weekdays\n• Use promotional codes\n• Group booking discounts\n\nCompare prices easily in our app! 📊';
    }
    
    // Default response with comprehensive help
    return '🤖 **Hi! I\'m BusBot - Your Smart Travel Assistant** 🚌\n\n**I can help you with:**\n\n🎫 **Ticket Booking** - Step-by-step guidance\n📍 **Live Tracking** - Real-time bus location\n🚌 **Route Information** - Schedules & timings\n💳 **Payment Help** - All payment options\n🛡️ **Safety Features** - Emergency support\n📱 **App Guidance** - How to use features\n💰 **Fare Information** - Pricing details\n↩️ **Cancellations** - Refund policies\n📞 **Support** - 24/7 customer care\n\n**Just ask me anything like:**\n• "How to book a ticket?"\n• "Track my bus DL-1234"\n• "Routes from Delhi to Mumbai"\n• "Payment options available?"\n\n**What would you like to know?** 😊';
  }

  // Method with fallback that always works
  Future<String> getBotResponseWithFallback(String userMessage, List<ChatMessage> chatHistory) async {
    try {
      // Try API first only if key is configured
      if (_apiKey != 'AIzaSyAomApJ4vZvjA1yUZSsvo0oWcMCsNM2jJA' && _apiKey.isNotEmpty) {
        return await getBotResponse(userMessage, chatHistory);
      } else {
        // Use fallback directly if no API key
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('API failed, using fallback: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  List<String> getQuickResponses() {
    return [
      'How to book a ticket?',
      'Track my bus',
      'Find routes near me',
      'Payment options',
      'Safety features',
      'Cancel booking',
      'Customer support',
    ];
  }
}
