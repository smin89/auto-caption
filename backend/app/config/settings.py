import os

from pathlib import Path
from dotenv import load_dotenv


class Settings:

    def __init__(self):
        # backend 디렉터리 경로
        base_dir = Path(__file__).resolve().parents[2]

        # .env 파일 로드
        load_dotenv(dotenv_path=base_dir / ".env")

        # Azure Speech 설정
        self.azure_speech_key = os.getenv("AZURE_SPEECH_KEY")
        self.azure_speech_region = os.getenv("AZURE_SPEECH_REGION")

        # 필수 환경변수 검증
        if not self.azure_speech_key:
            raise ValueError("AZURE_SPEECH_KEY가 설정되지 않았습니다.")

        if not self.azure_speech_region:
            raise ValueError("AZURE_SPEECH_REGION이 설정되지 않았습니다.")