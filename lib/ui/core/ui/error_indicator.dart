import 'package:flutter/material.dart';

/// Displays an error message with an optional retry button.
class ErrorIndicator extends StatelessWidget {
  const ErrorIndicator({super.key, required this.title, this.label, this.onPressed});

  final String title;
  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            if (onPressed != null && label != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onPressed, child: Text(label!)),
            ],
          ],
        ),
      ),
    );
  }
}
