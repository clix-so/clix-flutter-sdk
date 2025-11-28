import 'dart:convert';

import '../services/notification_service.dart';
import '../utils/logging/clix_logger.dart';
import 'messages.g.dart';

class ClixNativeBridge implements ClixFlutterApi {
  final NotificationService _notificationService;

  ClixNativeBridge(this._notificationService);

  @override
  void onNotificationTapped(Map<String?, Object?> userInfo) {
    try {
      final data = <String, dynamic>{};
      for (final entry in userInfo.entries) {
        if (entry.key != null) {
          data[entry.key!] = entry.value;
        }
      }

      if (data.containsKey('clix')) {
        final clixData = data['clix'];
        if (clixData is String) {
          data['clix'] = jsonDecode(clixData);
        }
        _notificationService.handleNotificationTap(data);
        return;
      }

      if (data.containsKey('payload')) {
        final payload = data['payload'];
        if (payload is String) {
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          _notificationService.handleNotificationTap(decoded);
          return;
        }
      }
    } catch (e) {
      ClixLogger.error('Failed to handle native notification tap', e);
    }
  }
}
