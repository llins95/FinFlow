import 'package:flutter/foundation.dart';

enum SyncPhase {
  localOnly,
  synced,
  syncing,
  pending,
  error,
}

class SyncStatusController extends ChangeNotifier {
  SyncPhase _phase = SyncPhase.pending;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;
  String? _lastError;

  SyncPhase get phase => _phase;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  String get label {
    return switch (_phase) {
      SyncPhase.localOnly => 'Somente neste aparelho',
      SyncPhase.synced => 'Dados sincronizados',
      SyncPhase.syncing => 'Sincronizando...',
      SyncPhase.pending => 'Aguardando sincronização',
      SyncPhase.error => 'Sincronização indisponível',
    };
  }

  void markSyncing(int pendingCount) {
    _phase = SyncPhase.syncing;
    _pendingCount = pendingCount;
    _lastError = null;
    notifyListeners();
  }

  void markPending(int pendingCount, {String? error}) {
    _phase = SyncPhase.pending;
    _pendingCount = pendingCount;
    _lastError = error;
    notifyListeners();
  }

  void markSynced() {
    _phase = SyncPhase.synced;
    _pendingCount = 0;
    _lastSyncedAt = DateTime.now().toUtc();
    _lastError = null;
    notifyListeners();
  }

  void markError(String error) {
    _phase = SyncPhase.error;
    _lastError = error;
    notifyListeners();
  }
}
