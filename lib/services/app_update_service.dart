import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_update.dart';

abstract interface class AppUpdateGateway {
  Future<bool> isSupported();

  Future<InstalledAppVersion> getCurrentVersion();

  Future<AppUpdateInfo?> fetchLatestRelease();

  Future<bool> canRequestPackageInstalls();

  Future<void> openInstallPermissionSettings();

  Future<void> downloadAndInstall(AppUpdateInfo update);
}

class AppUpdateService implements AppUpdateGateway {
  AppUpdateService({
    HttpClient? httpClient,
    Uri? releasesApi,
  }) : _httpClient = httpClient ?? HttpClient(),
       releasesApi = releasesApi ?? _defaultReleasesApi;

  static final Uri _defaultReleasesApi = Uri.https(
    'api.github.com',
    '/repos/llins95/FinFlow/releases/latest',
  );
  static const MethodChannel _channel = MethodChannel(
    'com.finflow/app_updates',
  );
  static const int _maxMetadataBytes = 1024 * 1024;
  static const int _maxApkBytes = 250 * 1024 * 1024;
  static const int _maxWindowsPackageBytes = 500 * 1024 * 1024;

  final HttpClient _httpClient;
  final Uri releasesApi;

  @override
  Future<bool> isSupported() async => Platform.isAndroid || Platform.isWindows;

  @override
  Future<InstalledAppVersion> getCurrentVersion() async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'getCurrentVersion',
    );
    if (raw == null) {
      throw StateError('O sistema não informou a versão instalada.');
    }
    return InstalledAppVersion.fromMap(raw);
  }

  @override
  Future<AppUpdateInfo?> fetchLatestRelease() async {
    final response = await _get(releasesApi, acceptJson: true);
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain<void>();
      return null;
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'O GitHub respondeu com HTTP ${response.statusCode}.',
        uri: releasesApi,
      );
    }

    final text = await _readText(response, maxBytes: _maxMetadataBytes);
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta de atualização inválida.');
    }
    return AppUpdateInfo.fromGitHubRelease(decoded);
  }

  @override
  Future<bool> canRequestPackageInstalls() async {
    if (Platform.isWindows) {
      return true;
    }
    return await _channel.invokeMethod<bool>(
          'canRequestPackageInstalls',
        ) ??
        false;
  }

  @override
  Future<void> openInstallPermissionSettings() async {
    if (Platform.isWindows) {
      return;
    }
    await _channel.invokeMethod<void>('openInstallPermissionSettings');
  }

  @override
  Future<void> downloadAndInstall(AppUpdateInfo update) async {
    if (Platform.isWindows) {
      await _downloadAndApplyWindows(update);
      return;
    }

    final expectedChecksum = await _fetchChecksum(update.checksumUri);
    final temporaryDirectory = await getTemporaryDirectory();
    final updateDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}updates',
    );
    await updateDirectory.create(recursive: true);

    final apk = File(
      '${updateDirectory.path}${Platform.pathSeparator}'
      'FinFlow-${update.versionCode}.apk',
    );

    if (!await _matchesChecksum(apk, expectedChecksum)) {
      await _downloadPackage(
        update.apkUri,
        apk,
        maxBytes: _maxApkBytes,
        description: 'APK',
      );
      if (!await _matchesChecksum(apk, expectedChecksum)) {
        await apk.delete().catchError((_) => apk);
        throw const FormatException(
          'O arquivo baixado não passou na validação SHA-256.',
        );
      }
    }

    final opened = await _channel.invokeMethod<bool>(
      'installApk',
      {'path': apk.path},
    );
    if (opened != true) {
      throw StateError('O instalador do Android não pôde ser aberto.');
    }
  }

  Future<void> _downloadAndApplyWindows(AppUpdateInfo update) async {
    final packageUri = update.windowsPackageUri;
    final checksumUri = update.windowsChecksumUri;
    if (packageUri == null || checksumUri == null) {
      throw const FormatException(
        'A release não contém o pacote de atualização do Windows.',
      );
    }

    final expectedChecksum = await _fetchChecksum(checksumUri);
    final temporaryDirectory = await getTemporaryDirectory();
    final updateDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}updates',
    );
    await updateDirectory.create(recursive: true);

    final archive = File(
      '${updateDirectory.path}${Platform.pathSeparator}'
      'FinFlow-Windows-${update.versionCode}.zip',
    );
    if (!await _matchesChecksum(archive, expectedChecksum)) {
      await _downloadPackage(
        packageUri,
        archive,
        maxBytes: _maxWindowsPackageBytes,
        description: 'pacote do Windows',
      );
      if (!await _matchesChecksum(archive, expectedChecksum)) {
        await archive.delete().catchError((_) => archive);
        throw const FormatException(
          'O pacote do Windows não passou na validação SHA-256.',
        );
      }
    }

    final executable = File(Platform.resolvedExecutable);
    final installDirectory = executable.parent;
    await _verifyInstallDirectoryIsWritable(installDirectory);

    final script = File(
      '${updateDirectory.path}${Platform.pathSeparator}'
      'FinFlow-Updater-${update.versionCode}.ps1',
    );
    final log = File(
      '${updateDirectory.path}${Platform.pathSeparator}'
      'FinFlow-Updater-${update.versionCode}.log',
    );
    await script.writeAsString(_windowsUpdaterScript, flush: true);

    final systemRoot = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    final powerShell =
        '$systemRoot${Platform.pathSeparator}System32'
        '${Platform.pathSeparator}WindowsPowerShell'
        '${Platform.pathSeparator}v1.0'
        '${Platform.pathSeparator}powershell.exe';

    await Process.start(
      powerShell,
      [
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script.path,
        '-ProcessId',
        pid.toString(),
        '-ArchivePath',
        archive.path,
        '-InstallDirectory',
        installDirectory.path,
        '-ExecutablePath',
        executable.path,
        '-LogPath',
        log.path,
        '-ScriptPath',
        script.path,
      ],
      workingDirectory: installDirectory.path,
      mode: ProcessStartMode.detached,
    );

    Timer(const Duration(milliseconds: 750), () => exit(0));
  }

  Future<void> _verifyInstallDirectoryIsWritable(Directory directory) async {
    final probe = File(
      '${directory.path}${Platform.pathSeparator}.finflow-update-write-test',
    );
    try {
      await probe.writeAsString('FinFlow');
    } on FileSystemException {
      throw const FileSystemException(
        'O FinFlow não tem permissão para atualizar esta pasta. '
        'Mova o aplicativo para uma pasta do seu usuário e tente novamente.',
      );
    } finally {
      if (await probe.exists()) {
        await probe.delete();
      }
    }
  }

  Future<String> _fetchChecksum(Uri uri) async {
    final response = await _get(uri);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'Não foi possível obter o checksum da atualização.',
        uri: uri,
      );
    }
    final text = await _readText(response, maxBytes: 4096);
    final match = RegExp(r'\b[0-9a-fA-F]{64}\b').firstMatch(text);
    if (match == null) {
      throw const FormatException('Checksum da atualização inválido.');
    }
    return match.group(0)!.toLowerCase();
  }

  Future<void> _downloadPackage(
    Uri uri,
    File destination, {
    required int maxBytes,
    required String description,
  }) async {
    final partial = File('${destination.path}.part');
    if (await partial.exists()) {
      await partial.delete();
    }

    final response = await _get(uri);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'Não foi possível baixar o $description da atualização.',
        uri: uri,
      );
    }

    IOSink? sink;
    try {
      sink = partial.openWrite();
      var receivedBytes = 0;
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        if (receivedBytes > maxBytes) {
          throw FileSystemException(
            'O $description excede o tamanho máximo permitido.',
          );
        }
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (await destination.exists()) {
        await destination.delete();
      }
      await partial.rename(destination.path);
    } catch (_) {
      await sink?.close();
      if (await partial.exists()) {
        await partial.delete();
      }
      rethrow;
    }
  }

  Future<bool> _matchesChecksum(File file, String expected) async {
    if (!await file.exists()) {
      return false;
    }
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase() == expected;
  }

  Future<HttpClientResponse> _get(Uri uri, {bool acceptJson = false}) async {
    final request = await _httpClient.getUrl(uri).timeout(
      const Duration(seconds: 20),
    );
    request.headers.set(HttpHeaders.userAgentHeader, 'FinFlow-App-Updater');
    if (acceptJson) {
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set('X-GitHub-Api-Version', '2022-11-28');
    }
    return request.close().timeout(const Duration(seconds: 30));
  }

  Future<String> _readText(
    HttpClientResponse response, {
    required int maxBytes,
  }) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('Resposta de atualização muito grande.');
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  static const String _windowsUpdaterScript = r'''
param(
  [Parameter(Mandatory = $true)][int]$ProcessId,
  [Parameter(Mandatory = $true)][string]$ArchivePath,
  [Parameter(Mandatory = $true)][string]$InstallDirectory,
  [Parameter(Mandatory = $true)][string]$ExecutablePath,
  [Parameter(Mandatory = $true)][string]$LogPath,
  [Parameter(Mandatory = $true)][string]$ScriptPath
)

$ErrorActionPreference = 'Stop'
$staging = Join-Path ([System.IO.Path]::GetTempPath()) "FinFlow-Update-$ProcessId"

try {
  if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
  }
  New-Item -ItemType Directory -Path $staging -Force | Out-Null
  Expand-Archive -LiteralPath $ArchivePath -DestinationPath $staging -Force

  $newExecutable = Join-Path $staging 'FinFlow.exe'
  if (-not (Test-Path -LiteralPath $newExecutable -PathType Leaf)) {
    throw 'O pacote baixado não contém FinFlow.exe.'
  }

  Wait-Process -Id $ProcessId -ErrorAction SilentlyContinue
  Get-ChildItem -LiteralPath $staging -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $InstallDirectory -Recurse -Force
  }

  Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue
  Start-Process -FilePath $ExecutablePath -WorkingDirectory $InstallDirectory
} catch {
  $_ | Out-String | Set-Content -LiteralPath $LogPath -Encoding UTF8
  if (Test-Path -LiteralPath $ExecutablePath -PathType Leaf) {
    Start-Process -FilePath $ExecutablePath -WorkingDirectory $InstallDirectory
  }
  exit 1
} finally {
  Remove-Item -LiteralPath $ScriptPath -Force -ErrorAction SilentlyContinue
}
''';
}
