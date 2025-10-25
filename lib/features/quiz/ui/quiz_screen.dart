import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app/locale_provider.dart';
// Background removed per request.
import '../../progress/star_utils.dart';
import '../../../utils/json_path.dart';
import '../../../utils/assets_index.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/ui_metrics.dart';
import '../../../services/report_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// ===== МОДЕЛИ =====
enum QuizDifficulty { easy, normal, hard }

class QA {
  final String q;
  final List<Ans> answers;
  final int timeSec;
  final String? fact;
  final int? id;
  // Новые поля (необязательные)
  final QuizDifficulty difficulty;
  final List<String> tags;

  QA({
    required this.q,
    required this.answers,
    required this.timeSec,
    this.fact,
    this.id,
    this.difficulty = QuizDifficulty.normal,
    this.tags = const [],
  });

  factory QA.fromMap(Map m) {
    final qText = (m['q'] ?? '').toString();
    final fact = (m['fact'] as String?)?.trim();
    final timeSec = (m['timeSec'] is int) ? m['timeSec'] as int : 20;
    final id = (m['id'] is int) ? m['id'] as int : null;
    // Разбор сложности и тегов (необязательно)
    final rawDiff = (m['difficulty'] ?? 'normal').toString().toLowerCase();
    QuizDifficulty diff;
    if (rawDiff == 'easy') {
      diff = QuizDifficulty.easy;
    } else if (rawDiff == 'hard') {
      diff = QuizDifficulty.hard;
    } else {
      diff = QuizDifficulty.normal;
    }
    final tags = (m['tags'] is List)
        ? (m['tags'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];

    // Формат 1: { answers: [ {text, correct}, ... ] }
    if (m['answers'] is List) {
      final list = (m['answers'] as List).map((e) => Ans.fromMap(e as Map)).toList();
      return QA(q: qText, answers: list, timeSec: timeSec, fact: fact, id: id, difficulty: diff, tags: tags);
    }
    // Формат 2 (country.json): { options: [...], answerIndex: N }
    if (m['options'] is List) {
      final idx = (m['answerIndex'] is int) ? m['answerIndex'] as int : -1;
      final opts = (m['options'] as List)
          .asMap()
          .entries
          .map((e) => Ans(text: e.value.toString(), correct: e.key == idx))
          .toList();
      return QA(q: qText, answers: opts, timeSec: timeSec, fact: fact, id: id, difficulty: diff, tags: tags);
    }
    // Fallback: пустой вопрос, чтобы не падать
    return QA(q: qText, answers: const [], timeSec: timeSec, fact: fact, id: id, difficulty: diff, tags: tags);
  }
}

class Ans {
  final String text;
  final bool correct;
  Ans({required this.text, required this.correct});
  factory Ans.fromMap(Map m) {
    // В некоторых RU-файлах используется ключ "test" вместо "text".
    final rawText = (m['text'] ?? m['test'] ?? '').toString().trim();
    final isCorrect = (m['correct'] ?? false) == true;
    return Ans(text: rawText, correct: isCorrect);
  }
}

// Добавьте тип коллбэка-загрузчика, чтобы подменять источник вопросов (API/Mock/Assets).
typedef QuestionLoader = Future<List<QA>> Function(String pack, int level);

/// ===== ЭКРАН =====
class QuizScreen extends ConsumerStatefulWidget {
  final String pack; // имя файла в assets/questions/ru без .json (country/subcategory key)
  final int level;   // 1..N
  // Новый необязательный загрузчик: если задан — возьмём вопросы из него (например, из API),
  // иначе используется текущая загрузка из ассетов.
  final QuestionLoader? loader;

  const QuizScreen({super.key, required this.pack, required this.level, this.loader});

  @override
  ConsumerState<QuizScreen> createState() => _QState();
}

class _QState extends ConsumerState<QuizScreen> {
  late Future<List<QA>> _future;
  int _i = 0;
  int _score = 0;
  int _left = 0;
  Timer? _t;
  bool _locked = false; // выбран ответ
  int? _picked;         // индекс выбранного ответа
  bool _shouldAutoNext = false; // авто-переход при таймауте
  int _fiftyLeft = 1;
  int _addTimeLeft = 1;
  final Set<int> _hidden = <int>{};

  @override
  void initState() {
    super.initState();
    // Если передан кастомный loader — используем его и гарантированно запускаем таймер после получения данных.
    if (widget.loader != null) {
      _future = widget.loader!(widget.pack, widget.level).then((qs) {
        final normalized = _normalizeQuestions(qs);
        if (normalized.isEmpty) {
          throw Exception('Нет валидных вопросов для уровня ${widget.level} (loader вернул пустой список)');
        }
        _startTimer(normalized.first.timeSec);
        _logEvent('quiz_start', {'pack': widget.pack, 'level': widget.level, 'count': normalized.length});
        return normalized;
      });
    } else {
      _future = _loadLevel(widget.pack, widget.level).then((qs) {
        _logEvent('quiz_start', {'pack': widget.pack, 'level': widget.level, 'count': qs.length});
        return qs;
      });
    }
    // Подгрузим индекс ассетов заранее, чтобы можно было выбрать фон
    AssetsIndex.ensureLoaded();
    // Попробуем выгрузить локальную очередь отчётов
    ReportService.flushQueue();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<List<QA>> _loadLevel(String pack, int level) async {
  // Новый приоритет: сперва стандартизированный путь через jsonPath()
  // затем прежние fallback варианты для обратной совместимости.

    String? raw;
    final Map<String, String> failReasons = {}; // path -> error
    Future<String?> tryLoad(String path) async {
      try {
        final data = await rootBundle.loadString(path);
        return data;
      } catch (e) {
        failReasons[path] = e.toString();
        return null;
      }
    }

    final parts = pack.split('_');
    final country = parts.isNotEmpty ? parts.first : pack;
    // Попытаемся угадать total: если файл с _100 существует — 100, иначе 50.
    // Здесь сначала пробуем 100, затем 50.
  // Определяем текущую локаль для вопросов: ru/en
  final selectedLocale = ref.read(localeControllerProvider).valueOrNull?.languageCode;
  final qLocale = (selectedLocale == 'en') ? 'en' : 'ru';
  final packName = parts.length > 1 ? parts.sublist(1).join('_') : 'classic';
  // Используем алиасы, чтобы 'food' искал файлы '*_cuisine_*.json', и т.п.
  final packAlias = _imageSubcatAlias(packName);
  final effectivePack = parts.length > 1 ? '${country}_${packAlias}' : pack; // полное имя пакета с алиасом
  final preferred100 = jsonPath(locale: qLocale, country: country, pack: packAlias, total: 100);
  final preferred50 = jsonPath(locale: qLocale, country: country, pack: packAlias, total: 50);
    final candidates = <String>{
      preferred100,
      preferred50,
      // legacy fallbacks
  // fallback на ru при отсутствии en
  // Сначала пути с алиасом
  'assets/questions/$qLocale/$effectivePack.json',
  'assets/questions/$qLocale/$country/$effectivePack.json',
  'assets/questions/$qLocale/$country/${effectivePack}_100.json',
  'assets/questions/$qLocale/$country/${effectivePack}_50.json',
  // Затем старые пути без алиаса на случай, если ассеты ещё не переименованы
  'assets/questions/$qLocale/$pack.json',
  'assets/questions/$qLocale/$country/$pack.json',
  'assets/questions/$qLocale/$country/${pack}_100.json',
  'assets/questions/$qLocale/$country/${pack}_50.json',
  'assets/questions/ru/$pack.json',
  'assets/questions/ru/$country/$pack.json',
  'assets/questions/ru/$country/${pack}_100.json',
  'assets/questions/ru/$country/${pack}_50.json',
    }.toList();

    // Fallback на частую опечатку в имени файла: egypt -> egypet (только для файлов в подпапке country)
    if (country.toLowerCase() == 'egypt') {
      final typoPack = pack.replaceFirst('egypt', 'egypet');
      candidates.addAll([
        'assets/questions/$qLocale/$country/${typoPack}_100.json',
        'assets/questions/$qLocale/$country/${typoPack}_50.json',
      ]);
    }

    for (final p in candidates) {
      raw = await tryLoad(p);
      if (raw != null) {
        debugPrint('[Quiz] Loaded questions file: $p');
        break;
      }
    }
    if (raw == null) {
      final detailed = failReasons.entries.map((e) => '${e.key} -> ${e.value}').join('\n');
      throw Exception('Не найден JSON для "$pack". Пробовали пути (с причинами):\n$detailed\nСоветы: \n1) Проверь, что файл реально существует по одному из путей.\n2) Выполни Hot Restart / полную пересборку (новые ассеты не подхватываются Hot Reload).\n3) Убедись, что путь папки добавлен в pubspec.yaml\n4) Название файла: country_subcategory_100.json (например japan_classic_100.json).');
    }

    final m = jsonDecode(raw) as Map;
    final levelsNode = m['levels'];
    List<QA> qs = const [];
    if (levelsNode is List) {
      // Старый/паковый формат: levels: [ { level: N, questions: [...] }, ... ]
      final target = levelsNode.firstWhere(
        (e) => (e is Map && (e['level'] ?? 0) == level),
        orElse: () => {'questions': <dynamic>[]},
      ) as Map;
      final qList = (target['questions'] as List? ?? const []);
      qs = qList.map((e) => QA.fromMap(e as Map)).toList();
    } else if (levelsNode is Map) {
      // Формат country.json: levels: { "1": [ {...}, {...} ], "2": [...] }
      final key = level.toString();
      final list = (levelsNode[key] as List?) ?? const [];
      qs = list.map((e) => QA.fromMap(e as Map)).toList();
    }
    if (qs.isEmpty) {
      throw Exception('Нет вопросов для уровня $level в $pack.json');
    }

    // Нормализуем вопросы (>=2 ответа, ровно 1 correct), затем перемешаем варианты.
    qs = _normalizeQuestions(qs);
    if (qs.isEmpty) {
      throw Exception('После валидации не осталось валидных вопросов для уровня $level');
    }
    final rng = Random();
    for (final q in qs) {
      q.answers.shuffle(rng);
    }
    _startTimer(qs.first.timeSec);
    return qs;
  }

  // Нормализация вопросов: >=2 варианта и ровно 1 correct. Если 0 correct — помечаем первый; если >1 — оставляем первым найденным.
  List<QA> _normalizeQuestions(List<QA> input) {
    final out = <QA>[];
    for (final qa in input) {
      final ans = qa.answers;
      if (ans.length < 2) continue;
      final firstCorrectIdx = ans.indexWhere((a) => a.correct);
      int ensureCorrectIdx = firstCorrectIdx >= 0 ? firstCorrectIdx : 0;
      final normalizedAnswers = ans.asMap().entries.map((e) {
        final makeCorrect = e.key == ensureCorrectIdx;
        return Ans(text: e.value.text, correct: makeCorrect);
      }).toList();
      final safeTime = qa.timeSec >= 1 ? qa.timeSec : 20;
      out.add(QA(
        q: qa.q,
        answers: normalizedAnswers,
        timeSec: safeTime,
        fact: qa.fact,
        id: qa.id,
        difficulty: qa.difficulty,
        tags: qa.tags,
      ));
    }
    return out;
  }

  void _startTimer(int sec) {
    _t?.cancel();
    final start = (sec >= 1) ? sec : 20;
    setState(() => _left = start);
    _t = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (_left <= 1) {
        tm.cancel();
        _onTime();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _onTime() {
    // если время вышло и не отвечено — просто показываем правильный и Next
    if (!_locked) {
      setState(() {
        _locked = true;
        _picked = -1; // специальная пометка «не отвечал»
        _shouldAutoNext = true; // запланируем авто-переход
      });
    }
  }

  void _pick(int idx, QA qa) {
    if (_locked) return;
    if (idx < 0 || idx >= qa.answers.length) return;
    final ok = qa.answers[idx].correct;
    setState(() {
      _locked = true;
      _picked = idx;
      if (ok) _score++;
    });
    _t?.cancel();
    _logEvent('answer', {
      'pack': widget.pack,
      'level': widget.level,
      'index': _i,
      'correct': ok,
      'difficulty': qa.difficulty.name,
      'timeSpent': (qa.timeSec - _left).clamp(0, qa.timeSec),
    });
  }

  void _next(List<QA> all) {
    if (_i + 1 >= all.length) {
      // конец — показываем экран результатов и возвращаемся с данными
      final starsEarned = StarUtils.fromScore(_score, all.length);
      _t?.cancel();
      Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => _ResultsScreen(
            total: all.length,
            score: _score,
            stars: starsEarned,
          ),
        ),
      ).then((_) {
        Navigator.pop(context, {
          'answered': all.length,
          'score': _score,
          'level': widget.level,
          'pack': widget.pack,
          'starsEarned': starsEarned,
        });
      });
      return;
    }
    setState(() {
      _i++;
      _locked = false;
      _picked = null;
      _hidden.clear();
      _shouldAutoNext = false;
    });
    _startTimer(all[_i].timeSec);
  }

  Color _answerColor(QA qa, int idx) {
    if (!_locked) return Colors.white;
    final isCorrect = qa.answers[idx].correct;
    if (_picked == idx && isCorrect) return Colors.green.shade100;
    if (_picked == idx && !isCorrect) return Colors.red.shade100;
    if (_picked != null && isCorrect) return Colors.green.shade50;
    return Colors.white;
  }

  double _answerOpacity(QA qa, int idx) {
    if (!_locked) return 1.0;
    final isCorrect = qa.answers[idx].correct;
    if (_picked == idx) return 1.0;
    if (isCorrect) return 1.0;
    // остальные тускнеют
    return 0.5;
  }

  void _useFifty(QA qa) {
    if (_locked || _fiftyLeft <= 0) return;
    // выберем двa неверных индекса для скрытия
    final wrong = <int>[];
    for (var i = 0; i < qa.answers.length; i++) {
      if (!qa.answers[i].correct && !_hidden.contains(i)) wrong.add(i);
    }
    wrong.shuffle();
    final toHide = wrong.take(2);
    setState(() {
      _hidden.addAll(toHide);
      _fiftyLeft--;
    });
    _logEvent('hint_50', {'pack': widget.pack, 'level': widget.level, 'index': _i});
  }

  void _useAddTime() {
    if (_locked || _addTimeLeft <= 0) return;
    setState(() {
      _left += 5;
      _addTimeLeft--;
    });
    _logEvent('hint_time', {'pack': widget.pack, 'level': widget.level, 'index': _i});
  }

  void _logEvent(String name, Map<String, Object?> data) {
    // Лёгкая локальная аналитика (замените на Firebase/Segment при необходимости)
    // ignore: avoid_print
    print('[analytics] $name ${jsonEncode(data)}');
  }

  Future<void> _openReportDialog(QA qa) async {
    String reason = 'wrong_fact';
    String? comment;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String localReason = reason;
        final controller = TextEditingController(text: comment ?? '');
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Пожаловаться на вопрос'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Ошибка факта'),
                    value: 'wrong_fact',
                    groupValue: localReason,
                    onChanged: (v) => setState(() => localReason = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Двусмысленность'),
                    value: 'ambiguous',
                    groupValue: localReason,
                    onChanged: (v) => setState(() => localReason = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Опечатка'),
                    value: 'typo',
                    groupValue: localReason,
                    onChanged: (v) => setState(() => localReason = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Другое'),
                    value: 'other',
                    groupValue: localReason,
                    onChanged: (v) => setState(() => localReason = v!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Комментарий (необязательно)'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  reason = localReason;
                  final text = controller.text.trim();
                  comment = text.isEmpty ? null : text;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Отправить'),
              ),
            ],
          ),
        );
      },
    );

    if (submitted == true) {
      await _report(qa, reason: reason, comment: comment);
    }
  }

  Future<void> _report(QA qa, {String? reason, String? comment}) async {
    String version = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    final parts = widget.pack.split('_');
    final country = parts.isNotEmpty ? parts.first : widget.pack;
    final options = qa.answers.map((e) => e.text).toList();
    // Прокинем причину/комментарий в meta, не ломая ReportService
    if (reason != null) options.add('[reason] $reason');
    if (comment != null && comment.isNotEmpty) options.add('[comment] $comment');

    final payload = ReportPayload(
      country: country,
      pack: widget.pack,
      level: widget.level,
      index: _i,
      questionId: qa.id,
      questionText: qa.q,
      options: options,
      choiceIndex: _picked,
      timedOut: _picked == -1,
      timeLimit: qa.timeSec,
      timeLeft: _left,
      locale: Localizations.localeOf(context).languageCode,
      appVersion: version,
      createdAt: DateTime.now(),
    );
    final ok = await ReportService.send(payload);
    if (!mounted) return;
    final hasHttp = ReportConfig.httpEndpoint.isNotEmpty;
    final message = ok
        ? 'Откроется почтовый клиент'
        : (hasHttp ? 'Сохранено и будет отправлено позже' : 'Не удалось открыть почтовое приложение. Установите Gmail/Outlook и попробуйте снова.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QA>>(
      future: _future,
      builder: (c, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).appTitle)),
            body: Center(child: Text('${AppLocalizations.of(context).error_prefix}${snap.error}')),
          );
        }
        final all = snap.data!;
        final qa = all[_i];

        // авто-переход при таймауте
        if (_shouldAutoNext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _shouldAutoNext = false;
              _next(all);
            }
          });
        }

        // Определим страну/подкатегорию на основе pack (до/после первого '_')
        final parts = widget.pack.split('_');
        final country = parts.isNotEmpty ? parts.first : widget.pack;
        final subcatRaw = parts.length > 1 ? parts.sublist(1).join('_') : 'classic';
        final subcat = _imageSubcatAlias(subcatRaw);
        final quizBg = _pickQuizBackground(country, subcat, widget.level);
        // Precache выбранный фон
        if (quizBg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) precacheImage(AssetImage(quizBg), context);
          });
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text('Вопрос ${_i + 1} / ${all.length}'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              Row(
                children: [
                  const Icon(Icons.timer, size: 18),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text('${_left}s', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              )
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (quizBg != null)
                Image.asset(
                  quizBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, contentTopPadding(context), 16, 16),
                child: Column(
                  children: [
                    // Вопрос — карточка
                    Expanded(
                      child: Card(
                        color: Colors.white.withOpacity(0.95),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Метка сложности
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _DifficultyChip(difficulty: qa.difficulty),
                                  ),
                                  Text(
                                    qa.q,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Ответы — сетка 2x2
                    _AnswersGrid(
                      qa: qa,
                      hidden: _hidden,
                      locked: _locked,
                      picked: _picked,
                      onPick: (idx) => _pick(idx, qa),
                      answerColor: (idx) => _answerColor(qa, idx),
                      answerOpacity: (idx) => _answerOpacity(qa, idx),
                    ),
                    const SizedBox(height: 12),
                    // Подсказки — ниже ответов
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HintButton(
                          icon: Icons.percent,
                          label: '50/50',
                          counter: _fiftyLeft,
                          onTap: () => _useFifty(qa),
                          enabled: !_locked && _fiftyLeft > 0,
                        ),
                        const SizedBox(width: 16),
                        _HintButton(
                          icon: Icons.timer,
                          label: '+5s',
                          counter: _addTimeLeft,
                          onTap: _useAddTime,
                          enabled: !_locked && _addTimeLeft > 0,
                        ),
                      ],
                    ),
                    // Кнопка «Пожаловаться на вопрос»
                    Align(
                      alignment: Alignment.centerRight,
                      child: Builder(
                        builder: (context) {
                          final primary = Theme.of(context).colorScheme.primary;
                          return TextButton.icon(
                            onPressed: () async {
                              await _openReportDialog(qa);
                              _logEvent('report', {'pack': widget.pack, 'level': widget.level, 'index': _i});
                            },
                            icon: const Icon(Icons.flag_outlined, size: 20),
                            label: const Text('Пожаловаться на вопрос'),
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ).copyWith(
                              overlayColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return primary.withOpacity(0.12);
                                }
                                if (states.contains(MaterialState.hovered)) {
                                  return primary.withOpacity(0.08);
                                }
                                return null;
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Факт — над кнопкой "Далее"
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: (_locked && _picked != null && _picked! >= 0 && qa.answers[_picked!].correct && (qa.fact?.isNotEmpty ?? false))
                          ? Container(
                              key: const ValueKey('fact'),
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${AppLocalizations.of(context).fact_prefix}${qa.fact!}'),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    // Кнопка далее — внизу
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_picked != null && _picked! >= 0)
                            ? () {
                                if (_i + 1 >= all.length) {
                                  _logEvent('quiz_finish', {
                                    'pack': widget.pack,
                                    'level': widget.level,
                                    'score': _score,
                                    'total': all.length,
                                  });
                                }
                                _next(all);
                              }
                            : null,
                        child: Text(_i + 1 >= all.length
                            ? AppLocalizations.of(context).finish
                            : AppLocalizations.of(context).next),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Фишка доступности: метка сложности
class _DifficultyChip extends StatelessWidget {
  final QuizDifficulty difficulty;
  const _DifficultyChip({required this.difficulty});
  Color _bg() {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return const Color(0xFFE8F5E9);
      case QuizDifficulty.hard:
        return const Color(0xFFFFEBEE);
      case QuizDifficulty.normal:
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  String _label() {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Лёгкий';
      case QuizDifficulty.hard:
        return 'Сложный';
      case QuizDifficulty.normal:
      default:
        return 'Средний';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Сложность: ${_label()}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(999)),
        child: Text(_label(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Простой экран результатов (минимум UI)
class _ResultsScreen extends StatelessWidget {
  final int total;
  final int score;
  final int stars;
  const _ResultsScreen({required this.total, required this.score, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Результаты'), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Правильных ответов: $score из $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Icon(i < stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Готово'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int counter;
  final bool enabled;
  final VoidCallback onTap;
  const _HintButton({required this.icon, required this.label, required this.counter, required this.onTap, this.enabled = true});
  @override
  Widget build(BuildContext context) {
    final fg = enabled ? Colors.black87 : Colors.black26;
    return Column(
      children: [
        InkResponse(
          onTap: enabled ? onTap : null,
          radius: 28,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(icon, color: fg),
          ),
        ),
        const SizedBox(height: 4),
        Text('x$counter', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Сетка ответов 2x2, учитывает скрытые позиции (50/50)
class _AnswersGrid extends StatelessWidget {
  final QA qa;
  final Set<int> hidden;
  final bool locked;
  final int? picked;
  final void Function(int idx) onPick;
  final Color Function(int idx) answerColor;
  final double Function(int idx) answerOpacity;

  const _AnswersGrid({
    required this.qa,
    required this.hidden,
    required this.locked,
    required this.picked,
    required this.onPick,
    required this.answerColor,
    required this.answerOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final visibleEntries = qa.answers.asMap().entries.where((e) => !hidden.contains(e.key)).toList();
    final items = visibleEntries.map((entry) {
      final idx = entry.key;
      final a = entry.value;
      final isBtnEnabled = !locked;
      final isCorrectNow = locked ? a.correct : null;
      return Semantics(
        button: true,
        enabled: isBtnEnabled,
        // Читатели экрана получат понятный текст
        label: 'Вариант ${idx + 1}: ${a.text}${locked ? (isCorrectNow == true ? ", правильный" : isCorrectNow == false ? ", неправильный" : "") : ""}',
        child: Material(
          color: answerColor(idx),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isBtnEnabled ? () => onPick(idx) : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: answerOpacity(idx),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      locked ? (a.correct ? Icons.check_circle : Icons.cancel) : Icons.circle_outlined,
                      color: locked ? (a.correct ? Colors.green : Colors.red) : Colors.black45,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a.text, style: const TextStyle(fontSize: 16))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.6, // достаточно широкие кнопки
      children: items,
    );
  }
}

// ===== УТИЛИТЫ ДЛЯ АЛИАСОВ И ФОНОВ =====

// Алиасы подкатегорий (для совместимости с именами файлов ассетов)
String _imageSubcatAlias(String subcatKey) {
  switch (subcatKey) {
    case 'food':
      return 'cuisine';
    case 'history_persons':
      return 'history_personalities';
    default:
      return subcatKey;
  }
}

/// Фон для экрана вопроса из assets/images/bg/quiz/// Приоритет:
/// 1) background_{country}.png
/// 2) {country}_{subcat}_{level}.png
/// 3) {country}_{subcat}.png
/// 4) {country}.png
/// 5) любой .png из папки
String? _pickQuizBackground(String country, String subcat, int level) {
  final byNewPattern = 'assets/images/bg/quiz/background_${country}.png';
  if (AssetsIndex.has(byNewPattern)) return byNewPattern;

  final specificLevel = 'assets/images/bg/quiz/${country}_${subcat}_${level}.png';
  if (AssetsIndex.has(specificLevel)) return specificLevel;

  final specificPack = 'assets/images/bg/quiz/${country}_${subcat}.png';
  if (AssetsIndex.has(specificPack)) return specificPack;

  final byCountry = 'assets/images/bg/quiz/${country}.png';
  if (AssetsIndex.has(byCountry)) return byCountry;

  return AssetsIndex.firstInDir('assets/images/bg/quiz/');
}
