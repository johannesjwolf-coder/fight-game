"""Compare a built Web client against the exported native-server fixture.

Usage: python tests/browser_replay.py build/server/fight-game.x86_64
Dependency: playwright==1.58.0; browsers installed separately.
"""
import functools
import http.server
import json
import subprocess
import sys
import threading
from pathlib import Path
from playwright.sync_api import sync_playwright


def main():
    native = subprocess.run(
        [sys.argv[1], "--headless", "--", "--verify-replay"],
        capture_output=True, text=True, timeout=60, check=True,
    )
    expected = json.loads(next(
        line.removeprefix("REPLAY_RESULT=")
        for line in native.stdout.splitlines() if line.startswith("REPLAY_RESULT=")
    ))
    assert expected["ok"], expected
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory="build/web")
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with sync_playwright() as playwright:
            for name in ("chromium", "firefox", "webkit"):
                browser = getattr(playwright, name).launch()
                try:
                    page = browser.new_page(viewport={"width": 1152, "height": 720})
                    errors = []
                    page.on("pageerror", lambda error: errors.append(str(error)))
                    page.goto(f"http://127.0.0.1:{server.server_port}/?selftest=1")
                    page.wait_for_function("window.FG_PHASE2_RESULT !== undefined", timeout=60000)
                    actual = page.evaluate("window.FG_PHASE2_RESULT")
                    assert actual == expected, (name, expected, actual)
                    assert not errors, errors
                    Path("build/checks").mkdir(exist_ok=True)
                    page.screenshot(path=f"build/checks/{name}.png")
                    print(f"PASS {name}: tick 120, complete trace {actual['trace_hash']}")
                finally:
                    browser.close()
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()
