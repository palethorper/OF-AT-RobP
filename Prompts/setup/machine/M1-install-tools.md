# M1 — Install the tools

**You do (needs admin rights):**

1. UiPath Studio 26.10 from your Automation Cloud org (Help → Download Studio). It installs Studio, Assistant
   and the Robot in user mode. Sign in to Assistant with your UiPath account.
2. Google Chrome, then the UiPath browser extension (Studio → Home → Tools → Extensions → Chrome).
3. Git, Node.js LTS (for the `uip` CLI), Python 3.11+ (for the Data Fabric scripts), VS Code with the
   Claude Code extension.
4. The `uip` CLI, in a new PowerShell window:
   `irm https://download.uipath.com/uipath-cli/install.ps1 | iex`
   Open a new terminal afterwards so `uip` is on PATH. Behind a corporate proxy, see
   <https://docs.uipath.com/coding-agents/standalone/latest/user-guide/install-and-set-up>.

**Then paste this prompt:**

```text
Check that this machine has the tools the OracleFusion_AgenticTesting project needs. Read-only: do not
install, upgrade or change anything; just report.

Report, for each, found/missing and the version:
- UiPath Studio and Robot (look under %LOCALAPPDATA%\Programs\UiPathPlatform\ and whether UiPath.Assistant
  is running),
- Google Chrome and whether the UiPath extension is installed in any Chrome profile
  (%LOCALAPPDATA%\Google\Chrome\User Data\<profile>\Extensions),
- git, node, npm, python,
- uip (`uip --version`).

Finish with a table and the exact install step for anything missing. Do not run installers yourself.
```

**Done when:** every row is found. Studio/Robot should be 26.10 or later.
