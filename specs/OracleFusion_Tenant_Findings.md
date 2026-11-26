# Oracle Fusion tenant findings: procure-to-pay

**Tenant:** `fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com` (Oracle demo pod, Sandbox banner shown)

**Explored as:** Casey Brown (`CASEY.BROWN`). This is the user behind credential asset `Oracle_Fusion_P2P_Test`; see `run-config.json`.

**Date:** 2026-11-22

**Method:** read only.
- Pages were read with UiPath UIA (`uip rpa uia`, DebuggerApi input) and page-text reads.
- Nothing was saved, submitted, approved, added to a cart or edited.
- Edit Rules, Edit task, Start Synchronization and Commit were not used.
- No other user's worklist item or transaction was opened.

**How confident each item is:**
- **Verified:** read on screen during this exploration.
- **Standard:** Oracle's standard navigation or behaviour. It was not clicked through in this tenant, so confirm it while recording.
- **Open:** not readable yet. The reason is given beside each one.

---

## 1. Summary

| Area | What is in place | Test impact |
|---|---|---|
| Requisition approval (`ReqApproval`) | 13 participants, all rule-based; header level only (no line or distribution stage) | US1: **under 50K auto-approves**; **50K or more goes to the preparer's manager** (Casey → Anita Kennedy). A test rule `1 is 1` also routes **every requisition to CASEY.BROWN** (§6.1). |
| PO approval (`DocumentApproval`) | 14 participants across Preapproval, Terms (contract terms) and Postapproval stages, all rule-based except Funds Override | **Observed 2026-11-23 via API (PO US165366, 2,190 USD, buyer Casey):** only `TermsApprovalHierarchyRules_POSelfApproval` fired and auto-approved, so the PO went straight to Open with no human approver. See API_Findings.md §7.4. |
| Invoice approval (`FinApInvoiceApproval`) | 26 rule-based participants: invoice line, invoice request and invoice header levels | Whether invoice approval is switched on is a Payables Options setting. It was not checked. |
| Payment approval (`PaymentApproval`) | 1 serial participant, `PaymentApprovalRuleSet` | Approval group **AP Payment Approvers** = matthew.schnieder, kerry.lane |
| Receipt | No receipt approval task. Only return and FYI notification tasks exist (`RcvInvMgmtReturnTask`, `RcvSelfSvcReturnTask`, `RcvSelfSvcFyiTask`, `RcvInvMgmtFyiTask`). | Receipts post without approval |
| Accounts | Every named approver has an Active, unlocked account in the US1 Business Unit, except `camille.fredricks`, who has **no user account** | See Blockers |
| Evidence the flow works | The Things to Finish feed shows Req 204160 approved and PO US165363 implemented, and Req 204161 approved and PO US165364 implemented (by Calvin Roth), 3 days ago | Requisition to PO works end to end for Casey |

---

## 2. Business processes

The navigation paths are **standard** Redwood/ADF entry points unless marked verified. The Home group tabs Procurement, Supply Chain Execution and Payables exist (**verified**).

### 2.1 Create requisition

| # | Step | Navigation | Notes |
|---|---|---|---|
| 1 | Open Purchase Requisitions | Home > Procurement > Purchase Requisitions (Redwood "Shop") | Redwood pages can take up to 2 minutes to load |
| 2 | Add a non-catalog or catalog item | Shop > Request Noncatalog Item / search catalog | Needs category, amount, supplier (optional) |
| 3 | Review the cart | Cart / Review | Charge account defaults from the requester's assignment (Finance US) |
| 4 | Submit | Submit | Routes through `ReqApproval` (§3.1) |
| 5 | Track | Purchase Requisitions > Requisitions list | Status Pending Approval > Approved; then the PO is created (buyer or auto) |

**Verified in P2P-01 (2026-11-22):** the Redwood requisitions URL, the noncatalog form, the cart, submit, View Approvers, withdraw (Edit), Save for Later and Cancel. Exact steps and element names are in `OracleFusion_Automation_Playbook.md` §5–§7. Approval amount = subtotal + 9.5% nonrecoverable tax.

**Verified:** Casey has requested before. Requisitions 204160 and 204161 were both approved, with Casey Brown named as approver on the FYI. Possible reasons: the requester-level rule auto-approves, Casey approves within her own limit, or the hierarchy rule resolved to Casey. Confirm this from the rule conditions (§6).

### 2.2 Purchase order

| # | Step | Navigation | Notes |
|---|---|---|---|
| 1 | Process requisition lines | Home > Procurement > Purchase Orders > Tasks > Process Requisitions | Buyer step. Casey has **Redwood Buyer** (custom); Calvin and Tiffany have the standard **Buyer** role. |
| 2 | Create / edit PO | Purchase Orders > Create Order, or from requisition | BU **US1 Business Unit** |
| 3 | Submit | Submit | Routes through `DocumentApproval` (§3.2) |
| 4 | Implemented / dispatched | Purchase Orders > Manage Orders | Status Open after approval |

### 2.3 Receipt

| # | Step | Navigation | Notes |
|---|---|---|---|
| 1 | Receive items | Home > Procurement > Purchase Requisitions > Receive Items (self-service), or Supply Chain Execution > Receipts > Receive Expected Shipments | Casey and Calvin have **Receiving Agent** |
| 2 | Submit receipt | Submit | No approval. Only FYI notifications go out. |
| 3 | View receipts | Manage Receipts | Needed for 3-way match before invoice |

### 2.4 Supplier invoice

| # | Step | Navigation | Notes |
|---|---|---|---|
| 1 | Create invoice | Home > Payables > Invoices > Tasks > Create Invoice | **Invoice Type** list needs hardware events (see project note) |
| 2 | Match to PO / receipt | Create Invoice > Match Invoice Lines | |
| 3 | Validate | Invoice Actions > Validate | Holds (match, amount) stop approval |
| 4 | Initiate approval | Invoice Actions > Approval > Initiate | Routes through `FinApInvoiceApproval` (§3.3), but only if invoice approval is enabled in Payables options (**open**) |
| 5 | Account | Invoice Actions > Account | |

### 2.5 Payment

| # | Step | Navigation | Notes |
|---|---|---|---|
| 1 | Pay single invoice | Payables > Invoices > invoice > Pay in Full, **or** Payables > Payments > Create Payment | |
| 2 | Payment process request (batch) | Payables > Payments > Submit Payment Process Request | |
| 3 | Payment approval | `PaymentApproval`, serial, `PaymentApprovalRuleSet` | Approver group **AP Payment Approvers** (§4). Only applies if payment approval is enabled in Payables options (**open**). |
| 4 | Confirm | Manage Payments / Manage Payment Process Requests | |

---

## 3. Approval routing (BPM task configuration)

**Where this was read (verified):** BPM Worklist (`/integration/worklistapp/faces/home.jspx`) > Casey Brown menu > Administration > Task Configuration > *task* > Assignees. Each participant was selected to read its properties. All rule-based participants show "Rule-based" with the rule-set name. The conditions sit behind "Go to rule" (see §6).

The tenant also shows a warning: "Associated flex fields have been modified… Start Synchronization". That is an admin action and was **not** clicked. Leave it to the tenant owner.

### 3.1 Requisition: `ReqApproval` (PrcPorManageReqApprovalComposite 11.13.26.07.0)

Setup and Maintenance > Setup: Procurement > Approval Management > Manage Requisition Approvals lists the same 13 participants, all enabled.

| Stage | Participant | Routing / voting | Rule set |
|---|---|---|---|
| Header Preapproval | Requester FYI | FYI | — |
| | Preapproval Header Consensus | Parallel, consensus | PreApprovalHeaderConsensusRules |
| | Preapproval Header First Responder Wins | Parallel, first responder | PreApprovalHeaderFirstResponderWinsRules |
| | Preapproval Header Hierarchy | Serial | PreApprovalHeaderHierarchyRules |
| Header | Header Hierarchy | Serial | **HeaderHierarchyRules** (the Oracle default is supervisor hierarchy) |
| | Header First Responder Wins | Parallel, first responder | HeaderStageFirstResponderWinsRules |
| | Header Consensus | Parallel, consensus | HeaderStageConsensusRules |
| | Header Hierarchy 2 | Serial | HeaderHierarchy2Rules |
| | Header Hierarchy 3 | Serial | HeaderHierarchy3Rules |
| Header Postapproval | Postapproval Header Consensus | Parallel, consensus | HeaderConsensusRules |
| | Postapproval Header First Responder Wins | Parallel, first responder | HeaderFirstResponderWinsRules |
| | Postapproval Header Hierarchy | Serial | PostApprovalHeaderHierarchyRules |
| | Funds Override Approval | Parallel, consensus | **Not rule-based.** User comes from payload `findReqHeaderDimensionResponse/result/FundsOverrideApprover`, which budgetary control sets. It only fires on a funds-check failure with override. |

### 3.2 Purchase order: `DocumentApproval` (PrcPoApprovalComposite)

| Stage | Participant | Rule set |
|---|---|---|
| Preapproval | Preapproval FYI, Preapproval Serial, Preapproval Parallel Consensus, Preapproval Parallel First Responder Wins | PreApprovalHierarchyRules, PreApprovalParallelConsensusRules, PreApprovalFirstResponderWinsRules |
| Terms (contract terms / clauses) | Terms Approval FYI, Terms Approval Serial, Terms Approval 2 Serial, Terms Approval 3 Serial, Terms Parallel FRW, Terms Parallel Consensus | TermsApprovalFYIRules, TermsApprovalHierarchyRules, TermsApprovalHierarchy2Rules, TermsApprovalHierarchy3Rules, TermsApprovalFirstResponderWinsRules, TermsApprovalParallelConsensusRules |
| Postapproval | Postapproval Serial, Postapproval Parallel Consensus, Postapproval Parallel FRW, Postapproval FYI | PostApprovalHierarchyRules, PostApprovalParallelConsensusRules, PostApprovalFirstResponderWinsRules, PostApprovalFYIRules |
| Postapproval | Parallel Funds Override Approval (consensus) | **Not rule-based.** Payload expression, as for requisitions. |

The approval groups **ClauseApprovalGroup** and **Clause Deviation Approval** exist. They are probably used by the Terms stage rules (unconfirmed).

### 3.3 Supplier invoice: `FinApInvoiceApproval` (FinApInvTransactionsInvoiceApprovalComposite 11.13.26.10.0)

All 26 participants are rule-based.

| Level | Participants (rule set) |
|---|---|
| Invoice line | InvoiceLineApprovers (InvoiceLineApproversRuleset); Parallel / Single / FYI in parallel mode; Parallel / Single / FYI "One in sequence"; Serial / Parallel / Single "Two in sequence" (rule sets `InvoiceLineApprovers…Ruleset`) |
| Invoice request (invoices without a PO from the supplier portal) | InvoiceRequestDefaultApprovers (InvoiceRequestDefaultApproversRuleSet); InvoiceRequestAdditionalApprovers (InvoiceRequestApprovalRuleSet); Custom Single / FYI / Parallel in parallel mode |
| Invoice header | InvoiceApprovers (**InvoiceApprovalRuleSet**); Parallel / Single / FYI in parallel mode; Parallel / Single / FYI one-in-sequence; Serial / Parallel / Single / FYI two-in-sequence |

Two older tasks also exist:
- `ApproveInvoiceTask`: participant InvoiceApprovers1, rule `ApproveInvoice`.
- `InvoiceApprovalHumantask`.

The live Redwood/ADF invoice approval uses `FinApInvoiceApproval`.

### 3.4 Payment: `PaymentApproval`

| Participant | Routing | Rule set |
|---|---|---|
| PaymentApprovalSerialParticipant | Serial | PaymentApprovalRuleSet |

The approval group **AP Payment Approvers** exists (members in §4). The rule set very likely routes to it, but the condition is still open.

### 3.5 Receipt

There is no receipt approval task. Receiving tasks are only for returns (`RcvInvMgmtReturnTask`, `RcvSelfSvcReturnTask`) and FYI notifications (`RcvSelfSvcFyiTask`, `RcvInvMgmtFyiTask`).

---

## 4. Approval groups (BPM Worklist > Administration > Approval Groups, verified)

| Group | Members | Likely P2P use |
|---|---|---|
| AP Payment Approvers | matthew.schnieder, kerry.lane | Payment approval |
| CategoryApprovalGroup | tiffany.irving | Requisition / PO category-based rules |
| ITPurchaseApproval | tiffany.irving | IT category purchases |
| Purchase Pricing Managers | **camille.fredricks (no user account)** | External purchase price approval; not core P2P |
| NewItemRequestApprovalGroup | kevin.schott | New item requests (PIM) |
| CEO | thomas.mack, casey.brown, anita.kennedy, michael.buchanan, william.taylor | High-value escalation |
| BlankApproval group | *(no members)* | Any rule that routes here will error or stall |
| Others | Billing_Manager_Approval_Group_* (BE, CH, CN, ES, FR, HC, IT, JP, NE, PL, PRGUS, SE, SupremoUS, TR, UK, US1, University US), Collection_Manager_Approval_Group_* (CH, CN, DE, ES, FR, IT, JP, NE, …), ClauseApprovalGroup, Clause Deviation Approval | Receivables/billing and contract terms; country- or BU-specific; outside P2P except the clause groups |

Searches for "Invoice", "Procure", "Buyer" and "Finance" found no other groups.

---

## 5. Personas (Security Console > Users, read only, verified)

Every user listed is Active, unlocked and assigned to **US1 Business Unit**. Password expiry for all of them is 19/02/27.

**Who can sign in:** only Casey's password is available to the robot, through `Oracle_Fusion_P2P_Test`. Every other persona needs its own credential asset before a test can sign in as them.

| User (login) | Job / dept | Manager | Key P2P roles | BU | Initiator? | Approver? |
|---|---|---|---|---|---|---|
| **Casey Brown** (`CASEY.BROWN`): robot login | Administrator, Finance US | Anita Kennedy | Advanced Procurement Requester, Redwood Buyer (custom `PO_BUYER_REDWOOD`), Receiving Agent, AP Specialist / Supervisor / Manager / Invoice Supervisor / Payment Supervisor, Payment Specialist, Category Manager, Procurement Application Administrator, Supplier Administrator, Employee, Line Manager, IT Security Manager (130 roles in total) | US1 | **Yes, for every step**: requisition, PO, receipt, invoice, payment | Is in the **CEO** group. Self-approval risk: one login holds requester, buyer and AP roles, which is a segregation-of-duties problem. |
| **Anita Kennedy** (`ANITA.KENNEDY`) | Chief Financial Officer, Executive Office | William Taylor | Employee, Line Manager only (18 roles) | US1 | No | **Yes**: Casey's supervisor, so the first approver for supervisor-hierarchy rules on Casey's requisitions. Also in CEO group. |
| **William Taylor** (`WILLIAM.TAYLOR`) | (not opened) | — | — | — | No | Anita's manager (next hierarchy level); CEO group |
| **Calvin Roth** (`CALVIN.ROTH`) | Procurement Manager, Procurement US | James Seller | Buyer, Procurement Manager, Procurement Requester, Advanced Procurement Requester, Procurement Preparer, Category Manager, Receiving Agent, AP Manager, Supplier Manager (77 roles) | US1 | Yes (buyer / PO) | Yes: Tiffany's supervisor and Procurement Manager. Implemented PO US165364. |
| **Tiffany Irving** (`TIFFANY.IRVING`) | Buyer, Procurement US | Calvin Roth | Buyer, Procurement Manager, Procurement Requester, Advanced Procurement Requester, Preparer, Category Manager (42 roles) | US1 | Yes (requester / buyer) | Yes: sole member of **CategoryApprovalGroup** and **ITPurchaseApproval** |
| **Matthew Schnieder** (`MATTHEW.SCHNIEDER`) | Payables Manager, Payables US | Kerry Lane | Accounts Payable Manager (29 roles) | US1 | Yes (invoice / payment) | Yes: **AP Payment Approvers** |
| **Kerry Lane** (`KERRY.LANE`) | Controller, Accounting US | James Seller | GSE Payables Invoice Inquiry, GSE PAYABLES UHP, Line Manager (41 roles) | US1 | No | Yes: **AP Payment Approvers**; Matthew's supervisor |
| **Kevin Schott** (`KEVIN.SCHOTT`) | Manager, Manufacturing US | James Aaron | PO view (BI), PLM Purchase Analysis (39 roles) | US1 | No | NewItemRequestApprovalGroup only |
| James Seller (`james.seller`) | (not opened) | — | — | — | — | Top of the procurement and accounting chain; Active, unlocked |
| Thomas Mack (`thomas.mack`), Michael Buchanan (`michael.buchanan`) | (not opened) | — | — | — | — | CEO group; Active, unlocked |

**Data access:** Security Console shows role assignments, not procurement BU access. "Manage Procurement Agents" (procurement BU and action access) and "Manage Data Access for Users" were **not** read. Each user's BU above is the BU of their worker assignment.

**Data roles:** none of the roles have a BU-specific data-role name (for example "… US1"). Access appears to come from data access sets or the procurement agent setup, which is still open.

---

## 6. Approval rule conditions

**Where these were read (verified):** BPM Worklist > Administration > Task Configuration > *task* > Assignees. Select the participant, then click the rule-set link in its properties panel.
- The link needs a **hardware** click; see §9.
- The rule set opens in a view with tabs Rules / Value Sets / Globals / Advanced. Each rule is selected to show its IF/THEN.
- Nothing was edited. "Edit task" was not clicked.

The raw captures are in the scratchpad (`uia/text/req_rules_all.txt`).

### 6.1 Requisition: `ReqApproval` > Header Hierarchy > **HeaderHierarchyRules** (23 rules)

**Business-unit IDs used in the rules.** The BU names are inferred from the rule names; the IDs were not mapped in Manage Business Units.

| BU ID | BU (inferred from rule name) |
|---|---|
| 300000047826665, 300000047826669 | Japan BU, India BU |
| 300000075888561 | Progress US BU |
| 300000257522698 | SA PS BU |
| 300000093962136 | Awards (grants) BU |
| *(all others, including **US1 Business Unit**)* | the "not in" rules below |

`approvalTotal` = requisition approval amount, `overridingApproverId` = the Approver override field on the requisition, `enteredByUsername` = preparer.

#### Rules that apply to US1 (the BU of all our personas)

| Rule | IF | THEN | Test impact |
|---|---|---|---|
| **Requisition Approval - Casey Brown** ("Test Approval for Casey Brown") | `1 is 1`: always true, **every BU, every requisition** | Resource list: user **CASEY.BROWN** | **Every requisition in the tenant also routes to Casey.** This is why Casey approved her own Req 204160 and 204161. A Casey-initiated requisition gets a worklist approval for Casey. Tests must expect it, or the rule must be disabled by the tenant owner. |
| **Requsition Self Approval under 50K** | override is null AND approvalTotal **< 50,000** AND BU **not in** {Japan, India, Progress US, SA PS} | Supervisory, 1 level, from/to `fusion_apps_prc_adf_appid`, **Auto action = APPROVE** | Requisitions under 50K USD in US1 auto-approve (apart from the Casey rule above) |
| **Requisition Supervisory 50K Approval** | override is null AND approvalTotal **≥ 50,000** AND BU **not in** {Japan, India, Progress US, SA PS} | Supervisory, **1 level**, starting at the **preparer's manager**, top = **WILLIAM.TAYLOR** | Casey ≥ 50K → **Anita Kennedy** (CFO). Tiffany ≥ 50K → Calvin Roth. |
| **Requisition 50K and Override** | override **is not** null AND approvalTotal ≥ 50,000 AND BU not in {…} | Supervisory, 1 level, starting at the **override approver**, top = WILLIAM.TAYLOR | Setting the Approver override sends it to that person |
| **CRM Users and 100** | override is null AND approvalTotal ≥ 100 AND requester in a fixed list of ~130 person IDs | Supervisory, 1 level from preparer's manager, top = WILLIAM.TAYLOR | Applies only to named CRM demo users; whether Casey (person no. 4) is in the list is unknown, since IDs weren't mapped |
| **MBP P2P for EMMA EMPLOYEE** | requisitionTotal ≥ 0 AND requester = person 300000257246573 (Emma Employee) AND override is null | Supervisory, 1 level from requester's manager, top = WILLIAM.TAYLOR | Only for that requester |

#### Rules for other business units (do not use in US1 tests)

| Rule | IF | THEN |
|---|---|---|
| Japan and India BU Requisition under 1M Self Approval | BU in Japan/India AND total < 1,000,000 AND no override | Auto APPROVE |
| Japan and India BU Requisition 1M Approval | BU in Japan/India AND total ≥ 1,000,000 AND no override | Supervisory 1 level from preparer's manager, top WILLIAM.TAYLOR |
| Japan and India BU Requisition 1M and Override | as above, with override | Supervisory from override approver, top WILLIAM.TAYLOR |
| Progress US BU Req under 1K | BU Progress US AND total ≤ 1,000 AND no override | Auto APPROVE |
| Progress US BU Req between 1K to 10K (with or without Override) | BU Progress US AND 1,000–10,000 | Approval group **ProgressUSperry** |
| Progress US BU Req over 10K (with or without Override) | BU Progress US AND ≥ 10,000 | Approval group **ProgressUSperryCHEN** |
| SA PS Req Approval under 50K Auto Approve | BU SA PS AND ≤ 50,000 | Auto APPROVE |
| SA PS Requisition Approval Over 50K to manager | BU SA PS AND > 50,000 | Supervisory 1 level from preparer's manager, top **Khalid.Almajid** |
| Healthcare BU Chun Yao 50 to 5000 / 5000 or more | requester = Chun Yao (300000100091105); 50–5,000 / ≥ 5,000 | Approval group **HealthcareCamille** / **HealthcareCamilleMonika** |
| Healthcare BU Camille Fredricks 5000 or less | requester = Camille Fredricks (300000087881329); ≤ 5,000 | Auto APPROVE |
| Healthcare BU Camille Fredricks 5000 to 50000 / 50000 or more | same requester; 5,000–50,000 / ≥ 50,000 | Approval group **HealthcareMonika** / **HealthcareMonikaEdward** |
| Awards PR approval rule1 | Awards BU AND project PI = 300000095986021 | Auto APPROVE |
| Awards PR approval rule2 | Awards BU AND project PI ≠ 300000095986021 | User **thomas.magnum** |

The approval groups ProgressUSperry, ProgressUSperryCHEN, HealthcareCamille, HealthcareCamilleMonika, HealthcareMonika and HealthcareMonikaEdward did not come up in the group keyword search (§4). Their members were not read. They aren't needed for US1.

### 6.2 Other rule sets: **Open** (next exploratory session)

These were **not read** in this session:

| Task | Rule sets still to read |
|---|---|
| `ReqApproval` | PreApprovalHeaderConsensusRules, PreApprovalHeaderFirstResponderWinsRules, PreApprovalHeaderHierarchyRules, HeaderStageFirstResponderWinsRules, HeaderStageConsensusRules, HeaderHierarchy2Rules, HeaderHierarchy3Rules, HeaderConsensusRules, HeaderFirstResponderWinsRules, PostApprovalHeaderHierarchyRules |
| `DocumentApproval` (PO) | All 13 rule sets in §3.2 |
| `FinApInvoiceApproval` | All 26 rule sets in §3.3; **InvoiceApprovalRuleSet** (header) matters most |
| `PaymentApproval` | PaymentApprovalRuleSet |

Many of these may be empty. Oracle ships the stages, and only the ones a tenant configures carry rules. Record "empty" explicitly when you find one.

**Why the automated scan failed, and how to avoid it next time:**
- After a rule set opens, the Rules view replaces the participant diagram and stays on the first rule set opened. Re-selecting another participant did not change it, so every capture showed HeaderHierarchyRules again.
- **Fix:** before selecting the next participant, go back to the diagram. Re-open the Assignees tab, or re-open the task from "Tasks to be configured", and check that "Switch to Vertical Layout" is visible again.
- In `DocumentApproval`, selecting a participant by its cut-off label did not expose the rule-set link (13 of 14 gave "no rule-set link"). The properties panel probably hadn't loaded yet.
- **Fix:** after selecting, wait until the `SoaOLabel.<Name>` field shows the expected participant before looking for the link.
- Confirm that each rule's details panel changed. A rule whose details repeat the previous rule's name was not actually selected. Scroll it into view with a DebuggerApi click, then hardware-click it.
- All of this needs Chrome in front and the PC left idle for the run.

The prompt for the next session, [Prompts/2-Map-the-app - Fixed.md](Prompts/2-Map-the-app%20-%20Fixed.md), includes these steps.

### 6.3 Still unchecked

- Payables options: is **invoice approval** enabled? *AP-01 (2026-11-23):* the invoice Approval submenu offers Initiate / Withdraw / Resubmit / Force Approve, and the Approval infotile shows 15 Others and 4 Rejected. But a canceled test invoice showed Approval Status "Not required". **Answered via REST (API_Findings.md §7 R4, corrected):** invoice approval is used heavily in other BUs. In US1 it has been used historically (9 Workflow approved, newest 14/11/25; 2 Rejected; 1 Manually approved). New US1 invoices, both manual (889900, UIP-AP-231126-1013), came out *Not required*, so the current rules don't require approval for them. Nothing is pending in US1.
- Invoice tax for US1 / ABC US1 is 9.0% exclusive (California county + state), not the 9.5% seen on Seattle requisitions. Why the jurisdiction is California is **Open**.
- Payment options: is **payment approval** enabled?
- Procurement BU access for each user (Manage Procurement Agents).
- The ID for US1 Business Unit. It is inferred to be outside the excluded list above but was not looked up.

Do **not** use Setup and Maintenance > Manage … Approvals > Edit Rules. It opens the rules in edit mode.

---

## 7. Blockers and risks

| # | Item | Severity | Detail |
|---|---|---|---|
| B0 | **Catch-all "Requisition Approval - Casey Brown" rule** | High | Condition `1 is 1`. Every requisition from any user or BU gets an approval step for CASEY.BROWN. A Casey-initiated requisition therefore lands in Casey's own worklist. Other testers' requisitions also land in Casey's worklist, and those must not be touched. Tests must approve only the requisition they created, identified by its number. |
| B1 | **Approver without a login** | Medium | `camille.fredricks` has no user account; searching "fredricks" returns nothing. She is the only member of **Purchase Pricing Managers**. She is also the requester in three Healthcare BU requisition rules. Any external purchase price approval will route to a non-existent user. This is not on the core US1 P2P path. |
| B2 | **Empty approval group** | Medium | **BlankApproval group** has no members. If any rule routes to it, approval stalls or errors. Check this when reading the rules (§6). |
| B3 | **Only one robot login** | High for approval tests | Only `Oracle_Fusion_P2P_Test` (Casey) exists. Approval steps route to Anita Kennedy (supervisor), Tiffany Irving (category), or Matthew Schnieder / Kerry Lane (payments). To test approval end to end, add credential assets for those users. Otherwise, design tests so Casey's own approval or auto-approval completes the flow. |
| B4 | **Segregation of duties** | Medium | Casey holds requester, buyer, receiver, AP and payment roles plus CEO-group membership. A test may self-approve or skip routing, so it won't exercise real approval paths. |
| B5 | **Business-unit and country-specific rules** | Info | Every persona sits in **US1 Business Unit** (US departments: Finance US, Procurement US, Payables US, Accounting US). Requisition rules branch by BU: Japan/India (1M threshold), Progress US (1K / 10K), SA PS (50K, top approver Khalid.Almajid), Awards. The billing and collection approval groups are country-specific. Use only US1 in tests. **Pick test amounts deliberately:** < 50,000 USD for auto-approval, ≥ 50,000 USD to exercise the supervisor approval. |
| B6 | **Flex field synchronisation pending** | Low | BPM shows "Associated flex fields have been modified… Start Synchronization" on `ReqApproval` and other tasks. Rules that use new flex fields may behave unexpectedly until an admin synchronises. Do not click it from a test. |
| B7 | **Funds override approvals** | Low | Requisition and PO Funds Override participants resolve from a budgetary-control payload, not a named user. They only fire on a failed funds check. Keep test amounts within budget. |
| B8 | **Invoice Type list** | Info | ~~It needs hardware events.~~ **Corrected in AP-01 (2026-11-23):** typing the option's first letter + Tab with DebuggerApi selects it in the background. See Playbook §8.1. |
| B9 | **Account expiry** | Info | Every account checked has password expiry 19/02/27 (dd/mm/yy, so 19 Feb 2027). That is not a blocker before then. |

No inactive, locked or end-dated accounts were found among the users checked.

---

## 8. Recommended test personas

| Role in test | Use | Reason |
|---|---|---|
| Requester / initiator | Casey Brown (robot login) | Has every initiator role and worked end to end in recent history |
| Requisition approver (supervisor hierarchy) | Anita Kennedy | Casey's manager, Active. **Needs a credential asset.** |
| Buyer / PO | Casey Brown (Redwood Buyer) or Calvin Roth (Buyer, Procurement Manager) | Calvin implemented a recent PO |
| Category approver | Tiffany Irving | Sole member of CategoryApprovalGroup and ITPurchaseApproval |
| Receiver | Casey Brown | Receiving Agent |
| AP invoice entry | Casey Brown or Matthew Schnieder | AP roles |
| Payment approver | Matthew Schnieder or Kerry Lane | AP Payment Approvers |

### Suggested test data per scenario (US1)

| Scenario | Requisition amount | Expected routing |
|---|---|---|
| Happy path, no human approval | < 50,000 USD **approval amount, tax included** (for example 1,000) | **Verified P2P-01 (204162):** not auto-approved. The requisition stays "Pending approval by Casey Brown, Header Hierarchy: RequisitionApprovalCaseyBrown" until Casey approves it in the BPM Worklist |
| Supervisor approval | ≥ 50,000 USD | Anita Kennedy (needs her credential asset), plus the CASEY.BROWN step |
| Approver override | any amount ≥ 50K with Approver override set | The override approver, top William Taylor |
| Funds failure | over budget | Funds Override participant (budgetary control); avoid unless you are testing it |

---

## 9. Automation guide (technical navigation and UI behaviour)

> **See also `OracleFusion_Automation_Playbook.md`.** It is the maintained, step-by-step guide to driving this tenant: Redwood requisitions, list-of-values recipe, withdraw and cancel, BPM approvals, sign-in switching, helper script `P2PGuide/tools/of.ps1`, and Test Manager capture. It was verified in exploratory session P2P-01 (2026-11-22). This section keeps the original exploration observations.

Everything here was observed while driving the tenant with `uip rpa uia` against Chrome. The project's own workflows use Edge `NApplicationCard` (incognito, DebuggerApi, maximised), and the same behaviour applies.

### 9.1 URLs (relative to `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`)

| Page | URL | Ready marker (text to wait for) |
|---|---|---|
| Home | `/fscmUI/faces/FuseWelcome` | `Good morning/afternoon/evening, <name>` |
| Setup and Maintenance | `/fscmUI/faces/FuseTaskListManagerTop` | `Setup:` and the offering name |
| BPM Worklist | `/integration/worklistapp/faces/home.jspx` | `My Tasks` |
| BPM Administration, Task Configuration | `/integration/worklistapp/faces/administration.jspx?selectedAdminTab=taskEditor` | `Tasks to be configured` |
| BPM Administration, Approval Groups | `/integration/worklistapp/faces/administration.jspx?selectedAdminTab=approvalGroup` | `Groups` |
| Security Console | `/hcmUI/faces/FndOverview` (Home > Tools > Security Console) | `Roles` / `User Accounts` |

You can open these URLs directly; going straight to the BPM URL is much faster than the menus. ADF adds `_afrLoop`, `_adf.ctrl-state` and similar parameters. **Never hard-code them**; match on title or path only.

### 9.2 Window and page identity

- **Browser title:** "Oracle Fusion Cloud Applications" for the Home page and most ADF pages. Setup is "Setup and Maintenance - Oracle Applications", BPM is "BPM Worklist", and Security Console is "Users - Security Console - Oracle Fusion Cloud Applications". Match the tab by URL path, not by title alone. Title and URL change on every ADF navigation.
- A **Sandbox banner** shows across the top. It shifts layout down, so don't anchor on fixed positions.
- **Load times:** BPM about 20 s; Redwood pages up to 2 min. Use "wait for ready marker" (poll the text every 5 s, timeout ≥ 150 s), never a fixed delay. A blank page is normal during load.
- **Spontaneous refresh:** ADF pages sometimes re-render on their own. Element references from before the refresh become invalid, so re-find targets after every navigation or partial page refresh.

### 9.3 Input methods: what works where

| Element | DebuggerApi | Simulate | Hardware events |
|---|---|---|---|
| Links, buttons, tabs, table rows, BPM participant boxes, approval-group names | ✅ | ✅ | ✅ |
| Text inputs (task, user, group search) | ✅ with **clear = Empty field (single line)** | | |
| BPM "Go to rule" icon / rule-set link (e.g. `HeaderHierarchyRules`) | ❌ ignored | ❌ | ✅ (needs window in focus) |
| BPM rule rows in the rules view | — | — | ✅ (scroll the row into view first with a DebuggerApi click) |
| BPM: moving from one rule set to the next | the Rules view stays on the first rule set; go back to the Assignees diagram before selecting the next participant | | |
| Payables **Invoice Type** list | ❌ | | ✅ (project note) |
| Mouse wheel / scrolling | ❌ (needs focus) | | ✅ |
| Home group tabs (`groupNode_procurement`, `groupNode_payables`, …) | ⚠️ the click lands but the tile panel didn't switch. Use the Navigator or a direct URL instead. | | not tried |

- **Clearing fields:** never use Ctrl+A in an ADF table, because it selects every row and Oracle drops the typed value. Use "Empty field (single line)".
- **Focus:** hardware events and screenshots need Chrome or Edge to be the active window. Windows' foreground lock refuses that while someone is typing in another window, with the error "Cannot bring the target application in the foreground". Run attended steps that need hardware input only when the PC is idle, or set `HKCU\Control Panel\Desktop\ForegroundLockTimeout = 0` on the robot machine.

### 9.4 Selector and target guidance (ADF / BPM)

- **IDs are dynamic** (`pt1:…:r1:0:…`). Use semantic attributes: visible text, `aria-label`, `title`, and `role`.
- **Duplicate invisible copies:** the navigator and group panels have hidden duplicates of each link. These show as `[invisible]` and resolve to screen position about (1920, 54). Target the visible instance, for example by also requiring a visible parent.
- **Search icons** are images with a title, for example `Search task types` (BPM), `Search Approval Group` (BPM) and `Search` (Security Console). The `Search` link next to the Setup "Search Tasks" box is a separate `<a>`.
- **BPM participant labels are truncated** ("Header Hierarc…"). The full name appears only in the properties panel after selection, in the input `SoaOLabel.<Name>`. Select a participant by position in the diagram, or by the truncated text plus its stage.
- **Large pages:** Setup and Maintenance renders over 3000 elements, and the UIA snapshot caps at 3000. Narrow targets with an anchor (for example the Search Tasks box) rather than scanning the full tree.
- **Virtualised tables:** Security Console roles render only 25 rows at a time. Scroll the table's container to load more; reading the first view gives a partial list.
- **Setup task search is offering-scoped:** "Search Tasks" on Setup: Financials only finds Financials tasks, and with "Show: Required Tasks" it finds nothing. Switch the offering (for example to Setup: Procurement > Approval Management) or use the BPM Worklist directly.

### 9.5 Things a robot must never click on these pages

- BPM Task Configuration: **Edit task**, **Save**, **Commit task**, **Reset**, and **Start Synchronization** (flex-field warning banner).
- Approval group details: **Save**, **Revert**.
- Security Console user details: **Edit**, **Reset Password**, **Reset MFA**. **Done** is safe and returns to search.
- Setup and Maintenance > Manage … Approvals: **Edit Rules**.

### 9.6 Reading data reliably

- A page-text read (`document.body.innerText`) was the most reliable way to read ADF pages. It gives the visible text of tables and panels without screenshots.
- Ready checks, record IDs (e.g. requisition number after Submit) and status should be read with **Get Text** on a labelled element, not from screenshots.
- The Home **Things to Finish** feed shows FYI items such as "Requisition 204160 Approved" and "Document (Purchase Order) US165363 (Requisition 204160) Implemented". It is a quick way to confirm that the end-to-end flow worked.

---

## 10. Environment

| Item | Value |
|---|---|
| Pod | `fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com` (Oracle demo, Sandbox banner) |
| UI | Mixed Redwood and ADF; BPM Worklist is classic ADF (© 2024) |
| SOA composite versions seen | PrcPorManageReqApprovalComposite 11.13.26.07.0, PrcPoApprovalComposite, FinApInvTransactionsInvoiceApprovalComposite 11.13.26.10.0 (Oracle 26A/26B-era release) |
| Pending admin action | Flex fields modified, synchronisation pending (BPM warning on several tasks) |
| Business unit for tests | US1 Business Unit |
| Robot login | `Oracle_Fusion_P2P_Test`, folder `Shared/Testing-UBAPI` → CASEY.BROWN (see `run-config.json`) |
| Password expiry (all checked users) | 19/02/27 |
| User category | DEMOSERVICES |
| Shared tenant | Other demo users (Healthcare, Progress US, Japan/India, SA PS, Awards) create transactions here too. Always filter by your own document number. |
