import 'package:flutter/material.dart';

class IntegrationsStubScreen extends StatelessWidget {
  final String title;

  const IntegrationsStubScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction_outlined,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'В разработке',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Интеграция "$title" находится в разработке. '
                'Архитектура подготовлена для подключения в будущих версиях.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Планируемые возможности:',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._features(title).map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 16,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _features(String title) {
    if (title.contains('Расписание')) {
      return [
        'Импорт расписания из университетской системы',
        'Автоматическое создание напоминаний',
        'Синхронизация изменений в реальном времени',
      ];
    }
    if (title.contains('Google')) {
      return [
        'Экспорт дедлайнов в Google Calendar',
        'Двусторонняя синхронизация событий',
        'Уведомления через Google',
      ];
    }
    if (title.contains('LMS') || title.contains('Moodle')) {
      return [
        'Автоматический импорт заданий',
        'Синхронизация оценок',
        'Уведомления о новых материалах',
      ];
    }
    if (title.contains('AI')) {
      return [
        'Персональные рекомендации по учёбе',
        'Анализ паттернов продуктивности',
        'Умное планирование задач',
        'Предсказание рисков просрочки',
      ];
    }
    return [
      'Интеграция с внешними сервисами',
      'Синхронизация данных',
      'Расширенные возможности',
    ];
  }
}
