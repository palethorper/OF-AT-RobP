# P1 — Connect the project to the cloud tenant

**You do:** sign in to UiPath Assistant (and Studio) with your account on `<ORG>` / `<TENANT>`, and
`uip login --organization <ORG> --tenant <TENANT>` (M2).

**Then paste this prompt:**

```text
Connect OracleFusion_AgenticTesting to tenant <TENANT> in org <ORG>. Use the uipath-platform and
uipath-rpa skills. Read first, change nothing until I confirm.

1. `uip login status` — confirm org/tenant.
2. Show the project's Test Manager link: `uip rpa tm status --project-dir "." --output json`.
   It lives in .tmh/config.json, which is git-ignored, so a fresh clone has none.
3. List Orchestrator folders and tell me whether <FOLDER> exists. If not, stop and point me to P2.
4. List Test Manager projects and tell me whether <TM_PROJECT_KEY> exists. If not, stop and point me to P5.
5. If both exist, propose the commands to link the Studio project to Test Manager
   (`uip rpa tm connect` and `uip rpa tm set-default-project --project-key <TM_PROJECT_KEY>`;
   check --help for exact flags) and run them when I say yes.
6. Check the tenant's Orchestrator assets in <FOLDER> include the credential asset <CREDENTIAL_ASSET>
   (name and type only — never read its value). If missing, point me to P3.
```

**Done when:** `uip rpa tm status` shows `<TM_PROJECT_KEY>`, and the folder and asset exist.
