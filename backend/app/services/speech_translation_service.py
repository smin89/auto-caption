import threading

import azure.cognitiveservices.speech as speechsdk

from backend.app.config.settings import Settings


class SpeechTranslationService:

    def __init__(self, settings: Settings):

        self.settings = settings

        # Azure Speech Translation 설정
        self.translation_config = speechsdk.translation.SpeechTranslationConfig(
            subscription=self.settings.azure_speech_key,
            region=self.settings.azure_speech_region
        )

        # 음성인식 언어: 한국어
        self.translation_config.speech_recognition_language = "ko-KR"

        # 번역 대상 언어: 영어
        self.translation_config.add_target_language("en")

        # MacBook 기본 마이크
        self.audio_config = speechsdk.audio.AudioConfig(
            use_default_microphone=True
        )

        # 음성인식 및 번역 객체 생성
        self.recognizer = speechsdk.translation.TranslationRecognizer(
            translation_config=self.translation_config,
            audio_config=self.audio_config
        )

        self.stop_event = threading.Event()

        self._register_events()

    def _register_events(self):

        self.recognizer.recognizing.connect(self._on_recognizing)
        self.recognizer.recognized.connect(self._on_recognized)
        self.recognizer.canceled.connect(self._on_canceled)
        self.recognizer.session_stopped.connect(self._on_session_stopped)

    def _on_recognizing(self, evt):

        original = evt.result.text
        translated = evt.result.translations.get("en")

        if original:
            print(f"[인식 중] 한국어: {original}")

        if translated:
            print(f"[번역 중] 영어: {translated}")

    def _on_recognized(self, evt):

        if evt.result.reason == speechsdk.ResultReason.TranslatedSpeech:

            original = evt.result.text
            translated = evt.result.translations.get("en")

            print("\n[최종 결과]")
            print(f"한국어: {original}")
            print(f"영어: {translated}")
            print("-" * 50)

        elif evt.result.reason == speechsdk.ResultReason.NoMatch:
            print("[알림] 음성을 인식하지 못했습니다.")

    def _on_canceled(self, evt):

        print(f"[취소] {evt.reason}")

        if evt.reason == speechsdk.CancellationReason.Error:
            print(f"[오류] {evt.error_details}")

        self.stop_event.set()

    def _on_session_stopped(self, evt):

        print("[알림] 음성 번역 세션이 종료되었습니다.")
        self.stop_event.set()

    def start(self):

        self.stop_event.clear()

        print("실시간 음성인식 및 번역을 시작합니다.")
        print("입력 언어: 한국어")
        print("번역 언어: 영어")
        print("종료하려면 Ctrl+C를 누르세요.\n")

        self.recognizer.start_continuous_recognition_async().get()

    def stop(self):

        print("\n음성인식 및 번역을 종료합니다.")

        self.recognizer.stop_continuous_recognition_async().get()