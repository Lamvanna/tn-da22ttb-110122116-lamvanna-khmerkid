# Handwriting Tracing Feature - Implementation Documentation

## Overview

This document describes the implementation of the handwriting recognition and scoring feature for the Khmer language learning app. The system uses **template-based pixel coverage scoring** instead of OCR or shape recognition.

## Architecture

### Core Components

1. **HandwritingTracingService** (`lib/services/handwriting_tracing_service.dart`)
   - Main scoring engine
   - Template bitmap generation
   - Stroke analysis and coverage calculation
   - Visual feedback generation

2. **WritingDetailScreen** (`lib/screens/learn/writing_detail_screen.dart`)
   - User interface for handwriting practice
   - Canvas for drawing
   - Visual feedback display (green/yellow/red strokes)

3. **ScoringService Integration** (`lib/services/scoring_service.dart`)
   - Bridge between old and new scoring systems
   - Maintains backward compatibility

## Scoring Algorithm

### 1. Template Bitmap Generation

The system creates a grid-based bitmap (64x64 resolution) representing the template character:

```dart
// Template is rendered at the center of canvas
// Grid cells are marked as "inside template" or "outside template"
final grid = List.generate(64, (_) => List.filled(64, false));
```

**Key Parameters:**
- `gridResolution`: 64x64 cells
- `templateStrokeWidth`: 180.0 (font size)
- `toleranceRadius`: 25.0 (pixels for "near" detection)

### 2. Stroke Analysis

Each point in the user's strokes is analyzed:

```dart
for (final point in stroke) {
  // Find corresponding grid cell
  final col = (point.dx / cellWidth).floor();
  final row = (point.dy / cellHeight).floor();
  
  // Check if point is inside/near/outside template
  if (grid[row][col]) {
    insidePoints++;  // Green
  } else if (isNear) {
    nearPoints++;    // Yellow (counted as 70% inside)
  } else {
    outsidePoints++; // Red
  }
}
```

### 3. Coverage Calculation

```dart
totalPoints = insidePoints + outsidePoints + nearPoints;
insideCoverage = (insidePoints + nearPoints * 0.7) / totalPoints * 100;
outsideCoverage = outsidePoints / totalPoints * 100;
```

### 4. Final Score Calculation

```dart
// Apply penalty for outside strokes
outsidePenalty = outsideCoverage * 0.5;
finalScore = insideCoverage - outsidePenalty;
finalScore = finalScore.clamp(0.0, 100.0);
```

### 5. Pass/Fail Logic

```dart
// Fail condition 1: Outside > Inside
if (outsideCoverage > insideCoverage) {
  return FAIL (score = 0);
}

// Fail condition 2: Score < 70%
if (finalScore < 70.0) {
  return FAIL;
}

// Otherwise: PASS
return PASS;
```

## Scoring Rules

### Pass Criteria
- **Final Score ≥ 70%**: Pass and unlock next lesson
- **Inside Coverage > Outside Coverage**: Required to pass
- **Stars awarded**:
  - 3 stars: Score ≥ 90%
  - 2 stars: Score ≥ 80%
  - 1 star: Score ≥ 70%
  - 0 stars: Score < 70%

### Fail Conditions
1. **Outside Coverage > Inside Coverage**: Automatic fail (score = 0)
   - User drew more outside the template than inside
   - Prevents "scribbling" or "filling the canvas" cheating

2. **Final Score < 70%**: Retry required
   - Not enough overlap with template
   - Too many strokes outside template area

## Visual Feedback

After checking, the system displays colored strokes:

- **Green**: Strokes correctly on template
- **Yellow**: Strokes near template (within tolerance radius)
- **Red**: Strokes outside template

```dart
class StrokeSegment {
  final List<Offset> points;
  final Color color;  // Green, Yellow, or Red
}
```

## Example Scenarios

### Scenario 1: Perfect Tracing
```
Inside Coverage: 90%
Outside Coverage: 10%
Final Score: 90 - (10 * 0.5) = 85%
Result: PASS ⭐⭐
```

### Scenario 2: Good but with some errors
```
Inside Coverage: 75%
Outside Coverage: 25%
Final Score: 75 - (25 * 0.5) = 62.5%
Result: FAIL (score < 70%)
Tips: "Tránh vẽ lan ra ngoài chữ mẫu"
```

### Scenario 3: Mostly Outside (Scribbling)
```
Inside Coverage: 40%
Outside Coverage: 60%
Result: FAIL (outside > inside)
Score: 0
Feedback: "Không đạt - Viết quá nhiều ngoài chữ mẫu"
```

### Scenario 4: Excellent Tracing
```
Inside Coverage: 95%
Outside Coverage: 5%
Final Score: 95 - (5 * 0.5) = 92.5%
Result: PASS ⭐⭐⭐
Feedback: "Xuất sắc! ⭐⭐⭐"
```

## Configuration Parameters

You can adjust these constants in `HandwritingTracingService`:

```dart
static const double strokeWidth = 4.0;           // User stroke thickness
static const double templateStrokeWidth = 180.0; // Template font size
static const double toleranceRadius = 25.0;      // "Near" detection radius
static const double passThreshold = 70.0;        // Minimum score to pass
static const int gridResolution = 64;            // Grid size (64x64)
```

### Tuning Guidelines

- **Increase `toleranceRadius`**: Make scoring more lenient (accept strokes further from template)
- **Decrease `passThreshold`**: Make it easier to pass (e.g., 60% instead of 70%)
- **Increase `gridResolution`**: More accurate but slower (e.g., 128x128)
- **Adjust `outsidePenalty` multiplier**: Currently 0.5 (50% penalty for outside strokes)

## Integration with Existing Code

### ScoringService Bridge

The new tracing service is integrated through `ScoringService.recognizeWriting()`:

```dart
RecognitionResult recognizeWriting({
  required String character,
  required List<List<Offset>> strokes,
  required Size canvasSize,
}) {
  // Use new HandwritingTracingService
  final tracingResult = HandwritingTracingService.instance.scoreTracing(
    character: character,
    userStrokes: strokes,
    canvasSize: canvasSize,
  );

  // Convert to RecognitionResult for backward compatibility
  return RecognitionResult(...);
}
```

### Legacy Support

The old $1 Unistroke Recognizer algorithm is preserved as `recognizeWritingLegacy()` for backward compatibility.

## Testing

Comprehensive tests are provided in `test/handwriting_tracing_test.dart`:

- Empty strokes handling
- Outside template detection
- Inside template detection
- Pass/fail logic
- Star rating calculation
- Visual feedback generation
- Multiple character support
- Feedback message generation

Run tests:
```bash
flutter test test/handwriting_tracing_test.dart
```

## Performance Considerations

### Optimization Strategies

1. **Grid-based approach**: O(n) complexity where n = number of stroke points
2. **Pre-computed template bitmap**: Template is generated once per character
3. **Efficient cell lookup**: Direct array indexing instead of distance calculations
4. **Tolerance radius**: Reduces false negatives without expensive calculations

### Memory Usage

- Template grid: 64x64 = 4,096 booleans ≈ 4KB per character
- User strokes: Varies based on drawing complexity
- Visual feedback: Stored only during feedback display

## Future Enhancements

### Potential Improvements

1. **Stroke Order Detection**: Check if user follows correct stroke sequence
2. **Pressure Sensitivity**: Use stroke pressure data if available
3. **Time-based Analysis**: Detect rushed vs. careful writing
4. **Adaptive Difficulty**: Adjust tolerance based on user age/skill level
5. **Machine Learning**: Train model on real user data for better accuracy

### Advanced Features

1. **Real-time Feedback**: Show green/yellow/red while drawing (not just after)
2. **Guided Tracing**: Animate the correct stroke order
3. **Progressive Hints**: Show partial template if user struggles
4. **Comparison View**: Side-by-side user vs. template comparison

## Troubleshooting

### Common Issues

**Issue**: Scores are too low even for good tracing
- **Solution**: Increase `toleranceRadius` or decrease `passThreshold`

**Issue**: Users can cheat by scribbling
- **Solution**: The "outside > inside" check prevents this

**Issue**: Template doesn't match font rendering
- **Solution**: Adjust `templateStrokeWidth` to match visual appearance

**Issue**: Visual feedback not showing
- **Solution**: Check that `_showFeedback` is set to true after scoring

## API Reference

### HandwritingTracingService

#### `scoreTracing()`
```dart
TracingScoreResult scoreTracing({
  required String character,
  required List<List<Offset>> userStrokes,
  required Size canvasSize,
})
```

**Parameters:**
- `character`: The Khmer character to trace
- `userStrokes`: List of strokes (each stroke is a list of Offset points)
- `canvasSize`: Size of the drawing canvas

**Returns:** `TracingScoreResult` containing:
- `insideCoverage`: Percentage of strokes on template (0-100)
- `outsideCoverage`: Percentage of strokes outside template (0-100)
- `finalScore`: Final score after penalties (0-100)
- `passed`: Whether the user passed (bool)
- `stars`: Number of stars earned (0-3)
- `feedback`: Feedback message (String)
- `tips`: List of improvement tips (List<String>)
- `visualFeedback`: Colored stroke segments for display (List<StrokeSegment>)

## Conclusion

This implementation provides a robust, cheat-resistant handwriting scoring system that:
- ✅ Scores based on template overlap (not OCR)
- ✅ Prevents scribbling/cheating
- ✅ Provides visual feedback
- ✅ Works for all Khmer characters
- ✅ Is configurable and tunable
- ✅ Has comprehensive test coverage

The system prioritizes accuracy and fairness while being lenient enough for children learning to write.
