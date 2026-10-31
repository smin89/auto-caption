import 'package:flutter/material.dart';

import '../models/speech_message.dart';
import 'caption_item.dart';

class CaptionView extends StatefulWidget {
  final List<SpeechMessage> finalResults;
  final String interimOriginal;
  final String interimTranslated;
  final double fontSize;

  const CaptionView({
    super.key,
    required this.finalResults,
    required this.interimOriginal,
    required this.interimTranslated,
    required this.fontSize,
  });

  @override
  State<CaptionView> createState() => _CaptionViewState();
}

class _CaptionViewState extends State<CaptionView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant CaptionView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.finalResults.length != widget.finalResults.length ||
        oldWidget.interimOriginal != widget.interimOriginal ||
        oldWidget.interimTranslated != widget.interimTranslated ||
        oldWidget.fontSize != widget.fontSize) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        ...widget.finalResults.map(
          (message) => CaptionItem(
            originalText: message.originalText ?? '',
            translatedText: message.translatedText ?? '',
            fontSize: widget.fontSize,
          ),
        ),

        if (widget.interimOriginal.isNotEmpty)
          CaptionItem(
            originalText: widget.interimOriginal,
            translatedText: widget.interimTranslated,
            fontSize: widget.fontSize,
            isInterim: true,
          ),
      ],
    );
  }
}
