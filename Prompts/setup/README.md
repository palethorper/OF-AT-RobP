# Setup prompts — OracleFusion_AgenticTesting

Prompts to paste into Claude Code (with the UiPath skills installed) to get this project running on a new
machine and, if needed, in a new UiPath Automation Cloud tenant. Run them in order. Each file says what you do
by hand, what the agent does, and how you know the step is done.

| Set | Use it when |
|---|---|
| `machine/` | A new PC: tools, `uip` CLI and skills, Chrome, the cloned project building locally |
| `project/` | Connecting the project to a tenant: login, Orchestrator folder and robot, credential asset, Data Fabric, Test Manager, publish and first run |

Same tenant as today? Run `machine/` M1–M4, then `project/` P1 and P6 only — the folder, robot account,
asset, entities and Test Manager project already exist.

## Fill these in once

Every prompt uses these placeholders. Replace them before pasting (or tell the agent the values up front).

| Placeholder | Meaning | Current value (dev) |
|---|---|---|
| `<ORG>` | Automation Cloud organization (logical name) | `salesyuhwlxy` |
| `<TENANT>` | Tenant | `DefaultTenant` |
| `<FOLDER>` | Orchestrator folder the tests run in | `Shared/Testing-UBAPI` |
| `<TM_PROJECT_KEY>` | Test Manager project key | `OFP2P` |
| `<CREDENTIAL_ASSET>` | Orchestrator Credential asset with the Oracle login | `Oracle_Fusion_P2P_Test` |
| `<ORACLE_USER>` | Oracle Fusion user the robot signs in as | `CASEY.BROWN` |
| `<FUSION_URL>` | Oracle Fusion start page | `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com/fscmUI/faces/FuseWelcome` |
| `<ROBOT_ACCOUNT>` | Robot account that runs unattended jobs | `robp-unattended` (one per person/machine) |
| `<WINDOWS_USER>` | Windows account the robot runs as on your machine | `DOMAIN\your.name` |
| `<CHROME_PROFILE>` | Chrome profile folder with the UiPath extension and file access | e.g. `Profile 4` |

## Ground rules the agent follows (from AGENTS.md)

- You sign in to Oracle and type every password yourself. The agent never types or reads a password.
- The agent announces every write to Oracle, Orchestrator, Data Fabric or Test Manager before it makes it.
- Publishing a package and changing security settings (folder assignments, robot accounts, roles) happen only
  when you say so.

## Lessons that cost time before

- `uip` reports "Not logged in" although you are: an environment variable `UIPATH_CLI_ENFORCE_ROBOT_AUTH`
  forces the Assistant/Robot sign-in. See `machine/M2`.
- A Test Manager run stuck in **Pending** with `RobotBusy` / `RobotConcurrencyLimit`: the folder has no robot
  account **with Windows credentials**, which foreground (browser) tests need. See `project/P2`.
- `uip rpa data-fabric-entities` crashes (`MissingMethodException`) on Studio 26.10.0: import entities with
  Studio's **Manage Entities** button instead. See `project/P4`.
- The questionnaire upload fails when Chrome opens a profile where the UiPath extension lacks
  **Allow access to file URLs**. See `machine/M3`.
