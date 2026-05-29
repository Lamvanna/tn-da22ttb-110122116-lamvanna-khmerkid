import 'dart:math';
import 'dart:ui';

class RecognitionMatch {
  final String character;
  final double score; // 0.0 to 1.0

  RecognitionMatch({required this.character, required this.score});
}

class DollarOneRecognizer {
  static const int numPoints = 128;
  static const double squareSize = 250.0;
  static final double halfDiagonal = 0.5 * sqrt(squareSize * squareSize * 2);

  // Golden Ratio for GSS (Golden Section Search)
  static final double phi = 0.5 * (sqrt(5.0) - 1.0);

  /// Resample a path of points into N evenly-spaced points
  static List<Offset> resample(List<Offset> points, int n) {
    if (points.isEmpty) return [];
    double length = pathLength(points);
    double interval = length / (n - 1);
    double D = 0.0;
    List<Offset> newPoints = [points.first];
    List<Offset> pts = List<Offset>.from(points);

    for (int i = 1; i < pts.length; i++) {
      double d = (pts[i] - pts[i - 1]).distance;
      if ((D + d) >= interval) {
        double qx = pts[i - 1].dx + ((interval - D) / d) * (pts[i].dx - pts[i - 1].dx);
        double qy = pts[i - 1].dy + ((interval - D) / d) * (pts[i].dy - pts[i - 1].dy);
        Offset q = Offset(qx, qy);
        newPoints.add(q);
        pts.insert(i, q); // Insert q so it becomes the next starting point
        D = 0.0;
      } else {
        D += d;
      }
    }

    // Handle float precision rounding anomalies
    while (newPoints.length < n) {
      newPoints.add(pts.last);
    }
    if (newPoints.length > n) {
      newPoints = newPoints.sublist(0, n);
    }
    return newPoints;
  }

  /// Calculate the total path length
  static double pathLength(List<Offset> points) {
    double d = 0.0;
    for (int i = 1; i < points.length; i++) {
      d += (points[i] - points[i - 1]).distance;
    }
    return d;
  }

  /// Rotate points by an angle (in radians) around their centroid
  static List<Offset> rotateBy(List<Offset> points, double radians) {
    Offset c = centroid(points);
    double cosTheta = cos(radians);
    double sinTheta = sin(radians);
    List<Offset> newPoints = [];
    for (Offset p in points) {
      double qx = (p.dx - c.dx) * cosTheta - (p.dy - c.dy) * sinTheta + c.dx;
      double qy = (p.dx - c.dx) * sinTheta + (p.dy - c.dy) * cosTheta + c.dy;
      newPoints.add(Offset(qx, qy));
    }
    return newPoints;
  }

  /// Scale points to fit a bounding box of squareSize x squareSize
  static List<Offset> scaleToSquare(List<Offset> points, double size) {
    if (points.isEmpty) return [];
    var bounds = boundingBox(points);
    double width = bounds.width;
    double height = bounds.height;
    
    // Avoid division by zero for straight vertical/horizontal lines
    if (width == 0) width = 0.0001;
    if (height == 0) height = 0.0001;

    List<Offset> newPoints = [];
    for (Offset p in points) {
      double qx = p.dx * (size / width);
      double qy = p.dy * (size / height);
      newPoints.add(Offset(qx, qy));
    }
    return newPoints;
  }

  /// Translate points to center at origin (0, 0)
  static List<Offset> translateToOrigin(List<Offset> points) {
    Offset c = centroid(points);
    List<Offset> newPoints = [];
    for (Offset p in points) {
      newPoints.add(p - c);
    }
    return newPoints;
  }

  /// Compute centroid (center of mass) of points
  static Offset centroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    double x = 0.0, y = 0.0;
    for (Offset p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }

  /// Compute bounding box of points
  static Rect boundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (Offset p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Distance between two paths point-by-point
  static double pathDistance(List<Offset> pts1, List<Offset> pts2) {
    double d = 0.0;
    int len = min(pts1.length, pts2.length);
    if (len == 0) return 0.0;
    for (int i = 0; i < len; i++) {
      d += (pts1[i] - pts2[i]).distance;
    }
    return d / len;
  }

  /// Distance at best angle (using Golden Section Search)
  static double distanceAtBestAngle(
    List<Offset> points,
    List<Offset> templatePoints,
    double a,
    double b,
    double threshold,
  ) {
    double x1 = phi * a + (1.0 - phi) * b;
    double f1 = distanceAtAngle(points, templatePoints, x1);
    double x2 = (1.0 - phi) * a + phi * b;
    double f2 = distanceAtAngle(points, templatePoints, x2);

    while ((b - a).abs() > threshold) {
      if (f1 < f2) {
        b = x2;
        x2 = x1;
        f2 = f1;
        x1 = phi * a + (1.0 - phi) * b;
        f1 = distanceAtAngle(points, templatePoints, x1);
      } else {
        a = x1;
        x1 = x2;
        f1 = f2;
        x2 = (1.0 - phi) * a + phi * b;
        f2 = distanceAtAngle(points, templatePoints, x2);
      }
    }
    return min(f1, f2);
  }

  static double distanceAtAngle(
    List<Offset> points,
    List<Offset> templatePoints,
    double radians,
  ) {
    List<Offset> rotatedPoints = rotateBy(points, radians);
    return pathDistance(rotatedPoints, templatePoints);
  }

  /// Preprocess user drawing (or template drawing)
  /// - Resample to 128 points
  /// - Scale to 250x250 square
  /// - Center at origin (0, 0)
  static List<Offset> preprocess(List<Offset> points) {
    if (points.isEmpty) return [];
    List<Offset> pts = resample(points, numPoints);
    pts = scaleToSquare(pts, squareSize);
    pts = translateToOrigin(pts);
    return pts;
  }

  /// Merge multiple strokes into a single continuous path
  static List<Offset> mergeStrokes(List<List<Offset>> strokes) {
    List<Offset> merged = [];
    for (var stroke in strokes) {
      merged.addAll(stroke);
    }
    return merged;
  }

  /// Recognize a processed path against a set of templates
  /// Since Khmer is rotation-sensitive, we search within a narrow range (-15 to +15 degrees)
  static RecognitionMatch recognize(
    List<Offset> userPath,
    Map<String, List<Offset>> templates,
  ) {
    if (userPath.isEmpty || templates.isEmpty) {
      return RecognitionMatch(character: '', score: 0.0);
    }

    // Preprocess user path
    List<Offset> processedUser = preprocess(userPath);

    String bestChar = '';
    double bestScore = -1.0;

    templates.forEach((character, templatePath) {
      if (templatePath.isEmpty) return;
      
      // Compute GSS distance within ±15 degrees (approx 0.26 radians)
      double d = distanceAtBestAngle(
        processedUser,
        templatePath,
        -15.0 * (pi / 180.0),
        15.0 * (pi / 180.0),
        2.0 * (pi / 180.0),
      );

      // Wobbrock's score calculation
      double score = 1.0 - (d / halfDiagonal);
      if (score < 0.0) score = 0.0;

      if (score > bestScore) {
        bestScore = score;
        bestChar = character;
      }
    });

    return RecognitionMatch(character: bestChar, score: bestScore);
  }
}
