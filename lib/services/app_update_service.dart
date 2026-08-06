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

  final HttpClient _httpClient;
  final Uri releasesApi;

  @override
  Future<bool> isSupported() async => Platform.isAndroid;

  @override
  Future<InstalledAppVersion> getCurrentVersion() async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'getCurrentVersion',
    );
    if (raw == null) {
      throw StateError('O Android não informou a versão instalada.');
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
    return await _channel.invokeMethod<bool>(
          'canRequestPackageInstalls',
        ) ??
        false;
  }

  @override
  Future<void> openInstallPermissionSettings() async {
    await _channel.invokeMethod<void>('openInstallPermissionSettings');
  }

  @override
  Future<void> downloadAndInstall(AppUpdateInfo update) async {
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
      await _downloadApk(update.apkUri, apk);
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

  Future<void> _downloadApk(Uri uri, File destination) async {
    final partial = File('${destination.path}.part');
    if (await partial.exists()) {
      await partial.delete();
    }

    final response = await _get(uri);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'Não foi possível baixar o APK da atualização.',
        uri: uri,
      );
    }

    IOSink? sink;
    try {
      sink = partial.openWrite();
      var receivedBytes = 0;
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        if (receivedBytes > _maxApkBytes) {
          throw const FileSystemException(
            'O APK excede o tamanho máximo permitido.',
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
    request.headers.set(HttpHeaders.userAgentHeader, 'FinFlow-Android-Updater');
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
}
