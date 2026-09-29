import 'package:flutter/foundation.dart';

import '../models/app_update.dart';
import '../services/app_update_service.dart';

class AppUpdateController extends ChangeNotifier {
  AppUpdateController(this._gateway);

  final AppUpdateGateway _gateway;

  AppUpdateStatus status = AppUpdateStatus.idle;
  InstalledAppVersion? installedVersion;
  AppUpdateInfo? availableUpdate;
  String? errorMessage;

  bool get isBusy =>
      status == AppUpdateStatus.checking ||
      status == AppUpdateStatus.downloading;

  Future<bool> checkForUpdates() async {
    if (isBusy) {
      return status == AppUpdateStatus.available;
    }

    status = AppUpdateStatus.checking;
    errorMessage = null;
    notifyListeners();

    try {
      if (!await _gateway.isSupported()) {
        status = AppUpdateStatus.unsupported;
        notifyListeners();
        return false;
      }

      installedVersion = await _gateway.getCurrentVersion();
      final latest = await _gateway.fetchLatestRelease();
      if (latest != null && latest.isNewerThan(installedVersion!)) {
        availableUpdate = latest;
        status = AppUpdateStatus.available;
        notifyListeners();
        return true;
      }

      availableUpdate = null;
      status = AppUpdateStatus.upToDate;
      notifyListeners();
      return false;
    } catch (error) {
      status = AppUpdateStatus.error;
      errorMessage = _friendlyMessage(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> downloadAndInstall() async {
    final update = availableUpdate;
    if (update == null || isBusy) {
      return;
    }

    try {
      if (!await _gateway.canRequestPackageInstalls()) {
        status = AppUpdateStatus.waitingForInstallPermission;
        errorMessage = null;
        notifyListeners();
        await _gateway.openInstallPermissionSettings();
        return;
      }

      status = AppUpdateStatus.downloading;
      errorMessage = null;
      notifyListeners();
      await _gateway.downloadAndInstall(update);
      status = AppUpdateStatus.openingInstaller;
      notifyListeners();
    } catch (error) {
      status = AppUpdateStatus.error;
      errorMessage = _friendlyMessage(error);
      notifyListeners();
    }
  }

  Future<void> handleAppResumed() async {
    if (status != AppUpdateStatus.waitingForInstallPermission) {
      return;
    }
    if (await _gateway.canRequestPackageInstalls()) {
      await downloadAndInstall();
    }
  }

  String _friendlyMessage(Object error) {
    final text = error.toString().replaceFirst(RegExp(r'^\w+Exception: '), '');
    return text.isEmpty
        ? 'Não foi possível concluir a atualização.'
        : text;
  }
}
