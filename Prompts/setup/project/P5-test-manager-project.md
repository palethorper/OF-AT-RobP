# P5 — Test Manager project

The test case lives in Test Manager project `<TM_PROJECT_KEY>`: requirement OFP2P:226, test case OFP2P:227
("E2E P2P automated: new supplier to validated invoice") with its parameters and attachments, linked to
the package entry point `Tests\TC_P2P_E2E.xaml`.

**Copy the existing project to another tenant (recommended):** export it to a `.tmh` package from the
current tenant and import it into the new one.

**Then paste this prompt:**

```text
Set up the Test Manager project for OracleFusion_AgenticTesting. Use the uipath-test skill.
Announce every Test Manager write before making it.

Case A — copying from the existing tenant:
1. While logged in to the SOURCE tenant: export project <TM_PROJECT_KEY> to a .tmh package
   (`uip tm project export`, check --help), save it under specs/source/, and tell me the file.
2. I log in to the TARGET tenant (`uip login --organization <ORG> --tenant <TENANT>`).
3. Import the .tmh into a new project with key <TM_PROJECT_KEY> (`uip tm project import`).

Case B — starting fresh:
1. Create project <TM_PROJECT_KEY> ("Oracle Fusion P2P") with `uip tm project create`.
2. Create the requirement and the automated test case from specs/P2P_E2E_Scenario.md
   (name, description, pre/post-conditions), and attach specs/source/ documents I name.

Both cases:
4. Set the project's default Orchestrator folder to <FOLDER> (`uip tm project --help` for the verb) and show
   `uip tm project settings get --project-key <TM_PROJECT_KEY>`.
5. Link the Studio project: `uip rpa tm connect` and
   `uip rpa tm set-default-project --project-key <TM_PROJECT_KEY>` (check flags), then
   `uip rpa tm status`.
6. Linking the automation to the test case happens after the first publish (P6).
```

**Done when:** the project exists with the test case, default folder `<FOLDER>`, and the Studio project is linked.
