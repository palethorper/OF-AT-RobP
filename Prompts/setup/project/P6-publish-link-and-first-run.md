# P6 — Publish, link and first run

Publishing pushes a version to the shared tenant feed, so the agent does it only when you say so.
The run drives Oracle Fusion on your machine and creates a supplier, requisition, PO and invoice
(all named `UIP-TEST-<RunId>` / `UIPTST Supplier <RunId>`); S9 cancels what it can afterwards.

**Before the first run:** be signed in to Assistant, Chrome set up (M3), robot account in the folder (P2),
credential asset (P3), entities imported (P4).

**Then paste this prompt:**

```text
Publish OracleFusion_AgenticTesting and run test case <TM_PROJECT_KEY>:227 from Test Manager on my machine.
Use the uipath-rpa skill for build/pack/publish and uipath-test for linking and running.

1. Build: `uip rpa build "." --log-level Warn --output json` — must succeed.
2. Show me project.json projectVersion; if that version is already on the tenant feed
   (`uip or packages list`), propose the next patch version. Wait for my "publish" before packing and
   publishing (`uip rpa pack` to a folder outside the project, then `uip rpa publish <nupkg>`).
3. Check the test automation process in <FOLDER> moved to the new version (`uip or processes list`).
4. Link the automation if the test case is not linked yet: `uip tm testcases list-automations` then
   `uip tm testcases link-automation` for package OracleFusion_AgenticTesting, entry point
   Tests\TC_P2P_E2E.xaml.
5. Announce, then start the run: `uip tm testcases run --project-key <TM_PROJECT_KEY> --test-case-id <id>
   --execution-type automated --folder-key <folder key> --async`, get the Orchestrator job key from the
   test case log and confirm the job reaches Running on my machine.
   If it stays Pending, read the job's PendingReasons: RobotBusy/RobotConcurrencyLimit = no robot account
   with Windows credentials in the folder (P2).
6. Wait with `uip tm wait` in the background, then report the result, the run documents from the job log
   ("RUN DOCUMENTS: ..."), the S9 cleanup lines, and the OracleP2PRun record for this RunId in Data Fabric.
```

**Done when:** the Test Manager execution finishes **Passed** and the run record shows the final stage.
