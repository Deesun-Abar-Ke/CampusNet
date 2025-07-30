#!/bin/bash
# Build script for CampusNet with Groq API key
# Usage: ./build.sh [your_groq_api_key]

if [ -z "$1" ]; then
    echo "Usage: ./build.sh [your_groq_api_key]"
    echo "Example: ./build.sh gsk_abc123xyz789"
    exit 1
fi

echo "Building CampusNet with Groq API key..."
flutter build apk --dart-define=GROQ_API_KEY=$1

echo "Build complete!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
