import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

/// Конфигурация отправки жалоб
class ReportConfig {
  /// Если указать HTTP endpoint (например, Google Apps Script / Google Form),
  /// будет предпринята попытка отправки POST. Если пусто — используем только mailto.
  static const String httpEndpoint = '';

  /// Почта для жалоб (замени на реальную)
  static const String mailTo = 'begemotik2017timur@gmail.com';
}

class ReportPayload {
  final String country; // например: egypt
  final String pack; // например: egypt_cuisine
  final int level; // 1..N
  final int index; // индекс вопроса в уровне (0..)
  final int? questionId; // из JSON если есть
  final String questionText;
  final List<String> options; // тексты вариантов
  final int? choiceIndex; // индекс выбранного варианта (-1 если по таймауту)
  final bool timedOut; // вышло ли время
  final int timeLimit; // сек
  final int timeLeft; // сек, когда зафиксировали ответ/таймаут
  final String locale; // ru/en
  final String appVersion; // может быть 'unknown'
  final DateTime createdAt;

  ReportPayload({
    required this.country,
    required this.pack,
    required this.level,
    required this.index,
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.choiceIndex,
    required this.timedOut,
    required this.timeLimit,
    required this.timeLeft,
    required this.locale,
    required this.appVersion,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'country': country,
        'pack': pack,
        'level': level,
        'index': index,
        'questionId': questionId,
        'questionText': questionText,
        'options': options,
        'choiceIndex': choiceIndex,
        'timedOut': timedOut,
        'timeLimit': timeLimit,
        'timeLeft': timeLeft,
        'locale': locale,
        'appVersion': appVersion,
        'createdAt': createdAt.toIso8601String(),
      };

  String toMailBody() {
    final buff = StringBuffer();
    // Краткая сводка для поддержки (вверху самое важное)
    buff.writeln('Report: quiz question issue');
    buff.writeln('Country: $country');
    buff.writeln('Category (pack): $pack');
    buff.writeln('Question: $questionText');
    buff.writeln('');
    // Доп. детали ниже
    buff.writeln('Details:');
    buff.writeln('Level: $level, Index: $index');
    if (questionId != null) buff.writeln('QuestionId: $questionId');
    buff.writeln('Locale: $locale');
    buff.writeln('App version: $appVersion');
    buff.writeln('Time limit: ${timeLimit}s, time left: ${timeLeft}s, timedOut: $timedOut');
    for (var i = 0; i < options.length; i++) {
      final marker = (choiceIndex == i) ? ' [picked]' : '';
      buff.writeln('  ${i + 1}) ${options[i]}$marker');
    }
    buff.writeln('Created at: ${createdAt.toIso8601String()}');
    return buff.toString();
  }
}

class ReportService {
  static const _queueKey = 'report_queue_v1';

  /// Попытаться слить очередь (если есть endpoint).
  static Future<void> flushQueue() async {
    if (ReportConfig.httpEndpoint.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_queueKey) ?? const [];
    if (list.isEmpty) return;
    final remain = <String>[];
    for (final jsonStr in list) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final ok = await _post(map);
        if (!ok) remain.add(jsonStr);
      } catch (e) {
        debugPrint('[Report] flush error: $e');
        remain.add(jsonStr);
      }
    }
    await p.setStringList(_queueKey, remain);
  }

  /// Отправить жалобу: сначала HTTP (если есть endpoint), иначе открываем mailto.
  /// Возвращает true, если отправлено (или открыт почтовый клиент), false — если сохранено в очередь.
  static Future<bool> send(ReportPayload payload) async {
    final map = payload.toMap();
    if (ReportConfig.httpEndpoint.isNotEmpty) {
      final ok = await _post(map);
      if (ok) return true;
      // сохраним в очередь
      await _enqueue(map);
      return false;
    }
    // mailto как дефолт
    return await _mailto(payload);
  }

  static Future<bool> _post(Map<String, dynamic> map) async {
    try {
      final uri = Uri.parse(ReportConfig.httpEndpoint);
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(map))
          .timeout(const Duration(seconds: 8));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('[Report] POST fail: $e');
      return false;
    }
  }

  static Future<void> _enqueue(Map<String, dynamic> map) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_queueKey) ?? <String>[];
    list.add(jsonEncode(map));
    await p.setStringList(_queueKey, list);
  }

  static Future<bool> _mailto(ReportPayload payload) async {
    final subjectRaw = '[Quiz Report] ${payload.country}/${payload.pack} L${payload.level}';
    final bodyRaw = payload.toMailBody();
    // 1) Стандартный mailto
    final mailtoUri = Uri(
      scheme: 'mailto',
      path: ReportConfig.mailTo,
      queryParameters: {
        'subject': subjectRaw,
        'body': bodyRaw,
      },
    );
    if (await canLaunchUrl(mailtoUri)) {
      final ok = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    }
    // 2) Gmail схема (если установлен Gmail)
    final gmailUri = Uri.parse(
        'googlegmail://co?to=${Uri.encodeComponent(ReportConfig.mailTo)}&subject=${Uri.encodeComponent(subjectRaw)}&body=${Uri.encodeComponent(bodyRaw)}');
    if (await canLaunchUrl(gmailUri)) {
      final ok = await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    }
    // 3) Outlook схема (если установлен Outlook)
    final outlookUri = Uri.parse(
        'ms-outlook://compose?to=${Uri.encodeComponent(ReportConfig.mailTo)}&subject=${Uri.encodeComponent(subjectRaw)}&body=${Uri.encodeComponent(bodyRaw)}');
    if (await canLaunchUrl(outlookUri)) {
      final ok = await launchUrl(outlookUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    }
    return false;
  }
}
