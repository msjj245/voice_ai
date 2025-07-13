#!/bin/bash

# Whisper 모델 다운로드 스크립트
# 사전 훈련된 Whisper 모델들을 다운로드합니다

set -e

echo "🎤 Whisper 모델 다운로드"
echo "======================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$SCRIPT_DIR/models"

# 모델 디렉토리 생성
mkdir -p "$MODELS_DIR"

# Whisper 모델 정보
declare -A WHISPER_MODELS=(
    ["tiny"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin"
    ["tiny.en"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin"
    ["base"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
    ["base.en"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
    ["small"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
    ["small.en"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"
    ["medium"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
    ["medium.en"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin"
    ["large-v1"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v1.bin"
    ["large-v2"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v2.bin"
    ["large-v3"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin"
)

# 모델 크기 정보 (MB)
declare -A MODEL_SIZES=(
    ["tiny"]="39"
    ["tiny.en"]="39"
    ["base"]="74"
    ["base.en"]="74"
    ["small"]="244"
    ["small.en"]="244"
    ["medium"]="769"
    ["medium.en"]="769"
    ["large-v1"]="1550"
    ["large-v2"]="1550"
    ["large-v3"]="1550"
)

# 모델 다운로드 함수
download_model() {
    local model_name=$1
    local url=${WHISPER_MODELS[$model_name]}
    local size=${MODEL_SIZES[$model_name]}
    local filename="ggml-${model_name}.bin"
    local filepath="$MODELS_DIR/$filename"
    
    if [ -z "$url" ]; then
        echo "❌ 알 수 없는 모델: $model_name"
        return 1
    fi
    
    echo "📥 다운로드 중: $model_name (${size}MB)"
    echo "   URL: $url"
    echo "   저장 위치: $filepath"
    
    # 이미 다운로드된 파일이 있는지 확인
    if [ -f "$filepath" ]; then
        echo "✅ 이미 다운로드됨: $filename"
        return 0
    fi
    
    # 임시 파일명
    local temp_file="${filepath}.tmp"
    
    # wget 또는 curl 사용
    if command -v wget >/dev/null 2>&1; then
        wget --progress=bar:force \
             --timeout=30 \
             --tries=3 \
             --continue \
             --output-document="$temp_file" \
             "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl --location \
             --continue-at - \
             --max-time 3600 \
             --retry 3 \
             --progress-bar \
             --output "$temp_file" \
             "$url"
    else
        echo "❌ wget 또는 curl이 필요합니다"
        return 1
    fi
    
    # 다운로드 성공 시 파일 이동
    if [ $? -eq 0 ] && [ -f "$temp_file" ]; then
        mv "$temp_file" "$filepath"
        echo "✅ 다운로드 완료: $filename"
        
        # 파일 크기 확인
        local actual_size=$(du -m "$filepath" | cut -f1)
        echo "📊 파일 크기: ${actual_size}MB"
        
        return 0
    else
        echo "❌ 다운로드 실패: $model_name"
        rm -f "$temp_file"
        return 1
    fi
}

# 권장 모델만 다운로드
download_recommended() {
    echo "⭐ 권장 모델 다운로드 중..."
    
    local recommended_models=("tiny" "base" "small")
    local success_count=0
    
    for model in "${recommended_models[@]}"; do
        echo ""
        echo "📥 $model 다운로드 중..."
        
        if download_model "$model"; then
            ((success_count++))
        fi
    done
    
    echo ""
    echo "🎉 권장 모델 다운로드 완료: $success_count/${#recommended_models[@]} 모델"
}

# 사용 가능한 모델 목록 표시
list_models() {
    echo "📋 사용 가능한 Whisper 모델:"
    echo ""
    printf "%-12s %-8s %s\n" "모델명" "크기(MB)" "설명"
    echo "----------------------------------------"
    printf "%-12s %-8s %s\n" "tiny" "39" "가장 빠름, 기본 정확도"
    printf "%-12s %-8s %s\n" "base" "74" "균형잡힌 속도와 정확도"
    printf "%-12s %-8s %s\n" "small" "244" "좋은 정확도"
    printf "%-12s %-8s %s\n" "medium" "769" "높은 정확도"
    printf "%-12s %-8s %s\n" "large-v3" "1550" "최고 정확도 (최신)"
    echo ""
    echo "💡 권장사항:"
    echo "   - 빠른 개발/테스트: tiny"
    echo "   - 프로덕션 사용: base 또는 small"
    echo "   - 최고 품질 필요: large-v3"
}

# 다운로드된 모델 확인
check_downloaded() {
    echo "📂 다운로드된 모델 확인:"
    echo ""
    
    if [ ! -d "$MODELS_DIR" ]; then
        echo "❌ 모델 디렉토리가 없습니다: $MODELS_DIR"
        return 1
    fi
    
    local found_models=0
    
    for model in "${!WHISPER_MODELS[@]}"; do
        local filename="ggml-${model}.bin"
        local filepath="$MODELS_DIR/$filename"
        
        if [ -f "$filepath" ]; then
            local size=$(du -h "$filepath" | cut -f1)
            printf "✅ %-12s %s\n" "$model" "$size"
            ((found_models++))
        fi
    done
    
    if [ $found_models -eq 0 ]; then
        echo "❌ 다운로드된 모델이 없습니다"
    else
        echo ""
        echo "📊 총 $found_models 개의 모델이 다운로드되어 있습니다"
    fi
}

# 사용법 출력
show_usage() {
    echo "사용법: $0 [명령어] [모델명]"
    echo ""
    echo "명령어:"
    echo "  list              사용 가능한 모델 목록 보기"
    echo "  check             다운로드된 모델 확인"
    echo "  download [모델명]  특정 모델 다운로드"
    echo "  recommended       권장 모델들 다운로드 (tiny, base, small)"
    echo ""
    echo "예시:"
    echo "  $0 list                    # 모델 목록 보기"
    echo "  $0 download base           # base 모델 다운로드"
    echo "  $0 recommended             # 권장 모델들 다운로드"
    echo "  $0 check                   # 다운로드 상태 확인"
}

# 메인 함수
main() {
    case "${1:-}" in
        list)
            list_models
            ;;
        check)
            check_downloaded
            ;;
        download)
            if [ -z "${2:-}" ]; then
                echo "❌ 모델명을 지정해주세요"
                show_usage
                exit 1
            fi
            download_model "$2"
            ;;
        recommended)
            download_recommended
            ;;
        ""|help|--help|-h)
            show_usage
            ;;
        *)
            echo "❌ 알 수 없는 명령어: $1"
            show_usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"