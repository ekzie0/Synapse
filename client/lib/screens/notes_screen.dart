import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:synapse/screens/graph_screen.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';
import 'package:synapse/widgets/image_picker_widget.dart';
import 'package:synapse/widgets/tag_picker.dart';

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
  final TextEditingController _noteContentController = TextEditingController();
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  Set<int> _expandedFolders = {};
  List<Folder> _folders = [];
  List<Note> _allNotes = [];
  List<Note> _notesInCurrentFolder = [];
  
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
      await folderProvider.loadAllData(authProvider.currentUser!.id!);
      setState(() {
        _folders = List.from(folderProvider.rootFolders);
        _allNotes = List.from(folderProvider.allNotes);
        _updateNotesInCurrentFolder();
      });
    }
  }

  void _updateNotesInCurrentFolder() {
    if (_selectedFolder == null) {
      _notesInCurrentFolder = _allNotes.where((n) => n.folderId == null).toList();
    } else {
      _notesInCurrentFolder = _allNotes.where((n) => n.folderId == _selectedFolder!.id).toList();
    }
    // Сортируем по дате обновления (новые сверху)
    _notesInCurrentFolder.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() {});
  }

  void _openNote(Note note) {
    setState(() {
      _selectedNoteId = note.id;
      _noteTitleController.text = note.title;
      _noteContentController.text = note.content ?? '';
    });
  }

  void _selectFolder(Folder? folder) {
    setState(() {
      _selectedFolder = folder;
      _selectedNoteId = null;
      _noteTitleController.clear();
      _noteContentController.clear();
      _updateNotesInCurrentFolder();
    });
  }

  Future<void> _saveNote() async {
    if (_selectedNoteId == null) return;
    
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final note = _allNotes.firstWhere((n) => n.id == _selectedNoteId);
    
    final updatedNote = note.copyWith(
      title: _noteTitleController.text,
      content: _noteContentController.text,
    );
    await folderProvider.updateNote(updatedNote);
    
    // Обновляем локальные списки
    final index = _allNotes.indexWhere((n) => n.id == _selectedNoteId);
    if (index != -1) _allNotes[index] = updatedNote;
    _updateNotesInCurrentFolder();
  }

  Future<void> _createNote() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    final title = 'Новая заметка ${DateTime.now().millisecondsSinceEpoch}';
    final success = await folderProvider.createNote(title, authProvider.currentUser!.id!, folderId: _selectedFolder?.id);
    
    if (success && mounted) {
      await _loadData();
      final newNote = _allNotes.lastWhere((n) => n.title == title);
      _openNote(newNote);
    }
  }

  Future<void> _createFolder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    _folderNameController.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать папку'),
        content: TextField(
          controller: _folderNameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Название папки'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, _folderNameController.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    
    if (name != null && name.isNotEmpty) {
      await folderProvider.createFolder(name, authProvider.currentUser!.id!, parentFolderId: _selectedFolder?.id);
      await _loadData();
      setState(() {});
    }
  }

  Future<void> _deleteNote(Note note) async {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку'),
        content: Text('Удалить "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await folderProvider.deleteNote(note.id!, authProvider.currentUser!.id!);
      await _loadData();
      if (_selectedNoteId == note.id) {
        setState(() {
          _selectedNoteId = null;
          _noteTitleController.clear();
          _noteContentController.clear();
        });
      }
    }
  }

  List<Note> _getFilteredNotes() {
    if (_searchQuery.isEmpty) return _notesInCurrentFolder;
    final query = _searchQuery.toLowerCase();
    return _notesInCurrentFolder.where((note) {
      if (note.title.toLowerCase().contains(query)) return true;
      if (note.content != null && note.content!.toLowerCase().contains(query)) return true;
      if (note.tags != null) {
        for (var tag in note.tags!) {
          if (tag.toLowerCase().contains(query)) return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final filteredNotes = _getFilteredNotes();
    
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
                      _selectedFolder?.name ?? 'Заметки',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.brightness == Brightness.dark
                            ? const Color.fromARGB(255, 70, 70, 70)
                            : Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GraphScreen())),
                    icon: const Icon(Icons.bubble_chart_outlined),
                    color: colorScheme.primary,
                  ),
                  const AvatarPopupMenu(),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: isDesktop
                  ? Row(
                      children: [
                        SizedBox(
                          width: _leftPanelWidth,
                          child: _buildLeftPanel(context, colorScheme, filteredNotes),
                        ),
                        GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              double newWidth = _leftPanelWidth + details.delta.dx;
                              if (newWidth >= _minPanelWidth && newWidth <= _maxPanelWidth) {
                                _leftPanelWidth = newWidth;
                              }
                            });
                          },
                          child: Container(
                            width: 4,
                            color: _isResizing ? colorScheme.primary : Colors.transparent,
                          ),
                        ),
                        Expanded(child: _buildRightPanel(context)),
                      ],
                    )
                  : const Center(child: Text('Мобильная версия в разработке')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, ColorScheme colorScheme, List<Note> filteredNotes) {
    return Column(
      children: [
        // Кнопки
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _createFolder,
                  icon: const Icon(Icons.folder_outlined, size: 16),
                  label: const Text('Папка'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createNote,
                  icon: const Icon(Icons.note_add, size: 16),
                  label: const Text('Заметка'),
                ),
              ),
            ],
          ),
        ),
        
        // Навигация
        if (_selectedFolder != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _selectFolder(null),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Назад'),
              ),
            ),
          ),
        
        // Поиск
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {
              _searchQuery = value;
              _isSearching = value.isNotEmpty;
            }),
            decoration: InputDecoration(
              hintText: 'Поиск...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              filled: true,
              fillColor: colorScheme.surface,
            ),
          ),
        ),
        
        // Список папок
        Expanded(
          child: ListView(
            children: [
              ..._folders.map((folder) => _buildFolderTile(folder, colorScheme)),
              if (filteredNotes.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(),
                ),
                ...filteredNotes.map((note) => _buildNoteTile(note, colorScheme)),
              ],
              if (_folders.isEmpty && filteredNotes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Пусто'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFolderTile(Folder folder, ColorScheme colorScheme) {
    final isSelected = _selectedFolder?.id == folder.id;
    return ListTile(
      leading: Icon(Icons.folder_outlined, color: colorScheme.primary),
      title: Text(folder.name),
      tileColor: isSelected ? colorScheme.primary.withOpacity(0.1) : null,
      onTap: () => _selectFolder(folder),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: () => _deleteFolder(folder),
      ),
    );
  }

  Widget _buildNoteTile(Note note, ColorScheme colorScheme) {
    final isSelected = _selectedNoteId == note.id;
    return ListTile(
      leading: Icon(Icons.description_outlined, size: 20),
      title: Text(
        note.title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      tileColor: isSelected ? colorScheme.primary.withOpacity(0.08) : null,
      onTap: () => _openNote(note),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: () => _deleteNote(note),
      ),
    );
  }

  Future<void> _deleteFolder(Folder folder) async {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить папку'),
        content: Text('Удалить папку "${folder.name}" со всеми заметками?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await folderProvider.deleteFolder(folder, authProvider.currentUser!.id!);
      await _loadData();
      if (_selectedFolder?.id == folder.id) _selectFolder(null);
    }
  }

  Widget _buildRightPanel(BuildContext context) {
    if (_selectedNoteId == null) {
      return const Center(child: Text('Выберите заметку'));
    }
    
    final note = _allNotes.firstWhere((n) => n.id == _selectedNoteId);
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _noteTitleController,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(hintText: 'Заголовок', border: InputBorder.none),
                  onChanged: (_) => _saveNote(),
                ),
                const SizedBox(height: 16),
                TagPicker(
                  selectedTags: note.tags ?? [],
                  onTagsChanged: (tags) {
                    final updatedNote = note.copyWith(tags: tags);
                    Provider.of<FolderProvider>(context, listen: false).updateNote(updatedNote);
                    _loadData();
                  },
                  availableTags: [],
                ),
                const SizedBox(height: 16),
                ImagePickerWidget(
                  imagePaths: note.images ?? [],
                  onImagesChanged: (images) {
                    final updatedNote = note.copyWith(images: images);
                    Provider.of<FolderProvider>(context, listen: false).updateNote(updatedNote);
                    _loadData();
                  },
                  noteId: note.id!,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteContentController,
                  maxLines: 20,
                  decoration: const InputDecoration(hintText: 'Содержимое...', border: InputBorder.none),
                  onChanged: (_) => _saveNote(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}