import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../models/speech_message.dart';
import '../services/websocket_service.dart';
import '../widgets/control_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // =========================================================
  // Services / Controllers
  // =========================================================

  final WebSocketService _webSocketService = WebSocketService();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<SpeechMessage>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // =========================================================
  // State
  // =========================================================

  bool _isConnected = false;
  bool _isRecognizing = false;
  bool _isProcessing = false;
  bool _isMouseHovering = false;

  String _statusMessage = '서버에 연결되지 않았습니다.';

  // 자막 글자 크기
  int _captionFontSize = 18;

  // 표시할 자막 메시지 개수 (1~10)
  int _captionCount = 2;

  // 배경 불투명도 25% 고정
  static const double _backgroundOpacity = 0.25;

  // 실시간 중간 자막
  String _interimOriginal = '';
  String _interimTranslated = '';

  // 확정 자막
  final List<SpeechMessage> _finalResults = [];

  // =========================================================
  // Lifecycle
  // =========================================================

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
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

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();

    _scrollController.dispose();

    unawaited(_webSocketService.dispose());

    super.dispose();
  }

  // =========================================================
  // WebSocket Events
  // =========================================================

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
          final original = message.originalText?.trim() ?? '';

          if (original.isEmpty) {
            break;
          }

          _finalResults.add(message);

          // 설정한 자막 개수만큼 유지
          while (_finalResults.length > _captionCount) {
            _finalResults.removeAt(0);
          }

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

  // =========================================================
  // WebSocket Connection
  // =========================================================

  Future<void> _connect() async {
    if (_isConnected || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '서버 연결 중...';
    });

    try {
      await _webSocketService.connect();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('[WebSocket] 연결 실패: $e');

      if (!mounted) return;

      setState(() {
        _isConnected = false;
        _isRecognizing = false;
        _isProcessing = false;
        _statusMessage = '서버에 연결할 수 없습니다.';
      });
    }
  }

  // =========================================================
  // Speech Control
  // =========================================================

  void _startSpeech() {
    if (!_isConnected || _isRecognizing || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '음성인식 시작 요청 중...';
    });

    try {
      _webSocketService.startSpeech();
    } catch (e) {
      debugPrint('[Speech] 시작 실패: $e');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusMessage = '음성인식을 시작할 수 없습니다.';
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
      debugPrint('[Speech] 종료 실패: $e');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusMessage = '음성인식을 종료할 수 없습니다.';
      });
    }
  }

  // =========================================================
  // Caption Control
  // =========================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _changeCaptionCount(int count) {
    setState(() {
      _captionCount = count;

      // 선택한 개수를 초과하는 오래된 자막 제거
      while (_finalResults.length > _captionCount) {
        _finalResults.removeAt(0);
      }
    });

    _scrollToBottom();
  }

  // =========================================================
  // Window Control
  // =========================================================

  Future<void> _closeApp() async {
    try {
      await _webSocketService.disconnect();
    } catch (e) {
      debugPrint('[App] WebSocket 종료 오류: $e');
    }

    await windowManager.close();
  }

  // =========================================================
  // Background
  // =========================================================

  Color _getBackgroundColor() {
    return const Color(0xFF121212).withValues(alpha: _backgroundOpacity);
  }

  // =========================================================
  // Caption Widgets
  // =========================================================

  Widget _buildCaptionItem(SpeechMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.originalText ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: _captionFontSize.toDouble(),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message.translatedText ?? '',
            style: TextStyle(
              color: Colors.white70,
              fontSize: (_captionFontSize - 2).toDouble(),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _interimOriginal,
            style: TextStyle(
              color: Colors.white70,
              fontSize: _captionFontSize.toDouble(),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _interimTranslated,
            style: TextStyle(
              color: Colors.white60,
              fontSize: (_captionFontSize - 2).toDouble(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionArea() {
    final hasInterim = _interimOriginal.trim().isNotEmpty;

    // 중간 자막도 표시 개수에 포함
    final visibleFinalCount = hasInterim
        ? (_captionCount - 1).clamp(0, 10)
        : _captionCount;

    final List<SpeechMessage> visibleFinalResults;

    if (visibleFinalCount == 0) {
      visibleFinalResults = [];
    } else if (_finalResults.length > visibleFinalCount) {
      visibleFinalResults = _finalResults.sublist(
        _finalResults.length - visibleFinalCount,
      );
    } else {
      visibleFinalResults = _finalResults;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 32).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...visibleFinalResults.map(_buildCaptionItem),

                  if (hasInterim) _buildInterimCaption(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // Control Bar
  // =========================================================

  Widget _buildControlBar() {
    return ControlBar(
      isConnected: _isConnected,
      isRecognizing: _isRecognizing,
      isProcessing: _isProcessing,
      statusMessage: _statusMessage,

      captionFontSize: _captionFontSize,
      captionCount: _captionCount,

      onConnect: _connect,
      onStartSpeech: _startSpeech,
      onStopSpeech: _stopSpeech,

      onFontSizeChanged: (value) {
        setState(() {
          _captionFontSize = value;
        });

        _scrollToBottom();
      },

      onCaptionCountChanged: _changeCaptionCount,

      onClose: _closeApp,
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final showControlBar = !_isRecognizing || _isMouseHovering;

    return MouseRegion(
      onEnter: (_) {
        if (!_isMouseHovering) {
          setState(() {
            _isMouseHovering = true;
          });
        }
      },
      onExit: (_) {
        if (_isMouseHovering) {
          setState(() {
            _isMouseHovering = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. 배경 투명도
            Positioned.fill(child: ColoredBox(color: _getBackgroundColor())),

            // 2. 자막 영역 - 창 전체 사용
            Positioned.fill(child: _buildCaptionArea()),

            // 3. ControlBar - 상단 오버레이
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: showControlBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !showControlBar,
                  child: DragToMoveArea(child: _buildControlBar()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
