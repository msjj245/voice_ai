cmake_minimum_required(VERSION 3.10)

# Project
project(whisper_android)

# C++ Standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# whisper.cpp source files
set(WHISPER_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../native/whisper_cpp")

# Add whisper library
add_library(whisper SHARED
    ${WHISPER_CPP_DIR}/whisper.cpp
    ${WHISPER_CPP_DIR}/ggml.c
    ${WHISPER_CPP_DIR}/ggml-alloc.c
    ${WHISPER_CPP_DIR}/ggml-backend.c
    ${WHISPER_CPP_DIR}/ggml-quants.c
)

# Include directories
target_include_directories(whisper PRIVATE
    ${WHISPER_CPP_DIR}
)

# Compile options
target_compile_options(whisper PRIVATE
    -O3
    -DNDEBUG
    -fPIC
    -pthread
    -mavx
    -mavx2
    -mfma
    -mf16c
)

# Link libraries
target_link_libraries(whisper
    android
    log
    m
)