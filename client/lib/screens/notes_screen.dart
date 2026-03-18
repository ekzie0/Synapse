import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> notes = [
      {
        'title': 'Архитектура Synapse',
        'preview': 'Flutter + Go, локальная синхронизация...',
        'date': '2 ч назад',
        'tags': ['dev', 'go'],
      },
      {
        'title': 'Идеи для диплома',
        'preview': 'Синхронизация по Wi-Fi, граф связей...',
        'date': 'вчера',
        'tags': ['диплом'],
      },
      {
        'title': 'Встреча с научником',
        'preview': 'Обсудили структуру, сказал ок',
        'date': '3 дня',
        'tags': ['важно'],
      },
      {
        'title': 'Заметки по Flutter',
        'preview': 'Widgets, State management, темы',
        'date': '5 дней',
        'tags': ['flutter'],
      },
      {
        'title': 'Go для бэкенда',
        'preview': 'gomobile, связка с Flutter',
        'date': 'неделю',
        'tags': ['go'],
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя панель
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    color: colorScheme.primary,
                    splashRadius: 15,
                    highlightColor: colorScheme.primary.withValues(alpha: 0.1),
                    splashColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      'Заметки',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: const Color.fromARGB(255, 70, 70, 70),
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Поиск
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color.fromARGB(255, 206, 206, 206),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 14),
                      child: Icon(
                        Icons.search,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Список заметок
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          print('Открыть: ${note['title']}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок и дата
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      note['title'] as String,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    note['date'] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Превью
                              Text(
                                note['preview'] as String,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Теги
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: (note['tags'] as List<String>).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tag,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontSize: 11,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}