"""Seed the OFP2P Data Fabric entities (idempotent).

- OracleP2PReference: the proposedSeedRows in specs/OracleP2PReference.schema.json (key = UniqueKey).
- OracleP2PRun: specs/datafabric/seed-p2p-runs.json (key = RunId); TestMarker = UIP-TEST-<RunId>.
Existing keys are skipped, never duplicated. Needs specs/datafabric/df-p2p-ids.json from create_p2p_df.py.

usage: python -I specs/datafabric/seed_p2p_df.py [--reference-only]
"""
import json, os, subprocess, sys

# uip is called as `node <cli>/dist/index.js` (the Windows launcher splits --file/--body on spaces).
# Override with UIP_CLI_JS; otherwise resolve the global npm install of @uipath/cli.
CLI = os.environ.get("UIP_CLI_JS") or os.path.join(
    subprocess.run("npm root -g", shell=True, capture_output=True, text=True).stdout.strip(),
    "@uipath", "cli", "dist", "index.js")
if not os.path.exists(CLI):
    sys.exit(f"uip CLI not found at {CLI}; install it or set UIP_CLI_JS")
HERE = os.path.dirname(os.path.abspath(__file__))
SPECS = os.path.dirname(HERE)
ids = json.load(open(os.path.join(HERE, "df-p2p-ids.json"), encoding="utf-8"))


def uip(*args, body=None):
    cmd = ["node", CLI, "df", *args, "--output", "json"]
    tmp = None
    if body is not None:
        tmp = os.path.join(HERE, "_body.json")
        json.dump(body, open(tmp, "w", encoding="utf-8"))
        cmd += ["--file", tmp]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if tmp:
        os.remove(tmp)
    raw = r.stdout
    i = raw.find("{")
    try:
        d = json.loads(raw[i:]) if i >= 0 else {}
    except json.JSONDecodeError:
        d = {}
    if d.get("Result") != "Success":
        sys.exit(f"FAILED: uip df {' '.join(args)}\n{raw[-1500:]}\n{r.stderr[-800:]}")
    return d


def existing_keys(entity_id, field):
    d = uip("records", "query", entity_id, body={"selectedFields": [field]})
    data = d.get("Data") or {}
    rows = data.get("Items", data.get("Records", data)) if isinstance(data, dict) else data
    return {r.get(field) for r in rows or []}


def seed(entity_id, key_field, rows):
    have = existing_keys(entity_id, key_field)
    new = [r for r in rows if r[key_field] not in have]
    for r in rows:
        print(("  + " if r in new else "  = ") + str(r[key_field]))
    if new:
        uip("records", "insert", entity_id, body=new)
    return len(new)


# Reference rows
ref = json.load(open(os.path.join(SPECS, "OracleP2PReference.schema.json"), encoding="utf-8"))
types = ids["choiceSets"]["OracleP2PReferenceType"]["values"]
ref_rows = []
for r in ref["proposedSeedRows"]:
    row = {k: v for k, v in r.items() if k != "ReferenceType"}
    row["ReferenceType"] = types[r["ReferenceType"]]
    row["UniqueKey"] = f'{r["ReferenceType"]}|{r["ReferenceKey"]}'
    ref_rows.append(row)
print("OracleP2PReference:")
n1 = seed(ids["entities"]["OracleP2PReference"]["id"], "UniqueKey", ref_rows)
if "--reference-only" in sys.argv:
    print(f"inserted {n1} reference rows (run rows skipped: --reference-only)")
    sys.exit(0)

# Run rows
runs = json.load(open(os.path.join(HERE, "seed-p2p-runs.json"), encoding="utf-8"))
stage = ids["choiceSets"]["OracleP2PStage"]["values"]
action = ids["choiceSets"]["OracleP2PCleanupAction"]["values"]
run_rows = []
for r in runs["runs"]:
    row = dict(runs["defaults"]); row.update(r)
    row["TestMarker"] = "UIP-TEST-" + r["RunId"]
    row["Stage"] = stage[r["Stage"]]
    row["CleanupAction"] = action[r["CleanupAction"]]
    row["LastStageAt"] = "2026-11-24T10:05:00+11:00"
    run_rows.append(row)
print("OracleP2PRun:")
n2 = seed(ids["entities"]["OracleP2PRun"]["id"], "RunId", run_rows)
print(f"inserted {n1} reference rows, {n2} run rows")
