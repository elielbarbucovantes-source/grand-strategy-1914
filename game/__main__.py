"""Point d'entree : ``python3 -m game``."""

from __future__ import annotations

import argparse
import webbrowser

from .server import serve


def main() -> None:
    parser = argparse.ArgumentParser(description="Grand Strategy-1914 — MVP jouable")
    parser.add_argument("--host", default="127.0.0.1", help="adresse d'ecoute (defaut : 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8765, help="port d'ecoute (defaut : 8765)")
    parser.add_argument("--open", action="store_true", help="ouvrir le navigateur au demarrage")
    args = parser.parse_args()
    if args.open:
        webbrowser.open(f"http://{args.host}:{args.port}/")
    serve(args.host, args.port)


if __name__ == "__main__":
    main()
