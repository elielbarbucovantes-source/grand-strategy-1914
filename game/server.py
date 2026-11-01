"""Serveur HTTP local et API JSON du MVP (bibliotheque standard uniquement)."""

from __future__ import annotations

import json
import mimetypes
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from . import engine, scenario, storage
from .model import GameState

WEB_DIR = Path(__file__).resolve().parent / "web"
STATE: GameState | None = None
LOCK = threading.RLock()


def _json_response(handler: BaseHTTPRequestHandler, payload: dict[str, Any], status: int = 200) -> None:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.send_header("Cache-Control", "no-store")
    handler.end_headers()
    handler.wfile.write(body)


def _view() -> dict[str, Any]:
    """Vue courante, avec brouillard de guerre si une nation est dirigee."""
    return engine.build_view(STATE, STATE.player_nation if STATE else None)


def _error(handler: BaseHTTPRequestHandler, message: str, status: int = 400) -> None:
    _json_response(handler, {"ok": False, "error": message}, status)


class Handler(BaseHTTPRequestHandler):
    server_version = "GrandStrategy1914/0.1"

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        # Journal minimal : evite de polluer la console avec chaque asset.
        if self.path.startswith("/api/"):
            super().log_message(format, *args)

    def _read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0") or 0)
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        try:
            data = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ValueError("Corps JSON invalide.") from exc
        if not isinstance(data, dict):
            raise ValueError("Le corps JSON doit etre un objet.")
        return data

    def _serve_file(self, path: Path) -> None:
        if not path.exists() or not path.is_file():
            self.send_error(404)
            return
        content = path.read_bytes()
        content_type, _ = mimetypes.guess_type(path.name)
        self.send_response(200)
        self.send_header("Content-Type", content_type or "application/octet-stream")
        self.send_header("Content-Length", str(len(content)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(content)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        path = parsed.path
        if path == "/api/view":
            with LOCK:
                _json_response(self, _view())
            return
        if path == "/api/saves":
            with LOCK:
                _json_response(self, {"ok": True, "saves": storage.list_saves()})
            return
        if path == "/api/meta":
            _json_response(self, {"ok": True, "playable": scenario.playable_nations()})
            return
        if path == "/api/map":
            _json_response(self, {"ok": True, **scenario.load_data("map.json")})
            return
        if path in ("/", "/index.html"):
            self._serve_file(WEB_DIR / "index.html")
            return
        candidate = (WEB_DIR / path.lstrip("/")).resolve()
        if WEB_DIR.resolve() in candidate.parents:
            self._serve_file(candidate)
            return
        self.send_error(404)

    def do_POST(self) -> None:  # noqa: N802
        global STATE
        parsed = urlparse(self.path)
        path = parsed.path
        try:
            payload = self._read_json()
        except ValueError as exc:
            _error(self, str(exc))
            return

        try:
            if path == "/api/new":
                nation = payload.get("nation")
                if nation in ("", "observer"):
                    nation = None
                seed = payload.get("seed")
                with LOCK:
                    STATE = scenario.new_game(nation, int(seed) if seed not in (None, "") else None)
                    _json_response(self, {"ok": True, "view": _view()})
                return
            if path == "/api/end-turn":
                with LOCK:
                    if STATE is None:
                        _error(self, "Aucune partie en cours.", 409)
                        return
                    orders = payload.get("orders") or {}
                    if not isinstance(orders, dict):
                        _error(self, "Ordres invalides.")
                        return
                    engine.end_turn(STATE, orders)
                    _json_response(self, {"ok": True, "view": _view()})
                return
            if path == "/api/save":
                with LOCK:
                    if STATE is None:
                        _error(self, "Aucune partie en cours.", 409)
                        return
                    name = str(payload.get("name") or f"partie-{STATE.turn}")
                    info = storage.save_game(STATE, name)
                    _json_response(self, {"ok": True, "save": info})
                return
            if path == "/api/load":
                with LOCK:
                    name = str(payload.get("name") or "")
                    STATE = storage.load_game(name)
                    _json_response(self, {"ok": True, "view": _view()})
                return
            if path == "/api/take-control":
                with LOCK:
                    if STATE is None:
                        _error(self, "Aucune partie en cours.", 409)
                        return
                    ok, message = engine.take_control(STATE, str(payload.get("nation") or ""))
                    if not ok:
                        _error(self, message)
                        return
                    _json_response(self, {"ok": True, "message": message, "view": _view()})
                return
            if path == "/api/action":
                # Point d'extension : les ordres sont transmis avec /api/end-turn.
                _json_response(self, {"ok": True, "message": "Les ordres sont resolus a la fin du tour."})
                return
            _error(self, "Route inconnue.", 404)
        except FileNotFoundError as exc:
            _error(self, str(exc), 404)
        except ValueError as exc:
            _error(self, str(exc))
        except Exception as exc:  # pragma: no cover - garde-fou serveur
            _error(self, f"Erreur interne : {exc}", 500)


def serve(host: str = "127.0.0.1", port: int = 8765) -> None:
    server = ThreadingHTTPServer((host, port), Handler)
    print(f"Grand Strategy-1914 — interface : http://{host}:{port}/")
    print("Ctrl+C pour arreter.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nArret du serveur.")
    finally:
        server.server_close()
