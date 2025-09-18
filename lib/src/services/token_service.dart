import '../utils/logging/clix_logger.dart';
import 'storage_service.dart';

class TokenService {
  final StorageService _storageService;
  static const String _currentTokenKey = 'clix_current_push_token';
  static const String _previousTokensKey = 'clix_push_tokens';

  TokenService({required StorageService storageService})
      : _storageService = storageService;

  Future<String?> getCurrentToken() async {
    try {
      return await _storageService.get<String>(_currentTokenKey);
    } catch (e) {
      ClixLogger.error('Failed to get current token', e);
      return null;
    }
  }

  Future<List<String>> getPreviousTokens() async {
    try {
      final result =
          await _storageService.get<List<dynamic>>(_previousTokensKey);
      if (result == null) return [];

      return result.map((item) => item.toString()).toList();
    } catch (e) {
      ClixLogger.error('Failed to get previous tokens', e);
      return [];
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _storageService.set<String>(_currentTokenKey, token);

      List<String> tokens = await getPreviousTokens();

      final currentIndex = tokens.indexOf(token);
      if (currentIndex != -1) {
        tokens.removeAt(currentIndex);
      }

      tokens.add(token);

      const maxTokens = 5;
      if (tokens.length > maxTokens) {
        tokens = tokens.skip(tokens.length - maxTokens).toList();
      }

      await _storageService.set<List<dynamic>>(_previousTokensKey, tokens);
      ClixLogger.debug('Token saved successfully');
    } catch (e) {
      ClixLogger.error('Failed to save token', e);
      rethrow;
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storageService.remove(_previousTokensKey);
      await _storageService.remove(_currentTokenKey);
      ClixLogger.debug('All tokens cleared');
    } catch (e) {
      ClixLogger.error('Failed to clear tokens', e);
      rethrow;
    }
  }

  String convertTokenToString(List<int> deviceToken) {
    final tokenParts =
        deviceToken.map((data) => data.toRadixString(16).padLeft(2, '0'));
    return tokenParts.join();
  }

  Future<void> reset() async {
    await clearTokens();
  }
}
