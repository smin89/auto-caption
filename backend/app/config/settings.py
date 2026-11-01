import os
import sys
from pathlib import Path

from dotenv import load_dotenv


class Settings:

    def __init__(self):
        env_path = self._get_env_path()

        load_dotenv(
            dotenv_path=env_path,
            override=False,
        )

        self.azure_speech_key = os.getenv("AZURE_SPEECH_KEY")
        self.azure_speech_region = os.getenv("AZURE_SPEECH_REGION")

        if not self.azure_speech_key:
            raise ValueError("AZURE_SPEECH_KEY가 설정되지 않았습니다.")

        if not self.azure_speech_region:
            raise ValueError("AZURE_SPEECH_REGION이 설정되지 않았습니다.")

    def _get_env_path(self) -> Path:
        if getattr(sys, "frozen", False):
            executable = Path(sys.executable).resolve()

            if sys.platform == "darwin":
                # AutoCaption/auto_caption.app/Contents/Resources/backend/
                backend_dir = executable.parent

                # AutoCaption/
                distribution_dir = backend_dir.parents[3]

                return distribution_dir / "config" / ".env"

            if sys.platform == "win32":
                return executable.parent.parent / "config" / ".env"

        # 일반 Python 개발 환경
        project_root = Path(__file__).resolve().parents[3]

        return project_root / "config" / ".env"