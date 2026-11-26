# Exploratory test charter: Oracle Fusion procure to pay (approval to payment)

| | |
|---|---|
| **Charter ID** | P2P-02 (continues P2P-01, which covered the requisition only) |
| **Application** | Oracle Fusion Cloud ERP, `fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com` (Sandbox demo pod) |
| **Business unit** | US1 Business Unit only |
| **Tester login** | Casey Brown (`CASEY.BROWN`): requester, buyer, receiver, AP. The human types the password. |
| **Approver login** | Anita Kennedy (`ANITA.KENNEDY`), Casey's manager. The human types her password. |
| **Timebox** | **90 minutes** (cut from 120 at the user's request). If one area uses more than half the time, stop it and move the rest to charter P2P-03. Priority if time runs short: Approval > PO > Receipt > Invoice > Payment. |
| **Assumption** | Same Oracle environment as the mapping and P2P-01: data, processes, roles and people are as in the findings (user's instruction, 2026-11-26), so the roles check is skipped. |
| **Sources** | `specs/OracleFusion_Tenant_Findings.md` (§5 personas, §6 rules, §7 blockers, §8 test data), `OracleFusion_Automation_Playbook.md` (how to drive each page), `specs/API_Findings.md` §7.3–7.6 (PO US165366 chain), P2P-01 session notes |
| **Evidence** | `P2PGuide/text/p2p02_NN_<screen>.txt` and `P2PGuide/shots/p2p02_NN_<screen>.png` (same name); `P2PGuide/documents.txt`, `P2PGuide/surprises.txt`, `P2PGuide/pending-shots.txt` (appended, prefixed `P2P-02`) |
| **Test Manager** | Project **DNZTRAIN** (org `deloivqbaydk`), folder Shared/OracleFusion, from `run-config.json`. Recorded as a manual session. |

---

## Mission

Take a requisition from Anita's approval through to a paid invoice as Casey Brown in US1, and try each approver action on the way. The aim is to learn:
- whether approval routing for requisitions, POs and payments matches the documented rules, at amounts of 50,000 or more
- how receipt tolerances and invoice match controls actually behave (warn, hold or block)
- which fields, defaults and actions will trip up automation of the later P2P steps

---

## Expected behaviour (from the findings)

| Area | Expectation | Source |
|---|---|---|
| Requisition ≥ 50,000 approval amount | Anita Kennedy first (`RequisitionSupervisory50KApproval`), then Casey (catch-all `RequisitionApprovalCaseyBrown`) | Findings §6.1, B0; P2P-01 S3 |
| Approval amount | Subtotal + 9.5% nonrecoverable tax (Seattle deliver-to). Rules test the approval amount. | P2P-01 S1; Playbook §5.4 |
| Anita Approve | Requisition moves to Casey's catch-all step; after Casey approves, status Approved | P2P-01 S3 |
| Anita Reject | Requisition status Rejected; Casey's step does not run | **Standard** (not seen) |
| Anita Request More Information | Task goes back to Casey to answer; after the answer, it returns to Anita | **Standard** (not seen) |
| PO approval | Only `TermsApprovalHierarchyRules_POSelfApproval` fired for a 2,190 USD PO by Casey (auto-approved, straight to Open). Whether a 50K PO behaves the same is **Open**. | API_Findings §7.4; Findings §6.2 (PO rules unread) |
| PO change order | Rules unread. Observe whether an increase or a decrease re-routes. | **Open** |
| Receipt | No approval task, FYI only. Over-receipt tolerance 50%, action None, so over-receiving should neither warn nor block. A schedule that is fully received becomes Closed for Receiving. | Findings §3.5; API_Findings §7.5 (US165366) |
| Invoice match | Match option Order, **2-way** (invoice vs PO, not vs receipt). Billing above the *received* quantity should **not** hold; billing above the *ordered* quantity should give a quantity-ordered hold; a price above the PO price should give a price hold (if tolerance is 0). | API_Findings §7.5; **Standard** for the hold names |
| Invoice header amount | Must include tax, or a Line Variance hold is raised. PO-matched tax rate is **Open** (9.5% on the PO; ABC US1 invoices used 9.0%). | Playbook §8.1; Findings §6.3 |
| Invoice approval | New US1 invoices came out "Not required" | Findings §6.3 |
| Payment approval | `PaymentApproval` → probably **AP Payment Approvers** (Matthew Schnieder, Kerry Lane). Whether it's switched on is **Open**. | Findings §3.4, §4, §6.3 |

---

## Areas and test ideas

### 1. Approval (Casey creates, Anita acts, Casey finishes)
Create three noncatalog requisitions as Casey (Desktops, Ea, Dell Inc. / Dell US1), prices from Playbook §5.4. Read the approval amount on the cart before each Submit.

| # | Purpose | Qty × unit price | Target approval amount |
|---|---|---|---|
| R1 | **Approve**, then goes to PO | 4 × 11,415.53 | 50,000.02 (45,662.12 + 4,337.90) |
| R2 | **Reject** | 1 × 45,662.10 | 50,000.00 |
| R3 | **Request More Information** | 1 × 45,662.11 | 50,000.01 |

- Check View Approvers on each: Anita, then Casey.
- Switch to Anita. In BPM Worklist, open **only** R1–R3, by number:
  - R1: Approve.
  - R2: Reject, with a comment.
  - R3: Request More Information, addressed to Casey, with a question.
  - Compare what Anita sees (amount, justification, lines, history) with the routing.
- Switch back to Casey:
  - answer R3's information request, and see where it goes next
  - approve R1's catch-all step (R1 only)
  - check R1 is Approved and R2 is Rejected
- Watch for: whether Reject and Request More Information need a hardware click (Approve did in P2P-01), whether the comment is required, and the notifications that arrive.

### 2. Purchase order (Casey as buyer)
- Process R1 into an order (Process Requisitions, or wherever the Redwood Buyer role puts it). Note document type, supplier site, buyer, terms and whether the order is created automatically.
- Submit the PO. Record which approval stages and rules fire at 50K (View Approvers / approval history).
- Change orders, one at a time, recording routing and status after each:
  - CO1: **quantity 4 → 5** (increase)
  - CO2: **price 11,415.53 → 11,400.00** (decrease)
- Expected final PO: 5 × 11,400.00 = 57,000.00 + tax.

### 3. Receipt (Casey)
- Receive **2** of 5 (partial). The schedule should stay open.
- Receive **4** more (total 6, 20% over), which tests over-receipt within the 50% tolerance. Record whether it warns, blocks or accepts.
- **Correct** the second receipt from 4 to **3** (total 5). Note where Correct and Return are.
- Record the receipt numbers and whether the schedule becomes Closed for Receiving.

### 4. Supplier invoice (Casey, AP)
Run the hold cases first and cancel them, so they don't use up the billed quantity for the clean invoice. Invoice numbers are `TUIP-P2P02-<B|C|A>-261126`. Supplier Dell Inc. / Dell US1, matched to the PO.

| # | Case | Quantity × price | Expected |
|---|---|---|---|
| I-B | Above ordered (and received) | 6 × 11,400.00 | Quantity-ordered hold (2-way match) |
| I-C | Price above PO | 5 × 11,500.00 | Price hold |
| I-A | Clean | 5 × 11,400.00 | Validated, 0 holds |

- For each: header amount including tax, Calculate Tax, Validate, then open the status chip and record the holds and their reasons.
- Cancel I-B and I-C after recording them.
- View only: is invoice approval switched on (Payables invoice options)? Record the approval status of I-A.
- Watch for a withholding invoice (AP-01 found one on ABC Consulting; Dell is not expected to have one).

### 5. Payment (Casey, AP)
- **Pay in Full** on I-A. Record whether it routes to AP Payment Approvers, and the payment number, method and status.

---

## Test data

- US1 Business Unit only (Findings B5). Deliver-to Seattle, charge account 101.10.15910.000.000.000 (defaults from Casey).
- Supplier Dell Inc. / Dell US1, category Desktops, UOM Ea (as P2P-01).
- Every description and comment starts with **"Test UiPath P2P-02"** plus the document tag (R1, I-A, …).
- Amounts are deliberately ≥ 50,000 so the PO, change order and payment are tested at the same level as the requisition approval.

---

## Risks and things to watch

- **Catch-all rule (B0):** Casey's worklist holds other teams' requisitions. Act only on this session's document numbers.
- **Unread rules:** PO, invoice and payment rules are unread (§6.2). What fires is a finding, not a failure.
- **Funds check (B7):** if a 50K requisition or PO fails the funds check, a Funds Override step fires. Record it and stop that line rather than overriding.
- **Fully received schedule:** after full receipt it may become Closed for Receiving, so the over-receipt test is done in the second receipt, before the schedule is full.
- **Payment is real money movement in a demo tenant.** Voiding it at cleanup needs the human's approval first.
- **Rejected requisition cleanup:** whether a Rejected requisition can be canceled is **Open**.
- **Test Manager:** DNZTRAIN is a new project. Labels, manual execution and defects have not been used there yet. If it has no defect tracker, record defects in the session notes instead.
- **Pending flex-field sync (B6):** never click Start Synchronization.
- **Load times:** Redwood's first load can take over 2 minutes. Log any page slower than 30 s.

---

## Capture in Test Manager (project DNZTRAIN)

The `uip tm` CLI cannot start an exploratory-type execution, so the session is a manual execution of a charter test case (Playbook §11).

1. **Charter test case:** "Exploratory charter: P2P-02 approval to payment (US1, Casey Brown)".
   - Description: Mission and Expected behaviour from this charter.
   - Steps, one per area: Approval, Purchase order, Receipt, Supplier invoice, Payment, Cleanup. Each expected result is that area's expectation above.
   - Labels: `Exploratory`, `P2P`, `Charter`.
2. **Start:** manual execution "Exploratory session 2026-11-26 - P2P-02 approval to payment", then `testcaselog start`. Save the ids to `P2PGuide/session-ids.txt` under a `P2P-02` heading.
3. **Finish:** `testcaselog finish` with `--step-logs-file`. Each step is Passed, Failed or None (not reached), and its comment gives that area's surprises and document numbers. The overall result is Failed if a routing mismatch or unexpected blocker was found.
4. **Attach** to the test case log: this charter with the session notes filled in, and a zip of this session's `p2p02_*` evidence plus `surprises.txt` and `documents.txt`.
5. **Defects:** only for real problems (routing that contradicts the rules, an unexpected blocker). Not for unread rules or things learned.
6. **Totals:** `uip tm executions get-stats`.

---

## Writes and cleanup

Announce every write before making it: create, submit, approve, reject, request information, withdraw, cancel, receive, correct, validate, pay, void. Record each document below as it is created.

Cleanup, newest first:
1. Payment: void, **only after the human approves**.
2. Invoices: cancel I-A (after the void); I-B and I-C are canceled during the session.
3. PO: cancel; if it has receipts or invoices, close it instead (Playbook §7.1).
4. Requisitions: R3 withdraw then cancel; R2 (Rejected) cancel if offered, otherwise record; R1 is fulfilled by the PO and is closed with it.

| # | Document | Number | Created at step | Final status | Cleaned up how |
|---|---|---|---|---|---|
| R1 | Requisition | | 1 (50,000.02, Approve) | | |
| R2 | Requisition | | 1 (50,000.00, Reject) | | |
| R3 | Requisition | | 1 (50,000.01, RMI) | | |
| PO1 | Purchase order | | 2 (from R1) | | |
| RC1 | Receipt | | 3 (2 units) | | |
| RC2 | Receipt | | 3 (4 units, corrected to 3) | | |
| I-B | Invoice | | 4 (6 units) | | |
| I-C | Invoice | | 4 (price 11,500) | | |
| I-A | Invoice | | 4 (clean) | | |
| PY1 | Payment | | 5 (I-A) | | |

---

## Session notes (fill in during the run)

**Start / end time:**

**Surprises:**

| # | Screen / step | Type | What happened | Expected (from findings) | Evidence |
|---|---|---|---|---|---|

**Routing observed vs documented:**

| Document | Amount | Expected approvers | Actual approvers / rules | Match? |
|---|---|---|---|---|

**Holds observed:**

| Invoice | Case | Expected hold | Actual holds and reasons | Match? |
|---|---|---|---|---|

**Focus batches run:**

**Pending screenshots:**

**Questions and follow-up charters (P2P-03):**

**Automation notes** (to add to the playbook):
