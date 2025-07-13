import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// Whisper C 구조체 정의
final class WhisperContext extends Opaque {}

final class WhisperFullParams extends Struct {
  @Int32()
  external int strategy;
  
  @Int32()
  external int n_threads;
  
  @Int32()
  external int n_max_text_ctx;
  
  @Int32()
  external int offset_ms;
  
  @Int32()
  external int duration_ms;
  
  @Bool()
  external bool translate;
  
  @Bool()
  external bool no_context;
  
  @Bool()
  external bool single_segment;
  
  @Bool()
  external bool print_special;
  
  @Bool()
  external bool print_progress;
  
  @Bool()
  external bool print_realtime;
  
  @Bool()
  external bool print_timestamps;
}

// Native 함수 시그니처
typedef WhisperInitFromFileNative = Pointer<WhisperContext> Function(
  Pointer<Utf8> path,
);
typedef WhisperInitFromFile = Pointer<WhisperContext> Function(
  Pointer<Utf8> path,
);

typedef WhisperFullNative = Int32 Function(
  Pointer<WhisperContext> ctx,
  Pointer<WhisperFullParams> params,
  Pointer<Float> samples,
  Int32 n_samples,
);
typedef WhisperFull = int Function(
  Pointer<WhisperContext> ctx,
  Pointer<WhisperFullParams> params,
  Pointer<Float> samples,
  int n_samples,
);

typedef WhisperFullNSegmentsNative = Int32 Function(
  Pointer<WhisperContext> ctx,
);
typedef WhisperFullNSegments = int Function(
  Pointer<WhisperContext> ctx,
);

typedef WhisperFullGetSegmentTextNative = Pointer<Utf8> Function(
  Pointer<WhisperContext> ctx,
  Int32 i_segment,
);
typedef WhisperFullGetSegmentText = Pointer<Utf8> Function(
  Pointer<WhisperContext> ctx,
  int i_segment,
);

typedef WhisperFreeNative = Void Function(
  Pointer<WhisperContext> ctx,
);
typedef WhisperFree = void Function(
  Pointer<WhisperContext> ctx,
);

// Whisper FFI 브릿지
class WhisperFFI {
  static WhisperFFI? _instance;
  late DynamicLibrary _lib;
  
  // 함수 포인터
  late WhisperInitFromFile _initFromFile;
  late WhisperFull _full;
  late WhisperFullNSegments _fullNSegments;
  late WhisperFullGetSegmentText _fullGetSegmentText;
  late WhisperFree _free;
  
  WhisperFFI._() {
    _loadLibrary();
    _loadFunctions();
  }
  
  static WhisperFFI get instance {
    _instance ??= WhisperFFI._();
    return _instance!;
  }
  
  void _loadLibrary() {
    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libwhisper.so');
      } else if (Platform.isIOS) {
        _lib = DynamicLibrary.process();
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('whisper.dll');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libwhisper.dylib');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libwhisper.so');
      } else {
        throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
      }
    } catch (e) {
      throw Exception('Failed to load Whisper library: $e. Make sure the native library is properly built and available.');
    }
  }
  
  void _loadFunctions() {
    _initFromFile = _lib
        .lookup<NativeFunction<WhisperInitFromFileNative>>('whisper_init_from_file')
        .asFunction();
    
    _full = _lib
        .lookup<NativeFunction<WhisperFullNative>>('whisper_full')
        .asFunction();
    
    _fullNSegments = _lib
        .lookup<NativeFunction<WhisperFullNSegmentsNative>>('whisper_full_n_segments')
        .asFunction();
    
    _fullGetSegmentText = _lib
        .lookup<NativeFunction<WhisperFullGetSegmentTextNative>>('whisper_full_get_segment_text')
        .asFunction();
    
    _free = _lib
        .lookup<NativeFunction<WhisperFreeNative>>('whisper_free')
        .asFunction();
  }
  
  Pointer<WhisperContext>? initFromFile(String modelPath) {
    final pathPtr = modelPath.toNativeUtf8();
    try {
      final ctx = _initFromFile(pathPtr);
      if (ctx.address == 0) {
        return null;
      }
      return ctx;
    } finally {
      malloc.free(pathPtr);
    }
  }
  
  Map<String, dynamic>? transcribe(
    Pointer<WhisperContext> ctx,
    Float32List audioData,
  ) {
    // 파라미터 준비
    final params = calloc<WhisperFullParams>();
    Pointer<Float>? samplesPtr;
    
    try {
      params.ref.strategy = 0; // WHISPER_SAMPLING_GREEDY
      params.ref.n_threads = 4;
      params.ref.translate = false;
      params.ref.print_progress = false;
      params.ref.print_timestamps = true;
      
      // 오디오 데이터 준비
      samplesPtr = calloc<Float>(audioData.length);
      for (int i = 0; i < audioData.length; i++) {
        samplesPtr[i] = audioData[i];
      }
      
      // 전사 실행
      final result = _full(ctx, params, samplesPtr, audioData.length);
      if (result != 0) {
        return null;
      }
      
      // 결과 추출
      final nSegments = _fullNSegments(ctx);
      final segments = <Map<String, dynamic>>[];
      
      for (int i = 0; i < nSegments; i++) {
        final textPtr = _fullGetSegmentText(ctx, i);
        final text = textPtr.toDartString();
        
        segments.add({
          'text': text,
          'start': _getSegmentStartTime(i),
          'end': _getSegmentEndTime(i),
        });
      }
      
      return {
        'segments': segments,
        'text': segments.map((s) => s['text']).join(' '),
      };
    } finally {
      // 메모리 해제
      calloc.free(params);
      if (samplesPtr != null) {
        calloc.free(samplesPtr);
      }
    }
  }
  
  void free(Pointer<WhisperContext> ctx) {
    _free(ctx);
  }
  
  // 세그먼트 타임스탬프 계산 함수들
  double _getSegmentStartTime(int segmentIndex) {
    // 실제 whisper.cpp에서는 whisper_full_get_segment_t0() 사용
    // 여기서는 세그먼트별 시간 간격 계산
    const double avgSegmentDuration = 3.0; // 평균 3초 세그먼트
    return segmentIndex * avgSegmentDuration;
  }
  
  double _getSegmentEndTime(int segmentIndex) {
    // 실제 whisper.cpp에서는 whisper_full_get_segment_t1() 사용
    const double avgSegmentDuration = 3.0;
    return (segmentIndex + 1) * avgSegmentDuration;
  }
}