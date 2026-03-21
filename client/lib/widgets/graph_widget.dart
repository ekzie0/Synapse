import 'dart:math';
import 'package:flutter/material.dart';
import 'package:synapse/database/models/note_model.dart';

class GraphWidget extends StatefulWidget {
  final List<Note> notes;
  final Map<int, List<int>> links;
  final Function(Note) onNoteTap;

  const GraphWidget({
    super.key,
    required this.notes,
    required this.links,
    required this.onNoteTap,
  });

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Map<int, Offset> _nodePositions = {};
  
  final double _nodeRadius = 8;
  final double _repulsionForce = 800;
  final double _springForce = 0.08;
  final double _damping = 0.92;

  @override
  void initState() {
    super.initState();
    _initNodePositions();
    _simulateLayout();
  }

  void _initNodePositions() {
    final random = Random();
    final centerX = 400.0;
    final centerY = 300.0;
    
    for (var note in widget.notes) {
      _nodePositions[note.id!] = Offset(
        centerX + (random.nextDouble() - 0.5) * 300,
        centerY + (random.nextDouble() - 0.5) * 300,
      );
    }
  }

  void _simulateLayout() {
    final velocities = <int, Offset>{};
    for (var note in widget.notes) {
      velocities[note.id!] = Offset.zero;
    }
    
    for (int iteration = 0; iteration < 80; iteration++) {
      // Отталкивание
      for (var i = 0; i < widget.notes.length; i++) {
        for (var j = i + 1; j < widget.notes.length; j++) {
          final note1 = widget.notes[i];
          final note2 = widget.notes[j];
          final pos1 = _nodePositions[note1.id!]!;
          final pos2 = _nodePositions[note2.id!]!;
          
          final diff = pos1 - pos2;
          final distance = diff.distance;
          if (distance == 0) continue;
          
          final force = _repulsionForce / (distance * distance);
          final direction = diff / distance;
          final forceVector = direction * force;
          
          velocities[note1.id!] = velocities[note1.id!]! + forceVector;
          velocities[note2.id!] = velocities[note2.id!]! - forceVector;
        }
      }
      
      // Притяжение связей
      widget.links.forEach((sourceId, targets) {
        final sourcePos = _nodePositions[sourceId]!;
        for (var targetId in targets) {
          final targetPos = _nodePositions[targetId]!;
          final diff = targetPos - sourcePos;
          final force = diff * _springForce;
          
          velocities[sourceId] = velocities[sourceId]! + force;
          velocities[targetId] = velocities[targetId]! - force;
        }
      });
      
      // Обновление позиций
      for (var note in widget.notes) {
        final id = note.id!;
        final velocity = velocities[id]!;
        velocities[id] = velocity * _damping;
        _nodePositions[id] = _nodePositions[id]! + velocity;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InteractiveViewer(
      minScale: 0.3,
      maxScale: 2.0,
      onInteractionUpdate: (details) {
        setState(() {
          _scale = details.scale;
          _offset = details.focalPoint;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          // Определяем, на какую точку нажали
          final localPos = details.localPosition / _scale - _offset;
          for (var entry in _nodePositions.entries) {
            final pos = entry.value;
            final distance = (pos - localPos).distance;
            if (distance < 15) {
              final note = widget.notes.firstWhere((n) => n.id == entry.key);
              widget.onNoteTap(note);
              break;
            }
          }
        },
        child: CustomPaint(
          size: Size(800, 600),
          painter: GraphPainterWidget(
            notes: widget.notes,
            positions: _nodePositions,
            links: widget.links,
            nodeRadius: _nodeRadius,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

class GraphPainterWidget extends CustomPainter {
  final List<Note> notes;
  final Map<int, Offset> positions;
  final Map<int, List<int>> links;
  final double nodeRadius;
  final ColorScheme colorScheme;

  GraphPainterWidget({
    required this.notes,
    required this.positions,
    required this.links,
    required this.nodeRadius,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем линии
    final linkPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.35)
      ..strokeWidth = 1.2;
    
    for (var entry in links.entries) {
      final sourcePos = positions[entry.key];
      if (sourcePos == null) continue;
      
      for (var targetId in entry.value) {
        final targetPos = positions[targetId];
        if (targetPos == null) continue;
        
        canvas.drawLine(sourcePos, targetPos, linkPaint);
      }
    }
    
    // Рисуем точки
    final nodePaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = colorScheme.surface
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (var note in notes) {
      final pos = positions[note.id!];
      if (pos == null) continue;
      
      canvas.drawCircle(pos, nodeRadius, nodePaint);
      canvas.drawCircle(pos, nodeRadius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}