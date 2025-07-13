#!/bin/bash

# Voice AI App 네이티브 라이브러리 빌드 스크립트
# Whisper.cpp와 LLaMA.cpp를 크로스 플랫폼으로 빌드

set -e

echo "🚀 Voice AI 네이티브 라이브러리 빌드 시작"
echo "============================================="

# 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NATIVE_DIR="$SCRIPT_DIR"
WHISPER_DIR="$NATIVE_DIR/whisper_cpp"
LLAMA_DIR="$NATIVE_DIR/llama_cpp"
RUST_DIR="$NATIVE_DIR/rust"
BUILD_DIR="$NATIVE_DIR/build"
OUTPUT_DIR="$NATIVE_DIR/libs"

# 플랫폼 감지
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    LIB_EXT="so"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    LIB_EXT="dylib"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
    LIB_EXT="dll"
else
    echo "❌ 지원되지 않는 플랫폼: $OSTYPE"
    exit 1
fi

echo "🖥️  플랫폼: $PLATFORM"

# 빌드 디렉토리 생성
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# 의존성 확인
check_dependencies() {
    echo "🔍 의존성 확인 중..."
    
    if ! command -v cmake &> /dev/null; then
        echo "❌ CMake가 설치되지 않았습니다"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        echo "❌ Git이 설치되지 않았습니다"
        exit 1
    fi
    
    if [[ "$PLATFORM" == "linux" ]] && ! command -v gcc &> /dev/null; then
        echo "❌ GCC가 설치되지 않았습니다"
        exit 1
    fi
    
    echo "✅ 의존성 확인 완료"
}

# Whisper.cpp 다운로드 및 빌드
build_whisper() {
    echo "🎤 Whisper.cpp 빌드 중..."
    
    if [ ! -d "$WHISPER_DIR" ]; then
        echo "📥 Whisper.cpp 소스 다운로드 중..."
        git clone --depth 1 https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
    else
        echo "📁 Whisper.cpp 소스 발견, 업데이트 중..."
        cd "$WHISPER_DIR"
        git pull origin master
    fi
    
    cd "$WHISPER_DIR"
    
    # 빌드 설정
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DWHISPER_BUILD_TESTS=OFF \
        -DWHISPER_BUILD_EXAMPLES=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    
    # 빌드 실행
    cmake --build build --config Release -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # 라이브러리 복사
    if [[ "$PLATFORM" == "linux" ]]; then
        cp build/libwhisper.$LIB_EXT "$OUTPUT_DIR/"
    elif [[ "$PLATFORM" == "macos" ]]; then
        cp build/libwhisper.$LIB_EXT "$OUTPUT_DIR/"
    elif [[ "$PLATFORM" == "windows" ]]; then
        cp build/Release/whisper.$LIB_EXT "$OUTPUT_DIR/"
        cp build/Release/whisper.lib "$OUTPUT_DIR/" 2>/dev/null || true
    fi
    
    echo "✅ Whisper.cpp 빌드 완료"
}

# LLaMA.cpp 다운로드 및 빌드
build_llama() {
    echo "🦙 LLaMA.cpp 빌드 중..."
    
    if [ ! -d "$LLAMA_DIR" ]; then
        echo "📥 LLaMA.cpp 소스 다운로드 중..."
        git clone --depth 1 https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
    else
        echo "📁 LLaMA.cpp 소스 발견, 업데이트 중..."
        cd "$LLAMA_DIR"
        git pull origin master
    fi
    
    cd "$LLAMA_DIR"
    
    # 빌드 설정
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_BUILD_EXAMPLES=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DLLAMA_NATIVE=OFF
    
    # 빌드 실행
    cmake --build build --config Release -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # 라이브러리 복사
    if [[ "$PLATFORM" == "linux" ]]; then
        cp build/libllama.$LIB_EXT "$OUTPUT_DIR/"
    elif [[ "$PLATFORM" == "macos" ]]; then
        cp build/libllama.$LIB_EXT "$OUTPUT_DIR/"
    elif [[ "$PLATFORM" == "windows" ]]; then
        cp build/Release/llama.$LIB_EXT "$OUTPUT_DIR/"
        cp build/Release/llama.lib "$OUTPUT_DIR/" 2>/dev/null || true
    fi
    
    echo "✅ LLaMA.cpp 빌드 완료"
}

# Rust 라이브러리 빌드 (선택사항)
build_rust() {
    if [ -d "$RUST_DIR" ] && [ -f "$RUST_DIR/Cargo.toml" ]; then
        echo "🦀 Rust 라이브러리 빌드 중..."
        
        cd "$RUST_DIR"
        
        if ! command -v cargo &> /dev/null; then
            echo "⚠️  Cargo가 설치되지 않았습니다. Rust 빌드를 건너뜁니다."
            return
        fi
        
        # Flutter Rust Bridge 설정
        if [ -f "flutter_rust_bridge.yaml" ]; then
            if command -v flutter_rust_bridge_codegen &> /dev/null; then
                flutter_rust_bridge_codegen
            fi
        fi
        
        # 릴리즈 빌드
        cargo build --release
        
        # 라이브러리 복사
        if [[ "$PLATFORM" == "linux" ]]; then
            cp target/release/*.so "$OUTPUT_DIR/" 2>/dev/null || true
        elif [[ "$PLATFORM" == "macos" ]]; then
            cp target/release/*.dylib "$OUTPUT_DIR/" 2>/dev/null || true
        elif [[ "$PLATFORM" == "windows" ]]; then
            cp target/release/*.dll "$OUTPUT_DIR/" 2>/dev/null || true
        fi
        
        echo "✅ Rust 라이브러리 빌드 완료"
    else
        echo "⚠️  Rust 소스가 없습니다. 건너뜀"
    fi
}

# Android 크로스 컴파일
build_android() {
    echo "📱 Android 라이브러리 빌드 중..."
    
    if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$ANDROID_NDK_ROOT" ]; then
        echo "⚠️  Android NDK 환경변수가 설정되지 않았습니다. Android 빌드를 건너뜁니다."
        return
    fi
    
    NDK_PATH="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"
    
    # Android 아키텍처들
    ANDROID_ARCHS=("arm64-v8a" "armeabi-v7a" "x86_64")
    
    for ARCH in "${ANDROID_ARCHS[@]}"; do
        echo "📦 Android $ARCH 빌드 중..."
        
        ANDROID_OUTPUT_DIR="$OUTPUT_DIR/android/$ARCH"
        mkdir -p "$ANDROID_OUTPUT_DIR"
        
        # Whisper Android 빌드
        if [ -d "$WHISPER_DIR" ]; then
            cd "$WHISPER_DIR"
            
            case $ARCH in
                arm64-v8a)
                    ABI="arm64-v8a"
                    TOOLCHAIN="aarch64-linux-android"
                    ;;
                armeabi-v7a)
                    ABI="armeabi-v7a"
                    TOOLCHAIN="armv7a-linux-androideabi"
                    ;;
                x86_64)
                    ABI="x86_64"
                    TOOLCHAIN="x86_64-linux-android"
                    ;;
            esac
            
            cmake -B "build-android-$ARCH" \
                -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
                -DANDROID_ABI="$ABI" \
                -DANDROID_PLATFORM=android-21 \
                -DCMAKE_BUILD_TYPE=Release \
                -DWHISPER_BUILD_TESTS=OFF \
                -DWHISPER_BUILD_EXAMPLES=OFF \
                -DBUILD_SHARED_LIBS=ON
            
            cmake --build "build-android-$ARCH" --config Release -j$(nproc 2>/dev/null || echo 4)
            
            cp "build-android-$ARCH/libwhisper.so" "$ANDROID_OUTPUT_DIR/"
        fi
        
        # LLaMA Android 빌드
        if [ -d "$LLAMA_DIR" ]; then
            cd "$LLAMA_DIR"
            
            cmake -B "build-android-$ARCH" \
                -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
                -DANDROID_ABI="$ABI" \
                -DANDROID_PLATFORM=android-21 \
                -DCMAKE_BUILD_TYPE=Release \
                -DLLAMA_BUILD_TESTS=OFF \
                -DLLAMA_BUILD_EXAMPLES=OFF \
                -DBUILD_SHARED_LIBS=ON \
                -DLLAMA_NATIVE=OFF
            
            cmake --build "build-android-$ARCH" --config Release -j$(nproc 2>/dev/null || echo 4)
            
            cp "build-android-$ARCH/libllama.so" "$ANDROID_OUTPUT_DIR/"
        fi
    done
    
    echo "✅ Android 빌드 완료"
}

# iOS 크로스 컴파일 (macOS에서만)
build_ios() {
    if [[ "$PLATFORM" != "macos" ]]; then
        echo "⚠️  iOS 빌드는 macOS에서만 가능합니다"
        return
    fi
    
    echo "📱 iOS 라이브러리 빌드 중..."
    
    if ! command -v xcodebuild &> /dev/null; then
        echo "⚠️  Xcode가 설치되지 않았습니다. iOS 빌드를 건너뜁니다."
        return
    fi
    
    IOS_OUTPUT_DIR="$OUTPUT_DIR/ios"
    mkdir -p "$IOS_OUTPUT_DIR"
    
    # Whisper iOS 빌드
    if [ -d "$WHISPER_DIR" ]; then
        cd "$WHISPER_DIR"
        
        # iOS Simulator (x86_64)
        cmake -B build-ios-simulator \
            -DCMAKE_SYSTEM_NAME=iOS \
            -DCMAKE_OSX_SYSROOT=iphonesimulator \
            -DCMAKE_OSX_ARCHITECTURES="x86_64" \
            -DCMAKE_BUILD_TYPE=Release \
            -DWHISPER_BUILD_TESTS=OFF \
            -DWHISPER_BUILD_EXAMPLES=OFF \
            -DBUILD_SHARED_LIBS=OFF
        
        cmake --build build-ios-simulator --config Release
        
        # iOS Device (arm64)
        cmake -B build-ios-device \
            -DCMAKE_SYSTEM_NAME=iOS \
            -DCMAKE_OSX_SYSROOT=iphoneos \
            -DCMAKE_OSX_ARCHITECTURES="arm64" \
            -DCMAKE_BUILD_TYPE=Release \
            -DWHISPER_BUILD_TESTS=OFF \
            -DWHISPER_BUILD_EXAMPLES=OFF \
            -DBUILD_SHARED_LIBS=OFF
        
        cmake --build build-ios-device --config Release
        
        # Universal 라이브러리 생성
        lipo -create \
            build-ios-simulator/libwhisper.a \
            build-ios-device/libwhisper.a \
            -output "$IOS_OUTPUT_DIR/libwhisper.a"
    fi
    
    echo "✅ iOS 빌드 완료"
}

# Flutter 프로젝트에 라이브러리 복사
copy_to_flutter() {
    echo "📦 Flutter 프로젝트에 라이브러리 복사 중..."
    
    # Android
    if [ -d "$OUTPUT_DIR/android" ]; then
        ANDROID_JNI_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"
        mkdir -p "$ANDROID_JNI_DIR"
        cp -r "$OUTPUT_DIR/android/"* "$ANDROID_JNI_DIR/"
        echo "✅ Android 라이브러리 복사 완료"
    fi
    
    # iOS
    if [ -d "$OUTPUT_DIR/ios" ]; then
        IOS_FRAMEWORKS_DIR="$PROJECT_ROOT/ios/Frameworks"
        mkdir -p "$IOS_FRAMEWORKS_DIR"
        cp "$OUTPUT_DIR/ios/"* "$IOS_FRAMEWORKS_DIR/"
        echo "✅ iOS 라이브러리 복사 완료"
    fi
    
    # Desktop
    if [ -n "$(ls -A "$OUTPUT_DIR/"*.{so,dylib,dll} 2>/dev/null)" ]; then
        case $PLATFORM in
            linux)
                DESKTOP_DIR="$PROJECT_ROOT/linux"
                ;;
            macos)
                DESKTOP_DIR="$PROJECT_ROOT/macos"
                ;;
            windows)
                DESKTOP_DIR="$PROJECT_ROOT/windows"
                ;;
        esac
        
        if [ -n "$DESKTOP_DIR" ]; then
            mkdir -p "$DESKTOP_DIR"
            cp "$OUTPUT_DIR/"*.{so,dylib,dll} "$DESKTOP_DIR/" 2>/dev/null || true
            echo "✅ $PLATFORM 데스크톱 라이브러리 복사 완료"
        fi
    fi
}

# 빌드 정보 출력
print_summary() {
    echo ""
    echo "🎉 네이티브 라이브러리 빌드 완료!"
    echo "=================================="
    echo "📁 출력 디렉토리: $OUTPUT_DIR"
    echo ""
    echo "📊 빌드된 라이브러리:"
    find "$OUTPUT_DIR" -type f \( -name "*.so" -o -name "*.dylib" -o -name "*.dll" -o -name "*.a" \) -exec ls -lh {} \;
    echo ""
    echo "🔧 사용법:"
    echo "  1. Flutter 프로젝트를 빌드하세요"
    echo "  2. 앱에서 FFI를 통해 네이티브 함수를 호출하세요"
    echo ""
    echo "⚠️  참고사항:"
    echo "  - 프로덕션 빌드 전에 라이브러리가 올바르게 작동하는지 테스트하세요"
    echo "  - 각 플랫폼별로 적절한 라이브러리가 포함되었는지 확인하세요"
}

# 메인 실행
main() {
    local BUILD_TARGET="${1:-all}"
    
    case $BUILD_TARGET in
        whisper)
            check_dependencies
            build_whisper
            ;;
        llama)
            check_dependencies
            build_llama
            ;;
        rust)
            build_rust
            ;;
        android)
            check_dependencies
            build_android
            ;;
        ios)
            build_ios
            ;;
        all)
            check_dependencies
            build_whisper
            build_llama
            build_rust
            
            # 크로스 플랫폼 빌드
            if [[ "${2:-}" == "--cross-platform" ]]; then
                build_android
                build_ios
            fi
            ;;
        clean)
            echo "🧹 빌드 캐시 정리 중..."
            rm -rf "$BUILD_DIR"
            rm -rf "$OUTPUT_DIR"
            echo "✅ 정리 완료"
            exit 0
            ;;
        *)
            echo "사용법: $0 [whisper|llama|rust|android|ios|all|clean] [--cross-platform]"
            exit 1
            ;;
    esac
    
    copy_to_flutter
    print_summary
}

# 스크립트 실행
main "$@"