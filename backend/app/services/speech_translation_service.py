import threading
from typing import Callable, Optional

import azure.cognitiveservices.speech as speechsdk

from backend.app.config.settings import Settings


class SpeechTranslationService:

    def __init__(
        self,
        settings: Settings,
        on_result: Optional[Callable[[dict], None]] = None
    ):
        self.settings = settings
        self.on_result = on_result

        self.translation_config = speechsdk.translation.SpeechTranslationConfig(
            subscription=self.settings.azure_speech_key,
            region=self.settings.azure_speech_region
        )

        self.translation_config.speech_recognition_language = "ko-KR"
        self.translation_config.add_target_language("en")

        self.audio_config = speechsdk.audio.AudioConfig(
            use_default_microphone=True
        )

        self.recognizer = speechsdk.translation.TranslationRecognizer(
            translation_config=self.translation_config,
            audio_config=self.audio_config
        )

        self.stop_event = threading.Event()
        self.is_running = False

        self._register_events()

    def _register_events(self):
        self.recognizer.recognizing.connect(self._on_recognizing)
        self.recognizer.recognized.connect(self._on_recognized)
        self.recognizer.canceled.connect(self._on_canceled)
        self.recognizer.session_stopped.connect(self._on_session_stopped)

    def _emit(self, data: dict):
        if self.on_result:
            self.on_result(data)

    def _on_recognizing(self, evt):
        original = (evt.result.text or "").strip()
        translated = (evt.result.translations.get("en") or "").strip()

        # 음성인식 결과가 없으면 전송하지 않음
        if not original:
            return

        data = {
            "type": "speech.recognizing",
            "originalText": original,
            "translatedText": translated,
            "isFinal": False
        }

        self._emit(data)

        if not self.on_result:
            print(f"[인식 중] 한국어: {original}")

            if translated:
                print(f"[번역 중] 영어: {translated}")

    def _on_recognized(self, evt):
        if evt.result.reason == speechsdk.ResultReason.TranslatedSpeech:
            original = evt.result.text
            translated = evt.result.translations.get("en")

            data = {
                "type": "speech.recognized",
                "originalText": original,
                "translatedText": translated or "",
                "isFinal": True
            }

            self._emit(data)

            if not self.on_result:
                print("\n[최종 결과]")
                print(f"한국어: {original}")
                print(f"영어: {translated}")
                print("-" * 50)

    def _on_canceled(self, evt):
        error_message = evt.error_details or str(evt.reason)

        self._emit({
            "type": "speech.error",
            "message": error_message
        })

        if not self.on_result:
            print(f"[오류] {error_message}")

        self.stop_event.set()

    def _on_session_stopped(self, evt):
        self.stop_event.set()

        self._emit({
            "type": "speech.session_stopped",
            "message": "음성 번역 세션이 종료되었습니다."
        })

        if not self.on_result:
            print("[알림] 음성 번역 세션이 종료되었습니다.")

    def start(self):
        if self.is_running:
            return

        self.stop_event.clear()

        self.recognizer.start_continuous_recognition_async().get()

        self.is_running = True

        if not self.on_result:
            print("실시간 음성인식 및 번역을 시작합니다.")
            print("종료하려면 Ctrl+C를 누르세요.")

    def stop(self):
        if not self.is_running:
            return

        self.recognizer.stop_continuous_recognition_async().get()

        self.is_running = False
        self.stop_event.set()

        if not self.on_result:
            print("\n음성인식 및 번역을 종료합니다.")