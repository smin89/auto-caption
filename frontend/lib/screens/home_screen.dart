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
  final ScrollController _scrollController = ScrollController();

  // 자막 글자 크기
  double _captionFontSize = 18.0;

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

  // 자막 최하단 이동
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _handleMessage(SpeechMessage message) {
    if (!mounted) return;

    bool shouldScroll = false;

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
          shouldScroll = true;
          break;

        case 'speech.recognized':
          _finalResults.add(message);

          _interimOriginal = '';
          _interimTranslated = '';

          shouldScroll = true;
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

    if (shouldScroll) {
      _scrollToBottom();
    }
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

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();

    _scrollController.dispose();

    unawaited(_webSocketService.dispose());

    super.dispose();
  }

  Widget _buildStatusIndicator() {
    Color color;

    if (!_isConnected) {
      color = Colors.grey;
    } else if (_isRecognizing) {
      color = Colors.green;
    } else {
      color = Colors.blue;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Text(_statusMessage, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildCaptionItem(SpeechMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 한국어 원문
          Text(
            message.originalText ?? '',
            style: TextStyle(
              fontSize: _captionFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // 영어 번역
          Text(
            message.translatedText ?? '',
            style: TextStyle(
              fontSize: _captionFontSize - 2,
              color: Colors.indigo.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterimCaption() {
    if (_interimOriginal.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 한국어 중간 인식 결과
          Text(
            _interimOriginal,
            style: TextStyle(fontSize: _captionFontSize, color: Colors.black54),
          ),

          const SizedBox(height: 8),

          // 영어 중간 번역 결과
          Text(
            _interimTranslated,
            style: TextStyle(
              fontSize: _captionFontSize - 2,
              color: Colors.indigo.shade400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Auto Caption',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _clearResults,
            tooltip: '자막 초기화',
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 상태 및 제어 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusIndicator(),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isConnected ? null : _connect,
                        icon: const Icon(Icons.link),
                        label: const Text('서버 연결'),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _isConnected && !_isRecognizing && !_isProcessing
                            ? _startSpeech
                            : null,
                        icon: const Icon(Icons.mic),
                        label: const Text('마이크 ON'),
                      ),
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

                  Row(
                    children: [
                      const Icon(Icons.format_size, size: 20),

                      const SizedBox(width: 8),

                      const Text(
                        '자막 크기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: Slider(
                          value: _captionFontSize,
                          min: 14,
                          max: 32,
                          divisions: 18,
                          label: '${_captionFontSize.toInt()}',
                          onChanged: (value) {
                            setState(() {
                              _captionFontSize = value;
                            });

                            _scrollToBottom();
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      SizedBox(
                        width: 48,
                        child: Text(
                          '${_captionFontSize.toInt()}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 자막 영역
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '실시간 자막',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        children: [
                          ..._finalResults.map(_buildCaptionItem),
                          _buildInterimCaption(),
                        ],
                      ),
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
