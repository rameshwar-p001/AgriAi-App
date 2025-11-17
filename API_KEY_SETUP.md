# Google Gemini AI API Key Setup Guide

## Step 1: Get Free API Key from Google AI Studio

1. **Visit Google AI Studio**: https://aistudio.google.com/
2. **Sign in** with your Google account
3. Click on **"Get API key"** button
4. Click **"Create API key"**
5. **Copy** the generated API key

## Step 2: Add API Key to Your App

1. Open `lib/services/ai_chatbot_service.dart`
2. Find line 15 with:
   ```dart
   static const String _geminiApiKey = 'YOUR_ACTUAL_GEMINI_API_KEY_HERE';
   ```
3. Replace `'YOUR_ACTUAL_GEMINI_API_KEY_HERE'` with your actual API key

## Step 3: Test AI Chatbot

1. Run `flutter pub get` 
2. Run `flutter run`
3. Open app → Dashboard → AI Chat Assistant
4. Start chatting in Hindi/Marathi/English!

## API Limits (Free Tier)
- ✅ **15 requests per minute**
- ✅ **1,500 requests per day**
- ✅ **1 million tokens per month**

## Features Ready to Test:
- 🤖 **AI Farming Assistant** - Expert advice in Hindi/Marathi
- 🎤 **Voice Input** - Speak your questions  
- 🔊 **Voice Output** - AI responds in voice
- 📱 **Smart Chat UI** - Professional chat interface
- 🌾 **Farming Expertise** - Crop, soil, weather, pest management

**Note:** Without valid API key, AI chatbot will show connection error.