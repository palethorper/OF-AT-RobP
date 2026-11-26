# Exploratory test charter: Oracle Fusion procure to pay (requisition to payment)

| | |
|---|---|
| **Charter ID** | P2P-01 |
| **Application** | Oracle Fusion Cloud ERP, `fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com` (Sandbox demo pod) |
| **Business unit** | US1 Business Unit only |
| **Tester / robot login** | Casey Brown (`CASEY.BROWN`, credential asset `Oracle_Fusion_P2P_Test`): requester, buyer, receiver, AP |
| **Approver login** | Anita Kennedy (`ANITA.KENNEDY`), Casey's manager. The human types her password. |
| **Timebox** | 90–120 minutes. If one area uses more than half the time, stop it and move the rest to charter P2P-02. |
| **Source of truth** | `OracleFusion_Tenant_Findings.md` (§3 routing, §6 rules, §5 personas, §7 blockers, §9 automation guide) |
| **Evidence folder** | `P2PGuide/shots` (screenshots `p2pNN_MM_<screen>.jpg`) and `P2PGuide/text` (page-text captures, same names, `.txt`) |
| **Test Manager** | Project **OFP2P** (Oracle Fusion P2P). Recorded as a manual session; see "Capture in Test Manager" below. |

---

## Mission

Explore the end-to-end flow (requisition → approval → purchase order → receipt → supplier invoice → payment) as Casey Brown in US1. The aim is to learn:
- whether approval routing matches the documented rules
- which fields, warnings and holds actually gate each step
- where the UI behaves in ways that will trip up automation

---

## How the robot drives the browser

Background driving is the default. Window focus is only needed where noted.

| Action | Method | Needs Chrome in front? |
|---|---|---|
| Clicks, links, buttons, tabs, menus, table rows | `DebuggerApi` | No |
| Typing into fields | `DebuggerApi`, clear mode **Empty field (single line)**. Never Ctrl+A in ADF tables. | No |
| Reading values, statuses, document numbers | Get Text / page-text read | No |
| Evidence for every screen | Page-text capture saved to `P2PGuide/text/<name>.txt` | No |
| Navigation | Direct URLs where known (Findings §9.1), otherwise menu clicks with `DebuggerApi` | No |
| Waiting for load | Poll the page's ready text every 5 s, up to 150 s. No fixed delays. | No |
| **Invoice Type** list (Create Invoice) | Hardware events | **Yes** |
| **Screenshots** | Window screenshot | **Yes** |
| Scrolling, if a `DebuggerApi` click doesn't bring an element into view | Hardware wheel | **Yes** |

**Focus rules:**
- Do every step in the background first. Record the screenshot names that are still needed as you go.
- Group the steps that need focus (Invoice Type selection and the pending screenshots) into short batches. Before each batch, tell the human "Focus batch: about N seconds, please leave the PC", then run it and say when it's done.
- If focus is refused ("Cannot bring the target application in the foreground"), don't retry in a loop. Keep the page-text capture as evidence, mark the screenshot as **pending**, and continue.
- Sign-in switches (Casey ↔ Anita) are done in the background. The robot opens the sign-in page and types the username; the human types the password.

---

## Expected behaviour (from the findings)

| Area | Expectation | Source |
|---|---|---|
| Requisition < 50,000 USD | Rule "Requsition Self Approval under 50K" auto-approves | Findings §6.1 |
| Requisition ≥ 50,000 USD | Supervisory, 1 level from the preparer's manager, so it goes to **Anita Kennedy**. The top approver is William Taylor. | §6.1 "Requisition Supervisory 50K Approval" |
| Every requisition | Extra approval for **CASEY.BROWN** from the catch-all rule "Requisition Approval - Casey Brown" (`1 is 1`) | §6.1, Blocker B0 |
| Approver override set, ≥ 50K | Routes to the override approver, top William Taylor | §6.1 "Requisition 50K and Override" |
| PO approval | Stages Preapproval → Terms → Postapproval. **Rules not read**, so observe what fires. | §3.2, §6.2 |
| Receipt | No approval task; FYI only | §3.5 |
| Invoice approval | `FinApInvoiceApproval`. **Unknown whether enabled.** | §3.3, §6.3 |
| Payment approval | `PaymentApproval` → probably **AP Payment Approvers** (Matthew Schnieder, Kerry Lane) | §3.4, §4 |

---

## Areas and test ideas

### 1. Requisition (Casey)
- Create a **noncatalog** request (description starts "Test UiPath", small quantity, US1, supplier and category copied from PO US165363 or US165364). Note required fields, defaults (deliver-to, charge account, requester) and the cart behaviour.
- **Amount boundary:** submit three requisitions totalling **49,999.99**, **50,000.00** and **50,000.01** USD. For each, record:
  - the status after submit
  - the approvers shown in the approval history or "View approvals"
  - whether the CASEY.BROWN step appears
- **Approver override:** on one ≥ 50K requisition, set the Approver field. Record which approver is used.
- **Withdraw:** withdraw a pending requisition, edit the amount or description, and resubmit. Check whether approval restarts.
- Watch for: the approval amount vs line total (does tax count?), currency defaults, and warnings that block versus warnings you can submit through.

### 2. Approval (Anita Kennedy; Casey for the catch-all step)
- Sign in as Anita (the robot types the username, the human types the password). Open **only** the requisitions created in this session, by number.
- Approve one ≥ 50K requisition. **Reject** another. On a third, use **Request More Information**, then answer it as Casey.
- Casey's catch-all approval: approve only this session's requisitions, by number. Casey's worklist holds other teams' items; don't open them.
- Compare: who received the task, the order of approvers, and what the approval history shows, against the expectations above.

### 3. Purchase order (Casey as buyer, Redwood Buyer role)
- Process an approved requisition into an order (Purchase Orders > Process Requisitions). Note:
  - the document type and supplier site defaults
  - whether the order is created automatically
- Submit the PO. Record **which approval stages fire**, since the PO rules are unread.
- Open the PO and try a **change order** (quantity or price). Note the approval behaviour on change.

### 4. Receipt (Casey)
- Receive **less than** the ordered quantity, then the remainder.
- Try to receive **more than** ordered. Is it a warning (tolerance) or a blocker?
- **Correct** a receipt. Note where Correct and Return live.

### 5. Supplier invoice (Casey, AP)
- Create an invoice matched to the PO. The **Invoice Type** list needs a focus batch.
- Three cases:
  - (a) quantity = received
  - (b) quantity > received, which should give a match hold
  - (c) unit price > PO price, which should give a price hold
- **Validate.** Record the holds and their names. Initiate approval if the action exists, and note whether invoice approval is switched on.

### 6. Payment (Casey, AP)
- **Pay in Full** on the clean invoice (a). Record whether it routes to AP Payment Approvers, and the payment number and status.

---

## Test data

- US1 Business Unit only (Findings Blocker B5).
- Supplier and category: copy them from Casey's own POs US165363 or US165364. Read them only, don't change them.
- Quantities 1–5. Unit prices chosen to hit the three totals exactly.
- Descriptions and comments start with **"Test UiPath P2P-01"** plus a step number, so they are easy to find and clean up.

---

## Risks and things to watch

- **Catch-all rule (B0):** every requisition gets a CASEY.BROWN approval, so Casey's worklist has other teams' items. Act only on this session's document numbers.
- **Unread rules:** the PO, invoice and payment rule conditions are open (§6.2). Treat what fires as a finding, not a failure.
- **Funds check:** stay within budget, or the Funds Override participant fires (B7).
- **Pending flex-field sync (B6):** don't click Start Synchronization.
- **Shared tenant:** other demo teams transact here.
- **Load times:** Redwood can take up to 2 minutes. Log any page slower than 30 s.

---

## Capture in Test Manager (project OFP2P)

This follows the pattern of the earlier session: test case OFP2P:76, recorded as the manual execution "Exploratory session 2026-11-20 - …", with the notes attached to its test case log. The `uip tm` CLI cannot start a native `exploratory`-type execution, so the session is a **manual** execution of a charter test case.

1. **Charter test case.** `uip tm testcases create --project-key OFP2P --name "Exploratory charter: P2P requisition to payment (US1, Casey Brown)"`.
   - Description: the Mission and Expected behaviour sections from this charter.
   - Add one manual step per area (Requisition, Approval, Purchase order, Receipt, Supplier invoice, Payment, Cleanup). Each step's expected result is its row from "Expected behaviour".
   - Label it `Exploratory`, `P2P`, `Charter`.
2. **Start the session.** `uip tm testcases run --project-key OFP2P --test-case-id <ID> --execution-type manual --name "Exploratory session <yyyy-mm-dd> - P2P requisition to payment (Casey Brown, dev16)"`. Then `uip tm testcaselog start`.
3. **During the run,** keep this charter's session notes up to date (surprises, routing table, cleanup table).
4. **Record step results** with `uip tm testcaselog finish` and `--step-logs-file`:
   - Each step is Passed, Failed or None (not reached). Its comment summarises that area's surprises and document numbers.
   - The overall result is **Failed** if any routing mismatch or blocker was found, otherwise **Passed**.
5. **Attach evidence** to the test case log with `uip tm attachment upload --object-type testCaseLog`:
   - this charter, with the session notes filled in
   - a zip of `P2PGuide/shots` and `P2PGuide/text`
6. **Defects.** For each real problem, such as a routing mismatch or an unexpected blocker, raise a defect from the session's test case log (`uip tm defects create`). Raise defects only for problems, not for things you just learned.
7. **Results.** Report totals with `uip tm executions get-stats`, not a hand count.

---

## Writes and cleanup

Announce every write before making it: create, submit, approve, reject, request information, withdraw, receive, correct, validate, pay, cancel or void. Record each document in the table below as it is created.

Before finishing:
- withdraw or cancel every requisition
- cancel POs
- cancel invoices
- **ask the human before voiding any payment**

| # | Document | Number | Created at step | Final status | Cleaned up how |
|---|---|---|---|---|---|
| R1 | Requisition | 204162 | 1 (49,999.99) | **Canceled** (was Approved) | More Actions > Cancel, reason "Test UiPath P2P-01 cleanup" |
| R2 | Requisition | 204163 | 1 (50,000.00) | **Canceled** (was Pending, Anita) | Edit (withdraw) > Save for Later, then More Actions > Cancel |
| R3 | Requisition | 204164 | 1 (50,000.01) | **Canceled** (was Pending, Anita) | Edit (withdraw) > Save for Later, then More Actions > Cancel |
| R4 | Requisition | 204165 | 1 (54,750, override Calvin Roth) | **Canceled** (was Pending, Calvin) | Edit (withdraw) > Save for Later, then More Actions > Cancel |

No POs, receipts, invoices or payments were created.

---

## Session notes (fill in during the run)

**Start / end time:** 2026-11-22 13:30 – closed early at the user's request. Areas 1 (Requisition) done; Area 2 (Approval) partly done (Casey's catch-all step on 204162 only, the session ended before Anita's approve/reject/RMI); Areas 3–6 not reached → carry into charter **P2P-02**.

**Surprises:**

| # | Screen / step | Type | What happened | Expected (from findings) | Evidence |
|---|---|---|---|---|---|
| S1 | Requisition approval amount | routing mismatch (doc gap) | Approval Amount = line subtotal + 9.5% nonrecoverable tax; the 50K rule tests the approval amount, so the boundary is after tax | Findings §6.1 implied the line amount | p2p01_08, p2p01_11 |
| S2 | Req 204162 (49,999.99) | routing mismatch | Did **not** auto-approve; held for Casey by `RequisitionApprovalCaseyBrown` (catch-all `1 is 1`) | Self-approval under 50K (but B0 predicted the extra step) | p2p01_07, p2p01_08 |
| S3 | Req 204163 / 204164 | — (matched) | 50,000.00 and 50,000.01 both route Anita Kennedy (Supervisory50K), then Casey | ≥ 50K → Anita | p2p01_11, p2p01_14 |
| S4 | Req 204165 override | — (matched) | Overriding Approver Calvin Roth → Calvin (`Requisition50KandOverride`), then Casey; Anita skipped | Override approver | p2p01_18 |
| S5 | Withdraw | unexpected button | No "Withdraw" action; **Edit** on a pending requisition withdraws it (dialog), returns it to the cart with the same number; resubmit restarts approval | Withdraw action | p2p01_19–21 |
| S6 | Cart summary | default / display | Cart summary does not show Justification after Update; the approval task does | — | p2p01_20, p2p01_23 |
| S7 | BPM approval task | unexpected button / automation | Task opens in a separate window; Approve opens a Comment dialog, commit is its `Submit` link; DebuggerApi/Simulate click on Approve showed no change, hardware click worked | — | p2p01_22, p2p01_23 |
| S8 | Noncatalog defaults | default | Supplier site Dell US1; Deliver-to Seattle; Destination Expense; charge account 101.10.15910.000.000.000 from the requester | — | p2p01_05 |
| S9 | Redwood LOVs | automation | Category/UOM/Supplier lose the first typed text after re-render; typing "Desktop" splits the option label | — | p2p01_04, p2p01_05 |
| S10 | Cleanup | unexpected button / automation | More Actions > **Delete** on the requisition page does not fire with DebuggerApi or Simulate (menu stays open); **Cancel** in the same menu works. The cart has no requisition-level Delete; a withdrawn requisition must be saved (Save for Later) to leave the cart | — | p2p01_24 |

**Routing observed vs documented:**

| Document | Approval amount | Expected approvers | Actual approvers | Match? |
|---|---|---|---|---|
| 204162 | 49,999.99 | Self-approve + Casey catch-all | Casey only (catch-all) | Partly: no self-approval completion |
| 204163 | 50,000.00 | Anita, Casey | Anita → Casey | Yes |
| 204164 | 50,000.01 | Anita, Casey | Anita → Casey | Yes |
| 204165 | 54,750.00 (override Calvin Roth) | Calvin, Casey | Calvin → Casey | Yes |

**Focus batches run:** 1 (≈ 14:38): hardware click on Approve in the 204162 task window and a screenshot. Not refused.

**Pending screenshots** (not taken because the session closed early; page text kept instead): p2p01_01 – p2p01_21, p2p01_23, p2p01_24. Only p2p01_22 has a screenshot.

**Questions and follow-up charters:**
- **P2P-02:** Anita's Approve / Reject / Request More Information; PO from an approved requisition (stages fired, change order); receipt (partial, over-receipt, correction); invoice holds (quantity, price); payment routing to AP Payment Approvers.
- Is the under-50K self-approval rule meant to finish approval on its own, or is the Casey catch-all intended to always add a step? Raise with the tenant owner (blocker B0).

**Automation notes** (to add to Findings §9):
- Compute requisition prices backwards from the approval amount (÷ 1.095).
- Withdraw = Edit on the requisition page, then `Button "Edit"` inside `withdrawWarningDialog`.
- BPM Approve: after the click, look for `Link "Submit"` in the Comment dialog; fall back to a hardware click if it is absent.
- Redwood LOVs: retype after re-render; match the option by a substring that highlighting does not split.
- Sign-in switch: Settings and Actions > Sign Out, then type the username into `InputBox "Username"` on the IDCS page.
