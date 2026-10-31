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
  bool _isRecognizing = false;
  bool _isProcessing = false;

  String _statusMessage = '서버에 연결되지 않았습니다.';

  String _interimOriginal = '';
  String _interimTranslated = '';

  final List<SpeechMessage> _finalResults = [];

  @override
  void initState() {
    super.initState();

    _messageSubscription = _webSocketService.messages.listen(_handleMessage);

    _connectionSubscription = _webSocketService.connectionStates.listen((
      connected,
    ) {
      if (!mounted) return;

      setState(() {
        _isConnected = connected;

        if (!connected) {
          _isRecognizing = false;
          _isProcessing = false;
          _statusMessage = '서버 연결이 종료되었습니다.';
        }
      });
    });
  }

  void _handleMessage(SpeechMessage message) {
    if (!mounted) return;

    setState(() {
      switch (message.type) {
        case 'connection.established':
          _statusMessage = '서버 연결 완료';
          break;

        case 'pong':
          _statusMessage = '서버가 정상적으로 동작하고 있습니다.';
          break;

        case 'speech.started':
          _isRecognizing = true;
          _isProcessing = false;
          _statusMessage = '음성인식 및 번역 중';
          break;

        case 'speech.recognizing':
          _interimOriginal = message.originalText ?? '';
          _interimTranslated = message.translatedText ?? '';
          break;

        case 'speech.recognized':
          _finalResults.add(message);

          _interimOriginal = '';
          _interimTranslated = '';
          break;

        case 'speech.stopped':
        case 'speech.session_stopped':
          _isRecognizing = false;
          _isProcessing = false;
          _statusMessage = '음성인식 종료';
          break;

        case 'speech.error':
        case 'error':
          _isRecognizing = false;
          _isProcessing = false;
          _statusMessage = message.message ?? '오류가 발생했습니다.';
          break;

        default:
          break;
      }
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

  void _startSpeech() {
    if (!_isConnected || _isRecognizing || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '음성인식 시작 요청 중...';
    });

    try {
      _webSocketService.startSpeech();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '시작 실패: $e';
      });
    }
  }

  void _stopSpeech() {
    if (!_isConnected || !_isRecognizing || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '음성인식 종료 요청 중...';
    });

    try {
      _webSocketService.stopSpeech();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '종료 실패: $e';
      });
    }
  }

  void _clearResults() {
    setState(() {
      _finalResults.clear();
      _interimOriginal = '';
      _interimTranslated = '';
    });
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
      appBar: AppBar(
        title: const Text('Auto Caption'),
        actions: [
          IconButton(
            onPressed: _clearResults,
            tooltip: '자막 초기화',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 연결 상태
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.circle : Icons.circle_outlined,
                  color: _isConnected ? Colors.green : Colors.grey,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(_statusMessage),
              ],
            ),

            const SizedBox(height: 24),

            // 제어 버튼
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isConnected ? null : _connect,
                  icon: const Icon(Icons.link),
                  label: const Text('서버 연결'),
                ),

                const SizedBox(width: 12),

                ElevatedButton.icon(
                  onPressed: _isConnected && !_isRecognizing && !_isProcessing
                      ? _startSpeech
                      : null,
                  icon: const Icon(Icons.mic),
                  label: const Text('마이크 ON'),
                ),

                const SizedBox(width: 12),

                ElevatedButton.icon(
                  onPressed: _isRecognizing && !_isProcessing
                      ? _stopSpeech
                      : null,
                  icon: const Icon(Icons.mic_off),
                  label: const Text('마이크 OFF'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 실시간 자막 영역
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView(
                  children: [
                    const Text(
                      '실시간 자막',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 최종 확정 자막
                    ..._finalResults.map(
                      (result) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.originalText ?? '',
                              style: const TextStyle(fontSize: 18),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              result.translatedText ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 인식 중간 결과
                    if (_interimOriginal.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _interimOriginal,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            _interimTranslated,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
