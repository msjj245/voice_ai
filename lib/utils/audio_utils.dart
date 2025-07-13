import 'dart:math';

/// 오디오 처리를 위한 유틸리티 클래스
class AudioUtils {
  /// 오디오 볼륨 레벨을 계산합니다
  static double calculateVolumeLevel(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    double sum = 0.0;
    for (final sample in samples) {
      sum += sample.abs();
    }
    
    return sum / samples.length;
  }
  
  /// 오디오 데이터를 정규화합니다
  static List<double> normalizeAudio(List<double> samples) {
    if (samples.isEmpty) return samples;
    
    final maxValue = samples.reduce((a, b) => max(a.abs(), b.abs()));
    if (maxValue == 0.0) return samples;
    
    return samples.map((sample) => sample / maxValue).toList();
  }
  
  /// 오디오 duration을 포맷팅합니다
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// 오디오 품질을 분석합니다
  static Map<String, dynamic> analyzeAudioQuality(List<double> samples) {
    if (samples.isEmpty) {
      return {
        'volume': 0.0,
        'snr': 0.0,
        'quality': 'poor',
      };
    }
    
    final volume = calculateVolumeLevel(samples);
    final snr = _calculateSNR(samples);
    
    String quality;
    if (snr > 20.0) {
      quality = 'excellent';
    } else if (snr > 15.0) {
      quality = 'good';
    } else if (snr > 10.0) {
      quality = 'fair';
    } else {
      quality = 'poor';
    }
    
    return {
      'volume': volume,
      'snr': snr,
      'quality': quality,
    };
  }
  
  /// Signal-to-Noise Ratio를 계산합니다
  static double _calculateSNR(List<double> samples) {
    final signalPower = _calculateSignalPower(samples);
    final noisePower = _calculateNoisePower(samples);
    
    if (noisePower == 0.0) return double.infinity;
    return 10 * log(signalPower / noisePower) / log(10);
  }
  
  /// 신호 파워를 계산합니다
  static double _calculateSignalPower(List<double> samples) {
    double sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return sum / samples.length;
  }
  
  /// 노이즈 파워를 추정합니다 (간단한 방법)
  static double _calculateNoisePower(List<double> samples) {
    // 샘플의 처음 10%를 노이즈로 가정
    final noiseLength = (samples.length * 0.1).round();
    if (noiseLength == 0) return 0.0;
    
    final noiseSamples = samples.take(noiseLength).toList();
    double sum = 0.0;
    for (final sample in noiseSamples) {
      sum += sample * sample;
    }
    return sum / noiseSamples.length;
  }
}