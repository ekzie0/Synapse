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
  final LinkRepository _linkRepo = LinkRepository();
  Map<int, List<int>> _graphData = {};
  List<Note> _allNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGraphData();
  }

  Future<void> _loadGraphData() async {
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    final userId = authProvider.currentUser!.id!;
    
    // Собираем все заметки (корневые + текущие)
    final allNotes = <Note>[];
    allNotes.addAll(folderProvider.rootNotes);
    allNotes.addAll(folderProvider.currentNotes);
    
    // Убираем дубликаты по id
    final uniqueNotes = <int, Note>{};
    for (var note in allNotes) {
      uniqueNotes[note.id!] = note;
    }
    
    setState(() {
      _allNotes = uniqueNotes.values.toList();
    });
    
    _graphData = await _linkRepo.getGraphData(userId);
    
    setState(() {
      _isLoading = false;
    });
  }

  void _openNote(Note note) {
    Navigator.pop(context);
    // TODO: открыть заметку в редакторе
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
                      'Граф связей',
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bubble_chart_outlined,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет заметок для отображения',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Создайте заметки и ссылки [[...]] между ними',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildGraphWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphWidget() {
    return InteractiveViewer(
      minScale: 0.3,
      maxScale: 2.0,
      boundaryMargin: const EdgeInsets.all(50),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: GraphPainter(
            notes: _allNotes,
            links: _graphData,
            colorScheme: Theme.of(context).colorScheme,
            onNoteTap: _openNote,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<Note> notes;
  final Map<int, List<int>> links;
  final ColorScheme colorScheme;
  final Function(Note) onNoteTap;
  
  // Кэш для позиций узлов
  Map<int, Offset> _positions = {};
  Size _lastSize = Size.zero;
  
  GraphPainter({
    required this.notes,
    required this.links,
    required this.colorScheme,
    required this.onNoteTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastSize != size) {
      _lastSize = size;
      _calculatePositions(size);
    }
    
    // Рисуем связи (линии)
    final linkPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (var entry in links.entries) {
      final sourcePos = _positions[entry.key];
      if (sourcePos == null) continue;
      
      for (var targetId in entry.value) {
        final targetPos = _positions[targetId];
        if (targetPos == null) continue;
        
        canvas.drawLine(sourcePos, targetPos, linkPaint);
      }
    }
    
    // Рисуем узлы (точки)
    final nodePaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = colorScheme.surface
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (var note in notes) {
      final pos = _positions[note.id!];
      if (pos == null) continue;
      
      // Точка
      canvas.drawCircle(pos, 8, nodePaint);
      canvas.drawCircle(pos, 8, borderPaint);
      
      // Название заметки
      final textSpan = TextSpan(
        text: note.title.length > 20 ? '${note.title.substring(0, 17)}...' : note.title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPaint.text = textSpan;
      textPaint.layout();
      textPaint.paint(
        canvas,
        Offset(pos.dx - textPaint.width / 2, pos.dy + 12),
      );
    }
  }
  
  void _calculatePositions(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = (size.width < size.height ? size.width : size.height) * 0.35;
    
    // Если мало заметок – круг
    if (notes.length <= 20) {
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        final angle = (2 * pi * i) / notes.length;
        final x = centerX + radius * cos(angle);
        final y = centerY + radius * sin(angle);
        _positions[note.id!] = Offset(x, y);
      }
    } else {
      // Сетка для большого количества
      final cols = (notes.length / 5).ceil();
      final spacing = size.width / (cols + 1);
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        final row = i ~/ cols;
        final col = i % cols;
        final x = spacing * (col + 1);
        final y = 50.0 + row * 70;
        _positions[note.id!] = Offset(x, y);
      }
    }
    
    // Сдвигаем связанные заметки ближе
    for (int iteration = 0; iteration < 30; iteration++) {
      for (var entry in links.entries) {
        final sourcePos = _positions[entry.key];
        if (sourcePos == null) continue;
        
        for (var targetId in entry.value) {
          final targetPos = _positions[targetId];
          if (targetPos == null) continue;
          
          final diff = targetPos - sourcePos;
          final distance = diff.distance;
          if (distance > 80) {
            final force = diff * 0.05;
            _positions[entry.key] = sourcePos + force;
            _positions[targetId] = targetPos - force;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}