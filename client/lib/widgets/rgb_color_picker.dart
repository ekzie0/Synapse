import 'package:flutter/material.dart';

class RgbColorPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;

  const RgbColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<RgbColorPicker> createState() => _RgbColorPickerState();
}

class _RgbColorPickerState extends State<RgbColorPicker> {
  late double _hue;
  late double _saturation;
  late double _value;
  
  Offset _pickerPosition = Offset.zero;
  
  final double _paletteSize = 200;
  final double _handleSize = 16;
  final double _sliderWidth = 30;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _updatePickerPositionFromSV();
  }

  void _updatePickerPositionFromSV() {
    _pickerPosition = Offset(
      _saturation * _paletteSize,
      (1 - _value) * _paletteSize,
    );
  }

  Color get currentColor => HSVColor.fromAHSV(1, _hue, _saturation, _value).toColor();

  void _updatePickerPosition(Offset position) {
    setState(() {
      final dx = position.dx.clamp(0, _paletteSize).toDouble();
      final dy = position.dy.clamp(0, _paletteSize).toDouble();
      
      _pickerPosition = Offset(dx, dy);
      _saturation = dx / _paletteSize;
      _value = 1 - (dy / _paletteSize);
    });
  }

  void _updateHue(double dy) {
    setState(() {
      final newHue = (dy.clamp(0, _paletteSize) / _paletteSize) * 360;
      _hue = newHue.clamp(0, 360).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Выберите цвет', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: Container(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorPalette(),
                const SizedBox(width: 16),
                _buildHueSlider(),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: currentColor,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onColorSelected(currentColor);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }

  Widget _buildColorPalette() {
    return GestureDetector(
      onPanStart: (details) => _updatePickerPosition(details.localPosition),
      onPanUpdate: (details) => _updatePickerPosition(details.localPosition),
      child: Container(
        width: _paletteSize,
        height: _paletteSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: HSVColor.fromAHSV(1, _hue, 1, 1).toColor(),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Positioned(
              left: _pickerPosition.dx - _handleSize / 2,
              top: _pickerPosition.dy - _handleSize / 2,
              child: Container(
                width: _handleSize,
                height: _handleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHueSlider() {
    return GestureDetector(
      onPanStart: (details) => _updateHue(details.localPosition.dy),
      onPanUpdate: (details) => _updateHue(details.localPosition.dy),
      child: Container(
        width: _sliderWidth,
        height: _paletteSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF0000), Color(0xFFFF8800), Color(0xFFFFFF00),
              Color(0xFF88FF00), Color(0xFF00FF00), Color(0xFF00FF88),
              Color(0xFF00FFFF), Color(0xFF0088FF), Color(0xFF0000FF),
              Color(0xFF8800FF), Color(0xFFFF00FF), Color(0xFFFF0088),
              Color(0xFFFF0000),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: (_hue / 360) * _paletteSize - 4,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}