import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';
import 'package:synapse/providers/theme_provider.dart';
import 'package:synapse/widgets/rgb_color_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.person_outline,
      'title': 'Аккаунт',
    },
    {
      'icon': Icons.computer_outlined,
      'title': 'Приложение',
    },
    {
      'icon': Icons.storage_outlined,
      'title': 'Данные',
    },
    {
      'icon': Icons.info_outline,
      'title': 'О нас',
    },
  ];

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
            // Верхняя панель
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

            // Основная часть
            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Левое меню
                        Container(
                          width: 250,
                          margin: const EdgeInsets.only(left: 20, right: 10),
                          child: _buildMenuList(context),
                        ),
                        
                        // Разделитель
                        Container(
                          width: 1,
                          height: double.infinity,
                          color: colorScheme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                        
                        // Правый контент
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
                        // Горизонтальное меню для мобилок
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
                        // Контент
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

  // Левое меню
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
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
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

  // Пункт меню для мобилок
  Widget _buildMobileMenuItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
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

  // Контент справа
  Widget _buildContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _buildAccountSettings(context);
      case 1:
        return _buildAppSettings(context);
      case 2:
        return _buildDataSettings(context);
      case 3:
        return _buildAboutSettings(context);
      default:
        return _buildAccountSettings(context);
    }
  }

  // НАСТРОЙКИ АККАУНТА
  Widget _buildAccountSettings(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        _buildSettingItem(
          context,
          icon: Icons.person_outline,
          title: 'Имя пользователя',
          value: 'synapse_user',
          onTap: () {},
        ),
        _buildSettingItem(
          context,
          icon: Icons.email_outlined,
          title: 'Email',
          value: 'user@example.com',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingItem(
          context,
          icon: Icons.lock_outline,
          title: 'Пароль',
          value: '••••••••',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingItem(
          context,
          icon: Icons.link_outlined,
          title: 'Привязанные аккаунты',
          value: 'Google, GitHub',
          onTap: () {},
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // НАСТРОЙКИ ПРИЛОЖЕНИЯ (с темой и акцентным цветом)
  Widget _buildAppSettings(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListView(
          children: [
            const SizedBox(height: 8),
            
            // Тема
            _buildSettingItem(
              context,
              icon: Icons.palette_outlined,
              title: 'Тема',
              value: themeProvider.currentTheme.name,
              onTap: () {
                _showThemeSelectionDialog(context, themeProvider);
              },
            ),
            
            // Акцентный цвет
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
                    onColorSelected: (color) {
                      themeProvider.setAccentColor(color);
                    },
                  ),
                );
              },
            ),
            
            _buildSettingItem(
              context,
              icon: Icons.language_outlined,
              title: 'Язык',
              value: 'Русский',
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // НАСТРОЙКИ ДАННЫХ
  Widget _buildDataSettings(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        _buildSettingItem(
          context,
          icon: Icons.cloud_sync_outlined,
          title: 'Синхронизация по Wi-Fi',
          value: 'Авто',
          onTap: () {},
          showSwitch: true,
          switchValue: true,
        ),
        _buildDivider(),
        _buildSettingItem(
          context,
          icon: Icons.storage_outlined,
          title: 'Использовано памяти',
          value: '2.4 МБ / 100 МБ',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingItem(
          context,
          icon: Icons.delete_outline,
          title: 'Очистить кэш',
          value: '12.5 МБ',
          onTap: () {},
          isDestructive: true,
        ),
        _buildSettingItem(
          context,
          icon: Icons.delete_forever_outlined,
          title: 'Удалить все заметки',
          value: 'Необратимо',
          onTap: () {},
          isDestructive: true,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // НАСТРОЙКИ О НАС
  Widget _buildAboutSettings(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingItem(
          context,
          icon: Icons.feedback_outlined,
          title: 'Обратная связь',
          value: 'Сообщить об ошибке',
          onTap: () {},
        ),
        _buildSettingItem(
          context,
          icon: Icons.star_outline,
          title: 'Оценить приложение',
          value: 'В Play Market',
          onTap: () {},
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

  // Заголовок для секции "О нас"
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
              colorFilter: ColorFilter.mode(
                colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Synapse',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Версия 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.brightness == Brightness.dark
                  ? Colors.grey[500]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Пункт настройки с цветом
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
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                  ),
                ),
                // Кружок с текущим цветом
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
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colorScheme.brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Один элемент настройки
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showSwitch = false,
    bool switchValue = false,
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
                  child: Icon(
                    icon,
                    size: 18,
                    color: isDestructive ? Colors.red : colorScheme.primary,
                  ),
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
                    onChanged: (val) {
                      print('$title: $val');
                    },
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
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[500],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Тонкий разделитель
  Widget _buildDivider() {
    return Container(
      height: 8,
      color: Colors.transparent,
    );
  }

  // Диалог выбора темы
  void _showThemeSelectionDialog(BuildContext context, ThemeProvider themeProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Тема оформления'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context, 
                'Светлая', 
                Icons.light_mode_outlined, 
                themeProvider.currentTheme.name == 'Светлая' && !themeProvider.useSystemTheme,
                () {
                  themeProvider.setThemeMode('Светлая');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context, 
                'Темная', 
                Icons.dark_mode_outlined, 
                themeProvider.currentTheme.name == 'Темная' && !themeProvider.useSystemTheme,
                () {
                  themeProvider.setThemeMode('Темная');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context, 
                'Системная', 
                Icons.settings_outlined, 
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
            Icon(
              icon, 
              color: isSelected ? colorScheme.primary : Colors.grey[400],
            ),
            const SizedBox(width: 14),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? colorScheme.primary : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected) 
              Icon(
                Icons.check_circle, 
                size: 20, 
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}