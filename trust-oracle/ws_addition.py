# ============================================================
# ADD TO main.py — WebSocket log streaming
# Paste after the imports block, before the endpoints
# ============================================================

from fastapi import WebSocket, WebSocketDisconnect
from loguru import logger
import sys

# Connected WebSocket clients
_ws_clients: list = []

async def ws_broadcast(message: str):
    """Send a log message to all connected dashboard clients."""
    dead = []
    for client in _ws_clients:
        try:
            await client.send_text(message)
        except Exception:
            dead.append(client)
    for d in dead:
        _ws_clients.remove(d)

@app.websocket("/ws/logs")
async def websocket_logs(websocket: WebSocket):
    """WebSocket endpoint — browser connects here for live log streaming."""
    await websocket.accept()
    _ws_clients.append(websocket)
    logger.info(f"📡 Dashboard connected via WebSocket. Total: {len(_ws_clients)}")
    try:
        while True:
            # Keep connection alive, client doesn't need to send anything
            await asyncio.sleep(20)
            await websocket.send_text("ping")
    except WebSocketDisconnect:
        _ws_clients.remove(websocket)
        logger.info(f"📡 Dashboard disconnected. Total: {len(_ws_clients)}")


# ============================================================
# ADD THIS to nokia_client.py — broadcast Nokia signals live
# After each successful Nokia API call, add:
# ============================================================

# In nokia_client.check(), after getting results, import and call:
# from main import ws_broadcast  ← don't do circular import
# Instead, add a callback pattern:

# In nokia_client.py, add at top:
_log_callback = None
def set_log_callback(fn):
    global _log_callback
    _log_callback = fn

def _emit(msg: str):
    if _log_callback:
        import asyncio
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                asyncio.create_task(_log_callback(msg))
        except Exception:
            pass

# Then in check(), after each API call:
# _emit(f"[NOKIA] device_changed: {device_changed}")
# _emit(f"[NOKIA] roaming: {roaming} country: {country}")
# etc.

# In main.py startup, wire it up:
@app.on_event("startup")
async def startup():
    database.init_db()
    nokia_client.set_log_callback(ws_broadcast)
    logger.success("Ubuntu Pay Trust Oracle started")
    logger.success(f"Nokia: {'REAL' if nokia_client.client else 'OFFLINE'}")
