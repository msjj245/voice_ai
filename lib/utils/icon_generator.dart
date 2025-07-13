import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// 앱 아이콘을 프로그래밍적으로 생성하는 유틸리티
class IconGenerator {
  static Future<void> generateAppIcon() async {
    const size = 1024;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );
    
    // 배경 그라데이션
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6750A4), // Primary color
          Color(0xFF4F378B), // Darker purple
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      bgPaint,
    );
    
    // 중앙 원
    final centerCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size * 0.35,
      centerCirclePaint,
    );
    
    // 마이크 아이콘
    final micPath = Path();
    final micX = size / 2;
    final micY = size / 2 - size * 0.1;
    final micWidth = size * 0.15;
    final micHeight = size * 0.25;
    
    // 마이크 몸체
    final micRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(micX, micY),
        width: micWidth,
        height: micHeight,
      ),
      Radius.circular(micWidth / 2),
    );
    
    micPath.addRRect(micRect);
    
    // 마이크 스탠드
    micPath.moveTo(micX - micWidth * 0.8, micY + micHeight * 0.4);
    micPath.quadraticBezierTo(
      micX,
      micY + micHeight * 0.7,
      micX + micWidth * 0.8,
      micY + micHeight * 0.4,
    );
    
    micPath.moveTo(micX, micY + micHeight * 0.7);
    micPath.lineTo(micX, micY + micHeight * 0.9);
    
    micPath.moveTo(micX - micWidth * 0.5, micY + micHeight * 0.9);
    micPath.lineTo(micX + micWidth * 0.5, micY + micHeight * 0.9);
    
    final micPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.02
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(micPath, micPaint);
    
    // AI 원들 (음파 효과)
    for (int i = 0; i < 3; i++) {
      final waveRadius = size * (0.15 + i * 0.1);
      final wavePaint = Paint()
        ..color = Colors.white.withOpacity(0.3 - i * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.01;
      
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(micX, micY),
          width: waveRadius * 2,
          height: waveRadius * 2,
        ),
        -math.pi * 0.7,
        -math.pi * 0.6,
        false,
        wavePaint,
      );
      
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(micX, micY),
          width: waveRadius * 2,
          height: waveRadius * 2,
        ),
        -math.pi * 0.3,
        math.pi * 0.6,
        false,
        wavePaint,
      );
    }
    
    // 작은 점들 (AI 효과)
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final radius = size * (0.25 + random.nextDouble() * 0.15);
      final dotX = micX + radius * math.cos(angle);
      final dotY = micY + radius * math.sin(angle);
      
      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.2 + random.nextDouble() * 0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(dotX, dotY),
        size * 0.008,
        dotPaint,
      );
    }
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      
      // 아이콘 저장 경로
      final iconPath = 'assets/icon/app_icon.png';
      final file = File(iconPath);
      await file.create(recursive: true);
      await file.writeAsBytes(pngBytes);
      
      print('App icon generated at: $iconPath');
    }
  }
}