import time

from backend.app.config.settings import Settings
from backend.app.services.speech_service import SpeechService


def main():

    settings = Settings()

    speech_service = SpeechService(settings)

    try:
        speech_service.start()

        while not speech_service.stop_event.is_set():
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\n사용자가 음성인식을 중단했습니다.")

    except Exception as e:
        print(f"[오류] {e}")

    finally:
        speech_service.stop()


if __name__ == "__main__":
    main()