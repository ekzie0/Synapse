import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/models/folder_model.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';

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
  
  Set<int> _expandedFolders = {};

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
    }
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
                final success = await folderProvider.createNote(title, authProvider.currentUser!.id!, folderId: folderId);
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
        setState(() {});
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

  void _toggleFolder(int folderId) {
    setState(() {
      if (_expandedFolders.contains(folderId)) {
        _expandedFolders.remove(folderId);
      } else {
        _expandedFolders.add(folderId);
      }
    });
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
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._buildFolderTree(provider.rootFolders, provider, userId, 0),
                
                if (provider.rootNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...provider.rootNotes.map((note) => _buildNoteTile(context, note, provider, userId, null)),
                ],
                
                if (provider.rootFolders.isEmpty && provider.rootNotes.isEmpty)
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
          () => _toggleFolder(folder.id!),
          () => _selectFolder(folder),
        ),
      );
      
      if (isExpanded) {
        if (folder.subfolders != null && folder.subfolders!.isNotEmpty) {
          widgets.addAll(_buildFolderTree(folder.subfolders!, provider, userId, depth + 1));
        }
        
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
            margin: const EdgeInsets.symmetric(vertical: 2),
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
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          margin: EdgeInsets.only(left: parentFolder != null ? 24 : 24),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
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
        
        Expanded(
          child: TextField(
            controller: _noteContentController,
            style: theme.textTheme.bodyLarge,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Начните писать...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _saveNote(),
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