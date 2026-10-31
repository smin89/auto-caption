class SpeechMessage {
  final String type;
  final String? message;
  final String? originalText;
  final String? translatedText;
  final bool? isFinal;

  SpeechMessage({
    required this.type,
    this.message,
    this.originalText,
    this.translatedText,
    this.isFinal,
  });

  factory SpeechMessage.fromJson(Map<String, dynamic> json) {
    return SpeechMessage(
      type: json['type'] as String? ?? '',
      message: json['message'] as String?,
      originalText: json['originalText'] as String?,
      translatedText: json['translatedText'] as String?,
      isFinal: json['isFinal'] as bool?,
    );
  }
}
