#!/bin/bash

echo "🚀 Building Voice AI App for Android"
echo "===================================="

# 1. Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# 2. Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# 3. Generate code
echo "🔧 Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Create required directories
echo "📁 Creating directories..."
mkdir -p android/app/src/main/jniLibs
mkdir -p assets/models
mkdir -p assets/fonts

# 5. Download placeholder for Whisper native library
echo "📥 Preparing native libraries..."
# In real implementation, you would copy actual whisper.so files
# For now, we'll create a placeholder
cat > native/README.md << 'EOF'
# Native Libraries

Place the following files here:
- whisper_cpp/whisper.cpp
- whisper_cpp/whisper.h
- whisper_cpp/ggml.c
- whisper_cpp/ggml.h

Download from: https://github.com/ggerganov/whisper.cpp
EOF

# 6. Build APK
echo "🔨 Building APK..."
flutter build apk --release --split-per-abi

# 7. Build App Bundle
echo "📦 Building App Bundle..."
flutter build appbundle --release

# 8. Display results
echo ""
echo "✅ Build Complete!"
echo "=================="
echo "APK files:"
ls -la build/app/outputs/flutter-apk/*.apk 2>/dev/null | awk '{print "  - " $9 " (" $5 " bytes)"}'
echo ""
echo "App Bundle:"
ls -la build/app/outputs/bundle/release/*.aab 2>/dev/null | awk '{print "  - " $9 " (" $5 " bytes)"}'
echo ""
echo "📱 To install on device:"
echo "  adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo ""
echo "🏪 For Play Store upload:"
echo "  Use: build/app/outputs/bundle/release/app-release.aab"