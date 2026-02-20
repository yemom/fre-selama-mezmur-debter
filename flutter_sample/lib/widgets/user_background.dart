import 'package:flutter/material.dart';
import '../theme/theme.dart';

class UserBackground extends StatelessWidget {
  final Widget child;

  const UserBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transparentTheme = theme.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
    );

    return Theme(
      data: transparentTheme,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppTheme.backgroundColor),
          const Positioned.fill(
            child: Image(
              image: AssetImage('photo_2024-09-27_00-18-20.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
