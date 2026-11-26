Use the uipath-test skill for Test Manager and the uipath-platform skill for Orchestrator.

## Target

- Application: Oracle Fusion ERP
  https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com/fscmUI/faces/FuseWelcome
- UiPath org / tenant: deloivqbaydk / DefaultTenant
- Test Manager: https://cloud.uipath.com/deloivqbaydk/DefaultTenant/testmanager_/
- Test Manager project key: DNZTRAIN
- Orchestrator folder: Shared/OracleFusion
- Login credential asset: Oracle_Fusion_P2P_Test (type Credential, in Shared/OracleFusion)

Mode: CREATE-MISSING
(Use CHECK-ONLY to report without changing anything.)

## Steps

1. Login. Run `uip login status`. If the organization or tenant is not the one above, stop and
   ask me to run `! uip login` (or `! uip login --profile <name>`). Do not check anything in the
   wrong org.

2. Test Manager project. Find DNZTRAIN with `project list --filter`. Record its key, name, id
   and URL. If it is missing, stop and tell me. Never create the project.

3. Folder. Look up Shared/OracleFusion by exact path. If it is missing, list the folders this
   login can see, so I can tell "does not exist" from "no access".
   - In CREATE-MISSING mode, announce it, then create OracleFusion under Shared.

4. Link. Read the project's default folder from `project settings get`, and compare its key
   with the folder key from step 3.
   - If it is empty and the mode is CREATE-MISSING: announce it, then `set-default-folder`.
   - If it points to a different folder: do not change it. Report both keys and ask me.

5. Credential asset. Look for Oracle_Fusion_P2P_Test in Shared/OracleFusion and confirm it is of
   type Credential. If no assets at all are visible, say the login may lack Assets.View.
   - In CREATE-MISSING mode, announce it, then create it with the placeholder value
     `CHANGE_ME:CHANGE_ME`, Global scope, and the tenant's credential store. Put "PLACEHOLDER"
     in the description. I will set the real username and password myself.

6. Who the asset signs in as. Read only the username, from the asset's list/get metadata
   (`CredentialUsername`, and any per-user or per-robot values).
   - Never use `assets get-asset-value`, because it returns the password.
   - Never read, print or store a password.
   - If the username is empty, record "not visible to this login", not "blank".
   - If the asset still holds the placeholder, record "placeholder - not set".
   - The sure check is a robot reading the asset at runtime. Do not run one without asking me.

7. Can tests run? Check, read-only, whether the folder has a machine and a robot (an unattended
   robot, or a user with a robot) assigned. Report what is missing. Do not assign anything.

## Output

Back up the existing run-config.json first (run-config.<checkedAt>.bak.json). Then write
run-config.json with:

- checkedAt
- status: ready | pending-credential | not-ready
- blockers: one plain sentence each
- uipath: org and tenant
- testManager: key, name, id, URL, defaultFolderKey
- orchestratorFolder: path, key, exists, linkedToTestManagerProject, createdBySetup (date, or null)
- loginCredentialAsset
- credentialAssets[]: name, key, type, scope, folder, exists, isPlaceholder, signsInAs,
  signsInAsNote

Never write secrets to the file.

Finish with a short table: each check, ✅ or ❌, and each change made.

Don't explore the application yet.
