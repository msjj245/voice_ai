import 'package:flutter_test/flutter_test.dart';
import 'package:voice_ai_app/utils/audio_utils.dart';

void main() {
  group('AudioUtils', () {
    test('calculateVolumeLevel should return 0 for empty samples', () {
      expect(AudioUtils.calculateVolumeLevel([]), equals(0.0));
    });
    
    test('calculateVolumeLevel should calculate correct volume level', () {
      final samples = [0.5, -0.3, 0.8, -0.2];
      final expected = (0.5 + 0.3 + 0.8 + 0.2) / 4;
      expect(AudioUtils.calculateVolumeLevel(samples), equals(expected));
    });
    
    test('normalizeAudio should return original samples when empty', () {
      final samples = <double>[];
      expect(AudioUtils.normalizeAudio(samples), equals(samples));
    });
    
    test('normalizeAudio should normalize audio correctly', () {
      final samples = [0.5, -1.0, 0.8];
      final normalized = AudioUtils.normalizeAudio(samples);
      expect(normalized, equals([0.5, -1.0, 0.8]));
    });
    
    test('formatDuration should format duration correctly', () {
      expect(AudioUtils.formatDuration(const Duration(minutes: 2, seconds: 30)), 
             equals('02:30'));
      expect(AudioUtils.formatDuration(const Duration(minutes: 0, seconds: 5)), 
             equals('00:05'));
    });
    
    test('analyzeAudioQuality should return poor quality for empty samples', () {
      final result = AudioUtils.analyzeAudioQuality([]);
      expect(result['quality'], equals('poor'));
      expect(result['volume'], equals(0.0));
    });
    
    test('analyzeAudioQuality should analyze quality correctly', () {
      final samples = List.generate(100, (index) => 0.5 + 0.1 * (index % 10 - 5));
      final result = AudioUtils.analyzeAudioQuality(samples);
      expect(result.containsKey('volume'), isTrue);
      expect(result.containsKey('snr'), isTrue);
      expect(result.containsKey('quality'), isTrue);
    });
  });
}