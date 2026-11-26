# Exploratory test charter: Oracle Fusion Payables, create and validate a supplier invoice

| | |
|---|---|
| **Charter ID** | AP-01 (Type: Testing Charter) |
| **Application** | Oracle Fusion Cloud ERP, Payables. Pod `fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com` (Sandbox demo pod), start page `/fscmUI/faces/FuseWelcome` |
| **Business unit** | US1 Business Unit only (Findings Blocker B5) |
| **Tester / robot login** | Casey Brown (`CASEY.BROWN`, credential asset `Oracle_Fusion_P2P_Test`). Casey holds AP Specialist, AP Supervisor, AP Manager and Invoice Supervisor (Findings §5). The robot types the username; **the human types the password**. |
| **Timebox** | 30 minutes |
| **Source of truth** | `OracleFusion_Tenant_Findings.md` (§2.4 invoice path, §3.3 invoice approval, §6.3 open items, §7 blockers) and `OracleFusion_Automation_Playbook.md` (how to drive the tenant) |
| **Builds on** | Session P2P-01 (2026-11-22, OFP2P:151), which closed before reaching the invoice area. This charter covers the manual-invoice part of the deferred follow-up charter P2P-02. |
| **Evidence folder** | `P2PGuide/shots` and `P2PGuide/text`, names `ap01_MM_<screen>` (`.png` / `.txt`) |
| **Test Manager** | Project **OFP2P**, recorded as a manual session (see "Capture in Test Manager") |

> **Template differences.** The template's login `natalie.salesrep` and URL `eqjz.ds-fa.oraclepdemos.com` belong to **another environment** (confirmed by the user, 2026-11-23). This charter uses the dev16 pod and Casey Brown. Passwords are never written into charters or typed by the robot. The template's password was left out of this file; because it has been shared in plain text, consider changing it.

---

## Mission

Explore how an Accounts Payable user creates a supplier invoice manually in Oracle Fusion Payables. Focus on:
- required header data and supplier-driven defaults
- invoice lines and distributions
- tax calculation
- validation status
- how clearly the system shows whether the invoice is ready for approval and payment

---

## How the robot drives the browser

Background driving is the default (Playbook §3). Window focus is needed only where noted.

| Action | Method | Chrome in front? |
|---|---|---|
| Clicks, links, buttons, menus, table rows | `DebuggerApi` | No |
| Typing | `DebuggerApi`, clear mode **Empty field (single line)**. Never Ctrl+A in ADF tables. | No |
| Reading values and statuses, evidence | Page-text read (Playbook §9) | No |
| Waiting | Poll the ready text every 5 s, timeout ≥ 180 s. No fixed delays. | No |
| **Invoice Type** list | Hardware events (Findings B8) | **Yes** |
| Keyboard shortcuts (Ctrl+Alt+V, Ctrl+Alt+X) | Hardware keys | **Yes** |
| Screenshots, wheel scrolling of wide ADF pages | Hardware | **Yes** |

Run the background steps first. Group the focus steps (Invoice Type, shortcuts, screenshots) into short batches, and tell the human before each one ("Focus batch: about N seconds, please leave the PC"). If focus is refused, don't loop: keep the page text and mark the screenshot pending.

---

## Expected behaviour (from the findings and Oracle defaults)

| Area | Expectation | Source / status |
|---|---|---|
| Navigation | Home > Payables > Invoices; **Create Invoice** in the Tasks panel (right-hand icon strip) | Findings §2.4, **Standard**, not yet clicked |
| Header defaults | After BU + Supplier: supplier number, site, legal entity, payment terms, terms date, distribution set | **Standard** |
| Invoice Type list | Needs hardware events; may gain *Withholding tax* after supplier selection | Findings B8; template |
| Tax | Calculated on Calculate Tax / Validate; 9.5% nonrecoverable tax was seen on Seattle/US1 requisitions | P2P-01 S1; invoice tax not yet seen |
| Validation | Status *Not validated* → *Validated*, or *Needs revalidation* after changes; holds listed in Manage Holds | **Standard** |
| Invoice approval | `FinApInvoiceApproval`, 26 rule-based participants. **Whether invoice approval is switched on is Open.** | Findings §3.3, §6.3 |
| Payment approval | AP Payment Approvers (Matthew Schnieder, Kerry Lane), if switched on | Findings §3.4. **Not tested here.** |

---

## What the tester should try to do

### 1. Access invoice creation
Sign in as Casey. Go to Home > **Payables** > **Invoices** (Home group tabs don't switch with DebuggerApi, so use **Navigator > Payables > Invoices**). Find **Create Invoice** in the Tasks panel on the right edge. **Record the page URL and its ready text** for the playbook.

Explore:
- How easy it is to find the Tasks panel, and the right task among the ~20 listed
- Whether the Invoice Workbench infotiles (Scanned, Recent, Holds, Approval, Prepaid) are understandable and clickable
- Whether the "Sandbox Mode" banner gets in the way or confuses the user

### 2. Enter invoice header details
Select a Business Unit and a Supplier, then enter Invoice Number, Amount, Type, Date and Description.

Explore:
- Which fields are mandatory (*) and which only become editable after others are filled
- What fills in automatically once BU and Supplier are chosen (Supplier Number, Site, Legal Entity, Payment Terms, Terms Date, Distribution Set)
- How easy the defaults are to understand and override (for example, change Payment Terms from *Immediate* to *Net 30*)
- Whether the Invoice **Type** list changes after a supplier is selected (for example, *Withholding tax* appears). This needs a focus batch.
- Behaviour with:
  - a duplicate invoice number
  - a future or past invoice date
  - a zero or negative amount
  - a non-USD currency
- What happens when the BU is changed after the supplier is entered, and whether the BU locks after the first save

### 3. Add invoice lines and distributions
Expand **Lines**, add one or more lines (Item / Freight / Miscellaneous) and check the distribution.

Explore:
- Whether the line amount must match the header amount before saving
- How the Distribution Set defaults, and whether the Distribution Combination can be viewed or changed. Compare it with the charge account seen on requisitions (101.10.15910.000.000.000).
- Adding, cancelling and deleting lines, and what happens to totals
- The Lines action list (Match Invoice Lines, Match to Receipt Charges, Correct …), and whether its purpose is clear to a non-expert

### 4. Check system determinations
Save, then run **Invoice Actions > Calculate Tax** and **Validate**.

Explore:
- How tax is determined (rate; exclusive vs inclusive) and where it shows (Totals panel). Is it the same 9.5% as on requisitions?
- What happens when the header amount doesn't include the calculated tax (*Needs revalidation*, ⚠ on totals)
- Whether withholding is applied, and how it affects the Unpaid Amount
- Whether holds are placed, and how the user finds out why (Manage Holds)
- **Answer Findings §6.3:** does the Invoice Actions menu offer *Approval > Initiate*? If so, invoice approval is probably switched on. Record it, but **don't click it**.

### 5. React to system messages
Watch status chips (*Not validated*, *Needs revalidation*, *Validated*), inline field errors, popups and warning icons.

Explore:
- Which messages block saving or validation, and which are informational
- Whether the messages explain *how* to fix the problem in plain business language
- Whether the menu shortcuts (Ctrl+Alt+V, Ctrl+Alt+X) work. This needs a focus batch.

### 6. Save, find and exit
Use Save, Save and Close and Cancel, then open **Manage Invoices** and search for the invoice.

Explore:
- How clearly the outcome is communicated (invoice number in the title, status, Last Saved timestamp)
- Search behaviour: the "At least one is required" rule, saved searches, result columns (Validation Status, Approval Status, Holds, Unpaid Amount)
- What happens when you leave a page with unsaved changes
- Whether the next step (approval, payment) is clear. **Don't initiate approval or payment in the shared demo.**

---

## Test data

- Business Unit: **US1 Business Unit**.
- Supplier: **ABC Consulting**, site **ABC US1** (from the template; **not yet verified** in this tenant). Fallback: **Dell Inc.**, site **Dell US1**, verified as a US1 supplier in P2P-01.
- Invoice Number: `UIP-AP-<ddMMyy>-<HHmm>`, which must be unique. Add a suffix (`-a`, `-b`) for each extra invoice.
- Description: starts with **"Test UiPath AP-01"**, plus the step number.
- Amounts: small (100–1,000 USD). Include one case where the header excludes tax.

---

## Risks to watch for

- The page assumes Oracle Payables knowledge.
- Hidden dependencies between BU, supplier and dates.
- Exclusive tax that silently breaks the header/line balance.
- Cryptic technical errors.
- Horizontally scrolling ADF pages that hide fields or buttons (for example, Cancel cut off at narrow widths). Check with a page-text read whether a button exists before concluding it's missing.
- Slow page transitions (3–6 s, longer on first load after sign-in; P2P-01 saw over 2 minutes).
- Little guidance after validation about what happens next.
- **Shared tenant:** other demo teams create invoices here. Only touch invoices created in this session, identified by invoice number.
- **Segregation of duties:** Casey holds every AP role (Findings B4), so what she sees may not match what a restricted AP clerk sees.

---

## Capture in Test Manager (project OFP2P)

Same pattern as P2P-01 (Playbook §11):
1. Create test case "Exploratory charter: AP create and validate supplier invoice (US1, Casey Brown)", with one manual step per area (1–6 above, plus Cleanup) and the expected results from the table above. Label it `Exploratory`, `AP`, `Charter`.
2. Run it as a manual execution named "Exploratory session <yyyy-mm-dd> - AP create supplier invoice (Casey Brown, dev16)", then `testcaselog start`. Save the IDs to `P2PGuide/session-ids.txt`.
3. At the end, run `testcaselog finish` with a step-logs file (result and comment per area). Attach this charter, filled in, and a zip of the `ap01_*` evidence.
4. Raise defects only for real problems (blockers, wrong behaviour), not for things learned.

---

## Writes and cleanup

Announce every write before making it: create, save, calculate tax, validate, cancel invoice, delete line.

- **Never** initiate approval, pay, or force-approve in this session.
- Before finishing, **cancel every invoice created** (Invoice Actions > Cancel Invoice, **Standard**), or delete it if it was never validated. Record the final status of each.

| # | Invoice number | Supplier | Amount | Created at step | Final status | Cleaned up how |
|---|---|---|---|---|---|---|
| 1 | UIP-AP-231126-1013 | ABC Consulting (1288), site ABC US1 | 500.00, then 545.00 USD | 2 (saved), 4 (validated) | **Canceled** (totals 0.00) | Invoice Actions > Cancel Invoice > OK. Verified in Manage Invoices. |

No approval was initiated and no payment was made.

**Found afterwards via REST (2026-11-23, API_Findings.md §7.8):** validation auto-created IRS withholding invoice **Withholding tax-300000342340067-4** (54.50, 10% of 545), and cancelling created **…-4-Canceled** (-54.50). Both are *Not validated / Pending control check* and not canceled; they net to zero. The UI Totals showed Withholding 0.00, so S9/S10 missed this. Cleanup decision pending.

---

## Session notes (fill in during the run)

**Start / end time:** 2026-11-23, about 10:05–10:35 local (tenant clock showed 22/11/26 11:10–11:30 PM). Test Manager execution `bf04ad37-2dc1-0400-a721-0b4a65c1f899`, log `c718d10e-0474-1300-9570-0b4a65c1f8dd`.

**Surprises:** (full list in `P2PGuide/ap01-surprises.txt`)

| # | Screen / step | Type | What happened | Expected | Evidence |
|---|---|---|---|---|---|
| S1 | Access | navigation | A direct URL opens the Invoices work area in about 7 s. The Tasks panel is an **unlabeled icon** (`Image "Tasks"`) on the right edge, with 20 links in 5 groups (Invoices, Accounting, Assets, Payables Periods…). | Hard to find | ap01_01, ap01_02 |
| S2 | Header | default | Before the supplier: BU **US1 Business Unit**, USD, Type Standard, Payment Terms **Immediate**, Date and Terms Date **22/11/26**, which is one day behind the local date (tenant clock) | — | ap01_03 |
| S3 | Header | default | `ABC Consulting` + Tab autocompletes: Supplier Number **1288**, Site **ABC US1**, Legal Entity **US1 Legal Entity**. Payment Terms stays Immediate. Override to **Net 30** works; Due Date becomes 22/12/26. | Supplier-driven defaults | ap01_04, ap01_05 |
| S4 | Header | default | The Type list gains **Withholding tax** after the supplier is chosen | As the template predicted | ap01_04 |
| S5 | Header | automation | Invoice Type is a native `<select>`. `uia interact select` works but **brings Chrome to the foreground**. A DebuggerApi type of the first letter + Tab (`S[k(tab)]`) selects it **in the background**. | Findings B8: hardware needed | — |
| S6 | Access | — | Approval infotile: 0 Pending, 15 Others, 4 Rejected. Tasks panel has "Initiate Approval Workflow". | — | ap01_01 |
| S7 | Lines | default | Line 1 is pre-created as **Item** with an empty amount. Distribution Set and Combination **do not default** from the supplier site. | Distribution Set defaults | ap01_05 |
| S8 | Invoice Actions | unexpected button | The ADF menu opens only via the inner `Link "Invoice Actions"`. Items: View, Manage Installments, Calculate Tax (Ctrl+Alt+X), Validate (Ctrl+Alt+V), Apply or Unapply Prepayments, Manage Holds, Account Coding, Approval ›, View Approval and Notification History, Cancel Invoice, Delete Invoice, Pay in Full, Post to Ledger, Account in Draft | — | ap01_06 |
| S9 | Tax | default / risk | Calculate Tax (which **also saves**) gives **45.00 = 9.0% exclusive**: CA San Mateo County 2.5% + CA State 6.5%, US SALES AND USE TAX, as tax-only lines 2 and 3. Requisitions in Seattle had 9.5%. | Same location as the requisitions | ap01_07 |
| S10 | Validate | hold | Header 500 excluding tax → **Needs revalidation**, with **no message**. The reason is only in the **status-chip popup** (Invoice Summary): 4 system holds, Line Variance 1 + Distribution Variance 3. Due 22/12/26, Unaccounted. | Plain-language reason | ap01_08, ap01_09 |
| S11 | Validate | — | Distribution Combination 101.10.15910.000.000.000 on the item line + header 545.00 → **Validated, 0 holds**. Tax lines inherit the distribution. The Approval submenu offers Initiate / Withdraw / Resubmit / Force Approve (not clicked). | — | ap01_10 |
| S12 | Automation | automation | `uia interact hover` uses hardware events and moves the real mouse. Read submenus from the DOM instead. | — | — |
| S13 | Manage Invoices | message | An empty search shows no new message, only the static "** At least one is required". Search by number works. The canceled invoice shows Approval Status **Not required**. | — | ap01_12, ap01_13 |

**Open items answered:**
- **Invoice Type options after supplier:** *Withholding tax* is added.
- **Tax:** 9.0% exclusive (California), not 9.5%.
- **Is invoice approval switched on?** Still **inconclusive**. The Approval actions are offered and the infotile shows approval activity, but the canceled invoice shows "Not required". Confirm by initiating approval on a dedicated invoice, with permission, or by reading Payables Options.

**Focus batches run:** none. One unintended focus grab (S5, `select`) and one mouse move (S12, `hover`).

**Pending screenshots:** ap01_01 – ap01_13 (page text kept for all).

**Questions and follow-up charters:**
- **Not run within the timebox:** duplicate invoice number, past/future date, zero or negative amount, non-USD currency, BU change before save, Freight/Misc lines and line delete, the Ctrl+Alt shortcuts (needs a focus batch), and unsaved-changes navigation.
- Why does the invoice tax use a California jurisdiction when the requester's location is Seattle? Check the ship-to on the invoice line and the supplier site address.

**Automation notes:** added to `OracleFusion_Automation_Playbook.md` §8.1.
