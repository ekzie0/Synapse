import 'package:flutter/material.dart';
import 'package:synapse/screens/settings_screen.dart';
// import 'package:synapse/screens/profile_screen.dart';

class AvatarPopupMenu extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  
  const AvatarPopupMenu({
    super.key,
    this.onProfileTap,
    this.onSettingsTap,
    this.onLogoutTap,
  });

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Выход',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Вы уверены, что хотите выйти?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (onLogoutTap != null) {
                  onLogoutTap!();
                } else {
                  print('Выход из аккаунта');
                  // TODO: добавить реальный выход
                }
              },
              child: const Text(
                'Выйти',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      splashRadius: 1,
      
      icon: Icon(
        Icons.account_circle_outlined,
        size: 28,
        color: colorScheme.primary,
      ),

      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 22,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Профиль',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        
        PopupMenuItem(
          value: 'settings',
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 22,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Настройки',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        
        const PopupMenuDivider(
          height: 1,
          thickness: 1,
        ),
        
        PopupMenuItem(
          value: 'logout',
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.logout,
                size: 22,
                color: Colors.red[400],
              ),
              const SizedBox(width: 12),
              Text(
                'Выйти',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        ),
      ],

      onSelected: (value) {
        switch (value) {
          case 'profile':
            if (onProfileTap != null) {
              onProfileTap!();
            } else {
              print('Профиль');
              // TODO: раскомментировать, когда создашь profile_screen.dart
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const ProfileScreen()),
              // );
            }
            break;
            
          case 'settings':
            if (onSettingsTap != null) {
              onSettingsTap!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }
            break;
            
          case 'logout':
            _showLogoutDialog(context);
            break;
        }
      },
    );
  }
}