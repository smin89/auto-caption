import asyncio

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from backend.app.config.settings import Settings
from backend.app.services.speech_translation_service import SpeechTranslationService


router = APIRouter()


@router.websocket("/ws/speech")
async def speech_websocket(websocket: WebSocket):

    await websocket.accept()

    print("[WebSocket] 클라이언트 연결")

    loop = asyncio.get_running_loop()
    event_queue = asyncio.Queue(maxsize=100)

    speech_service = None

    def on_speech_result(data: dict):
        # Azure SDK 콜백 스레드에서 호출될 수 있음
        def enqueue():
            if event_queue.full():
                try:
                    event_queue.get_nowait()
                except asyncio.QueueEmpty:
                    pass

            event_queue.put_nowait(data)

        loop.call_soon_threadsafe(enqueue)

    async def send_events():
        while True:
            data = await event_queue.get()
            await websocket.send_json(data)

    sender_task = asyncio.create_task(send_events())

    await websocket.send_json({
        "type": "connection.established",
        "message": "WebSocket 연결이 완료되었습니다."
    })

    try:
        while True:
            data = await websocket.receive_json()
            message_type = data.get("type")

            if message_type == "ping":
                await event_queue.put({
                    "type": "pong",
                    "message": "서버가 정상적으로 동작하고 있습니다."
                })

            elif message_type == "speech.start":

                if speech_service and speech_service.is_running:
                    await event_queue.put({
                        "type": "speech.error",
                        "message": "이미 음성인식이 실행 중입니다."
                    })
                    continue

                settings = Settings()

                speech_service = SpeechTranslationService(
                    settings=settings,
                    on_result=on_speech_result
                )

                await asyncio.to_thread(speech_service.start)

                await event_queue.put({
                    "type": "speech.started",
                    "message": "음성인식 및 번역이 시작되었습니다."
                })

            elif message_type == "speech.stop":

                if speech_service and speech_service.is_running:
                    await asyncio.to_thread(speech_service.stop)

                    await event_queue.put({
                        "type": "speech.stopped",
                        "message": "음성인식 및 번역이 종료되었습니다."
                    })

                else:
                    await event_queue.put({
                        "type": "speech.error",
                        "message": "실행 중인 음성인식이 없습니다."
                    })

            else:
                await event_queue.put({
                    "type": "error",
                    "message": f"지원하지 않는 메시지 유형입니다: {message_type}"
                })

    except WebSocketDisconnect:
        print("[WebSocket] 클라이언트 연결 종료")

    except Exception as e:
        print(f"[WebSocket 오류] {e}")

    finally:
        if speech_service and speech_service.is_running:
            await asyncio.to_thread(speech_service.stop)

        sender_task.cancel()

        try:
            await sender_task
        except asyncio.CancelledError:
            pass

        print("[WebSocket] 리소스 정리 완료")