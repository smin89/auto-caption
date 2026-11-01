import uvicorn

from backend.app.server import app


def main():
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="info",
        reload=False,
        workers=1,
    )


if __name__ == "__main__":
    main()