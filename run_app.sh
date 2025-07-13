#!/bin/bash

echo "🚀 Voice AI App Setup & Run Script"
echo "=================================="

# 1. Flutter 의존성 설치
echo "📦 Installing Flutter dependencies..."
flutter pub get

# 2. Hive 어댑터 생성
echo "🔧 Generating Hive adapters..."
flutter pub run build_runner build --delete-conflicting-outputs

# 3. iOS 설정 (macOS에서만)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Setting up iOS..."
    cd ios
    pod install
    cd ..
fi

# 4. 앱 실행
echo "📱 Running the app..."
echo "Choose platform:"
echo "1) Android"
echo "2) iOS"
echo "3) Web"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        flutter run -d android
        ;;
    2)
        flutter run -d ios
        ;;
    3)
        flutter run -d chrome
        ;;
    *)
        echo "Invalid choice. Running on available device..."
        flutter run
        ;;
esac