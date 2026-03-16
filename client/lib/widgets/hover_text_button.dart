import 'package:flutter/material.dart';

class HoverTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const HoverTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  State<HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<HoverTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isHovered ? widget.color : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            widget.text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}