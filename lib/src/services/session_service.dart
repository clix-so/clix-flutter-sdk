import 'package:flutter/widgets.dart';

import '../utils/logging/clix_logger.dart';
import 'event_service.dart';
import 'storage_service.dart';

enum SessionEvent {
  sessionStart('SESSION_START');

  final String value;
  const SessionEvent(this.value);
}

class SessionService with WidgetsBindingObserver {
  static const String _lastActivityKey = 'clix_session_last_activity';

  final StorageService _storageService;
  final EventService _eventService;
  final int _effectiveTimeoutMs;

  String? _pendingMessageId;

  SessionService({
    required StorageService storageService,
    required EventService eventService,
    required int sessionTimeoutMs,
  })  : _storageService = storageService,
        _eventService = eventService,
        _effectiveTimeoutMs = sessionTimeoutMs < 5000 ? 5000 : sessionTimeoutMs;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);

    try {
      final lastActivity = await _storageService.get<int>(_lastActivityKey);
      if (lastActivity != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastActivity;
        if (elapsed <= _effectiveTimeoutMs) {
          _pendingMessageId = null;
          await _updateLastActivity();
          ClixLogger.debug('Continuing existing session');
          return;
        }
      }
      await _startNewSession();
    } catch (e) {
      ClixLogger.error('Failed to start session', e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    } else if (state == AppLifecycleState.paused) {
      _onPaused();
    }
  }

  void setPendingMessageId(String? messageId) {
    _pendingMessageId = messageId;
  }

  Future<void> _onResumed() async {
    try {
      // Small delay to allow notification tap handlers to set pendingMessageId
      await Future.delayed(const Duration(milliseconds: 100));

      final lastActivity = await _storageService.get<int>(_lastActivityKey);
      if (lastActivity != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastActivity;
        if (elapsed <= _effectiveTimeoutMs) {
          _pendingMessageId = null;
          await _updateLastActivity();
          return;
        }
      }
      await _startNewSession();
    } catch (e) {
      ClixLogger.error('Failed to handle app resumed', e);
    }
  }

  Future<void> _onPaused() async {
    try {
      await _updateLastActivity();
    } catch (e) {
      ClixLogger.error('Failed to handle app paused', e);
    }
  }

  Future<void> _startNewSession() async {
    final messageId = _pendingMessageId;
    _pendingMessageId = null;
    await _updateLastActivity();

    try {
      await _eventService.trackEvent(
        SessionEvent.sessionStart.value,
        messageId: messageId,
      );
      ClixLogger.debug('${SessionEvent.sessionStart.value} tracked');
    } catch (e) {
      ClixLogger.error('Failed to track ${SessionEvent.sessionStart.value}', e);
    }
  }

  void cleanup() {
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> _updateLastActivity() async {
    await _storageService.set<int>(
        _lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }
}
