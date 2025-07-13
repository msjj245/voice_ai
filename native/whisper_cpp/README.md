# Whisper.cpp Integration

This directory should contain the whisper.cpp source files.

## Required Files

1. Download whisper.cpp from: https://github.com/ggerganov/whisper.cpp
2. Copy the following files here:
   - whisper.cpp
   - whisper.h
   - ggml.c
   - ggml.h
   - ggml-alloc.c
   - ggml-alloc.h
   - ggml-backend.c
   - ggml-backend.h
   - ggml-quants.c
   - ggml-quants.h

## Build Instructions

The Android build system will automatically compile these files using CMake.

For manual testing:
```bash
cd android
./gradlew assembleDebug
```

## Model Files

Model files (*.bin) should be downloaded at runtime and stored in:
- Android: /data/data/com.voiceai.app/files/models/
- iOS: Documents/models/

## Supported Models

- tiny.bin (39 MB)
- base.bin (74 MB) 
- small.bin (244 MB)