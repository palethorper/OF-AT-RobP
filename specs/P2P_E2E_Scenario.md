# E2E scenario: Oracle Fusion P2P, supplier registration to payment-ready invoice

| | |
|---|---|
| **Requirement** | OFP2P:156 "Oracle Fusion P2P end to end: supplier registration to payment-ready invoice (US1)", acceptance criteria AC1–AC7 |
| **Test case** | OFP2P:157 "E2E P2P: supplier registration to payment-ready invoice (US1, Casey Brown, dev16)", 27 steps, 44 parameters, labels E2E / P2P / DataDriven / Oracle Fusion / Regression |
| **Environment** | `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`, US1 Business Unit, Casey Brown |
| **Built from** | Run reconstructed on 2026-11-23: supplier **1502 UI Path Supplier** → requisition **204169** → PO **US165366** → receipt → invoice **889900** (API_Findings.md §7.3–7.6, reverse-engineering notes) |
| **API checkpoints** | Integration Service HTTP connection *Oracle Fusion dev16 - Basic (integration user)*: REST `/fscmRestApi/resources/11.13.18.05`, BPM `/bpm/api/4.0/tasks` |

---

## 1. Phases and steps

Each phase ends with an **API checkpoint**, so the result is checked against data, not screenshots. Values in `{braces}` are test-case parameters or Data Fabric fields (§3).

| Phase | # | Test step | Expected outcome |
|---|---|---|---|
| **P0 Setup** | 1 | Load scenario `{ScenarioId}` and its child rows from Data Fabric; create `RunId = {RunIdPrefix}-yyMMddHHmm`; insert P2P_TestRun (Running) | Data loaded; RunId used as the prefix on every entered text |
| | 2 | API pre-flight: ping `{ApiConnectionName}`; GET the REST catalog; GET `/bpm/api/4.0/tasks?limit=1` | Connection Enabled; REST 200 (v11.13.18.05); BPM 200 |
| | 3 | Open `{FusionBaseUrl}`, sign in as `{RequesterUser}` (`{CredentialAsset}`; in attended runs the human types the password) | Home page shows the user; no MFA or SSO error |
| **P1 Supplier** | 4 | Suppliers > **Register Supplier**: Company `{SupplierName}`, Tax Org Type, Taxpayer Country and ID | Accepted; the name is unique (RunId) |
| | 5 | Contacts: `{ContactFirstName} {ContactLastName}`, `{ContactEmail}`, admin contact, user account = `{CreateContactUser}` | Contact listed |
| | 6 | Addresses: `{AddressName}`, `{AddressLine1}`, `{City}`, `{PostalCode}`, `{AddressCountry}`; Ordering + Remit-to | Address listed |
| | 7 | Business classification `{BusinessClassification}`; products and services `{ProductsServicesCategory}`; **Register** | Registration request number shown → P2P_CreatedDocument |
| | 8 | BPM Worklist: "Supplier Registration Request <n> for `{SupplierName}`" > Approve > Submit | Success; the other admins' assignments are withdrawn |
| | 9 | Manage Suppliers > Edit > Sites > Create Site (`{BusinessUnit}`, `{AddressName}`, `{SupplierSiteName}`, Purchasing + Pay) > Site Assignments (Auto-Assign) > Save and Close | Site assigned to client BU `{BusinessUnit}` |
| | 10 | **API**: `suppliers` (expand sites, addresses, contacts), site `assignments`, BPM registration and spend task history | ACTIVE, *Spend Authorized*, source Registration; site and assignment ACTIVE; rules `RouteAllRegistrationRequestsToSupplierAdministrators` (approved by the requester) and `SpendAuthorizationGenApprovalRule` (auto) |
| **P2 Requisition** | 11 | Redwood **Create Noncatalog Request**: `{RunId} {ItemDescription}`, `{CategoryName}`, `{Quantity}` `{UOM}` @ `{UnitPrice}` `{Currency}`, `{SupplierName}` / `{SupplierSiteName}` > Add to Cart | Each list-of-values field reads back exactly |
| | 12 | Cart: record requisition #; check the summary | **Approval Amount = Qty × Price × (1 + `{ExpectedReqTaxRate}`) = `{ExpectedApprovalAmount}`**; Deliver-to `{DeliverToLocation}`; Charge To `{ChargeAccount}` |
| | 13 | Submit | "Pending approval Requisition <n>" |
| | 14 | **API**: BPM tasks keyword <req#> + history | Rules match P2P_ExpectedRouting (under 50K: `RequsitionSelfApprovalunder50K` auto → `RequisitionApprovalCaseyBrown` → Casey; category consensus auto. 50K or more: `RequisitionSupervisory50KApproval` → `{SupervisorUser}`) |
| **P3 Approval** | 15 | Each expected approver: "Approve Requisition <n>" > Approve > comment > **Submit** (switch user if needed) | Success; FYI "Requisition <n> Approved" |
| | 16 | **API**: `purchaseRequisitions` expand lines | Approved; line in pool = Y; `POAutomationFailedReason` recorded when no PO was auto-created |
| **P4 PO** | 17 | Buyer `{BuyerUser}`: **Process Requisitions** > add line to Document Builder > Create > Submit | PO # recorded; supplier, site and BU as expected |
| | 18 | **API**: `purchaseOrders` expand lines; BPM tasks keyword <PO#> (status COMPLETED) + history | **Open**; Ordered = Qty × Price; TotalTax / Ordered = `{ExpectedPoTaxRate}`; rule `TermsApprovalHierarchyRules_POSelfApproval` auto; FYI "Implemented" |
| **P5 Receipt** | 19 | **Receive Items**: PO <n>, quantity `{ReceiptQuantity}` > Submit | Receipt # recorded |
| | 20 | **API**: `purchaseOrders` expand `lines,lines.schedules` | ReceivedQuantity = `{ReceiptQuantity}`; *Closed for Receiving* when complete; match level `{ExpectedMatchLevel}` |
| **P6 Invoice** | 21 | **Create Invoice**: BU, supplier, site, number `{RunId}-INV`, amount `{InvoiceAmount}`, Identifying PO <n> / Match Invoice Lines, terms `{PaymentTerms}` > Save | "Create Invoice: <n>", Not validated, line matched to PO |
| | 22 | Invoice Actions > Calculate Tax > **Validate** (open the status chip for the summary) | **Validated, 0 holds**. With `{InvoiceAmountMode}`=ExcludesTax a *Line Variance* hold is expected (negative path) |
| | 23 | **API**: `invoices`, `invoiceLines`, `invoiceHolds`, withholding invoices (`LIKE 'Withholding tax-<id>%'`, framework v2) | Validated; approval `{ExpectedInvoiceApprovalStatus}`; MatchType ITEM_TO_PO; tax = Ordered × rate; 0 holds; withholding only if `{ExpectWithholding}` |
| **P7 Payment** | 24 | **API**: `invoices/<id>/child/invoiceInstallments` | **Ready**: Validated ∧ approval OK ∧ 0 holds ∧ HoldFlag false ∧ Unpaid = `{InvoiceAmount}`; due = date + terms; method Electronic |
| | 25 | *Optional* (`{ExecutePayment}`=Yes with owner approval): Pay in Full; check PaymentApproval routing | Payment # or AP Payment Approvers task; otherwise N/A |
| **P8 Cleanup** | 26 | Reverse all RunId documents, newest first: void payment (owner approval), cancel invoice (+ withholding), cancel PO, cancel requisition, inactivate site and supplier, deactivate contact user | All Canceled or Inactive in the API; no open BPM tasks; CleanupStatus = Done |
| | 27 | Attach evidence (page text, screenshots, API JSON); close P2P_TestRun | Evidence on the test case log; result recorded |

### Negative and variant paths (driven by data, same test case)

| Variant | Data change | Expected difference |
|---|---|---|
| Supervisor approval | `UnitPrice` such that approval amount ≥ 50,000 (e.g. 45,662.10 → 50,000.00) | Step 14: `RequisitionSupervisory50KApproval` → Anita Kennedy; step 15 needs a user switch |
| Boundary just under | approval amount 49,999.99 (price 45,662.09) | Same as the happy path |
| Override approver | `OverridingApprover` = Calvin Roth, approval amount ≥ 50K | `Requisition50KandOverride` → Calvin, Anita skipped |
| Existing supplier | `SupplierSource` = Existing (e.g. Dell Inc. / Dell US1) | Skip P1 (steps 4–10) |
| Tax not in header | `InvoiceAmountMode` = ExcludesTax | Step 22: Needs revalidation, Line Variance hold |
| Partial / over receipt | `ReceiptQuantity` < or > Quantity | Schedule stays open / over-receipt tolerance 50%, action None (no block) |
| Withholding supplier | supplier site with withholding (ABC Consulting / ABC US1) | Step 23: IRS withholding invoice created; cleanup must handle it |

---

## 2. Test Manager parameters (44, defaults = reconstructed run)

ScenarioId, RunIdPrefix, FusionBaseUrl, ApiConnectionName, CredentialAsset, RequesterUser, BuyerUser, SupervisorUser, BusinessUnit, SupplierName, TaxOrganizationType, TaxpayerCountry, TaxpayerId, ContactFirstName, ContactLastName, ContactEmail, CreateContactUser, AddressName, AddressLine1, City, PostalCode, AddressCountry, BusinessClassification, ProductsServicesCategory, SupplierSiteName, ItemDescription, CategoryName, Quantity, UOM, UnitPrice, Currency, ExpectedReqTaxRate, ExpectedApprovalAmount, DeliverToLocation, ChargeAccount, ExpectedPoTaxRate, ReceiptQuantity, ExpectedMatchLevel, InvoiceAmount, InvoiceAmountMode, PaymentTerms, ExpectedInvoiceApprovalStatus, ExpectWithholding, ExecutePayment.

Each parameter's hint names the Data Fabric field that should feed it. Passwords are **never** parameters; sign-in uses the credential asset.

---

## 3. Suggested Data Fabric model (not created yet)

One scenario row drives one run. Child entities hold the data and expectations, so new variants are new rows, not new test cases. Runs and created documents are logged for traceability and cleanup.

### Entities

**P2P_Scenario** (one row per variant)

| Field | Type | Example | Notes |
|---|---|---|---|
| ScenarioId | Text (unique) | P2P-E2E-001 | Key; Test Manager parameter `ScenarioId` |
| Title | Text | Happy path under 50K, new supplier | |
| Enabled | Boolean | true | Skip disabled rows |
| AmountBand | Choice set *P2P_AmountBand* | Under50K | Under50K / Boundary49999 / AtOrOver50K / Override |
| SupplierSource | Choice set *P2P_SupplierSource* | New | New / Existing |
| BusinessUnit | Text | US1 Business Unit | |
| RequesterUser / BuyerUser / SupervisorUser | Text | CASEY.BROWN / CASEY.BROWN / ANITA.KENNEDY | User names only; credentials live in Orchestrator assets |
| OverridingApprover | Text | (empty) | Override variant |
| DeliverToLocation / ChargeAccount | Text | Seattle / 101.10.15910.000.000.000 | Expected defaults |
| RunIdPrefix | Text | UIP | |
| ExecutePayment | Boolean | false | Payment only with owner approval |
| CleanupPolicy | Choice set *P2P_CleanupPolicy* | CancelAll | CancelAll / KeepForReview |

**P2P_SupplierData** (relationship → P2P_Scenario; used when SupplierSource = New)

| Field | Type | Example |
|---|---|---|
| Scenario | Relationship | P2P-E2E-001 |
| SupplierName | Text | UI Path Supplier (RunId appended) |
| ExistingSupplierName / ExistingSiteName | Text | Dell Inc. / Dell US1 (SupplierSource = Existing) |
| TaxOrganizationType | Text | Corporation |
| TaxpayerCountry / TaxpayerId | Text | New Zealand / 3434573456 |
| ContactFirstName / ContactLastName / ContactEmail | Text | Contact / 1 / 1@1.com |
| CreateContactUser | Boolean | true |
| AddressName / AddressLine1 / AddressLine2 / City / State / PostalCode / AddressCountry | Text | HQ / 216 Queen Street / Northcote Point / Auckland / Auckland / 0627 / New Zealand |
| BusinessClassification | Text | Veteran Owned |
| ProductsServicesCategory | Text | Healthcare |
| SupplierSiteName / SiteProcurementBU | Text | HQ / US1 Business Unit |
| SiteAssignmentMode | Choice set | AutoAssign / SingleBU |

**P2P_RequisitionLine** (relationship → P2P_Scenario; 1..n lines)

| Field | Type | Example |
|---|---|---|
| Scenario | Relationship | P2P-E2E-001 |
| LineNumber | Number | 1 |
| LineKind | Choice set | Noncatalog / Catalog / AmountBased |
| ItemDescription | Text | UI Path Item |
| CategoryName / CategorySearchText | Text | 206.61 Monitors / Monitors |
| Quantity / UOM / UnitPrice / Currency | Number / Text / Decimal / Text | 1 / Ea / 2000 / USD |
| ExpectedTaxRate | Decimal | 0.095 |
| ExpectedApprovalAmount | Decimal | 2190.00 |
| ReceiptQuantity | Number | 1 |

**P2P_ExpectedRouting** (relationship → P2P_Scenario; one row per expected approval step)

| Field | Type | Example |
|---|---|---|
| Scenario | Relationship | P2P-E2E-001 |
| DocumentType | Choice set *P2P_DocumentType* | Requisition |
| Sequence | Number | 1, 2, 3 |
| RuleName | Text | RequsitionSelfApprovalunder50K / RequisitionApprovalCaseyBrown / CategoryHierarchyLevel1isnotblank |
| ExpectedActor | Text | workflowsystem / casey.brown |
| Outcome | Choice set | AutoApproved / HumanApprove / HumanReject |

(PO row: `TermsApprovalHierarchyRules_POSelfApproval`, AutoApproved. Supplier rows: `RouteAllRegistrationRequestsToSupplierAdministrators`, HumanApprove; `SpendAuthorizationGenApprovalRule_RouteRequestToSupplierManagers`, AutoApproved.)

**P2P_InvoiceData** (relationship → P2P_Scenario)

| Field | Type | Example |
|---|---|---|
| InvoiceNumberPattern | Text | {RunId}-INV |
| InvoiceAmountMode | Choice set | IncludesTax / ExcludesTax |
| InvoiceAmount | Decimal | 2190.00 (or computed) |
| MatchMethod | Choice set | IdentifyingPO / MatchInvoiceLines / Unmatched |
| PaymentTerms | Text | Net 30 |
| ExpectedValidationStatus | Text | Validated |
| ExpectedHolds | Text | (none) / Line Variance |
| ExpectedApprovalStatus | Text | Not required |
| ExpectedMatchLevel | Text | 2-Way |
| ExpectWithholding | Boolean | false |

**P2P_TestRun** (written by the automation)

| Field | Type | Notes |
|---|---|---|
| RunId | Text (unique) | UIP-2611231040 |
| Scenario | Relationship | |
| TestManagerExecutionId / TestCaseLogId | Text | Links back to Test Manager |
| StartedAt / EndedAt | DateTime | |
| Status | Choice set *P2P_RunStatus* | Running / Passed / Failed / Aborted |
| Robot / Machine | Text | |

**P2P_CreatedDocument** (written by the automation; drives cleanup)

| Field | Type | Example |
|---|---|---|
| TestRun | Relationship | UIP-2611231040 |
| DocumentType | Choice set *P2P_DocumentType* | SupplierRegistration / Supplier / SupplierSite / SupplierContactUser / Requisition / PurchaseOrder / Receipt / Invoice / WithholdingInvoice / Payment |
| DocumentNumber | Text | 204169 |
| InternalId | Text | 300000342326493 |
| CreatedAt | DateTime | |
| StatusAtEnd | Text | Approved / Open / Validated |
| CleanupAction | Text | Cancel / Inactivate / Void |
| CleanupStatus | Choice set *P2P_CleanupStatus* | Pending / Done / Skipped / NeedsApproval |
| Evidence | File | API JSON or page text |

### Choice sets
*P2P_AmountBand*, *P2P_SupplierSource*, *P2P_CleanupPolicy*, *P2P_DocumentType*, *P2P_RunStatus*, *P2P_CleanupStatus*. Choice values use integer NumberIds in Data Fabric; map them in the workflow, not by label.

### Keep out of Data Fabric
Passwords and secrets stay in Orchestrator credential assets. The environment (base URL, connection name) goes in Orchestrator assets, or an *Environment* entity if several pods are tested.

---

## 4. Known behaviour the expectations rely on (re-verify each release)
- Approval Amount includes 9.5% nonrecoverable tax (Seattle). Invoice tax follows the PO ship-to; unmatched invoices may get other jurisdictions (AP-01 got California, 9.0%).
- A catch-all rule adds Casey to every requisition, so under 50K never completes approval without her.
- A small US1 PO auto-approves (Terms `POSelfApproval`). Noncatalog lines without a negotiated price are **not** auto-converted to POs ("price isn't negotiated"), so a buyer must Process Requisitions.
- Supplier registration goes to all 8 supplier administrators (first responder wins); Casey is one of them.
- PO schedule: 2-way match, over-receipt tolerance 50% / action None, Direct delivery.
- REST `q` with framework v1 needs `;` between conditions; put filters in the request `query` object.
