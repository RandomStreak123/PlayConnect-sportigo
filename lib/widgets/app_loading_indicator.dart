import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}
