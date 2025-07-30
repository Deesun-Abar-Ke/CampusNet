# 🔐 Security Configuration for CampusNet

## API Key Security

The Groq AI API key has been configured to use environment variables for security. **Never commit API keys to version control.**

### For Developers:

1. **Get Your API Key:**
   - Visit [Groq Console](https://console.groq.com/keys)
   - Create an account and generate an API key
   - Copy your API key (starts with `gsk_`)

2. **Configure Environment Variables:**

   **Option A: Flutter Run Command**
   ```bash
   flutter run --dart-define=GROQ_API_KEY=your_actual_api_key_here
   ```

   **Option B: VS Code (launch.json)**
   ```json
   {
     "configurations": [
       {
         "name": "Flutter: Run (Debug)",
         "type": "dart",
         "request": "launch",
         "program": "lib/main.dart",
         "args": ["--dart-define=GROQ_API_KEY=your_actual_api_key_here"]
       }
     ]
   }
   ```

   **Option C: Environment File (.env)**
   ```bash
   # Copy .env.example to .env
   cp .env.example .env
   
   # Edit .env and add your API key
   GROQ_API_KEY=your_actual_api_key_here
   ```

3. **Build for Production:**
   ```bash
   flutter build apk --dart-define=GROQ_API_KEY=your_actual_api_key_here
   flutter build ios --dart-define=GROQ_API_KEY=your_actual_api_key_here
   ```

### For Users:

If you're using a pre-built app and the AI features aren't working, contact the app developer to ensure proper API configuration.

### Security Notes:

- ✅ API keys are now stored as environment variables
- ✅ `.env` files are in `.gitignore`
- ✅ No hardcoded secrets in source code
- ✅ GitHub push protection will block exposed keys
- ✅ API key validation prevents runtime errors

### Troubleshooting:

1. **AI not responding:** Check if `GROQ_API_KEY` is set
2. **Build errors:** Ensure environment variables are passed to build command
3. **Development issues:** Verify API key format (should start with `gsk_`)

---

**Remember: Keep your API keys secure and never share them publicly!** 🔒
