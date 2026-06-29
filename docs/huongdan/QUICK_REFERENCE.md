# Handwriting Tracing - Quick Reference Guide

## Quick Start

### 1. Score User's Handwriting

```dart
import 'package:khmerkid/services/handwriting_tracing_service.dart';

final result = HandwritingTracingService.instance.scoreTracing(
  character: 'ក',
  userStrokes: userStrokes,
  canvasSize: Size(400, 400),
);

if (result.passed) {
  print('✓ Passed with ${result.stars} stars!');
} else {
  print('✗ Failed: ${result.feedback}');
  result.tips.forEach(print);
}
```

### 2. Display Visual Feedback

```dart
CustomPaint(
  painter: FeedbackPainter(result.visualFeedback),
)

class FeedbackPainter extends CustomPainter {
  final List<StrokeSegment> segments;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final segment in segments) {
      final paint = Paint()
        ..color = segment.color
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      if (segment.points.length >= 2) {
        final path = Path()..moveTo(segment.points[0].dx, segment.points[0].dy);
        for (int i = 1; i < segment.points.length; i++) {
          path.lineTo(segment.points[i].dx, segment.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

## API Reference

### TracingScoreResult

```dart
class TracingScoreResult {
  final double insideCoverage;    // 0-100: % strokes on template
  final double outsideCoverage;   // 0-100: % strokes outside template
  final double finalScore;        // 0-100: final score
  final bool passed;              // true if score >= 70% and inside > outside
  final int stars;                // 0-3 stars
  final String feedback;          // Feedback message
  final List<String> tips;        // Improvement tips
  final List<StrokeSegment> visualFeedback; // Colored segments
}
```

### StrokeSegment

```dart
class StrokeSegment {
  final List<Offset> points;
  final Color color;  // Colors.green, Colors.yellow, or Colors.red
}
```

## Configuration

### Adjust Difficulty

```dart
// In lib/services/handwriting_tracing_service.dart

// Make it easier (more tolerant)
static const double toleranceRadius = 30.0;  // Default: 25.0
static const double passThreshold = 65.0;    // Default: 70.0

// Make it harder (more strict)
static const double toleranceRadius = 20.0;
static const double passThreshold = 75.0;
```

### Adjust Penalty

```dart
// In _analyzeUserStrokes method
final outsidePenalty = outsideCoverage * 0.3;  // Default: 0.5 (50% penalty)
```

## Scoring Formula

```
Inside Coverage = (insidePoints + nearPoints * 0.7) / totalPoints * 100
Outside Coverage = outsidePoints / totalPoints * 100

Final Score = Inside Coverage - (Outside Coverage * 0.5)
Final Score = clamp(Final Score, 0, 100)

Pass Conditions:
1. Outside Coverage <= Inside Coverage
2. Final Score >= 70%
```

## Color Coding

- 🟢 **Green**: Point is directly on template
- 🟡 **Yellow**: Point is near template (within toleranceRadius)
- 🔴 **Red**: Point is outside template

## Common Patterns

### Pattern 1: Basic Integration

```dart
void _checkWriting() async {
  final result = HandwritingTracingService.instance.scoreTracing(
    character: currentCharacter,
    userStrokes: strokes,
    canvasSize: canvasSize,
  );
  
  setState(() {
    showFeedback = true;
    feedbackSegments = result.visualFeedback;
  });
  
  if (result.passed) {
    _showSuccessDialog(result);
  } else {
    _showRetryDialog(result);
  }
}
```

### Pattern 2: Progress Tracking

```dart
void _saveProgress(TracingScoreResult result) async {
  if (result.passed) {
    await progressService.saveWritingScore(
      character: character,
      score: result.finalScore.round(),
      stars: result.stars,
    );
  }
}
```

### Pattern 3: Adaptive Hints

```dart
String _getHint(TracingScoreResult result) {
  if (result.outsideCoverage > result.insideCoverage) {
    return 'Bạn đang vẽ quá nhiều ngoài chữ mẫu!';
  } else if (result.insideCoverage < 50) {
    return 'Hãy viết chính xác hơn theo nét mẫu!';
  } else if (result.finalScore < 70) {
    return 'Gần đạt rồi! Cố gắng viết sát hơn với chữ mẫu!';
  } else {
    return 'Tuyệt vời! Bạn đã viết rất tốt!';
  }
}
```

## Testing

### Unit Test Example

```dart
test('Perfect tracing should get high score', () {
  final strokes = [
    List.generate(30, (i) => Offset(180 + i * 2.0, 180 + i * 2.0)),
  ];
  
  final result = HandwritingTracingService.instance.scoreTracing(
    character: 'ក',
    userStrokes: strokes,
    canvasSize: Size(400, 400),
  );
  
  expect(result.insideCoverage, greaterThan(50));
  expect(result.finalScore, greaterThan(0));
});
```

### Widget Test Example

```dart
testWidgets('Writing screen shows feedback', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Tập viết'));
  await tester.pumpAndSettle();
  
  // Simulate drawing
  await tester.drag(find.byType(GestureDetector), Offset(50, 50));
  await tester.pumpAndSettle();
  
  // Check button
  await tester.tap(find.text('Xong'));
  await tester.pumpAndSettle();
  
  // Verify feedback is shown
  expect(find.byType(SnackBar), findsOneWidget);
});
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Scores too low | Increase `toleranceRadius` or decrease `passThreshold` |
| Users can cheat | Check "outside > inside" logic is working |
| Template mismatch | Adjust `templateStrokeWidth` |
| No visual feedback | Ensure `_showFeedback = true` after scoring |
| Slow performance | Decrease `gridResolution` (e.g., 32 instead of 64) |

## Performance Tips

1. **Cache template bitmaps** if scoring same character multiple times
2. **Use lower grid resolution** (32x32) for real-time feedback
3. **Debounce scoring** to avoid scoring on every stroke
4. **Dispose resources** properly to avoid memory leaks

## Best Practices

✅ **DO:**
- Show visual feedback after scoring
- Provide helpful tips based on coverage
- Save progress only on pass
- Clear canvas after moving to next character

❌ **DON'T:**
- Score while user is still drawing
- Show feedback before user finishes
- Allow progression without passing
- Forget to handle edge cases (empty strokes, etc.)

## Example Implementation

See `lib/screens/learn/writing_detail_screen.dart` for a complete working example.

## Support

For issues or questions:
- Check documentation: `docs/HANDWRITING_TRACING_IMPLEMENTATION.md`
- Run tests: `flutter test test/handwriting_tracing_test.dart`
- Review code: `lib/services/handwriting_tracing_service.dart`
