import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/speech_message.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final StreamController<SpeechMessage> _messageController =
      StreamController<SpeechMessage>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<SpeechMessage> get messages => _messageController.stream;

  Stream<bool> get connectionStates => _connectionController.stream;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) {
      return;
    }

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:8000/ws/speech'),
      );

      // WebSocket 연결 완료 대기
      await channel.ready;

      _channel = channel;
      _isConnected = true;

      _connectionController.add(true);

      _subscription = channel.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);

            final message = SpeechMessage.fromJson(
              Map<String, dynamic>.from(json as Map),
            );

            _messageController.add(message);
          } catch (e) {
            _messageController.add(
              SpeechMessage(type: 'error', message: '메시지 처리 오류: $e'),
            );
          }
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );
    } catch (e) {
      _handleDisconnect();
      rethrow;
    }
  }

  void send(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      throw StateError('WebSocket이 연결되지 않았습니다.');
    }

    _channel!.sink.add(jsonEncode(message));
  }

  void ping() {
    send({'type': 'ping'});
  }

  void startSpeech() {
    send({'type': 'speech.start'});
  }

  void stopSpeech() {
    send({'type': 'speech.stop'});
  }

  void _handleDisconnect() {
    if (!_isConnected) {
      return;
    }

    _isConnected = false;
    _channel = null;

    _connectionController.add(false);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();

    _handleDisconnect();
  }

  Future<void> dispose() async {
    await disconnect();

    await _messageController.close();
    await _connectionController.close();
  }
}
