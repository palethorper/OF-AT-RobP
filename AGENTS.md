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

## Layout

- `Main.xaml` — entry point
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
## Brownfield project context

- UIA convention: modern `uix:N*` activities with one Edge `NApplicationCard` (`ByInstance`, `OpenMode=Always`, `IsIncognito=True`, `InteractionMode=DebuggerApi`, maximized), embedded `TargetAnchorable` definitions, existing Object Repository references, semantic web attributes, and occasional CV fallback. Preserve target identity and repair existing references in place; do not hand-author selectors or create duplicates.
- Runtime constraints: interactive Windows desktop, Edge/UI Automation, network access to Oracle Fusion/IDCS, and required `Oracle` assets. ADF/Home selectors are sensitive to dynamic IDs, title/URL transitions, redraw timing, horizontal group-tab overflow, and the Sandbox banner; use stable semantic attributes and readiness conditions rather than coordinates/fixed delays.
- Known divergence: the current Oracle workflow contains `GetRobotCredential` plus secure password `NTypeInto` and automated `Next` click, while the repository specification calls for username-only automation and a human password/Next handoff. This discovery recorded the divergence and did not modify workflows, project configuration, selectors, or Test Manager configuration.

<!-- PROJECT-CONTEXT:END -->