import 'dart:async';

import 'package:flutter/material.dart';

import '../models/speech_message.dart';
import '../services/websocket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebSocketService _webSocketService = WebSocketService();

  StreamSubscription<SpeechMessage>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  bool _isConnected = false;
  String _statusMessage = '연결되지 않음';

  @override
  void initState() {
    super.initState();

    _messageSubscription = _webSocketService.messages.listen((message) {
      if (!mounted) return;

      setState(() {
        _statusMessage = '${message.type}: ${message.message ?? ''}';
      });
    });

    _connectionSubscription = _webSocketService.connectionStates.listen((
      connected,
    ) {
      if (!mounted) return;

      setState(() {
        _isConnected = connected;
      });
    });
  }

  Future<void> _connect() async {
    try {
      await _webSocketService.connect();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = '연결 실패: $e';
      });
    }
  }

  void _ping() {
    try {
      _webSocketService.ping();
    } catch (e) {
      setState(() {
        _statusMessage = '전송 실패: $e';
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();

    unawaited(_webSocketService.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Caption')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isConnected ? 'WebSocket 연결됨' : 'WebSocket 연결 안 됨',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isConnected ? null : _connect,
              child: const Text('서버 연결'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isConnected ? _ping : null,
              child: const Text('Ping 전송'),
            ),
          ],
        ),
      ),
    );
  }
}
