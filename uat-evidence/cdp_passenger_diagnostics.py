import json
import time
import urllib.request
import websocket

TARGET = "http://127.0.0.1:8102/"
for _ in range(20):
    try:
        tabs = json.load(urllib.request.urlopen("http://127.0.0.1:9223/json", timeout=2))
        break
    except Exception:
        time.sleep(0.5)
else:
    raise SystemExit("CDP endpoint unavailable")

page = next(t for t in tabs if t.get("type") == "page")
ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=5)
seq = 0
def send(method, params=None):
    global seq
    seq += 1
    ws.send(json.dumps({"id": seq, "method": method, "params": params or {}}))
    return seq

send("Runtime.enable")
send("Log.enable")
send("Page.enable")
send("Page.navigate", {"url": TARGET})
end = time.time() + 15
while time.time() < end:
    try:
        msg = json.loads(ws.recv())
    except Exception:
        break
    method = msg.get("method", "")
    if method in {"Runtime.exceptionThrown", "Runtime.consoleAPICalled", "Log.entryAdded", "Page.loadEventFired"}:
        print(json.dumps(msg, ensure_ascii=False))
print("DIAGNOSTIC_COMPLETE")
