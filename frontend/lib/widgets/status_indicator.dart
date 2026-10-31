import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  final bool isRecognizing;
  final String message;

  const StatusIndicator({
    super.key,
    required this.isConnected,
    required this.isRecognizing,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;

    if (!isConnected) {
      statusColor = Colors.grey;
    } else if (isRecognizing) {
      statusColor = Colors.greenAccent;
    } else {
      statusColor = Colors.lightBlueAccent;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 9, color: statusColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            message,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
