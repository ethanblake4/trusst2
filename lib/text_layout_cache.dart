import 'package:flutter/painting.dart';
import 'package:quiver/collection.dart';

/// Caches laid-out [TextPainter] widgets, since it is expensive to layout them every frame
class TextLayoutCache {
  final LruMap<int, TextPainter> _cache;
  final TextDirection textDirection;

  TextLayoutCache(this.textDirection, int maximumSize) : _cache = LruMap<int, TextPainter>(maximumSize: maximumSize);

  TextPainter getOrPerformLayout(TextSpan text) {
    final cachedPainter = _cache[text.hashCode];
    if (cachedPainter != null) {
      return cachedPainter;
    } else {
      return _performAndCacheLayout(text);
    }
  }

  TextPainter _performAndCacheLayout(TextSpan text) {
    final textPainter = TextPainter(text: text, textDirection: textDirection);
    textPainter.layout();

    _cache[text.hashCode] = textPainter;

    return textPainter;
  }
}
