import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/models/user_model.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/screens/settings_screen.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Выход', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: const Text('Вы уверены, что хотите выйти?', style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
                if (onLogoutTap != null) {
                  onLogoutTap!();
                }
              },
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      splashRadius: 0.1,
      icon: null,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: _buildAvatar(context, user),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          height: 48,
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 22, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Профиль', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          height: 48,
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 22, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Настройки', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1, thickness: 1),
        PopupMenuItem(
          value: 'logout',
          height: 48,
          child: Row(
            children: [
              Icon(Icons.logout, size: 22, color: Colors.red[400]),
              const SizedBox(width: 12),
              Text('Выйти', style: TextStyle(fontSize: 16, color: Colors.red[400])),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            // При нажатии на "Профиль" открываем настройки
            if (onProfileTap != null) {
              onProfileTap!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
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

  Widget _buildAvatar(BuildContext context, User? user) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (user?.avatarPath != null && user!.avatarPath!.isNotEmpty) {
      final file = File(user.avatarPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 18,
          backgroundImage: FileImage(file),
        );
      }
    }
    
    if (user?.avatarColor != null && user!.avatarColor!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Color(int.parse(user.avatarColor!.substring(1, 7), radix: 16) + 0xFF000000),
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    
    return CircleAvatar(
      radius: 18,
      backgroundColor: colorScheme.primary.withOpacity(0.1),
      child: Icon(
        Icons.account_circle_outlined,
        size: 28,
        color: colorScheme.primary,
      ),
    );
  }
}