import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child:Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back),
                    color: colorScheme.primary,
                    splashRadius: 20,
                    highlightColor: colorScheme.primary.withValues(alpha: 0.1),
                    splashColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      'Заметки',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bubble_chart,
                      size: 20,
                      color: colorScheme.primary,
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
}