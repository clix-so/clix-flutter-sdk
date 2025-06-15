import 'dart:async';
import 'storage_service.dart';
import '../utils/logger.dart';

class TokenService {
  static const String _tokenKey = 'push_token';
  static const String _tokenTypeKey = 'push_token_type';
  
  final StorageService _storageService;
  String? _currentToken;
  String? _currentTokenType;

  TokenService({required StorageService storage})
      : _storageService = storage;

  Future<void> initialize() async {
    try {
      _currentToken = _storageService.getString(_tokenKey);
      _currentTokenType = _storageService.getString(_tokenTypeKey);
      ClixLogger.debug('TokenService initialized with token type: $_currentTokenType');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to initialize TokenService', e, stackTrace);
      rethrow;
    }
  }

  String? get currentToken => _currentToken;
  String? get currentTokenType => _currentTokenType;

  Future<void> updateToken(String token, String tokenType) async {
    try {
      if (_currentToken == token && _currentTokenType == tokenType) {
        ClixLogger.debug('Token unchanged, skipping update');
        return;
      }

      _currentToken = token;
      _currentTokenType = tokenType;
      
      await _storageService.setString(_tokenKey, token);
      await _storageService.setString(_tokenTypeKey, tokenType);
      
      ClixLogger.info('Push token updated: type=$tokenType');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to update token', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clearToken() async {
    try {
      _currentToken = null;
      _currentTokenType = null;
      
      await _storageService.remove(_tokenKey);
      await _storageService.remove(_tokenTypeKey);
      
      ClixLogger.info('Push token cleared');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to clear token', e, stackTrace);
      rethrow;
    }
  }
}