import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/notification_purchase_candidate.dart';

class NotificationPurchaseImportService {
  const NotificationPurchaseImportService();

  static const MethodChannel _channel = MethodChannel(
    'com.finflow/notification_imports',
  );

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isSupported() async {
    if (!_isAndroid) {
      return false;
    }
    return _readBoolean('isSupported');
  }

  Future<bool> isAccessGranted() async {
    if (!_isAndroid) {
      return false;
    }
    return _readBoolean('isAccessGranted');
  }

  Future<bool> openAccessSettings() async {
    if (!_isAndroid) {
      return false;
    }
    return _readBoolean('openNotificationAccessSettings');
  }

  Future<List<NotificationPurchaseCandidate>> loadPending() async {
    if (!_isAndroid) {
      return const [];
    }

    try {
      final rawItems = await _channel.invokeMethod<List<Object?>>(
        'getPendingNotifications',
      );
      final candidates = <NotificationPurchaseCandidate>[];

      for (final rawItem in rawItems ?? const <Object?>[]) {
        if (rawItem is! Map) {
          continue;
        }
        final candidate = NotificationPurchaseParser.tryParse(
          Map<Object?, Object?>.from(rawItem),
        );
        if (candidate != null) {
          candidates.add(candidate);
        }
      }

      candidates.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return List.unmodifiable(candidates);
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<bool> dismiss(String candidateId) async {
    if (!_isAndroid || candidateId.isEmpty) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('removeNotifications', {
            'ids': [candidateId],
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> clearPending() async {
    if (!_isAndroid) {
      return true;
    }

    return _readBoolean('clearPendingNotifications');
  }

  Future<bool> _readBoolean(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
