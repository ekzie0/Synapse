import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/database/repositories/link_repository.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:synapse/widgets/avatar_popup_menu.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<Note> _notes = [];
  Map<int, List<int>> _links = {};
  Map<int, Offset> _nodePositions = {};
  bool _isLoading = true;
  
  int? _draggedNodeId;
  Offset _dragStartPosition = Offset.zero;
  Offset _nodeStartPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final linkRepo = LinkRepository();
    final userId = authProvider.currentUser!.id!;
    
    await folderProvider.loadAllData(userId);
    _links = await linkRepo.getGraphData(userId);
    
    setState(() {
      _notes = List.from(folderProvider.allNotes);
      _initNodePositions();
      _isLoading = false;
    });
  }

  void _initNodePositions() {
    if (_notes.isEmpty) return;
    final center = const Offset(500, 500); 
    final radius = _notes.length > 5 ? 220.0 : 130.0;
    
    for (int i = 0; i < _notes.length; i++) {
      final angle = (2 * pi * i) / _notes.length;
      _nodePositions[_notes[i].id!] = center + Offset(cos(angle) * radius, sin(angle) * radius);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Адаптивная шапка без лишних кнопок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: colorScheme.primary,
                  ),
                  Expanded(
                    child: Text(
                      isMobile ? 'Граф связей (щипок - зум)' : 'Граф связей',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ),
                  const AvatarPopupMenu(),
                ],
              ),
            ),
            Expanded(
              child: _isLoading || _notes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : InteractiveViewer(
                      minScale: 0.1, // Огромный масштаб отдаления
                      maxScale: 3.0,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(500),
                      // Блокируем скролл карты только в момент перетаскивания узла
                      panEnabled: _draggedNodeId == null, 
                      scaleEnabled: true,
                      child: Listener( // Listener вместо GestureDetector исправляет синтаксис и жесты
                        onPointerDown: (details) {
                          final localPos = details.localPosition;
                          for (var entry in _nodePositions.entries) {
                            final distance = (entry.value - localPos).distance;
                            // Увеличенный хитбокс для мобильного пальца
                            if (distance < (isMobile ? 35 : 25)) {
                              setState(() {
                                _draggedNodeId = entry.key;
                                _dragStartPosition = localPos;
                                _nodeStartPosition = entry.value;
                              });
                              break;
                            }
                          }
                        },
                        onPointerMove: (details) {
                          if (_draggedNodeId != null) {
                            setState(() {
                              _nodePositions[_draggedNodeId!] = _nodeStartPosition + (details.localPosition - _dragStartPosition);
                            });
                          }
                        },
                        onPointerUp: (_) {
                          if (_draggedNodeId != null) {
                            setState(() {
                              _draggedNodeId = null;
                            });
                          }
                        },
                        child: Container(
                          width: 1000,
                          height: 1000,
                          color: Colors.transparent, // Позволяет ловить касания в пустых местах
                          child: RepaintBoundary( // Изолирует отрисовку холста, поднимая FPS до 60+
                            child: CustomPaint(
                              painter: GraphPainter(
                                notes: _notes,
                                positions: _nodePositions,
                                links: _links,
                                colorScheme: colorScheme,
                                draggedNodeId: _draggedNodeId,
                                isMobile: isMobile,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<Note> notes;
  final Map<int, Offset> positions;
  final Map<int, List<int>> links;
  final ColorScheme colorScheme;
  final int? draggedNodeId;
  final bool isMobile;

  GraphPainter({
    required this.notes,
    required this.positions,
    required this.links,
    required this.colorScheme,
    this.draggedNodeId,
    required this.isMobile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;
    
    // 1. Рисуем линии связей
    final linkPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.25)
      ..strokeWidth = isMobile ? 1.0 : 1.5;
    
    for (var entry in links.entries) {
      final source = positions[entry.key];
      if (source == null) continue;
      for (var targetId in entry.value) {
        final target = positions[targetId];
        if (target == null) continue;
        canvas.drawLine(source, target, linkPaint);
      }
    }
    
    // 2. Рисуем светящиеся точки (узлы) и подписи к ним
    for (var note in notes) {
      final pos = positions[note.id!];
      if (pos == null) continue;
      
      final isDragged = draggedNodeId == note.id;
      final radius = isDragged ? 15.0 : (isMobile ? 11.0 : 9.0);
      
      // Эффект тени при удержании пальцем/мышкой
      if (isDragged) {
        final shadowPaint = Paint()
          ..color = colorScheme.primary.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(pos, radius + 2, shadowPaint);
      }
      
      final nodePaint = Paint()
        ..color = isDragged ? colorScheme.primary : colorScheme.primary.withOpacity(0.8);
      canvas.drawCircle(pos, radius, nodePaint);
      
      final borderPaint = Paint()
        ..color = colorScheme.surface
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, radius, borderPaint);
      
      // Настройка и отрисовка текста
      final textStyle = TextStyle(
        color: colorScheme.onSurface.withOpacity(0.85),
        fontSize: isMobile ? 9 : 10,
        fontWeight: isDragged ? FontWeight.bold : FontWeight.normal,
      );
      
      final maxChars = isMobile ? 10 : 14;
      final displayText = note.title.length > maxChars 
          ? '${note.title.substring(0, maxChars - 3)}...' 
          : note.title;
          
      final textSpan = TextSpan(text: displayText, style: textStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + radius + 4));
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    // Разрешаем перерисовку холста, так как RepaintBoundary и так контролирует этот процесс
    return true; 
  }
}