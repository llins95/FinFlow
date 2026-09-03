class InstalledAppVersion {
  const InstalledAppVersion({
    required this.name,
    required this.code,
  });

  final String name;
  final int code;

  factory InstalledAppVersion.fromMap(Map<Object?, Object?> map) {
    final name = map['versionName'];
    final code = map['versionCode'];
    if (name is! String || name.trim().isEmpty || code is! num) {
      throw const FormatException('Versão instalada inválida.');
    }

    return InstalledAppVersion(name: name.trim(), code: code.toInt());
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUri,
    required this.checksumUri,
    required this.windowsPackageUri,
    required this.windowsChecksumUri,
    required this.releaseNotes,
  });

  final String versionName;
  final int versionCode;
  final Uri apkUri;
  final Uri checksumUri;
  final Uri? windowsPackageUri;
  final Uri? windowsChecksumUri;
  final String releaseNotes;

  bool isNewerThan(InstalledAppVersion installed) =>
      versionCode > installed.code;

  factory AppUpdateInfo.fromGitHubRelease(Map<String, dynamic> release) {
    final tag = release['tag_name'];
    final assets = release['assets'];
    if (tag is! String || assets is! List) {
      throw const FormatException('Release do FinFlow inválida.');
    }

    final match = RegExp(
      r'^v(\d+\.\d+\.\d+)\+(\d+)$',
    ).firstMatch(tag.trim());
    if (match == null) {
      throw const FormatException('Tag de versão do FinFlow inválida.');
    }

    Uri? findAsset(String expectedName) {
      for (final rawAsset in assets) {
        if (rawAsset is! Map) {
          continue;
        }
        if (rawAsset['name'] != expectedName) {
          continue;
        }
        final url = rawAsset['browser_download_url'];
        if (url is! String) {
          continue;
        }
        final uri = Uri.tryParse(url);
        if (uri != null && uri.scheme == 'https') {
          return uri;
        }
      }
      return null;
    }

    final apkUri = findAsset('FinFlow.apk');
    final checksumUri = findAsset('FinFlow.apk.sha256');
    if (apkUri == null || checksumUri == null) {
      throw const FormatException(
        'A release não contém o APK e o checksum esperados.',
      );
    }

    return AppUpdateInfo(
      versionName: match.group(1)!,
      versionCode: int.parse(match.group(2)!),
      apkUri: apkUri,
      checksumUri: checksumUri,
      windowsPackageUri: findAsset('FinFlow-Windows-x64.zip'),
      windowsChecksumUri: findAsset('FinFlow-Windows-x64.zip.sha256'),
      releaseNotes: (release['body'] as String?)?.trim() ?? '',
    );
  }
}

enum AppUpdateStatus {
  idle,
  unsupported,
  checking,
  upToDate,
  available,
  waitingForInstallPermission,
  downloading,
  openingInstaller,
  error,
}
