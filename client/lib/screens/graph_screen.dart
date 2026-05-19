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
  
  // Для перетаскивания узлов
  int? _draggedNodeId;
  Offset _dragStartPosition = Offset.zero;
  Offset _nodeStartPosition = Offset.zero;
  
  // Для InteractiveViewer
  final TransformationController _transformationController = TransformationController();
  bool _isDraggingNode = false;

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
    
    setState(() {
      _notes = List.from(folderProvider.allNotes);
      _initNodePositions();
      _isLoading = false;
    });
    
    _links = await linkRepo.getGraphData(userId);
    setState(() {});
  }

  void _initNodePositions() {
    if (_notes.isEmpty) return;
    
    final center = Offset(400, 300);
    final radius = 250.0;
    
    for (int i = 0; i < _notes.length; i++) {
      final angle = (2 * pi * i) / _notes.length;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      _nodePositions[_notes[i].id!] = Offset(x, y);
    }
    
    // Разводим узлы
    for (int iter = 0; iter < 20; iter++) {
      bool moved = false;
      for (int i = 0; i < _notes.length; i++) {
        for (int j = i + 1; j < _notes.length; j++) {
          final id1 = _notes[i].id!;
          final id2 = _notes[j].id!;
          final pos1 = _nodePositions[id1]!;
          final pos2 = _nodePositions[id2]!;
          final distance = (pos1 - pos2).distance;
          
          if (distance < 60) {
            final diff = pos1 - pos2;
            final angle = atan2(diff.dy, diff.dx);
            const push = 10.0;
            _nodePositions[id1] = pos1 + Offset(cos(angle) * push, sin(angle) * push);
            _nodePositions[id2] = pos2 - Offset(cos(angle) * push, sin(angle) * push);
            moved = true;
          }
        }
      }
      if (!moved) break;
    }
  }

  void _onNodeTap(int noteId) {
    final note = _notes.firstWhere((n) => n.id == noteId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
                      'Граф связей (колесо - зум, перетащите узел)',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
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
                      transformationController: _transformationController,
                      minScale: 0.3,
                      maxScale: 3.0,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(100),
                      child: GestureDetector(
                        onPanStart: (details) {
                          // Проверяем, попали ли в узел
                          final localPos = details.localPosition;
                          for (var entry in _nodePositions.entries) {
                            final distance = (entry.value - localPos).distance;
                            if (distance < 20) {
                              setState(() {
                                _draggedNodeId = entry.key;
                                _dragStartPosition = localPos;
                                _nodeStartPosition = entry.value;
                                _isDraggingNode = true;
                              });
                              break;
                            }
                          }
                        },
                        onPanUpdate: (details) {
                          if (_isDraggingNode && _draggedNodeId != null) {
                            setState(() {
                              final newPos = _nodeStartPosition + (details.localPosition - _dragStartPosition);
                              _nodePositions[_draggedNodeId!] = newPos;
                            });
                          }
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _isDraggingNode = false;
                            _draggedNodeId = null;
                          });
                        },
                        child: Container(
                          width: 1200,
                          height: 800,
                          child: CustomPaint(
                            painter: GraphPainter(
                              notes: _notes,
                              positions: _nodePositions,
                              links: _links,
                              colorScheme: colorScheme,
                              draggedNodeId: _draggedNodeId,
                              onNodeTap: _onNodeTap,
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
  final Function(int) onNodeTap;

  GraphPainter({
    required this.notes,
    required this.positions,
    required this.links,
    required this.colorScheme,
    this.draggedNodeId,
    required this.onNodeTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;
    
    // Рисуем связи
    final linkPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.3)
      ..strokeWidth = 1.5;
    
    for (var entry in links.entries) {
      final source = positions[entry.key];
      if (source == null) continue;
      for (var targetId in entry.value) {
        final target = positions[targetId];
        if (target == null) continue;
        canvas.drawLine(source, target, linkPaint);
      }
    }
    
    // Рисуем узлы
    for (var note in notes) {
      final pos = positions[note.id!];
      if (pos == null) continue;
      
      final isDragged = draggedNodeId == note.id;
      final radius = isDragged ? 14.0 : 10.0;
      
      // Тень для перетаскиваемого
      if (isDragged) {
        final shadowPaint = Paint()
          ..color = colorScheme.primary.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(pos, radius + 2, shadowPaint);
      }
      
      // Основной круг
      final nodePaint = Paint()
        ..color = isDragged ? colorScheme.primary : colorScheme.primary.withOpacity(0.8);
      canvas.drawCircle(pos, radius, nodePaint);
      
      // Обводка
      final borderPaint = Paint()
        ..color = colorScheme.surface
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, radius, borderPaint);
      
      // Текст
      final textStyle = TextStyle(
        color: colorScheme.onSurface,
        fontSize: isDragged ? 12 : 10,
        fontWeight: isDragged ? FontWeight.w600 : FontWeight.normal,
      );
      
      final displayText = note.title.length > 15 ? '${note.title.substring(0, 12)}...' : note.title;
      final textSpan = TextSpan(text: displayText, style: textStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + radius + 4));
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.draggedNodeId != draggedNodeId || 
           oldDelegate.positions != positions;
  }
}