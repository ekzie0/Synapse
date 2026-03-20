import 'package:flutter/material.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _selectedNoteIndex = 0;
  double _leftPanelWidth = 320;
  bool _isResizing = false;
  
  final double _minPanelWidth = 200;
  final double _maxPanelWidth = 500;
  
  final List<Map<String, dynamic>> _notes = [
    {
      'title': 'Архитектура Synapse',
      'content': 'Flutter + Go, локальная синхронизация по Wi-Fi, граф связей как в Obsidian.\n\nПлан:\n- Настроить gomobile\n- Реализовать синхронизацию\n- Сделать граф связей',
      'date': '2 ч назад',
      'tags': ['dev', 'go'],
    },
    {
      'title': 'Идеи для диплома',
      'content': 'Синхронизация по Wi-Fi без интернета\nГраф связей между заметками\nТемная/светлая тема\nКастомные акцентные цвета',
      'date': 'вчера',
      'tags': ['диплом'],
    },
    {
      'title': 'Встреча с научником',
      'content': 'Обсудили структуру диплома. Сказал:\n- Добавить больше теории\n- Сделать сравнение с аналогами\n- Показать практическую часть',
      'date': '3 дня',
      'tags': ['важно'],
    },
    {
      'title': 'Заметки по Flutter',
      'content': 'Widgets: StatelessWidget, StatefulWidget\nState management: Provider, Riverpod\nТемы: ThemeData, CupertinoTheme',
      'date': '5 дней',
      'tags': ['flutter'],
    },
    {
      'title': 'Go для бэкенда',
      'content': 'Использовать gomobile для связи с Flutter\nSQLite для хранения\nREST API для синхронизации',
      'date': 'неделю',
      'tags': ['go'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
                        color: colorScheme.brightness == Brightness.dark
                            ? const Color.fromARGB(255, 70, 70, 70)
                            : Colors.grey[800],
                      ),
                    ),
                  ),
                  const AvatarPopupMenu(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isDesktop
                  ? MouseRegion(
                      cursor: _isResizing ? SystemMouseCursors.resizeColumn : MouseCursor.defer,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: _leftPanelWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _buildNotesList(context),
                            ),
                          ),
                          GestureDetector(
                            onHorizontalDragStart: (details) {
                              setState(() {
                                _isResizing = true;
                              });
                            },
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                double newWidth = _leftPanelWidth + details.delta.dx;
                                if (newWidth >= _minPanelWidth && newWidth <= _maxPanelWidth) {
                                  _leftPanelWidth = newWidth;
                                }
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              setState(() {
                                _isResizing = false;
                              });
                            },
                            child: Container(
                              width: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: _isResizing 
                                    ? colorScheme.primary 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeColumn,
                                child: Container(
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
                              child: _buildNoteEditor(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildMobileView(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          height: 42,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск заметок...',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: const Color.fromARGB(255, 206, 206, 206),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        
        // Кнопка новой заметки
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              print('Создать заметку');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Новая заметка'),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Expanded(
          child: ListView.separated(
            itemCount: _notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final note = _notes[index];
              final isSelected = _selectedNoteIndex == index;
              
              return Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? colorScheme.primary.withOpacity(0.3) 
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedNoteIndex = index;
                      });
                    },
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
                                  note['title'],
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? colorScheme.primary : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                note['date'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note['content'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (note['tags'] != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: (note['tags'] as List<String>).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontSize: 9,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
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
    );
  }

  Widget _buildNoteEditor(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentNote = _notes[_selectedNoteIndex];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: TextEditingController(text: currentNote['title']),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            hintText: 'Заголовок',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            setState(() {
              _notes[_selectedNoteIndex]['title'] = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ...(currentNote['tags'] as List<String>).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {},
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Добавить тег',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: colorScheme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: currentNote['content']),
            style: theme.textTheme.bodyLarge,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Начните писать...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() {
                _notes[_selectedNoteIndex]['content'] = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context) {
    final theme = Theme.of(context);
    final currentNote = _notes[_selectedNoteIndex];
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Список заметок'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Редактор'),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: TextEditingController(text: currentNote['title']),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Заголовок',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: currentNote['content']),
                  style: theme.textTheme.bodyLarge,
                  maxLines: 20,
                  decoration: const InputDecoration(
                    hintText: 'Начните писать...',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}