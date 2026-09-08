import 'dart:convert';

/// Deterministic Canonical JSON Serializer for Cryptographic Hashing
/// Ensures identical byte-for-byte serialization across all platforms and environments.
class CanonicalSerializer {
  CanonicalSerializer._();

  /// Serializes any JSON-compatible object into a deterministic canonical UTF-8 JSON string.
  /// Maps are sorted lexicographically by key at all levels.
  /// Numbers are formatted deterministically.
  static String serialize(dynamic value) {
    return _canonicalize(value);
  }

  static String _canonicalize(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is bool) {
      return value ? 'true' : 'false';
    } else if (value is int) {
      return value.toString();
    } else if (value is double) {
      // Format double with exact reproducible decimal representation
      if (value.isNaN || value.isInfinite) {
        throw ArgumentError('NaN and Infinite values are not permitted in canonical payloads');
      }
      // Remove trailing zeroes after dot or keep clean representation
      String formatted = value.toStringAsFixed(6);
      while (formatted.contains('.') && (formatted.endsWith('0') || formatted.endsWith('.'))) {
        if (formatted.endsWith('.')) {
          formatted = formatted.substring(0, formatted.length - 1);
          break;
        }
        formatted = formatted.substring(0, formatted.length - 1);
      }
      return formatted;
    } else if (value is String) {
      return jsonEncode(value);
    } else if (value is List) {
      final items = value.map((item) => _canonicalize(item)).join(',');
      return '[$items]';
    } else if (value is Map) {
      final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
      final entries = sortedKeys.map((k) {
        final keyStr = jsonEncode(k);
        final valStr = _canonicalize(value[k]);
        return '$keyStr:$valStr';
      }).join(',');
      return '{$entries}';
    } else {
      throw ArgumentError('Unsupported type in canonical serializer: ${value.runtimeType}');
    }
  }
}
