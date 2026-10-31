import os
import time

import azure.cognitiveservices.speech as speechsdk

from dotenv import load_dotenv


# 환경변수 로드
load_dotenv()

speech_key = os.getenv("AZURE_SPEECH_KEY")
speech_region = os.getenv("AZURE_SPEECH_REGION")

if not speech_key or not speech_region:
    raise ValueError("Azure Speech API 설정을 확인하세요.")


# Azure Speech 설정
speech_config = speechsdk.SpeechConfig(
    subscription=speech_key,
    region=speech_region
)

# 한국어 음성인식
speech_config.speech_recognition_language = "ko-KR"

# MacBook 기본 마이크 사용
audio_config = speechsdk.audio.AudioConfig(
    use_default_microphone=True
)

# 음성인식 객체 생성
recognizer = speechsdk.SpeechRecognizer(
    speech_config=speech_config,
    audio_config=audio_config
)


# 음성인식 중간 결과
def recognizing(evt):
    print(f"[인식 중] {evt.result.text}")


# 음성인식 완료 결과
def recognized(evt):
    if evt.result.reason == speechsdk.ResultReason.RecognizedSpeech:
        print(f"[인식 완료] {evt.result.text}")


# 음성인식 취소 및 오류
def canceled(evt):
    print(f"[오류] {evt.reason}")
    print(f"[상세] {evt.error_details}")


# 이벤트 연결
recognizer.recognizing.connect(recognizing)
recognizer.recognized.connect(recognized)
recognizer.canceled.connect(canceled)


# 실시간 음성인식 시작
print("실시간 음성인식을 시작합니다.")
print("종료하려면 Ctrl+C를 누르세요.")

recognizer.start_continuous_recognition()

try:
    while True:
        time.sleep(0.5)

except KeyboardInterrupt:
    print("\n음성인식을 종료합니다.")

finally:
    recognizer.stop_continuous_recognition()