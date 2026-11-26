# M2 — Validate the `uip` CLI and the UiPath skills

**You do first:** `uip login` in a terminal (it opens a browser; pick `<ORG>` / `<TENANT>`). Non-interactive:
`uip login --organization <ORG> --tenant <TENANT>`.

**Then paste this prompt:**

```text
Validate the UiPath CLI and agent skills on this machine for the OracleFusion_AgenticTesting project.
Org <ORG>, tenant <TENANT>. Read-only checks unless I approve a fix.

1. CLI: run `uip --version` and `uip login status --output json`. Report Status, Organization, Tenant,
   CredentialSource and ExpirationDate. Expected: Logged in, <ORG>, <TENANT>.
2. If status says "Not logged in" but I have logged in, check whether the environment variable
   UIPATH_CLI_ENFORCE_ROBOT_AUTH is set (names only, never print values). It forces the Assistant/Robot
   sign-in. Re-run `uip login status` with that variable unset for the one command and tell me which sign-in
   works. Do not change my environment permanently without asking.
3. Skills: run `uip skills list` and confirm these are installed: uipath-rpa, uipath-platform,
   uipath-test, uipath-troubleshoot. Also confirm they appear in your own skill list in this session.
   If they are missing, tell me to run `uip skills install` and restart the agent session (skills
   installed mid-session are not loaded).
4. Headless Studio: from the project folder run `uip rpa instances list --output json` and
   `uip rpa build "." --log-level Error --output json`. The first call can take 30–90 s while it restores.
   "Helm requires a signed-in user" means step 1 or 2 is not fixed yet.
5. Orchestrator and Test Manager reach: `uip or folders list --output json --output-filter "[].FullyQualifiedName"`
   and `uip tm project list --output json`. Confirm <FOLDER> and <TM_PROJECT_KEY> are visible (they will
   not be in a brand-new tenant — that is fine, the project/ prompts create them).

Optional: offer to run the /uipath:install-permissions skill so safe uip commands stop prompting.

Finish with a pass/fail table per check and the exact fix for each failure.
```

**Done when:** login, skills, build and the Orchestrator/Test Manager reads all pass.
