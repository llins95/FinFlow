import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/financial_entry.dart';
import '../models/financial_month.dart';

enum BillingReminderKind { invoiceClosing, dueTomorrow }

class BillingReminder {
  const BillingReminder({
    required this.id,
    required this.entryId,
    required this.kind,
    required this.scheduledDate,
    required this.title,
    required this.body,
  });

  final int id;
  final String entryId;
  final BillingReminderKind kind;
  final DateTime scheduledDate;
  final String title;
  final String body;
}

class BillingReminderPlanner {
  const BillingReminderPlanner({this.monthsAhead = 12, this.hour = 9});

  final int monthsAhead;
  final int hour;

  List<BillingReminder> plan({
    required FinancialMonth currentMonth,
    required DateTime now,
  }) {
    final reminders = <BillingReminder>[];

    for (var monthOffset = 0; monthOffset < monthsAhead; monthOffset++) {
      final targetMonth = DateTime(
        currentMonth.year,
        currentMonth.month + monthOffset,
      );

      for (final entry in currentMonth.entries.where((item) => item.isDebt)) {
        if (monthOffset > 0 && (!entry.isRecurring || !entry.isActive)) {
          continue;
        }
        if (monthOffset == 0 && entry.isPaid) {
          continue;
        }

        if (entry.type == FinancialEntryType.cardInvoice &&
            entry.closingDay != null) {
          final scheduledDate = _dateAtHour(
            targetMonth.year,
            targetMonth.month,
            entry.closingDay!,
          );
          if (scheduledDate.isAfter(now)) {
            reminders.add(
              BillingReminder(
                id: _notificationId(
                  entry.id,
                  BillingReminderKind.invoiceClosing,
                  targetMonth,
                ),
                entryId: entry.id,
                kind: BillingReminderKind.invoiceClosing,
                scheduledDate: scheduledDate,
                title: 'Fatura fecha hoje',
                body:
                    'A fatura de ${entry.name} fecha hoje, dia '
                    '${entry.closingDay}. Confira as compras antes do '
                    'fechamento.',
              ),
            );
          }
        }

        if (entry.dueDay == null) {
          continue;
        }

        final dueDate = _dateAtHour(
          targetMonth.year,
          targetMonth.month,
          entry.dueDay!,
        );
        final scheduledDate = dueDate.subtract(const Duration(days: 1));
        if (!scheduledDate.isAfter(now)) {
          continue;
        }

        final subject = entry.type == FinancialEntryType.cardInvoice
            ? 'A fatura de ${entry.name}'
            : 'A despesa ${entry.name}';
        reminders.add(
          BillingReminder(
            id: _notificationId(
              entry.id,
              BillingReminderKind.dueTomorrow,
              targetMonth,
            ),
            entryId: entry.id,
            kind: BillingReminderKind.dueTomorrow,
            scheduledDate: scheduledDate,
            title: 'Vencimento amanhã',
            body: '$subject vence amanhã, dia ${entry.dueDay}.',
          ),
        );
      }
    }

    reminders.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return List.unmodifiable(reminders);
  }

  DateTime _dateAtHour(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, requestedDay.clamp(1, lastDay), hour);
  }

  int _notificationId(
    String entryId,
    BillingReminderKind kind,
    DateTime month,
  ) {
    final value = '$entryId|${kind.name}|${month.year}|${month.month}';
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}

class BillingNotificationScheduler {
  BillingNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    this.planner = const BillingReminderPlanner(),
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'finflow_billing_reminders';
  static const _channelName = 'Lembretes financeiros';
  static const _channelDescription =
      'Avisos de fechamento e vencimento de faturas e despesas.';

  final FlutterLocalNotificationsPlugin _plugin;
  final BillingReminderPlanner planner;
  bool _initialized = false;
  bool _permissionGranted = false;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> sync({
    required FinancialMonth currentMonth,
    DateTime? now,
  }) async {
    if (!_isSupported || !await _initialize()) {
      return;
    }

    final localNow = now ?? DateTime.now();
    final reminders = planner.plan(currentMonth: currentMonth, now: localNow);

    try {
      await _plugin.cancelAll();
      for (final reminder in reminders) {
        final scheduledDate = tz.TZDateTime(
          tz.local,
          reminder.scheduledDate.year,
          reminder.scheduledDate.month,
          reminder.scheduledDate.day,
          reminder.scheduledDate.hour,
        );

        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
              icon: 'ic_stat_finflow',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'billing:${reminder.kind.name}:${reminder.entryId}',
        );
      }
    } catch (_) {
      // Lembretes não devem impedir o uso do controle financeiro.
    }
  }

  Future<bool> _initialize() async {
    if (_initialized) {
      return _permissionGranted;
    }
    _initialized = true;

    try {
      tz_data.initializeTimeZones();
      try {
        final timezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezone.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('America/Recife'));
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_finflow'),
        ),
      );
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      _permissionGranted =
          await androidPlugin?.requestNotificationsPermission() ?? true;
      return _permissionGranted;
    } catch (_) {
      _permissionGranted = false;
      return false;
    }
  }
}
