# P4 — Data Fabric entities and choice sets

The test records each run in Data Fabric (`OracleP2PRun`), and `GetP2PAssignment.xaml` hands POs to
downstream tests through `OracleP2PReservation`. Reference data lives in `OracleP2PReference`.

Source of truth in the repo:

| File | What |
|---|---|
| `specs/OracleP2PRun.schema.json`, `OracleP2PReference.schema.json`, `OracleP2PReservation.schema.json` | Fields and choice sets (Stage, CleanupAction, ReferenceType, ReservationStatus, ReservationPurpose) |
| `specs/datafabric/create_p2p_df.py` | Creates the choice sets and entities (idempotent; reuses by name) and writes `df-p2p-ids.json` |
| `specs/datafabric/seed_p2p_df.py`, `seed-p2p-runs.json` | Seeds reference rows (from the Reference schema) and sample run rows |
| `specs/datafabric/df-p2p-ids.json` | Entity / choice-set IDs **for one tenant** — regenerated per tenant |

**Same tenant as before?** Skip to step 3 — the entities exist.

**Then paste this prompt:**

```text
Set up the Data Fabric entities for OracleFusion_AgenticTesting in <ORG>/<TENANT>. Use the
uipath-platform skill (uip df). Announce every Data Fabric write before making it.

1. Read-only: list native entities and choice sets; report whether OracleP2PRun, OracleP2PReference,
   OracleP2PReservation and the five OracleP2P* choice sets already exist.
2. If any are missing, show me the plan, then on my yes run
   `python -I specs/datafabric/create_p2p_df.py` (it reuses what exists and writes df-p2p-ids.json),
   and optionally `python -I specs/datafabric/seed_p2p_df.py` for the reference rows. Read both entities back
   and show their fields. The choice-set value IDs must come out as listed in df-p2p-ids.json
   (Stage Requisition=0 ... Failed=8; ReservationStatus Reserved=0, InUse=1; Purpose Receipt=0, Invoice=1,
   Payment=2) — the workflows rely on them; stop and tell me if they differ.
3. Project import: the CLI import (`uip rpa data-fabric-entities`) crashes on Studio 26.10.0, so ask me to
   do it in Studio: Design ribbon > Manage Entities > tick OracleP2PRun, OracleP2PReference,
   OracleP2PReservation > Save, then save the project. Afterwards check .entities/EntitiesStore.json and
   project.json entitiesStores.
4. New tenant only: the workflows carry this tenant's entity and field IDs. Compare the IDs in
   Workflows/DF_SaveP2PRun.xaml and Workflows/GetP2PAssignment.xaml (EntityId="..." and
   DynamicEntityField Id="...") with .entities/EntitiesStore.json, propose a mapping old -> new, back up both
   files to .backup/, and update them when I approve. Then validate both files and build (uipath-rpa).
```

**Done when:** the entities exist, are imported (`.entities/EntitiesStore.json`), and the project builds.
