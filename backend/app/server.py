from fastapi import FastAPI

from backend.app.api.websocket import router as websocket_router


app = FastAPI(
    title="Auto Caption API",
    description="Real-time Speech Recognition and Translation API",
    version="0.1.0"
)


# WebSocket 라우터 등록
app.include_router(websocket_router)


# 서버 상태 확인 API
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "auto-caption",
        "version": "0.1.0"
    }