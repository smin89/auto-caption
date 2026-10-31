import asyncio
import json

from websockets.asyncio.client import connect


async def main():

    uri = "ws://127.0.0.1:8000/ws/speech"

    async with connect(uri) as websocket:

        # 연결 완료 이벤트 수신
        response = await websocket.recv()

        print(f"[연결] {response}")

        # 테스트 메시지
        messages = [
            {"type": "ping"},
            {"type": "speech.start"},
            {"type": "speech.stop"},
            {"type": "unknown"}
        ]

        for message in messages:

            print(f"\n[전송] {message}")

            await websocket.send(json.dumps(message))

            response = await websocket.recv()

            print(f"[응답] {response}")


if __name__ == "__main__":
    asyncio.run(main())