import '../utils/logger.dart';
import '../utils/clix_error.dart';
import 'storage_service.dart';

/// Token service for managing push notification tokens
class TokenService {
  final StorageService _storage;

  static const String _currentTokenKey = 'current_push_token';
  static const String _tokenHistoryKey = 'push_token_history';
  static const int _maxTokenHistory = 5;

  TokenService({
    required StorageService storage,
  }) : _storage = storage;

  /// Get current push token
  String? getCurrentToken() {
    try {
      return _storage.getString(_currentTokenKey);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get current token', e, stackTrace);
      return null;
    }
  }

  /// Set current push token
  Future<void> setCurrentToken(String token) async {
    try {
      final previousToken = getCurrentToken();

      // Don't update if token hasn't changed
      if (previousToken == token) {
        ClixLogger.debug('Token unchanged, skipping update');
        return;
      }

      // Store new token
      await _storage.setString(_currentTokenKey, token);

      // Add to history if there was a previous token
      if (previousToken != null && previousToken.isNotEmpty) {
        await _addTokenToHistory(previousToken);
      }

      ClixLogger.info('Push token updated');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set current token', e, stackTrace);
      throw ClixError.now(
        code: 'SET_TOKEN_ERROR',
        message: 'Failed to set push token: $e',
        details: e,
      );
    }
  }

  /// Get token history
  List<String> getTokenHistory() {
    try {
      final historyJson = _storage.getJson(_tokenHistoryKey);
      if (historyJson == null) return [];

      final historyList = historyJson['tokens'] as List<dynamic>? ?? [];
      return historyList.cast<String>();
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get token history', e, stackTrace);
      return [];
    }
  }

  /// Check if token is valid (basic validation)
  bool isValidToken(String? token) {
    if (token == null || token.isEmpty) return false;

    // Basic token validation - should be a reasonable length
    if (token.length < 10) return false;

    // Check if token contains only valid characters (alphanumeric, hyphens, underscores, colons)
    final validTokenRegex = RegExp(r'^[a-zA-Z0-9\-_:]+$');
    return validTokenRegex.hasMatch(token);
  }

  /// Clear current token
  Future<void> clearCurrentToken() async {
    try {
      final currentToken = getCurrentToken();
      if (currentToken != null) {
        await _addTokenToHistory(currentToken);
      }

      await _storage.remove(_currentTokenKey);
      ClixLogger.info('Push token cleared');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to clear current token', e, stackTrace);
      throw ClixError.now(
        code: 'CLEAR_TOKEN_ERROR',
        message: 'Failed to clear push token: $e',
        details: e,
      );
    }
  }

  /// Clear all tokens including history
  Future<void> clearAllTokens() async {
    try {
      await _storage.remove(_currentTokenKey);
      await _storage.remove(_tokenHistoryKey);
      ClixLogger.info('All push tokens cleared');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to clear all tokens', e, stackTrace);
      throw ClixError.now(
        code: 'CLEAR_ALL_TOKENS_ERROR',
        message: 'Failed to clear all tokens: $e',
        details: e,
      );
    }
  }

  /// Check if we have a current token
  bool hasCurrentToken() {
    final token = getCurrentToken();
    return isValidToken(token);
  }

  /// Get token for specific platform (for compatibility)
  String? getTokenForPlatform(String platform) {
    // For Flutter, we only have one token type per platform
    return getCurrentToken();
  }

  /// Convert token to different format if needed
  String? convertToken(String token, String format) {
    // Basic token conversion if needed
    // This could be extended for different token formats
    switch (format.toLowerCase()) {
      case 'base64':
        // If token needs base64 encoding
        return token; // Tokens are usually already in the correct format
      case 'raw':
        return token;
      default:
        return token;
    }
  }

  /// Get token metadata
  Map<String, dynamic> getTokenMetadata() {
    final currentToken = getCurrentToken();
    final history = getTokenHistory();

    return {
      'hasCurrentToken': hasCurrentToken(),
      'currentTokenLength': currentToken?.length ?? 0,
      'historyCount': history.length,
      'lastUpdated': _storage.getString('${_currentTokenKey}_timestamp'),
    };
  }

  // Private helper methods

  Future<void> _addTokenToHistory(String token) async {
    try {
      final history = getTokenHistory();

      // Don't add duplicate tokens
      if (history.contains(token)) {
        return;
      }

      // Add token to beginning of history
      history.insert(0, token);

      // Limit history size
      if (history.length > _maxTokenHistory) {
        history.removeRange(_maxTokenHistory, history.length);
      }

      // Store updated history
      await _storage.setJson(_tokenHistoryKey, {'tokens': history});

      // Store timestamp
      await _storage.setString(
        '${_currentTokenKey}_timestamp',
        DateTime.now().toIso8601String(),
      );

      ClixLogger.debug('Token added to history (${history.length} total)');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to add token to history', e, stackTrace);
      // Don't throw here as it's not critical
    }
  }
}
