import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/theme_provider.dart';
import 'package:synapse/providers/sync_provider.dart';
import 'package:synapse/models/theme_model.dart';
import 'package:synapse/widgets/rgb_color_picker.dart';
import 'package:synapse/services/avatar_service.dart';
import 'package:synapse/services/backup_service.dart';
import 'package:synapse/database/repositories/user_repository.dart';
import 'package:synapse/database/models/user_model.dart';
import 'package:synapse/providers/folder_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;
  final UserRepository _userRepo = UserRepository();
  final AvatarService _avatarService = AvatarService();
  final BackupService _backupService = BackupService();
  
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.person_outline, 'title': 'Аккаунт'},
    {'icon': Icons.app_settings_alt_outlined, 'title': 'Приложение'},
    {'icon': Icons.storage_outlined, 'title': 'Данные'},
    {'icon': Icons.info_outline, 'title': 'О нас'},
  ];

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar(BuildContext context, AuthProvider authProvider) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _avatarService.pickImageFromGallery();
                if (image != null && mounted) {
                  await _saveAvatar(authProvider, image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _avatarService.pickImageFromCamera();
                if (image != null && mounted) {
                  await _saveAvatar(authProvider, image);
                }
              },
            ),
            if (authProvider.currentUser?.avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить аватар', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteAvatar(authProvider);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAvatar(AuthProvider authProvider, File imageFile) async {
    final userId = authProvider.currentUser!.id!;
    final savedPath = await _avatarService.saveAvatar(imageFile, userId);
    
    if (savedPath != null && mounted) {
      await authProvider.updateAvatar(savedPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аватар сохранен')),
      );
    }
  }

  Future<void> _deleteAvatar(AuthProvider authProvider) async {
    final user = authProvider.currentUser!;
    if (user.avatarPath != null) {
      await _avatarService.deleteAvatar(user.avatarPath!);
    }
    await authProvider.updateAvatar(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аватар удален')),
      );
    }
  }

  Future<void> _updateUsername(AuthProvider authProvider) async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty || newUsername == authProvider.currentUser!.username) {
      return;
    }
    
    final updatedUser = authProvider.currentUser!.copyWith(username: newUsername);
    await _userRepo.updateUser(updatedUser);
    await authProvider.logout();
    await authProvider.login(newUsername, authProvider.currentUser!.password);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя пользователя обновлено')),
      );
    }
  }

  Future<void> _updateEmail(AuthProvider authProvider) async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty || newEmail == authProvider.currentUser!.email) {
      return;
    }
    
    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный email'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final updatedUser = authProvider.currentUser!.copyWith(email: newEmail);
    await _userRepo.updateUser(updatedUser);
    await authProvider.logout();
    await authProvider.login(authProvider.currentUser!.username, authProvider.currentUser!.password);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email обновлен')),
      );
    }
  }

  Future<void> _changePassword(AuthProvider authProvider) async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (oldPassword != authProvider.currentUser!.password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный старый пароль'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (newPassword.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Новый пароль должен быть не менее 4 символов'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final updatedUser = authProvider.currentUser!.copyWith(password: newPassword);
    await _userRepo.updateUser(updatedUser);
    await authProvider.logout();
    await authProvider.login(authProvider.currentUser!.username, newPassword);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль изменен')),
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      print('Ошибка подсчета размера: $e');
    }
    return size;
  }

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
    String? Function(String?)? validator,
  }) {
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Введите новое значение',
            ),
            validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSave();
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, AuthProvider authProvider) {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Смена пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Старый пароль',
                hintText: 'Введите текущий пароль',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Новый пароль',
                hintText: 'Минимум 4 символа',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Подтвердите пароль',
                hintText: 'Введите новый пароль еще раз',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _changePassword(authProvider);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Изменить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllNotesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все заметки'),
        content: const Text('Это действие необратимо. Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final folderProvider = Provider.of<FolderProvider>(context, listen: false);
              // TODO: реализовать удаление всех заметок
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция в разработке')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeProvider themeProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Тема оформления'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context, 'Светлая', Icons.light_mode_outlined,
                themeProvider.currentTheme.name == 'Светлая' && !themeProvider.useSystemTheme,
                () {
                  themeProvider.setThemeMode('Светлая');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context, 'Темная', Icons.dark_mode_outlined,
                themeProvider.currentTheme.name == 'Темная' && !themeProvider.useSystemTheme,
                () {
                  themeProvider.setThemeMode('Темная');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context, 'Системная', Icons.settings_outlined,
                themeProvider.useSystemTheme,
                () {
                  themeProvider.setThemeMode('system');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, 
    String label, 
    IconData icon, 
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : Colors.grey[400]),
            const SizedBox(width: 14),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? colorScheme.primary : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, size: 20, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // Методы экспорта/импорта
  Future<void> _exportJson(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final filePath = await _backupService.exportToJson(authProvider.currentUser!.id!);
    
    if (filePath != null && mounted) {
      final size = await _backupService.getBackupSize(filePath);
      final sizeMB = size / (1024 * 1024);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Экспорт завершен'),
          content: Text('Файл сохранен\nРазмер: ${sizeMB.toStringAsFixed(2)} МБ'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
            TextButton(
              onPressed: () async {
                await _backupService.shareFile(filePath);
                Navigator.pop(context);
              },
              child: const Text('Поделиться'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка экспорта'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dirPath = await _backupService.exportToMarkdown(authProvider.currentUser!.id!);
    
    if (dirPath != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Экспорт в Markdown завершен'),
          content: Text('Папка сохранена:\n$dirPath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка экспорта'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final filePath = await _backupService.pickJsonFile();
    if (filePath == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановление данных'),
        content: const Text('Внимание! Все текущие заметки будут заменены. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await _backupService.importFromJson(filePath, authProvider.currentUser!.id!);
    
    if (success && mounted) {
      final folderProvider = Provider.of<FolderProvider>(context, listen: false);
      await folderProvider.loadRootFolders(authProvider.currentUser!.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Импорт завершен')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка импорта'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importMarkdown(BuildContext context) async {
    final folderPath = await _backupService.pickMarkdownFolder();
    if (folderPath == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await _backupService.importFromMarkdown(folderPath, authProvider.currentUser!.id!);
    
    if (success && mounted) {
      final folderProvider = Provider.of<FolderProvider>(context, listen: false);
      await folderProvider.loadRootFolders(authProvider.currentUser!.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Импорт Markdown завершен')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка импорта'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSyncDialog(BuildContext context, SyncProvider syncProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wi-Fi синхронизация'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              syncProvider.isAutoSyncRunning 
                  ? '✅ Синхронизация активна' 
                  : '⏸ Синхронизация отключена',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              syncProvider.syncStatus,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Устройства в одной Wi-Fi сети будут автоматически обмениваться заметками.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 600;

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
                      'Настройки',
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
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 250,
                          margin: const EdgeInsets.only(left: 20, right: 10),
                          child: _buildMenuList(context),
                        ),
                        Container(
                          width: 1,
                          height: double.infinity,
                          color: colorScheme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: _buildContent(context),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _menuItems.length,
                            itemBuilder: (context, index) {
                              return _buildMobileMenuItem(context, index);
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: colorScheme.brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.black12,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildContent(context),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.separated(
      itemCount: _menuItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isSelected = _selectedIndex == index;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colorScheme.primary.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedIndex = index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      item['icon'],
                      size: 22,
                      color: isSelected ? colorScheme.primary : Colors.grey[400],
                    ),
                    const SizedBox(width: 14),
                    Text(
                      item['title'],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 15,
                        color: isSelected ? colorScheme.primary : Colors.grey[300],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileMenuItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary.withOpacity(0.3) 
                : (colorScheme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _menuItems[index]['icon'],
              size: 18,
              color: isSelected ? colorScheme.primary : Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              _menuItems[index]['title'],
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isSelected ? colorScheme.primary : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0: return _buildAccountSettings(context);
      case 1: return _buildAppSettings(context);
      case 2: return _buildDataSettings(context);
      case 3: return _buildAboutSettings(context);
      default: return _buildAccountSettings(context);
    }
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return ListView(
          children: [
            const SizedBox(height: 8),
            _buildAvatarSetting(context, user, authProvider),
            const SizedBox(height: 8),
            _buildEditableSetting(
              context,
              icon: Icons.person_outline,
              title: 'Имя пользователя',
              value: user?.username ?? '',
              controller: _usernameController,
              onSave: () => _updateUsername(authProvider),
            ),
            const SizedBox(height: 8),
            _buildEditableSetting(
              context,
              icon: Icons.email_outlined,
              title: 'Email',
              value: user?.email ?? '',
              controller: _emailController,
              onSave: () => _updateEmail(authProvider),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Введите корректный email';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _buildPasswordChangeSetting(context, authProvider),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildAvatarSetting(BuildContext context, User? user, AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _changeAvatar(context, authProvider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipOval(
                    child: _buildAvatarPreview(user, colorScheme),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Аватар',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Нажмите чтобы изменить',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPreview(User? user, ColorScheme colorScheme) {
    if (user?.avatarPath != null && user!.avatarPath!.isNotEmpty) {
      final file = File(user.avatarPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      }
    }
    
    return Center(
      child: Text(
        user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEditableSetting(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required TextEditingController controller,
    required VoidCallback onSave,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    controller.text = value;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showEditDialog(
              context,
              title: 'Изменить $title',
              controller: controller,
              onSave: onSave,
              validator: validator,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: colorScheme.brightness == Brightness.dark
                        ? Colors.grey[500]
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[700]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordChangeSetting(BuildContext context, AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPasswordDialog(context, authProvider);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Пароль',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
                  ),
                ),
                const Text('••••••••'),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[700]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 8, color: Colors.transparent);

  Widget _buildAppSettings(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListView(
          children: [
            const SizedBox(height: 8),
            _buildSettingItem(
              context,
              icon: Icons.palette_outlined,
              title: 'Тема',
              value: themeProvider.currentTheme.name,
              onTap: () => _showThemeSelectionDialog(context, themeProvider),
            ),
            _buildColorSettingItem(
              context,
              icon: Icons.color_lens_outlined,
              title: 'Акцентный цвет',
              currentColor: themeProvider.currentTheme.primaryColor,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => RgbColorPicker(
                    initialColor: themeProvider.currentTheme.primaryColor,
                    onColorSelected: (color) => themeProvider.setAccentColor(color),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.language_outlined,
              title: 'Язык',
              value: 'Русский',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Язык будет добавлен в следующем обновлении')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildDataSettings(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return ListView(
          children: [
            const SizedBox(height: 8),
            _buildSettingItem(
              context,
              icon: Icons.wifi,
              title: 'Wi-Fi синхронизация',
              value: syncProvider.isAutoSyncRunning ? 'Вкл' : 'Выкл',
              onTap: () => _showSyncDialog(context, syncProvider),
              showSwitch: true,
              switchValue: syncProvider.isAutoSyncRunning,
              onSwitchChanged: (value) async {
                if (value) {
                  await syncProvider.startAutoSync(context);
                } else {
                  await syncProvider.stopAutoSync();
                }
                setState(() {});
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              context,
              icon: Icons.storage_outlined,
              title: 'Использовано памяти',
              value: 'Вычисляется...',
              onTap: () async {
                final dir = await getApplicationDocumentsDirectory();
                final size = await _getDirectorySize(dir);
                final sizeMB = size / (1024 * 1024);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Использовано: ${sizeMB.toStringAsFixed(2)} МБ')),
                );
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              context,
              icon: Icons.delete_outline,
              title: 'Очистить кэш',
              value: 'Очистить',
              onTap: () async {
                final dir = await getApplicationDocumentsDirectory();
                final imagesDir = Directory('${dir.path}/note_images');
                final avatarsDir = Directory('${dir.path}/avatars');
                
                if (await imagesDir.exists()) {
                  await imagesDir.delete(recursive: true);
                }
                if (await avatarsDir.exists()) {
                  await avatarsDir.delete(recursive: true);
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Кэш очищен')),
                  );
                }
              },
              isDestructive: true,
            ),
            _buildSettingItem(
              context,
              icon: Icons.delete_forever_outlined,
              title: 'Удалить все заметки',
              value: 'Необратимо',
              onTap: () {
                _showDeleteAllNotesDialog(context);
              },
              isDestructive: true,
            ),
            _buildDivider(),
            _buildSettingItem(
              context,
              icon: Icons.backup_outlined,
              title: 'Экспорт (JSON)',
              value: 'Сохранить все заметки',
              onTap: () => _exportJson(context),
            ),
            _buildSettingItem(
              context,
              icon: Icons.text_snippet,
              title: 'Экспорт (Markdown)',
              value: 'Сохранить как .md файлы',
              onTap: () => _exportMarkdown(context),
            ),
            _buildSettingItem(
              context,
              icon: Icons.restore,
              title: 'Импорт из JSON',
              value: 'Восстановить из резервной копии',
              onTap: () => _importJson(context),
            ),
            _buildSettingItem(
              context,
              icon: Icons.folder_open,
              title: 'Импорт из Markdown',
              value: 'Загрузить папку с .md',
              onTap: () => _importMarkdown(context),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        _buildAboutHeader(context),
        _buildSettingItem(
          context,
          icon: Icons.info_outline,
          title: 'Версия',
          value: '1.0.0',
          onTap: () {},
        ),
        _buildSettingItem(
          context,
          icon: Icons.update_outlined,
          title: 'Проверить обновления',
          value: 'Актуально',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Вы используете последнюю версию')),
            );
          },
        ),
        _buildDivider(),
        _buildSettingItem(
          context,
          icon: Icons.feedback_outlined,
          title: 'Обратная связь',
          value: 'Сообщить об ошибке',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('feedback@synapse.com')),
            );
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.star_outline,
          title: 'Оценить приложение',
          value: 'В Play Market',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Скоро появится')),
            );
          },
        ),
        _buildDivider(),
        _buildSettingItem(
          context,
          icon: Icons.description_outlined,
          title: 'Пользовательское соглашение',
          value: '',
          onTap: () {},
        ),
        _buildSettingItem(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Политика конфиденциальности',
          value: '',
          onTap: () {},
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAboutHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: SvgPicture.asset(
              'assets/images/synapse_logo_without_text_white.svg',
              colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Synapse',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Версия 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Приложение для заметок с графом связей',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color currentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15))),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[700]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDestructive 
                        ? Colors.red.withOpacity(0.05)
                        : colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: isDestructive ? Colors.red : colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                ),
                if (showSwitch)
                  Switch(
                    value: switchValue,
                    onChanged: onSwitchChanged ?? (val) => print('$title: $val'),
                    activeColor: colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                else
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: isDestructive 
                          ? Colors.red[300] 
                          : (colorScheme.brightness == Brightness.dark
                              ? Colors.grey[500]
                              : Colors.grey[600]),
                    ),
                  ),
                if (!showSwitch) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[700]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}