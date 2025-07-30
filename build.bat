@echo off
REM Build script for CampusNet with Groq API key
REM Usage: build.bat [your_groq_api_key]

if "%1"=="" (
    echo Usage: build.bat [your_groq_api_key]
    echo Example: build.bat gsk_abc123xyz789
    exit /b 1
)

echo Building CampusNet with Groq API key...
flutter build apk --dart-define=GROQ_API_KEY=%1

echo Build complete!
echo APK location: build\app\outputs\flutter-apk\app-release.apk
