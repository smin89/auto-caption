import asyncio
import json

from websockets.asyncio.client import connect


async def receive_messages(websocket):
    try:
        async for message in websocket:
            data = json.loads(message)

            print(f"\n[수신] {data}")

    except Exception as e:
        print(f"[수신 오류] {e}")


async def main():

    uri = "ws://127.0.0.1:8000/ws/speech"

    async with connect(uri) as websocket:

        receiver_task = asyncio.create_task(
            receive_messages(websocket)
        )

        print("WebSocket 연결 완료")
        print("명령어: start / stop / ping / exit")

        try:
            while True:
                command = await asyncio.to_thread(
                    input,
                    "\n명령어 입력: "
                )

                if command == "start":
                    message = {"type": "speech.start"}

                elif command == "stop":
                    message = {"type": "speech.stop"}

                elif command == "ping":
                    message = {"type": "ping"}

                elif command == "exit":
                    break

                else:
                    print("지원하지 않는 명령어입니다.")
                    continue

                await websocket.send(json.dumps(message))

        finally:
            receiver_task.cancel()

            try:
                await receiver_task
            except asyncio.CancelledError:
                pass


if __name__ == "__main__":
    asyncio.run(main())