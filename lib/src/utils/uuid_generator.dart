import 'dart:math';

/// Simple UUID v4 generator
/// Generates random UUIDs without external dependencies
class UuidGenerator {
  static final Random _random = Random();
  
  /// Generates a random UUID v4 string
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  /// where x is any hexadecimal digit and y is one of 8, 9, A, or B
  static String generateV4() {
    final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    
    // Set version to 4 (bits 12-15 of 7th byte)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    
    // Set variant to 10 (bits 6-7 of 9th byte)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    
    return _formatUuid(bytes);
  }
  
  /// Formats bytes into standard UUID string format
  static String _formatUuid(List<int> bytes) {
    final buffer = StringBuffer();
    
    for (int i = 0; i < bytes.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    
    return buffer.toString();
  }
}