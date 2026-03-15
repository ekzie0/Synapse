import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Верхняя панель с приветствием
            SliverAppBar(
              floating: true,
              backgroundColor: colorScheme.background,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Synapse',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // TODO: перейти в настройки
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            // Поисковая строка
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск заметок...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            
            // Заголовок раздела
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Недавние заметки',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Список заметок
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildNoteCard(context, index);
                  },
                  childCount: 5,
                ),
              ),
            ),
            
            // Кнопка создания новой заметки
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    '➕ Создать заметку',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Нижняя навигация
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Заметки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart_outlined),
            activeIcon: Icon(Icons.bubble_chart),
            label: 'Граф',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // TODO: навигация
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Заглушка данных (потом уйдет в BLoC)
    final notes = [
      {'title': 'Архитектура Synapse', 'preview': 'Обсуждение Flutter + Go...', 'date': '2 часа назад'},
      {'title': 'Идеи для диплома', 'preview': 'Синхронизация по Wi-Fi, граф...', 'date': 'Вчера'},
      {'title': 'Встреча с научником', 'preview': 'Обсудили структуру, сказал...', 'date': '3 дня назад'},
      {'title': 'Заметки по Flutter', 'preview': 'Widgets, State management...', 'date': '5 дней назад'},
      {'title': 'Go для мобилок', 'preview': 'gomobile, связка с Flutter...', 'date': 'Неделю назад'},
    ];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          notes[index]['title']!,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notes[index]['preview']!,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              notes[index]['date']!,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.more_vert,
          color: Colors.grey[500],
          size: 20,
        ),
        onTap: () {
          // TODO: открыть заметку
        },
      ),
    );
  }
}