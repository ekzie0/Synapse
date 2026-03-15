import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AvatarPopupMenu extends StatelessWidget {
  final User user;

  const AvatarPopupMenu({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: user.isGuest 
              ? Colors.grey[800] 
              : colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: user.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    user.avatarUrl!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                )
              : Text(
                  user.name?[0].toUpperCase() ?? 
                  (user.isGuest ? '👤' : user.email[0].toUpperCase()),
                  style: TextStyle(
                    color: user.isGuest ? Colors.grey[400] : colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            // TODO: открыть профиль
            break;
          case 'settings':
            // TODO: открыть настройки
            break;
          case 'logout':
            await authService.logout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                user.isGuest ? 'Гость' : 'Профиль',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                'Настройки',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                size: 20,
                color: Colors.red[400],
              ),
              const SizedBox(width: 12),
              Text(
                'Выйти',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}