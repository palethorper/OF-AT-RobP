# P2 — Orchestrator folder, machine and robot account

The test drives a browser, so Orchestrator runs it as a **foreground** job. A foreground unattended job needs:

- a **machine** (template) in the folder, connected to your PC, with an Unattended / Testing runtime, and
- a **robot account with Windows credentials** (`<WINDOWS_USER>`) assigned to the folder.

Without the second one, Test Manager runs sit in **Pending** with `RobotBusy` / `RobotConcurrencyLimit`
(robot accounts without credentials can only run background jobs).

Everything here is a security or tenant configuration change: the agent proposes, you approve each step.

**Then paste this prompt:**

```text
Prepare Orchestrator folder <FOLDER> in <ORG>/<TENANT> to run OracleFusion_AgenticTesting test cases
unattended on my machine. Use the uipath-platform skill (and uipath-admin for robot accounts if needed).
These are security changes: show me each exact command and wait for my yes before running it.

Check and report first (read-only):
1. Does <FOLDER> exist? (`uip or folders list`)
2. Machine templates with connected runtimes (`uip or machines list --all-fields`): which one is my
   machine (hostname from `hostname`), and is it assigned to <FOLDER> with Unattended/Testing slots?
3. Robot accounts in the tenant and their unattended settings (`uip or users get <key> --all-fields`,
   look at UnattendedRobot.UserName). Is there one whose Windows user is <WINDOWS_USER>?
4. Which robot accounts are assigned to <FOLDER> (`uip or users list-in-folder --include-inherited`), and
   do any have Windows credentials?
5. Licences (`uip or licenses info`): free Unattended / Testing / AppTest runtimes.

Then propose only what is missing, for example:
- create the folder,
- assign the machine template to the folder,
- assign robot account <ROBOT_ACCOUNT> to the folder with the "Automation User" role
  (`uip or users assign --user-key ... --role-keys ... --folder-key ...`).
If the robot account does not exist or has no Windows credentials, tell me to create or edit it in
Orchestrator (Tenant > Manage Access > Robot accounts) and set its Windows username/password there myself —
never handle the password.
```

**Done when:** the folder has your machine template and a robot account with Windows credentials.
