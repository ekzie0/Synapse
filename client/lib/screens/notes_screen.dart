import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';
import 'package:synapse/widgets/image_picker_widget.dart';
import 'package:synapse/widgets/tag_picker.dart';

// Кастомный контроллер для ссылок
class LinkTextEditingController extends TextEditingController {
  final RegExp _linkRegex = RegExp(r'\[\[(.*?)\]\]');
  
  List<String> getLinks() {
    final matches = _linkRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }
  
  bool isCursorInsideLink(int cursorPos) {
    final matches = _linkRegex.allMatches(text);
    for (var match in matches) {
      if (cursorPos >= match.start && cursorPos <= match.end) {
        return true;
      }
    }
    return false;
  }
  
  String? getLinkAtCursor(int cursorPos) {
    final matches = _linkRegex.allMatches(text);
    for (var match in matches) {
      if (cursorPos >= match.start && cursorPos <= match.end) {
        return match.group(1);
      }
    }
    return null;
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  double _leftPanelWidth = 280;
  bool _isResizing = false;
  final double _minPanelWidth = 180;
  final double _maxPanelWidth = 400;
  
  int? _selectedNoteId;
  Folder? _selectedFolder;
  final TextEditingController _noteTitleController = TextEditingController();
  final LinkTextEditingController _noteContentController = LinkTextEditingController();
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  Set<int> _expandedFolders = {};
  List<Folder> _rootFolders = [];
  
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      await folderProvider.loadRootFolders(authProvider.currentUser!.id!);
      setState(() {
        _rootFolders = folderProvider.rootFolders;
      });
    }
  }

  void _openNote(Note note) {
    setState(() {
      _selectedNoteId = note.id;
      _selectedFolder = null;
      _noteTitleController.text = note.title;
      _noteContentController.text = note.content ?? '';
    });
  }

  void _selectFolder(Folder folder) {
    setState(() {
      if (_selectedFolder?.id == folder.id) {
        _selectedFolder = null;
      } else {
        _selectedFolder = folder;
        _selectedNoteId = null;
        _noteTitleController.clear();
        _noteContentController.clear();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFolder = null;
      _selectedNoteId = null;
      _noteTitleController.clear();
      _noteContentController.clear();
    });
  }

  void _saveNote() async {
    if (_selectedNoteId == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    Note? currentNote;
    
    currentNote = folderProvider.rootNotes.firstWhere(
      (n) => n.id == _selectedNoteId,
      orElse: () => folderProvider.currentNotes.firstWhere(
        (n) => n.id == _selectedNoteId,
        orElse: () => Note(userId: 0, title: '', createdAt: 0, updatedAt: 0),
      ),
    );
    
    if (currentNote.id != null) {
      final updatedNote = currentNote.copyWith(
        title: _noteTitleController.text,
        content: _noteContentController.text,
      );
      await folderProvider.updateNote(updatedNote);
      _updateNoteInList(updatedNote);
    }
  }

  void _onTextChanged() {
    _saveNote();
    final text = _noteContentController.text;
    if (text.endsWith('[[')) {
      _showLinkAutocomplete();
    }
  }

  void _showLinkAutocomplete() {
    final provider = Provider.of<FolderProvider>(context, listen: false);
    final allNotes = [...provider.rootNotes, ...provider.currentNotes];
    
    if (allNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных заметок для ссылки')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Связать с заметкой'),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: ListView.builder(
            itemCount: allNotes.length,
            itemBuilder: (context, i) {
              final note = allNotes[i];
              if (note.id == _selectedNoteId) return const SizedBox.shrink();
              return ListTile(
                title: Text(note.title),
                onTap: () {
                  final currentText = _noteContentController.text;
                  final newText = currentText.substring(0, currentText.length - 2) +
                      '[[${note.title}]]';
                  _noteContentController.text = newText;
                  _noteContentController.selection = TextSelection.collapsed(
                    offset: newText.length,
                  );
                  Navigator.pop(context);
                  _saveNote();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String? _getLinkUnderCursor() {
    final text = _noteContentController.text;
    final selection = _noteContentController.selection;
    if (!selection.isValid) return null;

    final regExp = RegExp(r'\[\[(.*?)\]\]');
    final matches = regExp.allMatches(text);

    for (final match in matches) {
      if (selection.start >= match.start && selection.start <= match.end) {
        return match.group(1);
      }
    }
    return null;
  }

  void _jumpToNote(String linkTitle) {
    final provider = Provider.of<FolderProvider>(context, listen: false);
    final allNotes = [...provider.rootNotes, ...provider.currentNotes];
    final targetNote = allNotes.firstWhere(
      (n) => n.title == linkTitle,
      orElse: () => Note(userId: 0, title: '', createdAt: 0, updatedAt: 0),
    );
    if (targetNote.id != null) {
      _openNote(targetNote);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Открыта заметка: ${targetNote.title}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заметка "$linkTitle" не найдена'), backgroundColor: Colors.red),
      );
    }
  }

  List<String> _getAllTags() {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final allNotes = [...folderProvider.rootNotes, ...folderProvider.currentNotes];
    final Set<String> tags = {};
    for (var note in allNotes) {
      if (note.tags != null) {
        tags.addAll(note.tags!);
      }
    }
    return tags.toList();
  }

  void _updateNoteInList(Note updatedNote) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    final rootIndex = folderProvider.rootNotes.indexWhere((n) => n.id == updatedNote.id);
    if (rootIndex != -1) {
      folderProvider.rootNotes[rootIndex] = updatedNote;
    }
    final currentIndex = folderProvider.currentNotes.indexWhere((n) => n.id == updatedNote.id);
    if (currentIndex != -1) {
      folderProvider.currentNotes[currentIndex] = updatedNote;
    }
    setState(() {});
  }

  void _showCreateFolderDialog({int? parentFolderId}) {
    _folderNameController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать папку'),
        content: TextField(
          controller: _folderNameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название папки',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final name = _folderNameController.text.trim();
              if (name.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final folderProvider = Provider.of<FolderProvider>(context, listen: false);
                await folderProvider.createFolder(name, authProvider.currentUser!.id!, parentFolderId: parentFolderId);
                if (mounted) {
                  Navigator.pop(context);
                  _refreshAfterAction();
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteDialog({int? folderId}) {
    final titleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать заметку'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Заголовок заметки',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final folderProvider = Provider.of<FolderProvider>(context, listen: false);
                final targetFolderId = folderId ?? _selectedFolder?.id;
                
                final success = await folderProvider.createNote(
                  title, 
                  authProvider.currentUser!.id!, 
                  folderId: targetFolderId,
                );
                
                if (success && mounted) {
                  Navigator.pop(context);
                  _refreshAfterAction();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка создания заметки')),
                  );
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _refreshAfterAction() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    folderProvider.loadRootFolders(authProvider.currentUser!.id!).then((_) {
      if (mounted) {
        setState(() {
          _rootFolders = folderProvider.rootFolders;
        });
      }
    });
  }

  void _showDeleteConfirmDialog(String type, String name, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить $type'),
        content: Text('Вы уверены, что хотите удалить "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
              _refreshAfterAction();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _toggleFolder(Folder folder, int userId) async {
    if (!_expandedFolders.contains(folder.id)) {
      final folderProvider = Provider.of<FolderProvider>(context, listen: false);
      final subfolders = await folderProvider.getSubfolders(folder.id!, userId);
      
      setState(() {
        _updateFolderInTree(_rootFolders, folder.id!, subfolders);
        _expandedFolders.add(folder.id!);
      });
    } else {
      setState(() {
        _expandedFolders.remove(folder.id);
      });
    }
  }

  void _updateFolderInTree(List<Folder> folders, int folderId, List<Folder> subfolders) {
    for (var i = 0; i < folders.length; i++) {
      if (folders[i].id == folderId) {
        folders[i] = folders[i].copyWith(subfolders: subfolders);
        return;
      }
      if (folders[i].subfolders != null && folders[i].subfolders!.isNotEmpty) {
        _updateFolderInTree(folders[i].subfolders!, folderId, subfolders);
      }
    }
  }

  Future<void> _moveNoteToFolder(Note note, Folder targetFolder) async {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    final updatedNote = note.copyWith(folderId: targetFolder.id);
    final success = await folderProvider.updateNote(updatedNote);
    
    if (success && mounted) {
      _refreshAfterAction();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Заметка "${note.title}" перемещена в "${targetFolder.name}"')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка перемещения заметки'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Consumer2<AuthProvider, FolderProvider>(
      builder: (context, authProvider, folderProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Ошибка: пользователь не найден')),
          );
        }
        
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
                                  padding: const EdgeInsets.only(left: 12, right: 8),
                                  child: _buildTreeView(context, folderProvider, user.id!),
                                ),
                              ),
                              GestureDetector(
                                onHorizontalDragStart: (_) => setState(() => _isResizing = true),
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    double newWidth = _leftPanelWidth + details.delta.dx;
                                    if (newWidth >= _minPanelWidth && newWidth <= _maxPanelWidth) {
                                      _leftPanelWidth = newWidth;
                                    }
                                  });
                                },
                                onHorizontalDragEnd: (_) => setState(() => _isResizing = false),
                                child: Container(
                                  width: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _isResizing ? colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.resizeColumn,
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
                                  child: _buildNoteEditor(context, folderProvider),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildMobileView(context, folderProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTreeView(BuildContext context, FolderProvider provider, int userId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Логика определения того, что показать пользователю
    List<Note> notesToShow;
    
    if (_searchQuery.trim().isEmpty) {
      // ПОИСК ПУСТОЙ: Показываем обычную структуру
      if (provider.isInRoot) {
        // Мы в корне — берем заметки без папок
        notesToShow = provider.rootNotes;
      } else {
        // Мы внутри папки — берем заметки этой папки
        notesToShow = provider.currentNotes;
      }
    } else {
      // ИДЕТ ПОИСК: Игнорируем папки, ищем везде
      final allNotes = [...provider.rootNotes, ...provider.currentNotes];
      final lowerQuery = _searchQuery.toLowerCase();
      notesToShow = allNotes.where((note) {
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
    
    // Отладка
    print('🔍 Заметок к показу: ${notesToShow.length}, isInRoot: ${provider.isInRoot}, searchQuery: "$_searchQuery"');
    
    return GestureDetector(
      onTap: _clearSelection,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCreateFolderDialog(parentFolderId: _selectedFolder?.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Папка', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showCreateNoteDialog(folderId: _selectedFolder?.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add, size: 16),
                      SizedBox(width: 6),
                      Text('Заметка', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _isSearching = value.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._buildFolderTree(_rootFolders, provider, userId, 0),
                
                // Список заметок
                if (notesToShow.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...notesToShow.map((note) => _buildNoteTile(context, note, provider, userId, null)),
                ],
                
                // Сообщение о пустоте
                if (_rootFolders.isEmpty && notesToShow.isEmpty && !_isSearching)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Пусто',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (_isSearching && notesToShow.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ничего не найдено',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFolderTree(List<Folder> folders, FolderProvider provider, int userId, int depth) {
    List<Widget> widgets = [];
    
    final allNotes = [...provider.rootNotes, ...provider.currentNotes];
    
    for (var folder in folders) {
      final isExpanded = _expandedFolders.contains(folder.id);
      final isSelected = _selectedFolder?.id == folder.id;
      final folderNotes = allNotes.where((n) => n.folderId == folder.id).toList();
      
      widgets.add(
        _buildFolderTile(
          context, 
          folder, 
          provider, 
          userId, 
          depth, 
          isExpanded,
          isSelected,
          folderNotes.isNotEmpty,
          () => _toggleFolder(folder, userId),
          () => _selectFolder(folder),
        ),
      );
      
      if (isExpanded && folder.subfolders != null && folder.subfolders!.isNotEmpty) {
        widgets.addAll(_buildFolderTree(folder.subfolders!, provider, userId, depth + 1));
        
        if (folderNotes.isNotEmpty) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(left: (depth + 1) * 16.0 + 24),
              child: Column(
                children: folderNotes.map((note) => _buildNoteTile(context, note, provider, userId, folder)).toList(),
              ),
            ),
          );
        }
      }
    }
    
    return widgets;
  }

  Widget _buildFolderTile(
    BuildContext context,
    Folder folder,
    FolderProvider provider,
    int userId,
    int depth,
    bool isExpanded,
    bool isSelected,
    bool hasNotes,
    VoidCallback onToggle,
    VoidCallback onSelect,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return DragTarget<Note>(
      onAccept: (note) {
        _moveNoteToFolder(note, folder);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            onSelect();
            provider.openFolder(folder, userId);
          },
          onSecondaryTapDown: (details) {
            _showFolderContextMenu(details.globalPosition, folder);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: depth * 16.0),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onToggle,
                          child: Icon(
                            isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.folder_outlined, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            folder.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _showDeleteConfirmDialog('папку', folder.name, () async {
                              await provider.deleteFolder(folder, userId);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteTile(BuildContext context, Note note, FolderProvider provider, int userId, Folder? parentFolder) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedNoteId == note.id;
    
    return Draggable<Note>(
      data: note,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            note.title,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildNoteTileContent(context, note, colorScheme, isSelected, provider, userId, parentFolder),
      ),
      child: _buildNoteTileContent(context, note, colorScheme, isSelected, provider, userId, parentFolder),
    );
  }

  Widget _buildNoteTileContent(
    BuildContext context,
    Note note,
    ColorScheme colorScheme,
    bool isSelected,
    FolderProvider provider,
    int userId,
    Folder? parentFolder,
  ) {
    return GestureDetector(
      onTap: () => _openNote(note),
      onSecondaryTapDown: (details) {
        _showNoteContextMenu(details.globalPosition, note, parentFolder);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          margin: EdgeInsets.only(left: parentFolder != null ? 24 : 24),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 14),
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showDeleteConfirmDialog('заметку', note.title, () async {
                        await provider.deleteNote(note.id!, userId);
                        if (_selectedNoteId == note.id) {
                          setState(() {
                            _selectedNoteId = null;
                            _noteTitleController.clear();
                            _noteContentController.clear();
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
              if (note.tags != null && note.tags!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: note.tags!.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 9, color: colorScheme.primary),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderContextMenu(Offset position, Folder folder) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.folder_outlined, size: 18),
              SizedBox(width: 12),
              Text('Создать папку'),
            ],
          ),
          onTap: () {
            _showCreateFolderDialog(parentFolderId: folder.id);
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.note_add, size: 18),
              SizedBox(width: 12),
              Text('Создать заметку'),
            ],
          ),
          onTap: () {
            _showCreateNoteDialog(folderId: folder.id);
          },
        ),
      ],
    );
  }

  void _showNoteContextMenu(Offset position, Note note, Folder? parentFolder) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 12),
              Text('Редактировать'),
            ],
          ),
          onTap: () {
            _openNote(note);
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('Удалить', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final folderProvider = Provider.of<FolderProvider>(context, listen: false);
            _showDeleteConfirmDialog('заметку', note.title, () async {
              await folderProvider.deleteNote(note.id!, authProvider.currentUser!.id!);
              if (_selectedNoteId == note.id) {
                setState(() {
                  _selectedNoteId = null;
                  _noteTitleController.clear();
                  _noteContentController.clear();
                });
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildNoteEditor(BuildContext context, FolderProvider provider) {
    final theme = Theme.of(context);
    
    Note? selectedNote;
    
    selectedNote = provider.rootNotes.firstWhere(
      (n) => n.id == _selectedNoteId,
      orElse: () => provider.currentNotes.firstWhere(
        (n) => n.id == _selectedNoteId,
        orElse: () => Note(userId: 0, title: '', createdAt: 0, updatedAt: 0),
      ),
    );
    
    if (_selectedNoteId == null || selectedNote.id == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              'Выберите заметку',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    final currentNote = selectedNote;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _noteTitleController,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: 'Заголовок',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (_) => _saveNote(),
        ),
        
        const SizedBox(height: 16),
        
        TagPicker(
          selectedTags: currentNote.tags ?? [],
          onTagsChanged: (tags) {
            if (currentNote.id != null) {
              final updatedNote = currentNote.copyWith(tags: tags);
              provider.updateNote(updatedNote);
              _updateNoteInList(updatedNote);
            }
          },
          availableTags: _getAllTags(),
        ),
        
        const SizedBox(height: 16),
        
        ImagePickerWidget(
          imagePaths: currentNote.images ?? [],
          onImagesChanged: (images) {
            if (currentNote.id != null) {
              final updatedNote = currentNote.copyWith(images: images);
              provider.updateNote(updatedNote);
              _updateNoteInList(updatedNote);
            }
          },
          noteId: currentNote.id!,
        ),
        
        const SizedBox(height: 16),
        
        Container(
          height: 1,
          color: theme.colorScheme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        
        const SizedBox(height: 16),
        
        // Кнопка перехода по ссылке под курсором
        ValueListenableBuilder(
          valueListenable: _noteContentController,
          builder: (context, value, child) {
            final linkTitle = _getLinkUnderCursor();
            if (linkTitle == null) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                title: Text(
                  "Перейти к: $linkTitle",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _jumpToNote(linkTitle),
              ),
            );
          },
        ),
        
        // Поле для содержимого
        Expanded(
          child: TextField(
            controller: _noteContentController,
            style: theme.textTheme.bodyLarge,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Начните писать... Используйте [[ для вставки ссылки',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              _onTextChanged();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, FolderProvider provider) {
    return const Center(
      child: Text('Мобильная версия в разработке'),
    );
  }
}