import 'package:flutter/material.dart';

class CaptionItem extends StatelessWidget {
  final String originalText;
  final String translatedText;
  final double fontSize;
  final bool isInterim;

  const CaptionItem({
    super.key,
    required this.originalText,
    required this.translatedText,
    required this.fontSize,
    this.isInterim = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            originalText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: isInterim ? 0.7 : 1.0),
            ),
          ),

          const SizedBox(height: 6),

          if (translatedText.isNotEmpty)
            Text(
              translatedText,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white.withValues(alpha: isInterim ? 0.6 : 0.9),
              ),
            ),
        ],
      ),
    );
  }
}
