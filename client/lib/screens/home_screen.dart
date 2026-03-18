import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:synapse/screens/notes_screen.dart';
import 'package:synapse/widgets/hover_text_button.dart';
import 'package:synapse/widgets/app_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

      return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя панель с логотипом
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppLogo(
                    size: 34,
                    color: isDark ? Colors.white : Colors.black,
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
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
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
                      padding: const EdgeInsets.only(left: 16, right: 8),
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

            // Быстрые действия
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Row(
                children: [
                  _buildQuickAction(
                    context,
                    icon: Icons.note_add_outlined,
                    label: 'Новая заметка',
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context,
                    icon: Icons.folder_outlined,
                    label: 'Все заметки',
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context,
                    icon: Icons.bubble_chart_outlined,
                    label: 'Граф',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 6),

            // Заголовок раздела
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Недавние',
                    style: theme.textTheme.titleLarge,
                  ),
                  
                  HoverTextButton(
                    text: 'Все',
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const NotesScreen()),
                      );
                    },
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Список заметок
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
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
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      note['title'] as String,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontSize: 15,
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
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                note['preview'] as String,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: (note['tags'] as List<String>).map((tag) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 6),
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

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (label == 'Все заметки') {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const NotesScreen()),
                );
              } else if (label == 'Новая заметка') {
                print('Новая заметка');
                // TODO: потом сделаем
              } else if (label == 'Граф') {
                print('Граф');
                // TODO: потом сделаем
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}