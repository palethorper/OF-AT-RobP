Use the uipath-rpa skill to explore the browser (`uip rpa uia`).

I'm signed in to Oracle Fusion Cloud ERP as Casey Brown in Chrome. Casey is the user behind credential
asset `Oracle_Fusion_P2P_Test`; see `run-config.json`. I believe Casey has requester, buyer, receiving,
Payables and admin roles. Check this in Security Console rather than assuming it.

Goal: map the tenant for a procure-to-pay test suite: Create Requisition, Purchase Order, Receipt,
Supplier Invoice and Payment. Write the result to `OracleFusion_Tenant_Findings.md` in a form we can
build automations from.

## Rules (read only)

- Don't save, submit, approve, add to cart, edit or synchronise anything.
- Never click these: Edit Rules, Edit task, Save, Commit task, Reset, Revert, Start Synchronization,
  Reset Password, Reset MFA, or Edit (Security Console).
- Don't open other users' worklist items or transactions. Casey's worklist may contain other users'
  items.
- Use Security Console read only. "Done" on a user page is safe.
- Never read, print or store a password or secret.
- Reading page text and scrolling a table's container are fine. Don't click, type or navigate by
  script; use UIA clicks only.

## Before you start

1. Some pages need hardware clicks, which need Chrome in front. The rule-set links in BPM and the
   Invoice Type list are examples. Windows refuses this while I'm typing elsewhere: "Cannot bring the
   target application in the foreground". At the start, ask me to keep the PC idle while those steps
   run. Batch them together and tell me before and after. If focus still fails, record the item as
   **Open**, give the reason, and carry on.
2. Create `OracleFusion_Tenant_Findings.md` straight away with the section skeleton below. Update it
   after every section you finish, not only at the end, so nothing is lost if the session runs long.
3. Save raw captures (page text, rule details) to the scratchpad. Cite the file names in the findings.

## Where things are

- **Approval routing.** Use BPM Worklist directly:
  `/integration/worklistapp/faces/administration.jspx?selectedAdminTab=taskEditor`. Read these tasks:
  - `ReqApproval` (requisition)
  - `DocumentApproval` (PO)
  - `FinApInvoiceApproval` (invoice)
  - `PaymentApproval` (payment)
  - Receiving tasks: confirm whether any approval task exists.

  For each task:
  1. Open the Assignees tab and select **every** participant. The labels are cut off; the full name
     is in the `SoaOLabel.*` field.
  2. Record stage, routing (serial, parallel, FYI), voting, "assignees based on", and the rule set or
     static assignee.
- **Rule conditions.** In the participant's properties panel, hardware-click the rule-set link (for
  example `HeaderHierarchyRules`). Then select **every** rule in the list and record:
  - the full IF conditions
  - the THEN action: list builder, start and top participant, levels, approval group or user, and
    auto-action
  - the rule name

  Do this for every rule set of every task, and say which rule sets are empty. The Rules view
  replaces the participant diagram and stays on the first rule set you open. Go back to the
  Assignees diagram before selecting the next participant. After selecting a participant, wait until
  its `SoaOLabel.*` field shows that participant before looking for the rule-set link. Rules lower in the
  list must be scrolled into view (DebuggerApi click) before the hardware click. Check that the
  details panel changed for each rule; if it shows the previous rule again, retry.
- **Approval groups.** BPM Worklist > Administration > Approval Groups. The list loads lazily, so use
  the search box. Record members of every group the rules reference, and of any P2P-looking group
  (payables, purchase, category, requisition, CEO and similar). Say which groups are empty.
- **Business units.** Map every BU ID that appears in a rule (for example `reqBuId in 3000000…`) to its
  name, using Manage Business Units or a similar read-only page. Find the ID for US1 Business Unit.
- **Payables settings.** Check whether invoice approval and payment approval are switched on (Manage
  Invoice Options / Manage Payment Options, view only).
- **Procurement access.** Use Manage Procurement Agents, view only, to see which BUs and actions each
  test user can use.
- **Setup and Maintenance.** Task search only covers the selected offering (and "Required Tasks"
  hides most tasks). Switch offering, or prefer BPM Worklist.
- **Navigation paths.** For each step, give the real menu path in this tenant (Navigator or Home tab
  > tile > task). Click through to the page that opens, without acting on it, and record its title,
  URL path and the text to wait for before it counts as loaded. Mark each path **Verified** (clicked)
  or **Standard** (from Oracle docs, not clicked).

## Personas

Check these in Security Console:
- Casey
- every named user in the rules and in the groups that P2P rules use
- each user's supervisor chain up to the top approver named in the rules, for example WILLIAM.TAYLOR

For each user, record:
- user name and whether the account exists
- Active / Locked / end-dated
- password expiry
- worker job, department, manager and business unit
- P2P job roles. The roles table only renders 25 rows at a time, so scroll it and confirm the total.
- procurement BU access
- whether they suit initiating or approving, and which credential asset they would need

## Flag blockers

- approvers with no login (user not found), and inactive, locked or end-dated users
- empty approval groups referenced by rules
- catch-all or test rules (for example a condition of `1 is 1`) that route every transaction to one user
- self-approval and segregation-of-duties problems for the robot login
- business-unit, legal-entity or country-specific rules and steps
- pending admin warnings (for example flex field synchronisation)

## Findings file skeleton

1. Summary table: one row per area, with the test impact
2. Business processes: steps in order with navigation path, page title or URL and ready text
3. Approval routing: per task, all participants
4. Approval rule conditions: per rule set, every rule's IF/THEN, with the BU ID → name map. Split into
   "applies to our BU" and "other BUs".
5. Approval groups and members
6. Personas table, with the supervisor chain
7. Blockers and risks, with severity
8. Recommended personas and test data, for example which amounts trigger which routing
9. Automation guide:
   - URLs and ready text
   - which input method works per element type (DebuggerApi, Simulate, hardware events)
   - selector guidance (dynamic IDs, hidden duplicates, truncated labels, virtualised tables,
     snapshot size limits)
   - load times and wait strategy
   - the never-click list
10. Environment: pod, UI type (Redwood / ADF), component versions, banners, warnings, robot login,
    shared-tenant notes
11. Open items: anything not read, why, and how to finish it

Label every fact **Verified** (seen on screen), **Standard** (Oracle default, not checked here) or
**Open**. Don't guess; if something couldn't be read, say so and say why.

## Page behaviour

- Redwood pages can take up to 2 minutes to load. Wait for the page's ready text, polling every
  5 seconds, rather than using fixed delays or treating a blank page as an error.
- ADF pages re-render on their own, so take a new snapshot after every navigation before using
  element references.
- **Input method.** Clicks and typing use the Chromium API (`DebuggerApi`), not hardware events, so
  the robot does not need window focus and the person at the PC can keep working. Typing relies on
  Empty field (single line) to clear: a Ctrl+A inside an ADF table selects every row and Oracle drops
  the typed value. The exceptions that need hardware events (and Chrome in front) are the Invoice
  Type select and the BPM rule-set links.

## Finish

Finish with a short report:
- what was verified
- what is still open, and why
- the top blockers

Don't publish anything.
