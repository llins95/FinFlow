package com.example.finflow

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.util.UUID

class WalletNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(notification: StatusBarNotification) {
        if (notification.packageName !in SUPPORTED_PACKAGES) {
            return
        }

        val flags = notification.notification.flags
        if (
            flags and Notification.FLAG_ONGOING_EVENT != 0 ||
            flags and Notification.FLAG_GROUP_SUMMARY != 0
        ) {
            return
        }

        val extras = notification.notification.extras
        val title = extras
            .getCharSequence(Notification.EXTRA_TITLE)
            ?.toString()
            ?.trim()
            .orEmpty()
        val text = sequenceOf(
            Notification.EXTRA_BIG_TEXT,
            Notification.EXTRA_TEXT,
            Notification.EXTRA_SUB_TEXT,
        )
            .mapNotNull { key -> extras.getCharSequence(key)?.toString()?.trim() }
            .firstOrNull { value -> value.isNotEmpty() }
            .orEmpty()

        if (title.isEmpty() && text.isEmpty()) {
            return
        }
        if (!BRL_AMOUNT.containsMatchIn("$title $text")) {
            return
        }

        val rawId =
            "${notification.packageName}:${notification.key}:${notification.postTime}"
        val safeId = UUID.nameUUIDFromBytes(
            rawId.toByteArray(StandardCharsets.UTF_8),
        ).toString()

        NotificationImportStore.add(
            this,
            JSONObject()
                .put("id", "wallet-notification-$safeId")
                .put("sourcePackage", notification.packageName)
                .put("title", title.take(MAX_TEXT_LENGTH))
                .put("text", text.take(MAX_TEXT_LENGTH))
                .put("postedAt", notification.postTime),
        )
    }

    companion object {
        private const val MAX_TEXT_LENGTH = 320
        private val SUPPORTED_PACKAGES = setOf(
            "com.google.android.apps.walletnfcrel",
        )
        private val BRL_AMOUNT = Regex(
            "R\\$\\s*\\d[\\d.]*,\\d{2}",
            RegexOption.IGNORE_CASE,
        )
    }
}

internal object NotificationImportStore {
    private const val PREFERENCES_NAME = "finflow_notification_imports"
    private const val PENDING_KEY = "pending_notifications"
    private const val MAX_PENDING = 50

    fun add(context: Context, item: JSONObject) {
        val id = item.optString("id")
        val existing = readObjects(context)
            .filterNot { stored -> stored.optString("id") == id }
        writeObjects(context, sequenceOf(item) + existing.asSequence())
    }

    fun pending(context: Context): List<Map<String, Any>> {
        return readObjects(context).map { item ->
            mapOf(
                "id" to item.optString("id"),
                "sourcePackage" to item.optString("sourcePackage"),
                "title" to item.optString("title"),
                "text" to item.optString("text"),
                "postedAt" to item.optLong("postedAt"),
            )
        }
    }

    fun remove(context: Context, ids: Set<String>) {
        if (ids.isEmpty()) {
            return
        }
        writeObjects(
            context,
            readObjects(context)
                .asSequence()
                .filterNot { item -> item.optString("id") in ids },
        )
    }

    fun clear(context: Context) {
        preferences(context).edit().remove(PENDING_KEY).apply()
    }

    private fun readObjects(context: Context): List<JSONObject> {
        val raw = preferences(context).getString(PENDING_KEY, null)
            ?: return emptyList()

        return try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    array.optJSONObject(index)?.let(::add)
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun writeObjects(
        context: Context,
        items: Sequence<JSONObject>,
    ) {
        val array = JSONArray()
        items.take(MAX_PENDING).forEach(array::put)
        preferences(context)
            .edit()
            .putString(PENDING_KEY, array.toString())
            .apply()
    }

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
}
