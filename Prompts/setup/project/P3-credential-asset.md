# P3 — Oracle credential asset (you create it)

S0_SignIn reads the Oracle login from an Orchestrator **Credential** asset at run time
(Test Manager parameter `Oracle_Fusion_P2P_Test` = asset name, `CredentialFolderPath` = folder).
The agent never creates, reads or types the password — you do this in the Orchestrator UI.

**You do:**

1. Orchestrator → `<FOLDER>` → **Assets** → **Add asset**.
2. Name: `<CREDENTIAL_ASSET>`. Type: **Credential**.
3. Username: `<ORACLE_USER>`. Password: the Oracle password (type it yourself).
4. Value scope: global, or per robot if different robots use different Oracle users.
5. Save. If the Oracle password changes later, update it here; a stale password makes S0 fail at sign-in.

**Then paste this prompt to check it (no secrets involved):**

```text
Check that the Oracle credential asset is in place for OracleFusion_AgenticTesting. Read-only, and never
read or print the asset's value.

1. In folder <FOLDER>, confirm an asset named <CREDENTIAL_ASSET> exists and its type is Credential
   (use the uipath-platform skill's asset list command with an output filter for Name and ValueType only).
2. Confirm Tests/TC_P2P_E2E.xaml defaults match: argument Oracle_Fusion_P2P_Test = "<CREDENTIAL_ASSET>"
   and CredentialFolderPath = "<FOLDER>". If they differ, tell me; Test Manager parameters can override
   them per run, so do not edit the test without asking.
3. Remind me that the robot account running the job must have access to <FOLDER> (P2).
```

**Done when:** the asset exists as a Credential in `<FOLDER>` and the test defaults point to it.
