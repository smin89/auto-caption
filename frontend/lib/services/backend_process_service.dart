import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class BackendProcessService {
  Process? _process;

  bool _isStarting = false;

  bool get isRunning => _process != null;

  Future<void> start() async {
    if (_process != null || _isStarting) {
      return;
    }

    _isStarting = true;

    try {
      final executablePath = _getExecutablePath();

      final executable = File(executablePath);

      if (!await executable.exists()) {
        throw Exception('Python 백엔드 실행 파일을 찾을 수 없습니다: $executablePath');
      }

      debugPrint('[Backend] 실행 파일: $executablePath');

      _process = await Process.start(
        executablePath,
        [],
        workingDirectory: executable.parent.path,
        mode: ProcessStartMode.normal,
      );

      debugPrint('[Backend] 프로세스 시작 PID: ${_process!.pid}');

      // 표준 출력 로그
      _process!.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('[Backend stdout] $data');
      });

      // 오류 출력 로그
      _process!.stderr.transform(utf8.decoder).listen((data) {
        debugPrint('[Backend stderr] $data');
      });

      // 프로세스 종료 감지
      final process = _process!;

      unawaited(
        process.exitCode.then((exitCode) {
          debugPrint('[Backend] 프로세스 종료: $exitCode');

          if (identical(_process, process)) {
            _process = null;
          }
        }),
      );

      await _waitForHealth();
    } catch (e) {
      debugPrint('[Backend] 실행 실패: $e');

      await stop();

      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  String _getExecutablePath() {
    if (Platform.isMacOS) {
      final executable = File(Platform.resolvedExecutable);

      final macosDirectory = executable.parent;

      return File(
        '${macosDirectory.parent.path}/Resources/backend/auto-caption-backend',
      ).path;
    }

    if (Platform.isWindows) {
      final executable = File(Platform.resolvedExecutable);

      return File(
        '${executable.parent.path}\\backend\\auto-caption-backend.exe',
      ).path;
    }

    throw UnsupportedError('지원하지 않는 운영체제입니다.');
  }

  Future<void> _waitForHealth() async {
    final client = HttpClient();

    try {
      const maxAttempts = 30;

      for (int i = 0; i < maxAttempts; i++) {
        try {
          final request = await client.getUrl(
            Uri.parse('http://127.0.0.1:8000/health'),
          );

          final response = await request.close();

          await response.drain<void>();

          if (response.statusCode == 200) {
            debugPrint('[Backend] 서버 준비 완료');
            return;
          }
        } catch (_) {
          // 서버 시작 중이므로 재시도
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      throw TimeoutException('Python 백엔드 서버 준비 시간이 초과되었습니다.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> stop() async {
    final process = _process;

    if (process == null) {
      return;
    }

    debugPrint('[Backend] 프로세스 종료 요청');

    process.kill();

    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      debugPrint('[Backend] 프로세스 종료 대기 시간 초과');
    }

    if (identical(_process, process)) {
      _process = null;
    }
  }
}
