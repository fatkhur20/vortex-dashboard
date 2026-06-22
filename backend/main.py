from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from datetime import datetime, timezone
from typing import Optional
import json
import os
import asyncio
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Vortex Tracker API", version="1.0.0")


class LocationUpdate(BaseModel):
    user_id: str
    latitude: float
    longitude: float
    altitude: float = 0
    speed: float = 0
    heading: float = 0
    battery: float = 100
    activity: str = "Stationary"
    timestamp: str | None = None


class PartnerLocation(BaseModel):
    id: str
    name: str
    latitude: float
    longitude: float
    altitude: float = 0
    speed: float = 0
    heading: float = 0
    battery: float | None = None
    activity: str = "Stationary"
    is_online: bool = True
    is_moving: bool = False
    timestamp: str | None = None
    last_seen: str | None = None


class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}
        self.user_locations: dict[str, LocationUpdate] = {}
        self.partner_map: dict[str, str] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
                self.user_locations.pop(user_id, None)

    def set_partner(self, user_id: str, partner_id: str):
        self.partner_map[user_id] = partner_id
        self.partner_map[partner_id] = user_id

    async def broadcast_to_user(self, user_id: str, message: dict):
        if user_id in self.active_connections:
            dead = []
            for ws in self.active_connections[user_id]:
                try:
                    await ws.send_json(message)
                except Exception:
                    dead.append(ws)
            for ws in dead:
                self.disconnect(user_id, ws)

    async def forward_to_partner(self, user_id: str, update: LocationUpdate):
        partner_id = self.partner_map.get(user_id)
        if partner_id is None:
            return

        self.user_locations[user_id] = update
        partner_loc = self._build_partner_location(user_id, update)

        await self.broadcast_to_user(partner_id, {
            "type": "partner_location",
            "partner": partner_loc.model_dump(),
        })

        await self.broadcast_to_user(user_id, {
            "type": "self_location",
            "partner": partner_loc.model_dump(),
        })

    def _build_partner_location(self, user_id: str, loc: LocationUpdate) -> PartnerLocation:
        return PartnerLocation(
            id=user_id,
            name=f"User {user_id[-4:]}",
            latitude=loc.latitude,
            longitude=loc.longitude,
            altitude=loc.altitude,
            speed=loc.speed,
            heading=loc.heading,
            battery=loc.battery,
            activity=loc.activity,
            is_online=True,
            is_moving=loc.speed > 1,
            timestamp=loc.timestamp or datetime.now(timezone.utc).isoformat(),
            last_seen=datetime.now(timezone.utc).isoformat(),
        )


manager = ConnectionManager()


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "connections": sum(len(v) for v in manager.active_connections.values()),
        "users": len(manager.active_connections),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/users/{user_id}/partner")
async def get_partner(user_id: str):
    partner_id = manager.partner_map.get(user_id)
    if partner_id is None:
        return {"error": "no partner paired"}
    partner_loc = manager.user_locations.get(partner_id)
    if partner_loc is None:
        return {"partner": None, "online": False}
    return {
        "partner": manager._build_partner_location(partner_id, partner_loc).model_dump(),
        "online": True,
    }


@app.post("/pair")
async def pair_users(user_id: str, partner_id: str):
    manager.set_partner(user_id, partner_id)
    return {"status": "paired", "user_id": user_id, "partner_id": partner_id}


@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(user_id, websocket)

    try:
        while True:
            raw = await websocket.receive_text()
            if raw == "ping":
                await websocket.send_json({"type": "pong"})
                continue

            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_json({"type": "error", "message": "invalid json"})
                continue

            msg_type = data.get("type")

            if msg_type == "subscribe":
                partner_id = data.get("partner_id")
                if partner_id:
                    manager.set_partner(user_id, partner_id)
                    await websocket.send_json({"type": "subscribed", "partner_id": partner_id})
                    existing = manager.user_locations.get(partner_id)
                    if existing:
                        await websocket.send_json({
                            "type": "partner_location",
                            "partner": manager._build_partner_location(partner_id, existing).model_dump(),
                        })

            elif msg_type == "location_update":
                try:
                    update = LocationUpdate(**data)
                    await manager.forward_to_partner(user_id, update)
                except Exception as e:
                    await websocket.send_json({"type": "error", "message": str(e)})

            else:
                await websocket.send_json({"type": "error", "message": f"unknown type: {msg_type}"})

    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
        partner_id = manager.partner_map.get(user_id)
        if partner_id:
            await manager.broadcast_to_user(partner_id, {
                "type": "partner_location",
                "partner": PartnerLocation(
                    id=user_id, name="", latitude=0, longitude=0,
                    is_online=False, is_moving=False,
                ).model_dump(),
            })
    except Exception:
        manager.disconnect(user_id, websocket)


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("WS_HOST", "0.0.0.0")
    port = int(os.getenv("WS_PORT", "8000"))
    uvicorn.run(app, host=host, port=port)
