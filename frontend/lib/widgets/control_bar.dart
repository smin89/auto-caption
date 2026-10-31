import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  final bool isConnected;
  final bool isRecognizing;
  final bool isProcessing;

  final String statusMessage;

  final int captionFontSize;
  final int captionCount;

  final VoidCallback onConnect;
  final VoidCallback onStartSpeech;
  final VoidCallback onStopSpeech;

  final VoidCallback onClose;

  final ValueChanged<int> onFontSizeChanged;
  final ValueChanged<int> onCaptionCountChanged;

  const ControlBar({
    super.key,
    required this.isConnected,
    required this.isRecognizing,
    required this.isProcessing,
    required this.statusMessage,
    required this.captionFontSize,
    required this.captionCount,
    required this.onConnect,
    required this.onStartSpeech,
    required this.onStopSpeech,
    required this.onFontSizeChanged,
    required this.onCaptionCountChanged,
    required this.onClose,
  });

  static const List<int> fontSizes = [14, 16, 18, 20, 24, 28, 32];

  static const List<int> captionCounts = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF202124).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 서버 상태 메시지
          Expanded(child: _buildStatus()),

          const SizedBox(width: 12),

          // 제어 버튼 영역
          Flexible(
            flex: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 서버 연결
                  _buildIconButton(
                    icon: Icons.link,
                    tooltip: '서버 연결',
                    onPressed: isConnected || isProcessing ? null : onConnect,
                  ),

                  const SizedBox(width: 8),

                  // 마이크 ON
                  _buildIconButton(
                    icon: Icons.mic,
                    tooltip: '마이크 ON',
                    onPressed: isConnected && !isRecognizing && !isProcessing
                        ? onStartSpeech
                        : null,
                  ),

                  const SizedBox(width: 8),

                  // 마이크 OFF
                  _buildIconButton(
                    icon: Icons.mic_off,
                    tooltip: '마이크 OFF',
                    onPressed: isConnected && isRecognizing && !isProcessing
                        ? onStopSpeech
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // 자막 글자 크기
                  _buildFontSizeDropdown(),

                  const SizedBox(width: 12),

                  // 자막 표시 개수
                  _buildCaptionCountDropdown(),

                  const SizedBox(width: 12),

                  // 앱 종료 버튼
                  _buildIconButton(
                    icon: Icons.close,
                    tooltip: '앱 종료',
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 서버 상태
  Widget _buildStatus() {
    Color statusColor;

    if (!isConnected) {
      statusColor = Colors.grey;
    } else if (isRecognizing) {
      statusColor = Colors.greenAccent;
    } else {
      statusColor = Colors.lightBlueAccent;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: statusColor),

        const SizedBox(width: 8),

        Expanded(
          child: Tooltip(
            message: statusMessage,
            child: Text(
              statusMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // 공통 아이콘 버튼
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      color: Colors.white,
      disabledColor: Colors.white30,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // 자막 글자 크기 선택
  Widget _buildFontSizeDropdown() {
    return SizedBox(
      width: 72,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: captionFontSize,
          isDense: true,
          dropdownColor: const Color(0xFF303030),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: fontSizes.map((size) {
            return DropdownMenuItem<int>(value: size, child: Text('$size'));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onFontSizeChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCaptionCountDropdown() {
    return Tooltip(
      message: '자막 표시 개수',
      child: SizedBox(
        width: 75,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: captionCount,
            isDense: true,
            dropdownColor: const Color(0xFF303030),
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: captionCounts.map((count) {
              return DropdownMenuItem<int>(
                value: count,
                child: Text('$count개'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onCaptionCountChanged(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
