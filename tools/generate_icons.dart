import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

// 독립 실행 가능한 아이콘 생성 스크립트
void main() async {
  print('Generating app icons...');
  
  // 메인 아이콘 생성
  await generateIcon(1024, 'assets/icon/app_icon.png');
  
  // Android 적응형 아이콘 전경
  await generateIcon(1024, 'assets/icon/app_icon_foreground.png', isAdaptive: true);
  
  print('✅ Icons generated successfully!');
  print('Run: flutter pub run flutter_launcher_icons:main');
}

Future<void> generateIcon(int size, String path, {bool isAdaptive = false}) async {
  // Create canvas
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );
  
  final center = size / 2;
  
  if (!isAdaptive) {
    // 배경 (일반 아이콘용)
    final bgPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(center, center),
        size * 0.7,
        [
          const ui.Color(0xFF6750A4),
          const ui.Color(0xFF4F378B),
        ],
        [0.0, 1.0],
      );
    
    canvas.drawCircle(
      ui.Offset(center, center),
      center,
      bgPaint,
    );
  }
  
  // 마이크 그리기
  drawMicrophone(canvas, size, isAdaptive);
  
  // AI 효과 그리기
  drawAIEffects(canvas, size, isAdaptive);
  
  // 이미지로 변환
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  if (byteData != null) {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    print('Generated: $path');
  }
}

void drawMicrophone(ui.Canvas canvas, int size, bool isAdaptive) {
  final center = size / 2;
  final micSize = size * (isAdaptive ? 0.5 : 0.3);
  
  final paint = ui.Paint()
    ..color = isAdaptive ? const ui.Color(0xFF6750A4) : const ui.Color(0xFFFFFFFF)
    ..style = ui.PaintingStyle.fill;
  
  // 마이크 몸체
  final micBody = ui.RRect.fromRectAndRadius(
    ui.Rect.fromCenter(
      center: ui.Offset(center, center - micSize * 0.2),
      width: micSize * 0.4,
      height: micSize * 0.8,
    ),
    ui.Radius.circular(micSize * 0.2),
  );
  
  canvas.drawRRect(micBody, paint);
  
  // 마이크 그릴
  final grillPaint = ui.Paint()
    ..color = isAdaptive ? const ui.Color(0xFF4F378B) : const ui.Color(0xFFFFFFFF).withOpacity(0.8)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = size * 0.005;
  
  for (int i = 0; i < 5; i++) {
    final y = center - micSize * 0.5 + i * micSize * 0.15;
    canvas.drawLine(
      ui.Offset(center - micSize * 0.15, y),
      ui.Offset(center + micSize * 0.15, y),
      grillPaint,
    );
  }
  
  // 마이크 스탠드
  final standPaint = ui.Paint()
    ..color = paint.color
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = size * 0.02
    ..strokeCap = ui.StrokeCap.round;
  
  final path = ui.Path();
  path.moveTo(center - micSize * 0.3, center + micSize * 0.2);
  path.quadraticBezierTo(
    center,
    center + micSize * 0.5,
    center + micSize * 0.3,
    center + micSize * 0.2,
  );
  
  canvas.drawPath(path, standPaint);
  
  // 베이스
  canvas.drawLine(
    ui.Offset(center, center + micSize * 0.5),
    ui.Offset(center, center + micSize * 0.7),
    standPaint,
  );
  
  canvas.drawLine(
    ui.Offset(center - micSize * 0.2, center + micSize * 0.7),
    ui.Offset(center + micSize * 0.2, center + micSize * 0.7),
    standPaint,
  );
}

void drawAIEffects(ui.Canvas canvas, int size, bool isAdaptive) {
  final center = size / 2;
  
  // 음파 효과
  for (int i = 1; i <= 3; i++) {
    final radius = size * (0.35 + i * 0.05);
    final paint = ui.Paint()
      ..color = (isAdaptive ? const ui.Color(0xFF6750A4) : const ui.Color(0xFFFFFFFF))
          .withOpacity(0.3 - i * 0.08)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = size * 0.01;
    
    // 왼쪽 음파
    canvas.drawArc(
      ui.Rect.fromCenter(
        center: ui.Offset(center, center),
        width: radius * 2,
        height: radius * 2,
      ),
      -math.pi * 0.7,
      -math.pi * 0.6,
      false,
      paint,
    );
    
    // 오른쪽 음파
    canvas.drawArc(
      ui.Rect.fromCenter(
        center: ui.Offset(center, center),
        width: radius * 2,
        height: radius * 2,
      ),
      -math.pi * 0.3,
      math.pi * 0.6,
      false,
      paint,
    );
  }
  
  // AI 점들
  final random = math.Random(42);
  for (int i = 0; i < 15; i++) {
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = size * (0.3 + random.nextDouble() * 0.2);
    final x = center + distance * math.cos(angle);
    final y = center + distance * math.sin(angle);
    
    final dotPaint = ui.Paint()
      ..color = (isAdaptive ? const ui.Color(0xFF6750A4) : const ui.Color(0xFFFFFFFF))
          .withOpacity(0.3 + random.nextDouble() * 0.4)
      ..style = ui.PaintingStyle.fill;
    
    canvas.drawCircle(
      ui.Offset(x, y),
      size * 0.01,
      dotPaint,
    );
  }
}