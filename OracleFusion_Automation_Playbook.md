# Oracle Fusion automation playbook (dev16 tenant)

How to drive `fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com` reliably, both for exploratory sessions run by an agent (`uip rpa uia`) and for UiPath workflows (`uix:N*` activities). Everything here was **verified** on screen between 2026-11-20 and 2026-11-22 unless marked **Standard** (Oracle default, not clicked here) or **Open**.

- Business rules, routing, personas and blockers: `specs/OracleFusion_Tenant_Findings.md` (§3–§8). This playbook covers *how to drive the UI*.
- Evidence and session notes from charter P2P-01: `specs/charter-p2p-requisition-to-payment.md`, `P2PGuide/` (text captures, surprises, documents).
- Helper script: `P2PGuide/tools/of.ps1` (§10).

**Contents:** 1 Ground rules · 2 URLs and ready text · 3 Input methods · 4 Sign-in and user switching · 5 Requisitions (Redwood) · 6 BPM Worklist approvals · 7 Cleanup · 8 Not yet driven (PO, receipt, invoice, payment) · 9 Reading data and evidence · 10 Agent tooling (`uip rpa uia`, helper script) · 11 Test Manager capture · 12 Workflow-authoring guidance · 13 Known traps checklist

---

## 1. Ground rules (always)

- **Sign-in:** type the username only. The human types the password. Never read or store a password.
- **Announce every write** before making it: create, submit, approve, reject, request information, withdraw, cancel, receive, validate, pay, void.
- **Own documents only.** Casey's worklist and requisition list contain other teams' items (catch-all rule B0). Identify your documents by number, and put **"Test UiPath <charter-id>"** at the start of every description and comment so they are easy to find.
- **Clean up** everything created; ask before voiding a payment.
- **US1 Business Unit only.**
- **Never click:** Edit Rules, Edit task, Save / Commit task / Reset / Revert (BPM admin), Start Synchronization, Security Console Edit / Reset Password / Reset MFA. See Findings §9.5.

---

## 2. URLs and ready text

Base: `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`. Navigate by setting `location.href` (agent) or `NGoToUrl` (workflow); it is much faster and steadier than menus.

| Page | Path | Wait for (ready text) | Title |
|---|---|---|---|
| Home | `/fscmUI/faces/FuseWelcome` | `Good morning/afternoon/evening` | Oracle Fusion Cloud Applications |
| Requisitions (Redwood "Shop") | `/fscmUI/redwood/procurement/requisitions` | `Create Noncatalog Request` **and** `My recent requisitions` | Oracle Applications |
| Noncatalog request form | `…/requisitions/tabbar/shopping/create_noncatalog_request` | `Item Description` | Noncatalog Request - Edit |
| Cart | `…/requisitions/tabbar/shopping/shoppingcart` | `Approval Amount` | Shopping Cart - View |
| Requisition details | `…/tabbar/shopping/requisitiondetails?…requisitionHeaderId=<id>` | `Approval Amount` and `<number><status>` | Requisition Details - View |
| Requisition header edit | `…/tabbar/shopping/editrequisition-header` | `Overriding Approver` | Requisition - Edit |
| Approvers (View Approvers) | `…/tabbar/shopping/approval-history` | `Pending approval by` / `Approved by` | Approval History - View |
| BPM Worklist (My Tasks) | `/integration/worklistapp/faces/home.jspx` | `My Tasks` | BPM Worklist |
| BPM task configuration | `/integration/worklistapp/faces/administration.jspx?selectedAdminTab=taskEditor` | `Tasks to be configured` | |
| BPM approval groups | `…/administration.jspx?selectedAdminTab=approvalGroup` | `Groups` | |
| Security Console | `/hcmUI/faces/FndOverview` | `User Accounts` | |
| Sign-in (IDCS) | `https://idcs-dfd9d303fd844502b1bca6b30a13b968.identity.oraclecloud.com/ui/v1/signin` | `Username` | Cloud Sign In |

**Load times and waiting**
- Poll the ready text every 5 s with a timeout of **≥ 180 s**. Never use fixed delays; a blank page is normal.
- The **first Redwood load after sign-in** sat on just "Skip to main content" for over 2 minutes, then later loads took 2–16 s. Treat a first-load timeout as "wait again", not as an error.
- Redwood details pages render in about 2–10 s; BPM about 20 s; Approve/Reject in BPM about 5–10 s.
- Redwood numbers and statuses run together in page text: `204163Pending approval`, `204162Canceled`. Match `"<number>(Pending approval|Approved|Withdrawn|Canceled)"`.

**Navigator (if a URL is unknown):** `Link "Navigator"` (hamburger) > click `Text "Procurement"` to expand > Purchase Requisitions / Purchasing / My Receipts. Home group tabs (`groupNode_*`) do **not** switch with DebuggerApi, so don't use them.

---

## 3. Input methods: what works where

Default to **DebuggerApi** (Chromium API). It needs no window focus, so the person at the PC can keep working. Use hardware events only where the table says so, and batch those steps.

| Element | DebuggerApi | Simulate | Hardware | Notes |
|---|---|---|---|---|
| Redwood links, buttons, `TabPage "Cart"`, `Button "More Actions"` | ✅ | | | |
| Redwood More Actions menu: View Approvers, Save for Later, **Cancel** | ✅ | | | |
| Redwood More Actions menu: **Delete** | ❌ menu stays open | ❌ | not tried | Use Cancel instead (§7) |
| Redwood text inputs (Item Description, Price, Cancellation Reason) | ✅ clear mode **SingleLine** | | | |
| Redwood list-of-values (Category, UOM, Supplier, Overriding Approver) | ✅ with retries | | | See §5.3 |
| Withdraw dialog `Button "Edit"`, Cancel dialog `Button "Cancel Requisition"`, Save for Later confirm | ✅ | | | |
| IDCS `InputBox "Username"` | ✅ | | | |
| BPM task links in My Tasks | ✅ | | | Opens a **new window** |
| BPM task **Approve / Reject** buttons | ⚠️ no visible change | ⚠️ | ✅ | §6 |
| BPM Comment dialog `Link "Submit"` | ✅ | | | |
| BPM "Go to rule" / rule-set links, rule rows | ❌ | ❌ | ✅ | Findings §9.3 |
| Payables **Invoice Type** list (native `<select>`) | ✅ **type first letter + `[k(tab)]`** | | ✅ | Verified AP-01. `uia interact select` works but takes focus. |
| ADF **Invoice Actions** menu | ✅ on the inner `Link`, not the MenuItem | | | §8.1 |
| ADF key flexfield (Distribution Combination ID) | ✅ type the full combination + `[k(tab)]` | | | §8.1 |
| `uia interact hover` | — | — | ⚠️ always hardware (moves the real mouse) | Avoid; read submenus from the DOM |
| Mouse wheel, screenshots | — | | ✅ needs focus | |

**Focus batches.** Hardware events and screenshots need the browser in front. Windows' foreground lock refuses this ("Cannot bring the target application in the foreground") while someone is typing elsewhere.
- Do all background steps first and queue screenshot names (`pending-shots.txt`).
- Tell the human "Focus batch: about N seconds, please leave the PC", run, then say it's done.
- If focus is refused, don't loop: keep the page text and mark the screenshot pending.
- Robot machines: set `HKCU\Control Panel\Desktop\ForegroundLockTimeout = 0`.

**Typing:** never Ctrl+A inside ADF tables (it selects every row and Oracle drops the value). Use "Empty field (single line)".

### 3.1 Lessons from building the E2E automation (2026-11-23, OFP2P:227)

**How to tell a value really reached the page:** a typed or selected value has only reached Oracle's page code when:
- the field's red **"Required"** hint disappears, and
- any dependent fields **enable** (for example, Taxpayer ID enables once Country is set).

A field that merely displays the text proves nothing. After every fill, re-snapshot and check both. Count the visible hints with `Text "Required" [ref=…]` lines that are not `[invisible]`.

**Simulate input does NOT commit values in Redwood (Oracle JET) forms.** It writes the DOM value, but JET's model never sees a change event:
- the hint stays, dependent fields stay disabled, and Continue / Submit will fail.
- Simulate is fine for **clicks that navigate**: home group tabs (`groupNode_*`) and Procurement tiles.
- Do not use Simulate for typing into, or choosing values in, Redwood or JET forms.

**DebuggerApi (Chromium API) sends trusted events** and is the method to use for Redwood form input. Known gaps:
- **IDCS sign-in page:** DebuggerApi could not attach in Edge ("close any extension pop-up"), and the first attempt kept only "C" of the username. Recheck in Chrome.
- **Robot sign-in:** S0 typed the password with Simulate, and Oracle did not accept the sign-in, which is consistent with the above. Recheck with DebuggerApi in Chrome.

**Redwood search-select dropdowns** (`oj-searchselect`, for example Business Relationship, Procurement BU, Request Reason, Country, Organization Type):
- `uip rpa uia interact select` fails with a COM HRESULT error, so don't use it on these.
- Typing the value plus Enter does **not** commit it.
- **What works:** click the field to open the list (or type a filter), then click the option.
- Highlighting splits the option's label into several text nodes ("New Zeal" + "and"). Target the **grid cell** instead, which carries the full text: OR element *Dropdown Option Cell*, `<webctrl aria-role='gridcell' tag='DIV' visibleinnertext='{{optionText}}' class='oj-listview-cell-element' />`.
- `items` on the closed control does list the options, which is useful for reading valid values.

**Browser choice: use Chrome, not Edge** (user decision, 2026-11-23). In Edge:
- **sleeping tabs** discarded the background capture tab (`[discarded]`), and neither reload nor tab-select restored it;
- the extension then lost the page (`[content unreachable]`);
- snapshots and clicks failed with "Unexpected HRESULT … COM component".

If Edge must be used, turn off *Save resources with sleeping tabs* (`edge://settings/system`), or exempt the Fusion host.

**Window selectors:**
- **Volatile attribute:** Fusion pages carry a random `htmlwindowname='…'` per tab. Remove it (evaluate, then `target-app update-definition --selector`) **before** `create-screen`; otherwise every run fails.
- **Titles:** stabilize with wildcards, for example `title='*Oracle Fusion Cloud Applications*'` (home) or `title='Registration Internal*Oracle Fusion Cloud Applications'` (wizard).

**Supplier registration wizard:**
- **URL:** `/fscmUI/redwood/supplier-registration-internal?SupplierRegId=<id>`. **Opening the wizard already reserves a registration ID**, so log it for cleanup.
- **Supplier Management landing page:** `/fscmUI/redwood/suppliers/landing-page/overview`.
- **Verified 2026-11-23 (Chrome + DebuggerApi):** every page 1 field committed and 0 "Required" hints remained. The pattern: open each short dropdown with a click, then click the option row; for Country, type the name to filter, then click the first row.
- **Duplicate check on Continue:** Oracle shows "Some issues need your attention — This company is already a supplier". It fires on the **Taxpayer ID** (3434573456 belongs to supplier 1502), and probably on similar names too. Generate a **unique Taxpayer ID and company name per run**, for example `UIPTST Supplier <yyMMddHHmm>` and a 10-digit Taxpayer ID from the timestamp.
- **Page 2 (Contacts) defaults:** Admin contact = Yes, User account = Yes, all user roles ticked, phone country NZ (from the Country field).
- **Field IDs:** `CompanySearchField`, `busRelSelectSingle`, `prcBUSelectSingle`, `reqReasonSelectSingle`, `countrySelectSingle`, `taxOrganizationType`. Taxpayer ID has a generated ID (`ui-id-NN|input`), so match it by its label.

**Fusion home:**
- It lands on the **Sales** tab, so click `groupNode_procurement` (Simulate) first.
- The "My Receipts" tile is `itemNode_procurement_MyReceiptsNew_*`, which is My Receipts (New), so there's no need for "Show More".

**Wizard pages 3–7 (verified 2026-11-23, Chrome + DebuggerApi, draft 300000342326536):**
- **Option matching must be exact.** `visibleinnertext='*Veteran Owned*'` also matches "Service-disabled Veteran Owned", and the first match wins. The OR element *Dropdown Option Cell* now uses exact `visibleinnertext='{{optionText}}'`. When a prefix is needed, pass the wildcard in the value, for example `"216 Queen Street Northcote Point Auckland 0627*"`.
- **Address lookup (page 3):** type the address into *Enter Address*. Suggestions render as list grid cells, so *Dropdown Option Cell* matches them. Click the cell; the Required hint then clears.
- **Table-style search-selects** (Branch Number, page 5) show results as a table (`oj-table`, columns Branch Number / Bank / Branch), not a list. Use OR element *Dropdown Table Option Row*, `<webctrl tag='TR' parentclass='oj-table-body' visibleinnertext='{{optionText}}' />`, with optionText `"1010*"`. Picking the row auto-fills Bank and Bank Branch.
- **JET commits a text field when it loses focus.** The last field typed before Continue still shows "Required" until focus moves. Clicking Continue blurs it, so this is harmless; just don't treat that one hint as a failure.
- **Bank account duplicate check:** Continue on page 5 fails with "Some issues need your attention — A record with this combination of values already exists" when branch + account number + suffix already exist (54334467 is taken). Generate a **unique account number per run** (`MMddHHmm`).
- **Bank Country** defaults from the Tax Country, so there's no need to set it.
- **Products and Services (page 6):** a category tree table. Tick a category through its row's selector box. OR element *Category Checkbox* is `<webctrl tag='TR' parentid='table' visibleinnertext='*{{optionText}}*' /><webctrl tag='INPUT' type='checkbox' class='oj-selectorbox' />`. Confirmation text: "1 selected".
- **Questionnaire (page 7):**
  - Radio buttons are `INPUT` under `parentname='rs-questionnaire'`, matched by `aaname='*a. Full Compliance'` (OR *Questionnaire Answer Radio*).
  - Choosing an answer shows **Add Attachments (0)**, and the attachment is mandatory.
  - The panel "Response attachments for question 1" has a drop zone (`oj-filepicker-container`) and Close (`id='responseMCSSAttachCloseDrawer'`). **Upload without the native dialog:** wrap the drop-zone click in **Browser File Picker Scope** (`NBrowserFilePickerScope`, SingleFilePath), which answers the dialog through the browser API. The `uip rpa uia interact` CLI has no upload command, so upload can only be exercised from a workflow.
- **Submit** (page 7) replaces Continue (`aria-label='Submit'`). After Submit the app returns to Supplier Management.

**Building elements and workflows (CLI lessons):**
- **Strict selector updates:** `target-anchorable resolve-defaults` often adds an anchor, so `update-definition` with a strict selector then fails ("search steps not enabled: Strict selector"). Run `remove-anchor --index 0` first; it converts the target to strict.
- **Stale refs:** after `selector-intelligence evaluate` or `target-anchorable validate`, element refs from the previous snapshot can be invalid ("The UI element is invalid"). Re-snapshot before clicking.
- **Linking and UiElement arguments:** `object-repository link-screen` / `link-elements` fail with "property 'Target' / 'TargetApp' was not found" when the workflow declares a **`UiElement` argument**, even though `validate` is clean. Link first, then add the argument (`InArgument(ui:UiElement)`) and the card's `InUiElement` / `OutUiElement`.
- **Type name:** `UiElement` in XAML is `ui:UiElement`. A test case using it needs assembly references `UiPath.UIAutomationNext.Activities` and `UiPath.UIAutomationCore`.
- **Browser handoff:** S0 outputs `out_Browser` (the card's OutUiElement). S1 onwards attach with `InUiElement=[in_Browser]`, `OpenMode=Never`, so they never pick a different Chrome window.
- **Analyzer rules enforced as errors here:**
  - **ST-DBP-002:** at most 20 arguments per workflow. Group static data in a `Dictionary(Of String, String)` (S1 `in_Profile`).
  - **ST-SEC-008:** declare the `SecureString` variable in the same scope as Get Credential and Type Into.
- **No window activation:** set `ActivateBefore="False"` on DebuggerApi clicks and types so the robot never brings Chrome to the front.
- Item tiles have stable IDs `itemNode_procurement_<Name>_*`; quick actions are matched by name plus `group='groupNode_procurement'`.

**Robot run lessons (debug runs, 2026-11-23):**
- **Type Company last on wizard page 1.** A value typed right after the wizard opens is cleared while the page finishes initialising; Continue then silently stays on page 1.
- **Get URL reads the wrong tab** when several Fusion tabs exist. Read the `url` attribute of an element on the page instead (Get Attribute `url` on Company Input).
- **Re-rendered elements (InvalidNodeException):** Register Supplier (landing page still loading) and Add Attachments (re-renders after the questionnaire radio). Wrap these clicks in a Retry Scope (3 attempts, 2–3 s).
- **Browser File Picker Scope** needs the UiPath Chrome extension's **Allow access to file URLs** (chrome://extensions > UiPath > Details). A browser setting: ask the user.
- **Close leftover robot windows before a run.** Oracle sessions expire in about 2 hours. An expired robot tab signs back in to the page it was on (for example an old draft wizard), and selectors then attach there. `uip rpa uia interact window close <wRef>` closes one robot window. Never close the user's own windows.
- **Ending a suspended debug session:** there is no `stop`. Run `debug continue` repeatedly until the state is Completed; each call bubbles the exception up one scope.

**S2–S7 capture (2026-11-23, Chrome + DebuggerApi, all background input):**
- **Supplier registration approval** is a BPM task "Supplier Registration Request NNNNN for <company>:" (parallel, first responder wins; Casey is one approver). Approving creates the supplier at once (UIPTST Supplier 2611232030 = supplier 1503, site = address name HQ). The FYI is "... Was Approved:", so match the task title with the trailing colon right after the company name.
- **BPM Approve works with a DebuggerApi click** in Chrome (opens the Approve dialog; Comment `it_apprej::content`, commit link `ctb_apprej_submit`). This replaces the earlier "needs a hardware click" note, which was Edge. The task window closes itself after Submit.
- **Draft-exists dialog:** Register Supplier shows `internalDraftRequestExistsDialog` (Start Over / Continue Registration) when the user has an unfinished draft. Start Over discards it and opens a new SupplierRegId.
- **Redwood LOVs (requisition form):** options are `LI aria-role='row'` (OR *LOV Option Row*, `visibleinnertext='*{{optionText}}*'`). Category: type the code ("206.61"). UOM: type "Each", pick "Ea". Supplier: type the full name; the first attempt often loses the text, so retry.
- **Buyer** comes from the category (206.61 Monitors → Calvin Roth). Casey can still stage the line in Process Requisitions (`/fscmUI/redwood/process-requisitions/manage`): search by requisition number, tick the row, Stage, then Publish → banner "Purchase order USnnnnnn created" + View purchase order.
- **PO** opens in Edit, status Incomplete; Submit makes it receivable straight away (no PO approval for 2,190 USD).
- **My Receipts** (`/fscmUI/redwood/self-service-receiving/main`): smart search, type the PO number + Enter, tick the row, Receive Now → "Receipt NNNNN created".
- **Invoice (ADF):** Identifying PO + Tab fills supplier/site; the first Go (Match Invoice Lines) can open the Identifying PO search dialog (Search, pick the PO cell, OK), then Go again opens the match dialog (row checkbox, Apply, OK). OK saves the invoice. Invoice Actions > Validate → status link "Validated" (amount = line × 1.095).
- **Reading page text** with `uia interact browser eval <tab> "() => document.body.innerText"` (the script must be an arrow function).

**Stability analysis (2026-11-24, runs 1–10) and the patterns now in the workflows:**
- Async re-render (InvalidNode) → every post-action click is in its own Retry Scope (4×3 s).
- Clicks that do not commit (cart Submit, run 9: requisition stayed Incomplete) → act-and-verify: after each write, check the next state (Check State / Get Text) and retry the action if it did not land. Verify with REST (`purchaseRequisitions` DocumentStatus) when in doubt.
- Approvals arrive 1–12 min later; the BPM worklist did not list registration 35012 at all → approve from the Redwood **Notifications** panel (inline Approve, no window), retried up to ~10 min.
- Leftover state → S1 Start Over on the draft dialog; S3 parks a non-empty cart (Save for Later); the test case closes the robot browser in Finally.
- Debug runs pause on every caught exception in a Retry Scope and `continue-retry` re-runs only the failed activity → use `uip rpa run` for end-to-end runs.
- **"Submit too early" (confirmed 24/11, run 12):** Redwood primary buttons (cart Submit, PO Submit) are visible and clickable before the page has finished wiring them. A DebuggerApi click then does nothing visible: requisition 204173 stayed *Incomplete*, PO US165369 stayed *Incomplete* (API). The same Submit clicked on the settled page worked at once (US165369 → Pending Approval). Pattern: Retry Scope { click Submit; Check State for the page Oracle returns to (cart → Requisitions home with Create Noncatalog Request; PO → Process Requisitions search) with Timeout 45–60 s; throw if absent }.
- **Slow Redwood loads re-render the tab bar:** the Cart tab was found, then replaced when the home finished loading (InvalidNode after 3 min). Every first click on a freshly loaded Redwood page sits in a Retry Scope.
- **Try/Finally without a Catch does not run its Finally when the exception is unhandled** (Windows Workflow semantics): the test's "close robot browser" never ran and robot windows piled up. Catch the exception into a variable, close the browser in Finally, then rethrow after the Try.
- **PO number:** the "Purchase order USnnnnnn created" banner after Publish is not reliable (absent in run 13 though the PO was created). Find the PO instead in Purchase Orders (`/fscmUI/redwood/purchase-orders/manage`): smart search with the requisition number + Enter, read the order link in that row (`<webctrl tag='TR' visibleinnertext='*{req}*' /><webctrl tag='A' class='oj-link' />`), open it, Submit, and confirm the return to the Purchase Orders search.
- **Closing windows:** close only the window ref you opened or the robot opened in this run; match by exact title/URL, never "any Fusion window".
- **Redwood slow spells recur in daytime too** (24/11 09:15–09:25: Supplier Management took 4 min 41 s to render). First-load waits on Redwood pages are now 300 s; a run in a slow spell takes 40+ min.
- **Never run ANY `uip rpa` command with `--project-dir` while a `uip rpa run` is in progress** (validate, build, and also `uip rpa uia snapshot` / `interact browser eval`): they regenerate the compiled workflow assemblies under `.local`, and the running job then fails with "Could not load file or assembly OracleFusion_AgenticTesting.Workflows_<name>" at the next Invoke (run 18, 24/11). Edit sources during a run if you must, but validate and build only after it ends.
- **Wait design (user rule, 24/11): every UI action times out in 10 s; long waits are polling loops.** Two levels: an inner Retry Scope polls the first element of a page with 10 s checks and no reload (about 2 min, so a slow Redwood render is not restarted); an outer Retry Scope reloads the page (NGoToUrl) and tries again, which is also how async state is awaited: approvals (Notifications bell, our row's Approve), PO lines becoming receivable (My Receipts), POs appearing (Purchase Orders search). Use the UI for these checks for now, not REST (user preference). Navigate by URL (e.g. Supplier Management `/fscmUI/redwood/suppliers/landing-page/overview`) instead of Home tabs and tiles: on 24/11 the Supplier Management tile click landed but Home did not navigate.
- **S0 with 10 s checks:** "no Username box within 10 s" does not mean "signed in". S0 polls: Username box → sign in; else Home greeting → already signed in; else retry (~7 min), then polls the greeting after sign-in.
- **Chrome profile:** a new robot browser opens in Chrome's *last-used* profile. On 24/11 that switched to Profile 2 ("UiPath-Training"), where the UiPath extension has no file access, and the questionnaire upload failed. S0 launches Chrome with `UserDataFolderMode=DefaultFolder` and, when set, `--profile-directory="<profile>"`, taken from the S0 argument `in_ChromeProfile` or else the per-machine environment variable `UIP_CHROME_PROFILE` (for example `Profile 4`, the folder name under `%LOCALAPPDATA%\Google\Chrome\User Data`). Set the variable on each machine to the profile where the UiPath extension has **Allow access to file URLs** on; unset, Chrome uses its last-used profile. Setup: `Prompts/setup/machine/M3-chrome-profile-and-extension.md`.
- **Sessions expire overnight** (seen 07:13 NZT): the first page is the IDCS sign-in again. S0 handles this with the credential asset; the human never needs to sign the robot in.
- **First Redwood load after sign-in can exceed 2 min**: the first Redwood clicks after S0 (Procurement tab, Supplier Management, Register Supplier) now wait up to 180 s.
- **Verify with REST, not only the screen:** `GET purchaseRequisitions?q=Requisition='NNN'` showed run 9's requisition as *Incomplete* while the robot had logged "submitted". `GET /bpm/api/4.0/tasks?keyword=<doc>&assignment=ALL&status=ASSIGNED|COMPLETED` shows whether an approval task exists and its state (registration 36014 had only the "Was Approved" FYI, so it was already approved).
- **Stopping a `uip rpa run`:** the job runs in a long-lived `UiPath.Executor.NetCore.exe` (one per robot session, reused across jobs). Stop the process whose start time matches the job, after checking the log tail shows it is still running.
- **Environment:** around 00:00 NZT on 24/11 the Redwood pages stopped rendering for minutes (stuck on "Skip to main content" with hidden content) while ADF pages and REST worked. Check a Redwood page loads before starting a run.

**Package versions:** UIA **26.10.7** failed `target-app resolve-defaults` on the IDCS sign-in tab ("Failed to serialize the target into XAML"). **26.10.9** fixed it.

---

## 4. Sign-in and switching users

1. Sign out: avatar `Settings and Actions` > `Sign Out` (Home or any Redwood page).
2. The tab lands on **Cloud Sign In** (IDCS). Element: `InputBox "Username"` (re-snapshot; its ref changes after each render). Type the user name, for example `CASEY.BROWN`, `ANITA.KENNEDY`.
3. **Stop.** The human types the password into `InputBoxPassword "Password"` and clicks `Button "Next"`. (MFA may follow.)
4. Confirm sign-in: title becomes "Oracle Fusion Cloud Applications" and the host is the Fusion pod. Then check the user name on the page (Redwood header, BPM header "Casey Brown").

Notes:
- BPM task windows and BPM tabs opened under the previous user close or go stale; re-capture the top level (`Get-Tabs`).
- Tab refs (`bNNNN`) renumber on every top-level capture.
- Usernames: CASEY.BROWN (requester, buyer, receiver, AP), ANITA.KENNEDY (Casey's manager), Calvin Roth (override approver / buyer), WILLIAM.TAYLOR (top approver). See Findings §5.

---

## 5. Requisitions (Redwood Self Service Procurement)

### 5.1 Create a noncatalog request

Path: Requisitions page > `Button "Create Noncatalog Request"` (ready text `Item Description`).

| Field | Required | How to fill | Verified value used |
|---|---|---|---|
| Item Description | Yes | `InputBox "Item Description"` | `Test UiPath P2P-01 R1 below 50K boundary` |
| Category | Yes | LOV: type `Comput`, pick the row containing `Text "Desktops"` | Desktops |
| Quantity | (defaults 1) | | 1 |
| UOM | Yes | LOV: type `Each`, pick the row with `Text "Ea"` | Ea |
| Price | Yes | `InputBox "Price"` (the visible one, not `[invisible]`) | 45,662.09 |
| Currency | defaults | USD | |
| Supplier | No (but use it) | LOV: type `Dell`, pick the row containing `Other name: Dell Inc` | Dell Inc. |
| Supplier Site | defaults | Dell US1 after supplier pick | |

Then `Button "Add to Cart"`. The cart badge on `TabPage "Cart"` increments.

**Defaults from the requester** (cart summary): Requester Casey Brown; Deliver-to **Seattle**; Destination **Expense**; Charge To **101.10.15910.000.000.000**. Business unit US1.

### 5.2 Cart and submit

- Open the cart with `TabPage "Cart"` (it is a tab page in the Redwood bottom bar, not a link). Ready text `Approval Amount`.
- The cart shows **Requisition NNNNNN** as soon as the first line is added. **Record the number here**; it is the same number after submit.
- Summary fields: Subtotal, **Nonrecoverable Tax**, **Approval Amount**, Description, Justification, Requester, Deliver-to, Destination, Charge To.
- `Button "Submit"` submits. Afterwards the requisitions list shows `Pending approval Requisition NNNNNN`.
- Requisition summary > `Edit` opens the header edit page (Description, Justification, **Overriding Approver**, Requester, Deliver-to, Charge account). Confirm with `Button "Update"`.
- **The cart summary never displays Justification**, even after it is saved. The approval task shows it. Don't use the cart to verify Justification.
- The cart holds **one requisition at a time**. To leave a requisition without submitting: cart `More Actions` > `Save for Later` > confirm `Button "Save for Later"` ("Your shopping cart will be cleared and its contents will be saved to requisition NNN").

### 5.3 Redwood list-of-values (LOV) recipe

1. Re-snapshot and find the **visible** `DropDown "<Field>"` (skip `[invisible]` copies).
2. Type the search text with DebuggerApi.
3. Wait about 6 s, re-snapshot. **The field often re-renders and loses the first typed text.** If no option rows appear, find the new focused ref and type again.
4. Options are `TableRow`s. Find the line that contains the option text, then click the nearest `TableRow` above it.
5. **Search highlighting splits text nodes:** typing `Desktop` turns "Desktops" into "Desktop" + "s". Search with a prefix that differs from the option (`Comput` for Desktops) or match a secondary line (`Other name: Dell Inc`).
6. Confirm by reading the field back: `DropDown "Category" … : Desktops`.
7. **Never type into an LOV twice without clearing it.** A retry loop produced "Dell Inc.Dell". Clear with SingleLine-mode typing, then pick again.
8. Overriding Approver: type the **full name** ("Calvin Roth") to get one unique `Button "Calvin Roth"` option.

### 5.4 Amounts and the 50K boundary

- **Approval Amount = Subtotal + Nonrecoverable Tax** (9.5% for Seattle / US1). Approval rules test the approval amount.
- Compute the unit price backwards: price = target ÷ 1.095, then check the rounding on the cart.

| Target approval amount | Unit price (qty 1) | Tax |
|---|---|---|
| 49,999.99 | 45,662.09 | 4,337.90 |
| 50,000.00 | 45,662.10 | 4,337.90 |
| 50,000.01 | 45,662.11 | 4,337.90 |
| 54,750.00 | 50,000.00 | 4,750.00 |

- Observed routing (P2P-01): **every** requisition gets a Casey Brown step (catch-all rule `RequisitionApprovalCaseyBrown`). Under 50K does **not** finish approval on its own. At 50K or more: Anita Kennedy first, then Casey. With an override approver: that approver, then Casey (Anita skipped).

### 5.5 Requisition details page

- Open from the list: click `Text "Requisition NNNNNN"` (the list paginates 5 pages; recent ones are on page 1).
- Header page text: `NNNNNN<Status>`, Entered By, Business Unit, Creation Date, Description, Justification, Subtotal, Nonrecoverable Tax, Approval Amount, Lines.
- `Button "Edit"` (visible one) and `Button "More Actions"`. The menu items depend on status:
  - Pending approval: View Approvers, Duplicate, View Life Cycle, Reassign, View PDF, …
  - Withdrawn: Duplicate, View Document History, View Life Cycle, Reassign, View PDF, **Cancel**, **Delete**
  - Approved: includes **Cancel**
- **View Approvers** goes to `approval-history`: `Pending approval by <name>` followed by the rule, for example `Header Hierarchy: RequisitionApprovalCaseyBrown`. This is the quickest routing check; no BPM needed.

### 5.6 Withdraw, edit, resubmit

- There is **no "Withdraw" action**. `Button "Edit"` on a pending requisition opens dialog `withdrawWarningDialog`: "Edit requisition? The requisition is pending approval. It will be withdrawn and removed from the approval process for you to edit." Confirm with the `Button "Edit"` **inside** that dialog (the first `Button "Edit"` after the `withdrawWarningDialog_layer` line in the snapshot).
- The requisition returns to the cart with the **same number**. Edit and Submit again; approval restarts from the start.
- To leave it withdrawn without resubmitting: cart `More Actions` > Save for Later. The status becomes **Withdrawn**.

---

## 6. BPM Worklist approvals

1. Open `/integration/worklistapp/faces/home.jspx` (ready `My Tasks`). Tasks are titled `Approve Requisition NNNNNN`. FYIs look like `Requisition NNNNNN Approved` and `Document (Purchase Order) USnnnnnn (Requisition NNNNNN) Implemented`.
2. **Open only your own task by number.** Clicking the title (DebuggerApi) opens a **separate Chrome window** titled "Approve Requisition NNNNNN" (URL `/fscmUI/faces/adf.task-flow`). Re-capture the top level to get its tab ref.
3. The task page shows: Actions `Approve` `Reject`, amount, requester, description, number, **Justification**, lines, charge account, approvers history, and `Edit Requisition`.
4. **Approve** (or Reject) opens a modal with a Comment box. The DebuggerApi/Simulate click on Approve showed no visible change; a **hardware click** opened the modal. Next time try DebuggerApi, then look for `Link "Submit"` before falling back to a hardware-click focus batch.
5. Type the comment (`Test UiPath <charter> …`), then click the modal's **`Link "Submit"`** (not the Approve button again).
6. Success text: "The action performed was completed successfully. Please close this window." Close the window.
7. Verify in My Tasks (`Link "Refresh Page"`): the task becomes the FYI `Requisition NNNNNN Approved`, or check View Approvers on the Redwood page.

**Not yet driven (Open):** Reject and Request More Information as Anita; answering an information request as the requester. These belong to charter P2P-02.

---

## 7. Cleanup recipes (verified 2026-11-22)

| Start status | Steps | Helper |
|---|---|---|
| Approved | Details > `More Actions` > `MenuItem "Cancel"` > dialog `cancel-header-dialog`: `InputBox "Cancellation Reason"` (required, max 240) > `Button "Cancel Requisition"` | `Cancel-Req` |
| Pending approval | Withdraw (§5.6) > cart `More Actions` > `Save for Later` > confirm. Status Withdrawn; this removes the approver's task. Then Cancel as above. | `Withdraw-Req`, then `Cancel-Req` |
| Withdrawn / Incomplete | Cancel as above | `Cancel-Req` |

- Success: toast "Requisition lines canceled"; header `NNNNNNCanceled`, approval amount $0.00, line shows the cancellation reason.
- **Delete** (More Actions) does not fire in the background, and the cart has no requisition-level delete. Cancel is the reliable cleanup.
- POs, invoices and payments: not created yet. Cancel PO / Cancel invoice / Void payment paths are **Standard** (Findings §2), and voiding a payment needs the human's approval first.

---

### 7.1 Cleanup through REST (verified 24/11, S9_Cleanup.xaml)

All calls use Basic auth (Casey) and `Content-Type: application/vnd.oracle.adf.action+json` for actions.

| Document state | Call | Result |
|---|---|---|
| Invoice (any, unpaid) | `POST /invoices/action/cancelInvoice` `{"InvoiceNumber","BusinessUnit","Supplier"}` | "Cancel Invoice has completed successfully" |
| PO Open, not received | `POST /purchaseOrders/{POHeaderId}/action/cancel` `{"cancellationReason","initiatingParty":"BUYER","cancelUnfulfilledDemandFlag":false}` | 200 |
| PO received/invoiced | cancel → 400 "invoiced or received schedules exist"; use `POST .../action/close` `{"closeAction":"CLOSE","closeReason"}` | 200 SUCCESS, status Closed (reversible) |
| PO Incomplete (draft) | cancel/close → 400 PO-2055153; use `DELETE /draftPurchaseOrders/{POHeaderId}` | 204; the requisition lines return, then cancel the requisition |
| Requisition Incomplete (cart / saved for later) | cancel → 400 POR-2010919 "must delete it"; use `DELETE /purchaseRequisitions/{RequisitionHeaderId}` | 204 |
| Requisition Approved, no PO | `POST /purchaseRequisitions/{id}/action/cancel` `{"cancelReason"}` | 200 |
| Requisition line staged in a document builder | cancel → 400 POR-2010924 "no requisition lines available"; remove the staged document in Process Requisitions first | open |

UiPath HTTP Request (`NetHttpRequest`) notes: a JSON body that starts with `{` in an attribute must be written `{}{...}` (XAML markup-extension escape); VB `Left()`/`vbLf` are not available in Portable projects (use `Substring`, `Environment.NewLine`); ST-SEC-008 needs a Get Credential inside **every** scope that uses the SecureString.

---

## 8. Not yet driven: PO, receipt, invoice, payment

Menu paths are in Findings §2.2–2.5 (mostly **Standard**). Known in advance:
- PO: Casey has the custom **Redwood Buyer** role. Process Requisitions is under Purchase Orders > Tasks. PO approval rules are unread (Findings §6.2), so record which stages fire.
- Receipt: Receive Items (self-service) or Receipts > Receive Expected Shipments. No approval, FYI only.
- Invoice: Payables > Invoices > Create Invoice. **Invoice Type needs hardware events** (focus batch). Whether invoice approval is switched on is **Open**.
- Payment: Pay in Full from the invoice, or Create Payment. Payment approval would route to **AP Payment Approvers** (Matthew Schnieder, Kerry Lane) if switched on (**Open**).

When these are driven, add a section here in the same shape as §5–§7.

### 8.1 Supplier invoice (manual, ADF), verified in AP-01, 2026-11-23

**Navigation**
- Invoices work area: `/fscmUI/faces/FndOverview?fndGlobalItemNodeId=itemNode_payables_payables_invoices`. Loads in about 7 s. Ready text `Scanned` + `Holds` (infotiles). Title "Invoice Workbench - Invoices".
- Tasks panel: the **unlabeled** `Image "Tasks"` on the right edge (DebuggerApi click). Then `Link "Create Invoice"` or `Link "Manage Invoices"`.
- Create Invoice title: "Create Invoice - Invoices - Oracle Fusion Cloud Applications". **Wait for the title**, not for "Invoice Number": that text also appears in the workbench table and gives a false ready.

**Header**
- Required: Business Unit, Supplier, Supplier Site, Legal Entity, Number, Amount, Type, Date, Payment Terms, Terms Date.
- Defaults: BU US1 (from the user), USD, Type Standard, Payment Terms Immediate, Date and Terms Date = tenant date (one day behind local in the morning).
- Supplier: DebuggerApi type `ABC Consulting[k(tab)]` with SingleLine clear. Autocomplete fills Supplier Number 1288, Site ABC US1, Legal Entity US1 Legal Entity.
- Payment Terms: type `Net 30[k(tab)]`.
- **Type (native `<select>`):** DebuggerApi type of the option's first letter + `[k(tab)]` (`S` = Standard, `P` = Prepayment) works **in the background**. Don't use `uia interact select` (it takes focus) or clicks (the native popup isn't in the DOM). After the supplier is chosen the options are Standard, Prepayment, Debit memo, Credit memo, Withholding tax, Retainage release.
- BU becomes read-only text after the first save.

**Lines**
- `Button "Expand Lines"`. Line 1 exists already (Type Item). The line `InputBox "Amount"` is the second "Amount" in the snapshot; the first is the header.
- Distribution: the key flexfield `InputBox` named **"Distribution Combination ID"** (id ends `kf1CS::content`). Type `101.10.15910.000.000.000[k(tab)]`. No Distribution Set defaults for ABC US1.
- Two `InputBox "Description"` fields (header and line). Re-snapshot before typing into the line one; refs go stale after each partial refresh.

**Actions**
- `Link "Save"` (also `Save and Close`, `Save and Create Next`, `Cancel`). After save: title text `Create Invoice: <number>`, status link `Not validated`, `Last Saved <tenant time>`.
- **Invoice Actions:** click the inner `Link "Invoice Actions"` (not the MenuItem), then the item's `Text "<name>"` via `Get-R` (fresh capture). Calculate Tax also saves.
- Validation result: the status chip is a link (`Link "Validated|Needs revalidation|Not validated"`). Clicking it opens the **Invoice Summary** popup with Validation, Accounting, Payments, Due Date and hold counts (Line Variance, Distribution Variance, Manual, System, Supplier Site). Read it from the DOM: `div[id*=popup]` with text "Invoice Summary".
- Typical holds: header excluding exclusive tax → **Line Variance**; missing distribution → **Distribution Variance** (one per line, tax lines included). Fix both, Save, Validate → `Validated`.
- Tax in US1 with ABC US1: 9.0% exclusive (CA San Mateo 2.5% + CA State 6.5%). Header amount must be item total × 1.09.
- **Cancel Invoice:** Invoice Actions > `Text "Cancel Invoice"` > warning "The invoice will be canceled. Do you want to continue?" > `Button "OK"`. Status becomes `Canceled`, totals 0.00. If the menu click doesn't open the dialog (the Invoice Summary popup was open), reopen the menu and click again.
- Approval submenu (DOM only, not clicked): Initiate, Withdraw, Resubmit, Force Approve.

**Manage Invoices**
- Tasks > `Link "Manage Invoices"`. Ready text `Manage Invoices` + `At least one is required`. Fill `InputBox "Invoice Number"`, then `Button "Search"`.
- Result columns: Invoice Number, Invoice Date, Creation Date, Supplier or Party, Supplier Site, Unpaid Amount, Invoice Amount, Applied Prepayments, Invoice Type, Source, Notes, Validation Status, Approval Status, Holds, Accounting Status.

---

## 9. Reading data and capturing evidence

- **Page text is the most reliable read.** Evaluate `document.title + '\n' + location.href.split('?')[0] + '\n' + document.body.innerText` and save it. This works in the background, survives re-renders, and doubles as evidence.
- In workflows, read numbers and statuses with **Get Text** on a labelled element, not from screenshots.
- Dialog state from the DOM: Redwood dialogs are `oj-dialog` elements with stable ids (`withdrawWarningDialog`, `cancel-header-dialog`, `delete-requisition-dialog`, `editInCartWarningDialog`, `requisition-canceled-success-message-toast`, …). An open dialog has `offsetParent !== null`. Use this to check whether a click opened a dialog.
- Evidence naming: `P2PGuide/text/p2pNN_MM_<screen>.txt` and `P2PGuide/shots/p2pNN_MM_<screen>.png`. Keep the same name for both, queue screenshots in `P2PGuide/pending-shots.txt`, and take them in focus batches.
- Keep `P2PGuide/documents.txt` (every document number and action, with time) and `P2PGuide/surprises.txt` up to date as you go, not at the end.

---

## 10. Agent tooling: `uip rpa uia` and `P2PGuide/tools/of.ps1`

**Set up (PowerShell):**
```powershell
. ./P2PGuide/tools/of.ps1        # once, to get Get-Tabs
Get-Tabs                         # lists Oracle Chrome tabs with refs, e.g. b1221
$env:OFTAB = "b1221"; . ./P2PGuide/tools/of.ps1   # bind helpers to that tab
```

| Helper | Purpose |
|---|---|
| `Get-Tabs` | Capture top level; list Oracle/BPM tabs and their refs |
| `Get-Snap <regex> [max]` | Capture the tab tree and grep it |
| `Find-Ref <regex>` | Grep the last tree without re-capturing |
| `Get-R <regex>` | Re-capture and return the first matching `eNNN` ref |
| `Invoke-Click <ref>` / `Invoke-HwClick <ref>` | DebuggerApi click / hardware click (needs focus) |
| `Set-Text <ref> <text>` | DebuggerApi type with SingleLine clear |
| `Wait-Page <regex> [sec]` | Poll page text every 5 s until it matches |
| `Get-PageText`, `Read-Page`, `Save-Evidence <name>` | Read page text; save it to evidence and queue a screenshot |
| `Pick-LovRow <field> <search> <rowText>` | Redwood LOV recipe (§5.3) |
| `New-NoncatalogToCart <desc> <price>` | Fill a noncatalog request up to Add to Cart (Desktops, Ea, Dell) |
| `Open-Cart`, `Get-Approvers <req> [evidence]` | Open the cart; open View Approvers for a requisition |
| `Withdraw-Req <req>`, `Cancel-Req <req> [reason]` | Cleanup (§7). These are writes: announce first |
| `Open-Task`, BPM helpers | BPM admin task navigation (rules exploration) |

**Snapshot rules**
- Element refs (`eNNNN`) change on **every** capture. Re-capture after each click that changes the page, and never reuse refs across captures.
- Pages carry hidden duplicates of buttons (`[invisible]`). Filter with `\[ref=e\d+\](?! \[invisible\])`.
- `Find-Ref` matches the raw, indented line, so don't anchor patterns with `^-`.
- Snapshots cap at about 3000+ elements (Redwood details pages are about 4000). Anchor on a nearby element (for example the dialog's `_layer` line) and search a window of lines after it.
- Keyboard input: `type <ref> "[k(enter)]"` is accepted but did not activate the Redwood Delete menu item.

**PowerShell gotchas**
- Variable names are case-insensitive: `$t` overwrites a helper's `$T`. Don't reuse helper variable names (`$P $W $T $B $EV`).
- PowerShell 5.1 strips quotes in JSON arguments to native executables. Use files (`--step-logs-file`) or one-flag-per-value CLI modes.
- Write files with `[IO.File]::WriteAllText` (UTF-8, no BOM) when another tool reads them.
- `uip` writes progress messages to stderr; add `2>$null` before piping JSON into `ConvertFrom-Json`.

---

## 11. Test Manager capture (project OFP2P)

The CLI can't start an `exploratory`-type execution, so an exploratory session is a **manual execution of a charter test case** (precedents OFP2P:76 and OFP2P:151).

1. `uip tm testcases create --project-key OFP2P --name "Exploratory charter: …"`, then add one step per area with `uip tm testcases steps add --project-key OFP2P --test-case-id <uuid> --description … --expected-result …` (flag mode, one call per step).
2. `uip tm testcases run --project-key OFP2P --test-case-id <uuid> --execution-type manual --name "Exploratory session <date> - …"`, then `uip tm testcaselog start`. Save the execution, log and test case ids to `P2PGuide/session-ids.txt`.
3. To finish, get the step ids with `uip tm testcases steps list --test-case-id <uuid>` and build a JSON file: one object per step with `id` (new GUID), `testStepId`, `result` (Passed / Failed / None), `comment`, `orderNo` (1-based), `hasError`, `hasAttachment`, `testCaseLogId`, `actionType` "Manual", `description`, `expectedResult`, `clipboardData` "".
4. `uip tm testcaselog finish --project-key OFP2P --execution-id … --test-case-id … --result Failed|Passed --has-error false --executed-by <tester email> --step-logs-file steplogs.json`
5. `uip tm attachment upload --project-key OFP2P --object-type testCaseLog --object-id <log id> --file <path>`: the filled-in charter and a zip of `P2PGuide/text`, `shots`, `surprises.txt` and `documents.txt`.
6. `uip tm executions get-stats --project-key OFP2P --execution-id …` to report totals.

---

### 11.1 Publish, link and run unattended (verified 24/11, OFP2P:227)

1. The test case must be **Publishable** (`project.json` → `designOptions.fileInfoCollection[].editingStatus = "Publishable"`); "InProgress" packs with no entry point and Orchestrator rejects the upload: *"A testing project should contain at least one entry point"* (2006).
2. `uip rpa pack <projectDir> <outDir>` → `uip rpa publish <nupkg>` with **no destination flag**: Shared/Testing-UBAPI has no folder feed ("no associated package feed"), it uses the **tenant processes feed**.
3. `uip tm testcases list-automations --project-key OFP2P --folder-key <Testing-UBAPI key> --package-name OracleFusion_AgenticTesting` → entry point `Tests\TC_P2P_E2E`, id = the test case's `testCaseId` in project.json.
4. `uip tm testcases link-automation --project-key OFP2P --test-case-key OFP2P:227 --folder-key <key> --package-name OracleFusion_AgenticTesting --test-name 'Tests\TC_P2P_E2E' --entry-point-id <id>` (`--test-name` is required even with the id).
5. `uip tm testcases run --project-key OFP2P --test-case-id <uuid> --name "<name>" --execution-type automated --folder-key <key> --async`; poll `uip tm executions get-stats`. It runs on machine template **LocalUserUnattended** (host CPC-ROBPA-DURUL, the user's own session).
6. Verification screenshots need a desktop: under `uip rpa run` they log "no active desktop"; the unattended session has one.

---

## 12. Guidance for UiPath workflows (`uix:N*`)

These follow from the behaviour above. Follow the project conventions in AGENTS.md (one Edge `NApplicationCard`, `InteractionMode=DebuggerApi`, Object Repository targets).
- **Navigate with `NGoToUrl`** to the paths in §2, then `NCheckState` / wait on the ready text with a timeout of ≥ 180 s (first load after sign-in is slow).
- **Targets:** semantic attributes (`aria-label`, visible text, role). Redwood and ADF ids are dynamic (`_oj1633_…`, `pt1:…:r1:0`). Exclude hidden duplicates; prefer the element inside the open dialog for dialog buttons (anchor on the dialog title, for example "Edit requisition?" or "Cancel requisition?").
- **LOVs:** type, wait for the option table, verify the field value afterwards, and retry the type once if the value is empty. Model the option target on a text that highlighting won't split.
- **Amounts:** drive tests from the **approval amount** and compute the price; assert on the cart's Approval Amount before Submit.
- **Document numbers:** read `Requisition NNNNNN` from the cart header before Submit, and use it for every later lookup (list click, View Approvers, BPM task title).
- **Approvals in BPM:** the task opens a new browser window; attach to it by title "Approve Requisition NNNNNN". Expect Approve to need a hardware click; the commit is the dialog's `Submit` link.
- **Sign-in:** the project spec is username-only automation plus a human password/Next handoff. The current workflow types the password from `GetRobotCredential` (known divergence, AGENTS.md).
- **Cleanup at the end of a test:** Withdraw (Edit > dialog Edit) > Save for Later > Cancel with a reason. Don't rely on Delete.

---

## 13. Known traps checklist

- [ ] Waiting on the right ready text, with a timeout of ≥ 180 s (first Redwood load is slow).
- [ ] Re-snapshot after every page change; refs are not stable.
- [ ] Visible element, not the `[invisible]` duplicate.
- [ ] LOV value read back after picking.
- [ ] Approval amount includes 9.5% tax.
- [ ] Casey's catch-all approval step expected on every requisition.
- [ ] Only your own document numbers touched, in lists and in the BPM worklist.
- [ ] BPM tasks open a new window; Approve may need hardware click; commit with `Submit`.
- [ ] Withdraw = Edit; cart holds one requisition; Save for Later to park it.
- [ ] Cleanup with Cancel, not Delete.
- [ ] Hardware/screenshot steps batched, human warned, no retry loops when focus is refused.
- [ ] Every write announced; documents and surprises logged as you go.
