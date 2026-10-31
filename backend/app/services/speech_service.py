import threading

import azure.cognitiveservices.speech as speechsdk

from backend.app.config.settings import Settings


class SpeechService:

    def __init__(self, settings: Settings):

        self.settings = settings

        # Azure Speech 설정
        self.speech_config = speechsdk.SpeechConfig(
            subscription=self.settings.azure_speech_key,
            region=self.settings.azure_speech_region
        )

        # 음성인식 언어
        self.speech_config.speech_recognition_language = "ko-KR"

        # 기본 마이크 사용
        self.audio_config = speechsdk.audio.AudioConfig(
            use_default_microphone=True
        )

        # 음성인식 객체 생성
        self.recognizer = speechsdk.SpeechRecognizer(
            speech_config=self.speech_config,
            audio_config=self.audio_config
        )

        # 인식 종료 및 오류 발생 여부
        self.stop_event = threading.Event()

        # 이벤트 등록
        self._register_events()

    def _register_events(self):

        self.recognizer.recognizing.connect(self._on_recognizing)
        self.recognizer.recognized.connect(self._on_recognized)
        self.recognizer.canceled.connect(self._on_canceled)
        self.recognizer.session_stopped.connect(self._on_session_stopped)

    def _on_recognizing(self, evt):

        if evt.result.text:
            print(f"[인식 중] {evt.result.text}")

    def _on_recognized(self, evt):

        if evt.result.reason == speechsdk.ResultReason.RecognizedSpeech:
            print(f"[인식 완료] {evt.result.text}")

        elif evt.result.reason == speechsdk.ResultReason.NoMatch:
            print("[알림] 음성을 인식하지 못했습니다.")

    def _on_canceled(self, evt):

        print(f"[취소] {evt.reason}")

        if evt.reason == speechsdk.CancellationReason.Error:
            print(f"[오류] {evt.error_details}")

        self.stop_event.set()

    def _on_session_stopped(self, evt):

        print("[알림] 음성인식 세션이 종료되었습니다.")
        self.stop_event.set()

    def start(self):

        print("실시간 음성인식을 시작합니다.")
        print("종료하려면 Ctrl+C를 누르세요.")

        self.stop_event.clear()

        # Azure Speech 연속 음성인식 시작
        self.recognizer.start_continuous_recognition_async().get()

    def stop(self):

        print("\n음성인식을 종료합니다.")

        # Azure Speech 연속 음성인식 종료
        self.recognizer.stop_continuous_recognition_async().get()