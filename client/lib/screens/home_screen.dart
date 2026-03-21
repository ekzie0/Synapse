import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/screens/notes_screen.dart';
import 'package:synapse/screens/graph_screen.dart';
import 'package:synapse/widgets/hover_text_button.dart';
import 'package:synapse/widgets/app_logo.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:synapse/database/models/note_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Note> _getRecentNotes(FolderProvider provider) {
    final allNotes = [...provider.rootNotes, ...provider.currentNotes];
    // Убираем дубликаты по id
    final uniqueNotes = <int, Note>{};
    for (var note in allNotes) {
      uniqueNotes[note.id!] = note;
    }
    final notes = uniqueNotes.values.toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes.take(5).toList();
  }

  List<Note> _filterNotes(List<Note> notes, String query) {
    if (query.isEmpty) return notes;
    final lowerQuery = query.toLowerCase();
    return notes.where((note) {
      if (note.title.toLowerCase().contains(lowerQuery)) return true;
      if (note.content != null && note.content!.toLowerCase().contains(lowerQuery)) return true;
      if (note.tags != null) {
        for (var tag in note.tags!) {
          if (tag.toLowerCase().contains(lowerQuery)) return true;
        }
      }
      return false;
    }).toList();
  }

  void _createNewNote(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    final title = 'Новая заметка ${DateTime.now().millisecondsSinceEpoch}';
    final success = await folderProvider.createNote(title, authProvider.currentUser!.id!);
    
    if (success && mounted) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => const NotesScreen()),
      );
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) {
      return '${diff.inDays ~/ 7} нед';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} дн';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ч';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} мин';
    } else {
      return 'только что';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<FolderProvider>(
      builder: (context, folderProvider, child) {
        final recentNotes = _getRecentNotes(folderProvider);
        final filteredNotes = _filterNotes(recentNotes, _searchQuery);
        final isLoading = folderProvider.isLoading;

        if (isLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

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
                      const AvatarPopupMenu(),
                    ],
                  ),
                ),

                // Поиск
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
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
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
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
                        onTap: () => _createNewNote(context),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        context,
                        icon: Icons.folder_outlined,
                        label: 'Все заметки',
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (context) => const NotesScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        context,
                        icon: Icons.bubble_chart_outlined,
                        label: 'Граф',
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (context) => const GraphScreen()),
                          );
                        },
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
                        _searchQuery.isEmpty ? 'Недавние' : 'Результаты поиска',
                        style: theme.textTheme.titleLarge,
                      ),
                      
                      if (_searchQuery.isEmpty)
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
                  child: filteredNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty ? Icons.note_outlined : Icons.search_off,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty ? 'Нет заметок' : 'Ничего не найдено',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (_searchQuery.isEmpty)
                                const SizedBox(height: 8),
                              if (_searchQuery.isEmpty)
                                Text(
                                  'Нажмите + чтобы создать заметку',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredNotes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            return _buildNoteCard(context, note);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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
            onTap: onTap,
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

  Widget _buildNoteCard(BuildContext context, Note note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final preview = note.content?.replaceAll('\n', ' ') ?? '';
    final previewText = preview.length > 80 ? '${preview.substring(0, 80)}...' : preview;

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
            // TODO: открыть конкретную заметку
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const NotesScreen()),
            );
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
                        note.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(note.updatedAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  previewText.isEmpty ? 'Нет содержимого' : previewText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.tags != null && note.tags!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: note.tags!.map((tag) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}