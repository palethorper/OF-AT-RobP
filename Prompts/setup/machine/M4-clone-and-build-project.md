# M4 — Clone the project and build it locally

**You do:** `git clone <repo-url> C:\UiPath\OracleFusion_AgenticTesting`, open the folder in VS Code and
start Claude Code there (so it reads `CLAUDE.md` / `AGENTS.md`).

**Then paste this prompt:**

```text
Read the project context (AGENTS.md, project.json, OracleFusion_Automation_Playbook.md §1, and the README
in Prompts/setup). Then check that this fresh clone of OracleFusion_AgenticTesting builds on this machine.
Use the uipath-rpa skill.

1. Confirm the files that are not regenerated are present: project.json, .objects/, .screenshots/,
   .settings/, .project/, .entities/EntitiesStore.json (project.json -> entitiesStores points at it),
   Data/Questionnaire_Attachment.docx, Tests/TC_P2P_E2E.xaml, Workflows/*.xaml.
2. Confirm .local/ is absent or ignored (it is generated) and that git status is clean.
3. Run `uip rpa build "." --log-level Warn --output json`. Report errors in full; summarise warnings by
   rule. Expected: Success. Warnings about "verification feature", step counts and
   "not invokable via the generated WorkflowRunnerService" for the Data Fabric workflows are known and fine.
4. Validate the entry test case: `uip rpa validate --file-path "Tests/TC_P2P_E2E.xaml" --project-dir "." --output json`.
5. If the build fails with `Cannot create unknown type ...OracleP2P...`, the Data Fabric entities are not
   imported for this tenant: stop and point me to Prompts/setup/project/P4.

Do not run the test (it drives Oracle) and do not publish.
```

**Done when:** build succeeds and the test case validates with no errors.
