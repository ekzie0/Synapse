import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoColor = color ?? theme.colorScheme.primary;

    return SvgPicture.asset(
      'assets/images/synapse_logo_without_text_white.svg',
      height: size,
      width: size,
      colorFilter: ColorFilter.mode(
        logoColor,
        BlendMode.srcIn,
      ),
      placeholderBuilder: (context) => Container(
        color: Colors.grey.withOpacity(0.1),
        child: Icon(
          Icons.bubble_chart,
          color: logoColor,
          size: size * 0.7,
        ),
      ),
    );
  }
}