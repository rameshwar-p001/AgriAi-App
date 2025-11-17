import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_message.dart';
import '../models/user.dart' as app_user;

/// Enhanced AI Chatbot Service with multiple AI providers
/// Supports both Google Gemini and OpenAI ChatGPT
class EnhancedAIChatbotService extends ChangeNotifier {
  
  // AI Provider Keys
  static const String _geminiApiKey = 'AIzaSyB_1L_-ciVAp7Fsufzbo6M5d-3y5wMYF4E';
  static const String _openAiApiKey = 'YOUR_OPENAI_API_KEY_HERE'; // आपको यह ChatGPT से लेना होगा
  
  // AI Providers
  GenerativeModel? _geminiModel;
  
  // Other services
  late SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  
  // State variables
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  List<ChatMessage> _chatHistory = [];
  app_user.User? _currentUser;
  
  // Current AI provider
  AIProvider _currentProvider = AIProvider.openAI; // Default to OpenAI
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  List<ChatMessage> get chatHistory => _chatHistory;
  AIProvider get currentProvider => _currentProvider;

  /// Initialize Enhanced AI Chatbot Service
  Future<void> initialize({app_user.User? user}) async {
    try {
      _currentUser = user;
      
      // Initialize OpenAI (Primary)
      OpenAI.apiKey = _openAiApiKey;
      OpenAI.organization = "your-org-id"; // Optional
      
      // Initialize Gemini as backup
      try {
        _geminiModel = GenerativeModel(
          model: 'models/gemini-1.5-flash',
          apiKey: _geminiApiKey,
        );
      } catch (e) {
        print('Gemini initialization failed: $e');
      }

      // Initialize Speech to Text
      _speechToText = SpeechToText();
      await _speechToText.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          notifyListeners();
        },
        onError: (error) {
          print('Speech recognition error: $error');
          _isListening = false;
          notifyListeners();
        },
      );

      // Initialize Text to Speech
      _flutterTts = FlutterTts();
      await _setupTts();

      _isInitialized = true;
      
      // Add welcome message
      _addWelcomeMessage();
      
      notifyListeners();
      print('Enhanced AI Chatbot Service initialized successfully');
    } catch (e) {
      print('Error initializing Enhanced AI Chatbot Service: $e');
      _isInitialized = false;
    }
  }

  /// Switch AI Provider
  void switchAIProvider(AIProvider provider) {
    _currentProvider = provider;
    notifyListeners();
    print('Switched to AI Provider: ${provider.name}');
  }

  /// Send message to AI
  Future<void> sendMessage(String text) async {
    if (!_isInitialized || text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      messageType: ChatMessageType.text,
    );
    _chatHistory.add(userMessage);
    notifyListeners();

    try {
      String response;
      
      // Try current provider first
      if (_currentProvider == AIProvider.openAI) {
        response = await _generateOpenAIResponse(text);
      } else {
        response = await _generateGeminiResponse(text);
      }
      
      // Add AI response
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: ChatMessageType.text,
      );
      _chatHistory.add(aiMessage);
      
      // Speak response if Hindi/Marathi
      if (_currentUser?.language == 'hindi' || _currentUser?.language == 'marathi') {
        _speakText(response);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error with ${_currentProvider.name}: $e');
      
      // Try fallback provider
      try {
        String response;
        if (_currentProvider == AIProvider.openAI) {
          print('Trying Gemini as fallback...');
          response = await _generateGeminiResponse(text);
        } else {
          print('Trying OpenAI as fallback...');
          response = await _generateOpenAIResponse(text);
        }
        
        final aiMessage = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: "🔄 ${_currentProvider == AIProvider.openAI ? 'Gemini' : 'OpenAI'} Response:\n\n$response",
          isUser: false,
          timestamp: DateTime.now(),
          messageType: ChatMessageType.text,
        );
        _chatHistory.add(aiMessage);
        notifyListeners();
      } catch (e2) {
        print('Both AI providers failed: $e2');
        
        // Add fallback response
        final fallbackResponse = _getFallbackResponse(text);
        final aiMessage = ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_fallback',
          text: fallbackResponse,
          isUser: false,
          messageType: ChatMessageType.system,
          timestamp: DateTime.now(),
        );
        _chatHistory.add(aiMessage);
        notifyListeners();
      }
    }
  }

  /// Generate OpenAI ChatGPT Response
  Future<String> _generateOpenAIResponse(String userMessage) async {
    print('🔄 Attempting OpenAI ChatGPT response for: $userMessage');
    
    final prompt = _buildContextualPrompt(userMessage);
    
    final chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo", // या "gpt-4" for better quality
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      maxTokens: 1000,
      temperature: 0.7,
    );
    
    final response = chatCompletion.choices.first.message.content?.first.text ?? '';
    
    if (response.isNotEmpty) {
      print('✅ OpenAI Response received: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
      return response;
    } else {
      throw Exception('Empty response from OpenAI');
    }
  }

  /// Generate Gemini Response (Backup)
  Future<String> _generateGeminiResponse(String userMessage) async {
    if (_geminiModel == null) {
      throw Exception('Gemini model not initialized');
    }
    
    print('🔄 Attempting Gemini response for: $userMessage');
    
    final prompt = _buildContextualPrompt(userMessage);
    final content = [Content.text(prompt)];
    
    final response = await _geminiModel!.generateContent(content);
    
    if (response.text != null && response.text!.isNotEmpty) {
      print('✅ Gemini Response received: ${response.text!.substring(0, response.text!.length > 100 ? 100 : response.text!.length)}...');
      return response.text!;
    } else {
      throw Exception('Empty response from Gemini');
    }
  }

  /// Setup Text to Speech
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage('hi-IN'); // Hindi
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  /// Add welcome message
  void _addWelcomeMessage() {
    final welcomeText = _currentUser?.language == 'hindi' 
        ? '''नमस्कार ${_currentUser?.name ?? 'किसान भाई'}! 🌾

मैं AgriAI का Enhanced Smart Farming Assistant हूं। 

🤖 **AI Providers Available:**
• OpenAI ChatGPT (Primary) ✅
• Google Gemini (Backup) ⚡

आप मुझसे खेती के बारे में कुछ भी पूछ सकते हैं:

🌱 फसल की समस्याएं और समाधान
🌦️ मौसम के अनुसार सलाह  
💰 बाजार की कीमतें और बेचने का समय
🚜 खाद और उर्वरक की जानकारी
🔬 बीमारी की पहचान और इलाज

कैसे मदद कर सकूं आपकी?'''
        : '''Hello ${_currentUser?.name ?? 'Farmer'}! 🌾

I'm AgriAI's Enhanced Smart Farming Assistant.

🤖 **AI Providers Available:**
• OpenAI ChatGPT (Primary) ✅
• Google Gemini (Backup) ⚡

You can ask me anything about farming:

🌱 Crop problems and solutions
🌦️ Weather-based advice
💰 Market prices and selling time
🚜 Fertilizer and pesticide information  
🔬 Disease identification and treatment

How can I help you today?''';

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
      messageType: ChatMessageType.text,
    );

    _chatHistory.add(message);
  }

  /// Build contextual prompt for better responses
  String _buildContextualPrompt(String userMessage) {
    final language = _currentUser?.language ?? 'english';
    final userName = _currentUser?.name ?? 'Farmer';
    final userSoilType = _currentUser?.soilType ?? 'Not specified';

    String basePrompt = '';
    
    if (language == 'hindi') {
      basePrompt = '''आप एक अनुभवी भारतीय कृषि विशेषज्ञ हैं।

किसान की जानकारी:
- नाम: $userName  
- मिट्टी का प्रकार: $userSoilType

निर्देश:
1. हमेशा हिंदी में उत्तर दें
2. व्यावहारिक सलाह दें
3. सरल भाषा का उपयोग करें
4. 🌾, 🌱, 💰 जैसे emojis का उपयोग करें

प्रश्न: "$userMessage"

उत्तर:''';
    } else {
      basePrompt = '''You are an experienced Indian agricultural expert.

Farmer Information:
- Name: $userName
- Soil Type: $userSoilType  

Instructions:
1. Provide practical farming advice
2. Use simple language
3. Include emojis like 🌾, 🌱, 💰
4. Focus on Indian farming conditions

Question: "$userMessage"

Answer:''';
    }

    return basePrompt;
  }

  /// Get fallback response when all APIs fail
  String _getFallbackResponse(String userMessage) {
    final language = _currentUser?.language ?? 'english';
    
    if (language == 'hindi') {
      return '''🙏 माफ़ करें, AI सेवा में तकनीकी समस्या है।

📱 **कृपया कोशिश करें:**
• इंटरनेट कनेक्शन चेक करें
• कुछ देर बाद फिर से पूछें

🌾 **तुरंत सलाह:**
• सुबह-शाम खेत का निरीक्षण करें
• मिट्टी की नमी जाँचें  
• स्थानीय कृषि विशेषज्ञ से संपर्क करें

धन्यवाद!''';
    } else {
      return '''🙏 Sorry, AI service is temporarily unavailable.

📱 **Please try:**
• Check internet connection
• Ask again after some time

🌾 **General advice:**
• Inspect field morning and evening
• Check soil moisture
• Contact local agricultural expert

Thank you!''';
    }
  }

  /// Start voice recognition
  Future<void> startListening() async {
    if (!_isInitialized) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    final available = await _speechToText.initialize();
    if (!available) return;

    String localeId = 'en-US';
    if (_currentUser?.language == 'hindi') {
      localeId = 'hi-IN';
    } else if (_currentUser?.language == 'marathi') {
      localeId = 'mr-IN';
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          sendMessage(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stop voice recognition
  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Speak text using TTS
  Future<void> _speakText(String text) async {
    if (!_isInitialized) return;
    
    final cleanText = text.replaceAll(RegExp(r'[🌾🌱💰🌦️🚜🔬📱📈⚠️✅❌🎯🤖⚡]'), '');
    await _flutterTts.speak(cleanText);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Clear chat history
  void clearChat() {
    _chatHistory.clear();
    _addWelcomeMessage();
    notifyListeners();
  }

  /// Update current user
  void updateUser(app_user.User? user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

/// AI Provider enum
enum AIProvider {
  openAI('OpenAI ChatGPT'),
  gemini('Google Gemini');
  
  const AIProvider(this.name);
  final String name;
}