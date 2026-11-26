# UiPath Project: OracleFusion_AgenticTesting

Type: Tests · Target: Portable · Expressions: VisualBasic · Studio: 26.10.0

## Instructions

- I sign in to the application myself. You may open the sign-in page and type the username; never type a
password, and never read secrets from a password manager.
- Announce every write to the application (create, submit, approve, cancel, rescind) before you make it.
- Never touch data that belongs to other people or teams, such as other users' inbox items or records
someone else created.
- Before you change Test Manager or Studio files in bulk, save a backup copy of what you are about to
change.
- Only publish a package or change security settings when I say so.

## Which skill to use

- **uipath-rpa** — `.xaml` and coded (`.cs`) workflows, UI automation, Object Repository selectors, test cases. The default for most work in this project.
- **uipath-agents** — coded (Python: LangGraph / LlamaIndex / OpenAI) and low-code (`agent.json`) agents.
- **uipath-maestro-flow** — `.flow` Maestro orchestration files.
- **uipath-maestro-bpmn** — `.bpmn` process orchestration.
- **uipath-maestro-case** — case management plans.
- **uipath-coded-apps** — coded web and action apps (`app.config.json`, `action-schema.json`).
- **uipath-api-workflow** — JSON API workflows run by `uip api-workflow run`.
- **uipath-data-fabric** — Data Fabric entities and record CRUD.
- **uipath-human-in-the-loop** — authoring approval / validation / Human Task nodes.
- **uipath-solution** — `.uipx` solutions, SDD/PDD authoring, packaging and publishing.
- **uipath-platform** — Orchestrator, Studio Web, Integration Service, and LLM Gateway operations.
- **uipath-test** — Test Manager projects, cases, and executions.
- **uipath-review** — read-only audit of project structure and best practices.
- **uipath-troubleshoot** — diagnosing failures, errors, and regressions.

If you are unsure where to start, use **uipath-planner** to break the request into tasks
and route each to the right skill.

## Working here

- Load the `uipath-rpa` skill for anything touching a workflow file. For other `uip` areas use the
  matching skill, or `uip <cmd> --help` — not this file.
- `.xaml`, `.cs` and `project.json` are strict-schema files Studio must be able to reopen. Edit them
  through the skill's conventions, leave the Studio-generated view-state blocks alone, and run
  `uip rpa validate` after every change.
- Done means `uip rpa validate` comes back clean and `uip rpa build` succeeds. A change is not
  finished until both do.
- `uip rpa run` executes on this machine and may drive the desktop UI. Confirm with the user first.
- Only `uip rpa publish` when explicitly asked — it pushes a version to a shared Orchestrator tenant.

## Test conventions

Every automated test has a matching Test Manager test case. Reference implementation:
`Tests\API\CreatePR.xaml` with Test Manager case DNZTRAIN:78 (`specs/tm/API-CreatePR.json`).

### API tests (`Tests\API\`)

- **One file per scenario:** `Tests\API\<Action><Object>.xaml`, for example `CreatePR.xaml`.
  - `x:Class` follows the path: `Tests_API_CreatePR`.
  - Register it in `project.json` `fileInfoCollection` as `InProgress`.
  - Set it to `Publishable` only when the user asks to publish.
- **Structure:** Given / When / Then.
  - Each API call is its own sequence: `Step <n> <Verb>: <METHOD> <resource>`.
  - Calls that change data add `(WRITE: ...)` to the display name.
- **Test data:** comes from Data Fabric (see **Data-driven tests** below). Endpoint and credential settings stay as arguments with defaults.
  - RunId is `yyMMddHHmmss`.
  - Every Oracle description starts with `UIP-TEST-API-<RunId>`.
- **HTTP calls:** UiPath.WebAPI `NetHttpRequest`, Basic auth, timeout 60 s.
  - Use credential asset `Oracle_Fusion_P2P_Test` (Shared/OracleFusion), read with Get Credential **inside each call's scope**. Never pass the password between scopes or workflows.
  - Write calls use `RetryPolicyType="None"`, so a retry can't create a duplicate. Read calls may retry once.
  - Store the status code in a variable straight after each call. Parse JSON (`JObject`) only after checking the status is the expected one.
- **Expected outcomes:** one verification per expected outcome, in Then.
  - Use `VerifyExpressionWithOperator` for comparisons and `VerifyExpression` for anything else.
  - The display name names the check. `OutputMessageFormat` shows the actual value against the expected one.
  - Expected refusals and error codes are asserted too, for example POR-2010919.
- **Cleanup:** a `TryCatch` `Finally` removes anything the test created that the main path didn't remove. Tests leave no data behind, pass or fail.
- **Done means:**
  - `validate` and `build` are clean.
  - One local run (announce its Oracle writes first) has every verification logged at Info. A failed check logs at Error. Checks continue on failure, so the run result alone doesn't show failures.
  - The created documents are logged in `P2PGuide/documents.txt`.
- **Portable-project pitfalls:**
  - No `MultipleAssign` (Windows-only); use separate `Assign`s.
  - `RetryCount` must be at least 1; to turn retries off, use `RetryPolicyType="None"`.
  - `JObject` in `x:TypeArguments` needs `xmlns:njl="clr-namespace:Newtonsoft.Json.Linq;assembly=Newtonsoft.Json"`.
  - A `LogMessage` for an outcome the row may expect (for example a rejected create) logs at Info. Only failed checks log at Error.

### Data-driven tests (Data Fabric)

Test Manager runs a data-driven case once per matching record. It reads the records when the run starts, so data changes need no republish.

- **One entity holds all of this project's test data:** `OfatTestData` (tenant scope; schema in `specs/OfatTestData.schema.json`).
  - `DataSet` (text): for example `API_CreatePR`, one data set per test case.
  - `RowOrder` (whole number from 1).
  - `RowData` (long text): one JSON object of **text** values. Every field of the data set is present; an empty value is `""`. The field isn't called `Row`, because Data Fabric rejects that as a reserved word.
- **Each row carries its expected outcomes, as well as its inputs,** for example `ExpectedCreateStatus`, `ExpectedDocumentStatus`, `ExpectedErrorCode`. One test then covers positive and negative scenarios, and Then branches on the expectation.
- **Binding a test to its data set** takes four pieces:
  1. `.variations/OfatTestData_<DataSet>.json`: `EntityName`, `TypeName` `OF_AT_RobP.OfatTestData`, `Filters` = Base64 of the query-builder JSON filtering `DataSet = <DataSet>`, a fresh `TestCaseId` GUID, `Name`.
  2. An entry in `.variations/config.json` with `dataVariationType` `Entity`.
  3. `dataVariationFilePath` on the case's `fileInfoCollection` entry in `project.json`.
  4. One test argument `ofatTestData` typed `local:OfatTestData`, with no default. The name must be the entity name in camelCase exactly; the data binds by that name.
- **Parse first:** the test calls `Workflows\Common_ParseTestRow.xaml` (strict) at the start of Given, passing its required field list. Then it converts numbers inside a TryCatch that throws an `ArgumentException` naming the data set, row and raw values. It never logs row values.
- **Installing a new entity into the project** must be done in Studio (Data Service → Manage Entities, namespace `OF_AT_RobP`). `uip rpa data-fabric-entities install` fails on this Studio build. Close and reopen the project in Studio before installing, so it doesn't save over `project.json`.
- **Local runs** don't fetch Data Fabric data. Run each row with `--input-arguments-file Data\LocalRuns\<Test>_row<n>.json`, which holds `{"ofatTestData": {"DataSet", "RowOrder", "RowData"}}`. Keep one file per row. Running every row locally is part of "done".
- **Adding rows:** add them to the data set in `specs/OfatTestData.schema.json` and insert them with `uip df records insert`. Check the count per data set read back from the server. If no record matches a case's filter, Test Manager marks the case Failed without running it.

### Test Manager test case (every automated test)

- **Project:** the default project in `.tmh/config.json` (DNZTRAIN).
- **Name:** `<Area> <TestName>: <what it proves>`.
- **Description:** what is tested; the automation file and its Studio test case ID; how it authenticates; how it cleans up; the last verified run.
- **Pre- and post-conditions:** the environment, the credential and the test data; what is left afterwards.
- **Steps:** one manual step per Given / When / Then action. Each expected result comes from the test's verifications.
- **Labels:**
  - API tests: `api`, plus the area (for example `P2P`).
  - UI end-to-end tests: `E2E`, `P2P`, `Oracle Fusion`.
  - Exploratory charters: `Exploratory`, `P2P`, `Charter`.
- **Storage:** keep the definition in `specs/tm/<name>.json` and apply it with a script, so it can be re-run and reviewed. Back up the existing case before bulk changes.
- **Linking:** link the automation (`uip tm testcases link-automation`) once a package containing the test has been published. Publishing is only done when the user says so.

## Layout

- `Tests/` — test cases. `Tests/TC_P2P_E2E.xaml` is the UI end-to-end test; `Tests/API/` holds API tests.
- `Workflows/` — stage and helper workflows invoked by the tests.
- `Main.xaml` — named as `main` in project.json but not present (test project; tests are the entry points)
- `project.json` — manifest: dependencies, entry point, expression language, target framework.
  Ground truth; prefer it over the header above, which is a snapshot from creation time.
- `.objects/`, `.screenshots/` — Object Repository source. Commit these.
- `.settings/` — project settings. Commit these.
- `.local/` — generated. Don't edit or commit.

## When something is missing

- **`uip` not found** — ask the user to install it; it needs admin rights and installs runtimes, so
  don't run it yourself. A new shell is needed afterwards before `uip` is on PATH.
  `curl -fsSL https://download.uipath.com/uipath-cli/install.sh | bash` (macOS/Linux) or
  `irm https://download.uipath.com/uipath-cli/install.ps1 | iex` (Windows).
  Install trouble behind a corporate proxy is usually `@uipath` npm scope configuration:
  <https://docs.uipath.com/coding-agents/standalone/latest/user-guide/install-and-set-up>
- **No UiPath skills in your skill list** — run `uip skills install`, then restart the agent session.
  Skills installed mid-session are not loaded into the one already running.
- **Auth error** on anything touching Orchestrator, Studio Web, Integration Service or publishing —
  ask the user to run `uip login`. It opens a browser, so you can't complete it yourself.
  Non-interactive alternative: `uip login --client-id <id> --client-secret <secret>`.
- **No user to ask** (headless or CI) — stop and report the blocker. Don't install, publish, or guess.

<!-- PROJECT-CONTEXT:START -->
<!-- discovery-metadata: cs=0 xaml=13 deps=5 -->
# OF-AT-RobP — Project Context

> Auto-generated by project discovery agent. Regenerate after significant project changes.

## Overview

| Property | Value |
|----------|-------|
| **Name** | OF-AT-RobP (title: OracleFusion_AgenticTesting) |
| **Type** | Tests (UI + REST test automation, Oracle Fusion Procure-to-Pay) |
| **Description** | Test Automation Project; E2E P2P scenario on Oracle Fusion dev16 pod |
| **Target Framework** | Portable (net10.0), Studio 26.10.0, schema 4.1 |
| **Expression Language** | VisualBasic |
| **Runtime** | isAttended=false, requiresUserInteraction=false, excludes `Private:*`, `*password*` from logs |

## Dependencies

| Package | Version | Category | Description |
|---------|---------|----------|-------------|
| UiPath.System.Activities | 26.10.1 | Core | Core activities |
| UiPath.Testing.Activities | 26.10.0 | Testing | Given/When/Then, Verify Expression |
| UiPath.UIAutomation.Activities | 26.10.10 | UI Automation | Modern `uix:N*` activities, Chrome NApplicationCard |
| UiPath.WebAPI.Activities | [2.5.2] | Web | `NetHttpRequest` for Oracle REST (S9_Cleanup) |
| UiPath.DataService.Activities | 26.10.1 | Other UiPath | Data Fabric entity activities |

## Project Structure

```
OF-AT-RobP/
├── Tests/TC_P2P_E2E.xaml        # the only test case
├── Workflows/                   # 12 workflows (S0..S9 steps, Common_*, DF_*, helpers)
├── .objects/                    # Object Repository: 2 apps (686 files)
├── .entities/EntitiesStore.json # Data Fabric store, namespace OF_AT_RobP
├── .tmh/config.json             # Test Manager link
├── .codedworkflows/             # generated ConnectionsFactory/Manager (.cs)
├── specs/ Prompts/ P2PGuide/ Data/   # documentation, charters, evidence
├── run-config.json, project.json, project.uiproj
└── OracleFusion_Automation_Playbook.md, README.md
```

| File Type | Count |
|-----------|-------|
| Coded workflows (.cs) | 0 (2 generated connection files in `.codedworkflows/`) |
| RPA workflows (.xaml) | 13 |
| Test cases | 1 (`Tests\TC_P2P_E2E.xaml`) |

## Entry Points

| File | Input Arguments | Output Arguments | Purpose |
|------|----------------|------------------|---------|
| Main.xaml (declared as `main` in project.json; file not present) | none | none | n/a |
| Tests/TC_P2P_E2E.xaml | Oracle_Fusion_P2P_Test (asset name), CredentialFolderPath (default `Shared/OracleFusion`), FusionUrl, UseIncognito (False), RunCleanup (True), profile args (SupplierName, TaxpayerId=AUTO, AccountNumber=AUTO, ProcurementBU, Country, OrganizationType, ContactEmail, AddressLookup, BusinessClassification, BranchNumber, ProductsCategory, ItemDescription, Category, Quantity, Price) | none | Supplier registration to validated invoice |

## Conventions

- **File naming**: `S<n>_<Action>.xaml` for stages, `Common_*` shared steps, `DF_*` Data Fabric, `Dev_*` iteration harness
- **Arguments**: `in_` / `out_` prefixes (`in_Browser` as `ui:UiElement`, `in_BaseUrl`, `in_Profile` as `Dictionary(String,String)`); test-case args unprefixed
- **Test structure**: Given / When / Then with Try/Finally (closes browser, runs S9 cleanup when RunCleanup, rethrows When failure); Then uses `VerifyExpression`
- **Error handling**: Retry/Poll loops with 10 s checks and page-reload retries; DF save never fails the caller
- **Logging**: `Log Message` at start/end of each step; WRITE actions named `(WRITE: ...)` in DisplayName
- **Test data**: run id `yyMMddHHmm`; Oracle documents described `UIP-TEST-<RunId>`; unique supplier/taxpayer/account/invoice numbers per run

## Key Workflows

| Workflow | Purpose | Services/Activities Used |
|----------|---------|--------------------------|
| S0_SignIn | Open Fusion in Chrome, poll for sign-in or home; out_Browser | NApplicationCard (Chrome), Get Credential, NTypeInto, NClick |
| S1_RegisterSupplier | Supplier Registration wizard; out_RegistrationId | NGoToUrl, NClick, NGetAttribute |
| Common_ApproveNotification | Approve own task from notifications bell (polls up to ~20 min) | NClick, retry/poll |
| Common_ApproveBpmTask | Approve BPM worklist task by title | NClick, NTypeInto |
| S3_CreateRequisition | Pre-clean cart, create and submit requisition; out_RequisitionNumber | NClick, NTypeInto |
| S5_CreatePurchaseOrder | Stage, publish, submit PO; out_PONumber | NClick, polling |
| S6_ReceiveOrder | Receive the PO in My Receipts | NClick, NTypeInto |
| S7_CreateInvoice | Create, match, validate invoice; out_ValidationStatus | NClick, NCheck, polling |
| S9_Cleanup | REST cancel invoice / delete or cancel PO / cancel requisition | Get Credential, NetHttpRequest (Basic auth) |
| DF_SaveP2PRun | Create/update OracleP2PRun record | Data Fabric Create/Update Entity Record |
| GetP2PAssignment | Claim reservation or latest run record at needed stage | Data Fabric query/update |
| Dev_RunFromS6 | Dev harness: S0 + S6 + S7 for existing PO (not a test) | Invoke Workflow File |

## Shared Resources

**Data Fabric** (`.entities/EntitiesStore.json`, namespace `OF_AT_RobP`): OracleP2PRun, OracleP2PReference, OracleP2PReservation, SystemUser. Schemas in `specs/*.schema.json`.
**Object Repository**: 2 apps — Oracle Fusion Cloud (Procurement Redwood + Payables ADF) and Oracle Identity Cloud (IDCS sign-in); 686 files under `.objects/`.
**Credential asset**: `Oracle_Fusion_P2P_Test` in folder `Shared/OracleFusion`; REST calls use it for Basic auth.
**Test Manager**: `.tmh/config.json` — project DNZ-Train (key DNZTRAIN), org `deloivqbaydk`, linked case DNZTRAIN:76 (see run-config.json).

## Architecture

- **Pattern**: Test case orchestrates step workflows (S0 to S7), approvals via Common_*, REST cleanup in S9
- **Data flow**: test builds profile dictionaries and unique ids; each step returns a document number; DF_SaveP2PRun records stage (Requisition, Approved, PO, Received, final outcome)
- **Execution flow**: Given (ids, profiles, DF create) → S0 → S1 → S2 approve → S3 → S4 approve → S5 → S6 → S7 → Finally (close browser, S9 cleanup, DF final) → Then verifies
- **External integrations**: Oracle Fusion UI (Chrome) and REST (`UiPath.WebAPI` NetHttpRequest, Basic auth), Orchestrator credential asset, Data Fabric, Test Manager

## Code Patterns

```
Step workflow: args in_Browser (UiElement), in_BaseUrl, document ids; out_<Document>
  Log start -> Use Browser Chrome (NApplicationCard, attach to in_Browser)
  -> Retry/Poll (10 s checks) around NClick/NTypeInto using Object Repository targets
  -> WRITE actions named "(WRITE: ...)" -> Log done
```

Notes: UI automation uses Chrome NApplicationCard (preserve target identity; no hand-authored selectors). Known divergence: S0_SignIn contains Get Credential, password Type Into and Click Next, whereas the repo spec calls for username-only automation with human password/Next handoff.

## Quick Reference

- **Run**: `uip rpa run --file-path "Tests/TC_P2P_E2E.xaml" --project-dir "C:\Source\WIP\OF-AT-RobP" --output json` (executes locally and drives the desktop; confirm first)
- **Validate**: `uip rpa validate --file-path "Tests/TC_P2P_E2E.xaml" --project-dir "C:\Source\WIP\OF-AT-RobP" --output json`
- **Key files to read first**: `Tests/TC_P2P_E2E.xaml`, `Workflows/S0_SignIn.xaml`, `specs/P2P_E2E_Scenario.md`
<!-- PROJECT-CONTEXT:END -->