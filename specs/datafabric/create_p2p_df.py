"""Create the OFP2P Data Fabric choice sets and entities (tenant scope) from the approved specs.

Idempotent: existing choice sets / values / entities with the same name are reused, never duplicated.
Writes specs/datafabric/df-p2p-ids.json with entity ids, choice-set ids and {value Name -> NumberId}.

usage: python -I specs/datafabric/create_p2p_df.py
"""
import json, os, re, subprocess, sys

# uip is called as `node <cli>/dist/index.js` (the Windows launcher splits --file/--body on spaces).
# Override with UIP_CLI_JS; otherwise resolve the global npm install of @uipath/cli.
CLI = os.environ.get("UIP_CLI_JS") or os.path.join(
    subprocess.run("npm root -g", shell=True, capture_output=True, text=True).stdout.strip(),
    "@uipath", "cli", "dist", "index.js")
if not os.path.exists(CLI):
    sys.exit(f"uip CLI not found at {CLI}; install it or set UIP_CLI_JS")
HERE = os.path.dirname(os.path.abspath(__file__))
SPECS = os.path.dirname(HERE)
IDS = os.path.join(HERE, "df-p2p-ids.json")


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


def ensure_choice_set(cs):
    existing = {c["Name"]: c for c in uip("choice-sets", "list").get("Data") or []}
    if cs["name"] in existing:
        cid = existing[cs["name"]]["Id"]
        print("reuse choice set", cs["name"], cid)
    else:
        cid = uip("choice-sets", "create", cs["name"], "--display-name", cs["displayName"], "--description", cs["description"])["Data"]["Id"]
        print("created choice set", cs["name"], cid)

    def values():
        d = uip("choice-sets", "list-values", cid).get("Data") or {}
        items = d.get("Items", d) if isinstance(d, dict) else d
        return {v["Name"]: v["NumberId"] for v in items}

    have = values()
    for v in cs["values"]:
        if v not in have:
            label = re.sub(r"(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", " ", v)
            uip("choice-set-values", "create", cid, v, "--display-name", label)  # fails loud on rejection
            print("  + value", v)
    have = values()  # authoritative NumberIds
    missing = [v for v in cs["values"] if v not in have]
    if missing:
        sys.exit(f"values missing after create: {missing}")
    return cid, {v: have[v] for v in cs["values"]}


def ensure_entity(spec, cs_ids):
    ent = spec["entity"]
    existing = {e["Name"]: e for e in uip("entities", "list", "--native-only").get("Data") or []}
    if ent["name"] in existing:
        eid = existing[ent["name"]]["Id"]
        print("reuse entity", ent["name"], eid)
        return eid
    fields = []
    for f in ent["fields"]:
        f = dict(f)
        if f.get("choiceSetId", "").startswith("<"):
            f["choiceSetId"] = cs_ids[f["choiceSetId"].strip("<>")]
        if f.get("type") == "RELATIONSHIP" and "referenceEntity" in f:
            tgt = existing[f.pop("referenceEntity")]["Id"]
            tf = f.pop("referenceField")
            fields_t = uip("entities", "get", tgt)["Data"]["Fields"]
            f["referenceEntityId"] = tgt
            f["referenceFieldId"] = next(x["Id"] for x in fields_t if x["Name"] == tf)
        fields.append(f)
    body = {"displayName": ent["displayName"], "description": ent["description"], "fields": fields}
    eid = uip("entities", "create", ent["name"], body=body)["Data"]["Id"]
    print("created entity", ent["name"], eid)
    return eid


def main():
    out = {"scope": "tenant", "choiceSets": {}, "entities": {}}
    cs_ids = {}
    for fn in ("OracleP2PRun.schema.json", "OracleP2PReference.schema.json", "OracleP2PReservation.schema.json"):
        spec = json.load(open(os.path.join(SPECS, fn), encoding="utf-8"))
        for cs in spec["choiceSets"]:
            cid, numbers = ensure_choice_set(cs)
            cs_ids[cs["name"]] = cid
            out["choiceSets"][cs["name"]] = {"id": cid, "values": numbers}
        out["entities"][spec["entity"]["name"]] = {"id": ensure_entity(spec, cs_ids)}
    if os.path.exists(IDS):
        old = json.load(open(IDS, encoding="utf-8"))
        old["choiceSets"].update(out["choiceSets"]); old["entities"].update(out["entities"]); out = old
    json.dump(out, open(IDS, "w", encoding="utf-8"), indent=2)
    print("saved", IDS)


if __name__ == "__main__":
    main()
