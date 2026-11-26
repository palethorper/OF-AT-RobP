import json, subprocess, sys
CLI = r"C:\Users\rob.palethorpe\AppData\Roaming\npm\node_modules\@uipath\cli\dist\index.js"
def call(conn, req, show=6, raw=False):
    p = subprocess.run(["node", CLI, "is", "resources", "run", "create", "uipath-uipath-http", "http-request",
                        "--connection-id", conn, "--body", json.dumps(req), "--output", "json"],
                       capture_output=True, text=True, encoding="utf-8")
    try: r = json.loads(p.stdout)
    except Exception: print("RAW", p.stdout[:800], p.stderr[:400]); return None
    d = r.get("Data") or {}
    b = d.get("body")
    print("HTTP", d.get("code"), r.get("Message", ""))
    if raw: print(str(d.get("rawStringBody") or b)[:raw]); return r
    if isinstance(b, dict) and "items" in b:
        print("count", b.get("count"), "total", b.get("totalResults"), "hasMore", b.get("hasMore"))
        for i in b["items"][:show]: print(json.dumps(i)[:900])
    else: print(str(b)[:800])
    return r
if __name__ == "__main__":
    call(sys.argv[1], json.load(open(sys.argv[2], encoding="utf-8")))
