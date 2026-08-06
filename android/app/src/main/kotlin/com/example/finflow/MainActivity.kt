package com.example.finflow

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerNotificationChannel(flutterEngine)
        registerAppUpdateChannel(flutterEngine)
    }

    private fun registerNotificationChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2,
                )
                "isAccessGranted" -> result.success(hasNotificationAccess())
                "openNotificationAccessSettings" -> {
                    openNotificationAccessSettings()
                    result.success(true)
                }
                "getPendingNotifications" -> result.success(
                    NotificationImportStore.pending(this),
                )
                "removeNotifications" -> {
                    val ids = call.argument<List<String>>("ids").orEmpty()
                    NotificationImportStore.remove(this, ids.toSet())
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun registerAppUpdateChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_UPDATE_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentVersion" -> result.success(currentVersion())
                "canRequestPackageInstalls" -> result.success(
                    canRequestPackageInstalls(),
                )
                "openInstallPermissionSettings" -> {
                    openInstallPermissionSettings()
                    result.success(null)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    try {
                        result.success(path != null && openApkInstaller(path))
                    } catch (error: Exception) {
                        result.error(
                            "INSTALLER_ERROR",
                            error.message ?: "Não foi possível abrir o instalador.",
                            null,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun currentVersion(): Map<String, Any> {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                android.content.pm.PackageManager.PackageInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode.toLong()
        }

        return mapOf(
            "versionName" to (packageInfo.versionName ?: "0.0.0"),
            "versionCode" to versionCode,
        )
    }

    private fun canRequestPackageInstalls(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            packageManager.canRequestPackageInstalls()
    }

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        startActivity(
            Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            ),
        )
    }

    private fun openApkInstaller(path: String): Boolean {
        if (!canRequestPackageInstalls()) {
            openInstallPermissionSettings()
            return false
        }

        val updateDirectory = File(cacheDir, "updates").canonicalFile
        val apk = File(path).canonicalFile
        require(apk.isFile && apk.parentFile == updateDirectory) {
            "O APK não pertence ao diretório seguro de atualizações."
        }

        val contentUri = FileProvider.getUriForFile(
            this,
            "$packageName.updates",
            apk,
        )
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(contentUri, APK_MIME_TYPE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(installIntent)
        return true
    }

    private fun hasNotificationAccess(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false

        return enabledListeners
            .split(":")
            .mapNotNull(ComponentName::unflattenFromString)
            .any { component -> component.packageName == packageName }
    }

    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    companion object {
        private const val NOTIFICATION_CHANNEL_NAME =
            "com.finflow/notification_imports"
        private const val APP_UPDATE_CHANNEL_NAME = "com.finflow/app_updates"
        private const val APK_MIME_TYPE =
            "application/vnd.android.package-archive"
    }
}
