# 🔐 GROQ API Key Setup Instructions

This document explains how to securely configure your Groq API key for the NetBOT chatbot feature.

## 🚀 Quick Start

### 1. Get Your Groq API Key
1. Visit [https://console.groq.com/](https://console.groq.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (it looks like: `gsk_abc123xyz789...`)

### 2. Configure the API Key

#### Method A: VS Code Launch Configuration (Recommended for Development)
1. Open `.vscode/launch.json` in your project
2. Replace `YOUR_GROQ_API_KEY_HERE` with your actual API key:
```json
"args": [
    "--dart-define=GROQ_API_KEY=gsk_your_actual_key_here"
]
```
3. Press F5 or use "Run and Debug" in VS Code

#### Method B: Environment File (Recommended for Development)
1. Open the `.env` file in your project root
2. Replace `your_actual_groq_api_key_here` with your actual API key:
```
GROQ_API_KEY=gsk_your_actual_key_here
```
3. Run with: `flutter run --dart-define-from-file=.env`

#### Method C: Command Line (For Building/Running)
```bash
# For running in debug mode
flutter run --dart-define=GROQ_API_KEY=gsk_your_actual_key_here

# For building release APK
flutter build apk --dart-define=GROQ_API_KEY=gsk_your_actual_key_here

# Using the provided build scripts
# Windows:
build.bat gsk_your_actual_key_here

# Linux/Mac:
./build.sh gsk_your_actual_key_here
```

## 🔒 Security Features

✅ **API Key Protection**: The key is loaded via environment variables, not hardcoded
✅ **Git Security**: `.env` files are automatically ignored by Git
✅ **Offline Fallback**: App works without API key using local MIST responses
✅ **Error Handling**: Graceful degradation when API is unavailable

## 🤖 How It Works

- **With API Key**: NetBOT uses Groq's LLaMA model for intelligent MIST-focused responses
- **Without API Key**: NetBOT provides predefined helpful responses for common MIST queries
- **Error Handling**: If API fails, falls back to offline responses automatically

## 📱 Testing the Integration

1. Set up your API key using any method above
2. Run the app: `flutter run`
3. Navigate to the Chatbot page
4. Try asking: "Tell me about MIST departments"
5. You should see an AI-powered response with the 🤖 NetBOT greeting

## ⚠️ Important Security Notes

- **Never commit your API key to Git**
- **Keep your API key private**
- **The `.env` file is already in `.gitignore`**
- **Use different keys for development and production**

## 🛠️ Troubleshooting

**"API key is empty" message?**
- Check that your API key is correctly set in the environment
- Verify the key format (should start with 'gsk_')

**App building but no AI responses?**
- Check the Flutter console for error messages
- Verify internet connection
- Ensure API key is valid and has credits

**Need help?**
- Check Groq documentation: [https://console.groq.com/docs](https://console.groq.com/docs)
- Review the app logs for specific error messages
