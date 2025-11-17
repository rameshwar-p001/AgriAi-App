# 🔧 API Key Fix Guide

## Problem:
Your AI chatbot is showing only static responses because the Gemini API key is invalid.

## Solution:

### Step 1: Get Valid API Key
1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with Google account  
3. Click "Create API Key"
4. Copy the complete key (39 characters long)

### Step 2: Update API Key in Code
Open `lib/services/ai_chatbot_service.dart` and replace line 13:

```dart
// OLD (Invalid - too short):
static const String _geminiApiKey = 'AIzaSyB-iL--ciVAp7Fufzbo6M5d-3y5wMYF4Ek';

// NEW (Replace with your complete key):
static const String _geminiApiKey = 'YOUR_COMPLETE_39_CHARACTER_API_KEY_HERE';
```

### Step 3: Test the Fix
1. Save the file
2. Run: `flutter run` 
3. Test AI chat with farming questions
4. Check console for API logs

## How to Verify It's Working:
- Console should show: "✅ Received response from Gemini API"
- Chat should show intelligent responses, not static fallbacks
- No "API key not valid" errors

## Example Valid API Key Format:
```
AIzaSyC1234567890abcdefghijklmnopqrstuvwxyz
```
(39 characters total)

## Free Tier Limits:
- 15 requests per minute
- 1500 requests per day
- Perfect for testing and demos