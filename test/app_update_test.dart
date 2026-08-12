import 'package:finflow/controllers/app_update_controller.dart';
import 'package:finflow/models/app_update.dart';
import 'package:finflow/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const installed = InstalledAppVersion(name: '1.0.0', code: 1);
  final update = AppUpdateInfo(
    versionName: '1.1.0',
    versionCode: 2,
    apkUri: Uri.https('github.com', '/example/FinFlow.apk'),
    checksumUri: Uri.https(
      'github.com',
      '/example/FinFlow.apk.sha256',
    ),
    windowsPackageUri: Uri.https(
      'github.com',
      '/example/FinFlow-Windows-x64.zip',
    ),
    windowsChecksumUri: Uri.https(
      'github.com',
      '/example/FinFlow-Windows-x64.zip.sha256',
    ),
    releaseNotes: 'Versão de teste.',
  );

  test('interpreta uma release versionada do GitHub', () {
    final parsed = AppUpdateInfo.fromGitHubRelease({
      'tag_name': 'v1.1.0+2',
      'body': 'Novidades',
      'assets': [
        {
          'name': 'FinFlow.apk',
          'browser_download_url': 'https://github.com/demo/FinFlow.apk',
        },
        {
          'name': 'FinFlow.apk.sha256',
          'browser_download_url':
              'https://github.com/demo/FinFlow.apk.sha256',
        },
        {
          'name': 'FinFlow-Windows-x64.zip',
          'browser_download_url':
              'https://github.com/demo/FinFlow-Windows-x64.zip',
        },
        {
          'name': 'FinFlow-Windows-x64.zip.sha256',
          'browser_download_url':
              'https://github.com/demo/FinFlow-Windows-x64.zip.sha256',
        },
      ],
    });

    expect(parsed.versionName, '1.1.0');
    expect(parsed.versionCode, 2);
    expect(parsed.releaseNotes, 'Novidades');
    expect(parsed.isNewerThan(installed), isTrue);
    expect(
      parsed.windowsPackageUri,
      Uri.https('github.com', '/demo/FinFlow-Windows-x64.zip'),
    );
    expect(
      parsed.windowsChecksumUri,
      Uri.https('github.com', '/demo/FinFlow-Windows-x64.zip.sha256'),
    );
  });

  test('aceita release Android anterior sem pacote do Windows', () {
    final parsed = AppUpdateInfo.fromGitHubRelease({
      'tag_name': 'v1.3.0+4',
      'assets': [
        {
          'name': 'FinFlow.apk',
          'browser_download_url': 'https://github.com/demo/FinFlow.apk',
        },
        {
          'name': 'FinFlow.apk.sha256',
          'browser_download_url':
              'https://github.com/demo/FinFlow.apk.sha256',
        },
      ],
    });

    expect(parsed.windowsPackageUri, isNull);
    expect(parsed.windowsChecksumUri, isNull);
  });

  test('rejeita release sem APK ou checksum', () {
    expect(
      () => AppUpdateInfo.fromGitHubRelease({
        'tag_name': 'v1.1.0+2',
        'assets': const [],
      }),
      throwsFormatException,
    );
  });

  test('detecta uma versão mais nova', () async {
    final gateway = _FakeUpdateGateway(
      installed: installed,
      latest: update,
    );
    final controller = AppUpdateController(gateway);

    expect(await controller.checkForUpdates(), isTrue);
    expect(controller.status, AppUpdateStatus.available);
    expect(controller.availableUpdate, same(update));

    controller.dispose();
  });

  test('solicita permissão e continua ao voltar para o app', () async {
    final gateway = _FakeUpdateGateway(
      installed: installed,
      latest: update,
      installPermission: false,
    );
    final controller = AppUpdateController(gateway);

    await controller.checkForUpdates();
    await controller.downloadAndInstall();

    expect(
      controller.status,
      AppUpdateStatus.waitingForInstallPermission,
    );
    expect(gateway.permissionSettingsOpened, isTrue);
    expect(gateway.downloadCalled, isFalse);

    gateway.installPermission = true;
    await controller.handleAppResumed();

    expect(gateway.downloadCalled, isTrue);
    expect(controller.status, AppUpdateStatus.openingInstaller);

    controller.dispose();
  });
}

class _FakeUpdateGateway implements AppUpdateGateway {
  _FakeUpdateGateway({
    required this.installed,
    required this.latest,
    this.installPermission = true,
  });

  final InstalledAppVersion installed;
  final AppUpdateInfo? latest;
  bool installPermission;
  bool permissionSettingsOpened = false;
  bool downloadCalled = false;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<InstalledAppVersion> getCurrentVersion() async => installed;

  @override
  Future<AppUpdateInfo?> fetchLatestRelease() async => latest;

  @override
  Future<bool> canRequestPackageInstalls() async => installPermission;

  @override
  Future<void> openInstallPermissionSettings() async {
    permissionSettingsOpened = true;
  }

  @override
  Future<void> downloadAndInstall(AppUpdateInfo update) async {
    downloadCalled = true;
  }
}
