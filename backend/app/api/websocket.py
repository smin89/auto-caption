from fastapi import APIRouter, WebSocket, WebSocketDisconnect


router = APIRouter()


@router.websocket("/ws/speech")
async def speech_websocket(websocket: WebSocket):

    # WebSocket 연결 수락
    await websocket.accept()

    print("[WebSocket] 클라이언트 연결")

    # 연결 완료 이벤트
    await websocket.send_json({
        "type": "connection.established",
        "message": "WebSocket 연결이 완료되었습니다."
    })

    try:
        while True:

            # JSON 메시지 수신
            data = await websocket.receive_json()

            message_type = data.get("type")

            print(f"[WebSocket] 수신: {data}")

            # 연결 확인
            if message_type == "ping":

                await websocket.send_json({
                    "type": "pong",
                    "message": "서버가 정상적으로 동작하고 있습니다."
                })

            # 음성인식 시작 요청
            elif message_type == "speech.start":

                await websocket.send_json({
                    "type": "speech.started",
                    "message": "음성인식 시작 요청을 수신했습니다."
                })

            # 음성인식 종료 요청
            elif message_type == "speech.stop":

                await websocket.send_json({
                    "type": "speech.stopped",
                    "message": "음성인식 종료 요청을 수신했습니다."
                })

            # 지원하지 않는 메시지
            else:

                await websocket.send_json({
                    "type": "error",
                    "message": f"지원하지 않는 메시지 유형입니다: {message_type}"
                })

    except WebSocketDisconnect:

        print("[WebSocket] 클라이언트 연결 종료")