# Oracle Fusion API findings (dev16 tenant)

Probe of the Oracle Fusion SOAP and REST APIs on `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`, for use from UiPath (Integration Service, API workflows, RPA). Started 2026-11-23.

**Status (2026-11-23):**
- Unauthenticated discovery is done.
- **REST and SOAP with basic auth (Casey Brown) work through Integration Service**, using the HTTP connection *Oracle Fusion dev16 - Basic (integration user)* in Testing-UBAPI (§7).
- REST over OAuth is **pending** a confidential application (§4.2).
- No write has been sent; every call was a GET or a read-only SOAP operation.

Legend: **Verified** = called and seen; **Docs** = from Oracle/UiPath documentation, not yet called here; **Pending** = waiting for credentials.

---

## 1. Summary

| Interface | Auth | Status | Good for |
|---|---|---|---|
| REST metadata (`/fscmRestApi/resources/<ver>/` catalog, `…/<resource>/describe`) | None | **Verified: works without auth** (200) | Discovering resources, fields, mandatory and updatable flags, LOVs and actions. Good for building automation and test data without signing in. |
| REST data (`/fscmRestApi`, `/hcmRestApi`) | Basic, Bearer (OAuth) or `oit` (`WWW-Authenticate: Basic realm="owsm",Bearer realm="owsm",oit realm="owsm"`) | **Verified: 401 without credentials.** Authenticated calls **Pending**. | Reading and writing invoices, POs, requisitions, receipts, suppliers and payments. Faster and steadier than the UI for setup, checks and cleanup. |
| SOAP WSDLs (`/fscmService/<Service>?WSDL`, BI Publisher `/xmlpserver/services/ExternalReportWSSService?WSDL`) | None | **Verified: public** (200, `text/xml`) | Contract discovery: operations, schemas and security policy |
| SOAP calls | WS-Security UsernameToken over HTTPS, or SAML (policy `wss11_saml_or_username_token_with_message_protection_service_policy`, TransportBinding + HttpsToken + UsernameToken alternatives) | **Pending** | Bulk and ESS operations REST doesn't cover: `ErpIntegrationService` (load files to UCM, submit ESS import jobs, `getESSJobStatus`, `downloadESSJobExecutionDetails`, `exportBulkData`), BI Publisher reports (`runReport`), and legacy services such as `InvoiceInterfaceService` and `PurchaseOrderServiceV2` |
| OAuth token endpoint (IDCS) | Client credentials | **Verified: discovery document readable.** Token request **Pending** (needs a client). | Bearer tokens for REST (and SOAP, see §5) |

**Integration Service connectors:** there is **no Oracle Fusion connector**. Searching for "oracle" returns only Oracle NetSuite and Oracle Eloqua, which are different products. Searching for "fusion", "erp" and "soap" finds nothing relevant. The route is the generic **HTTP connector** (`uipath-uipath-http`), which has no connections in this tenant yet.

---

## 2. Endpoints probed (unauthenticated, read-only GET)

| # | Call | Result | Notes |
|---|---|---|---|
| 1 | `GET /fscmRestApi/resources/11.13.18.05/invoices?limit=1` | 401 | Advertises Basic, Bearer and oit |
| 2 | `GET /hcmRestApi/resources/11.13.18.05/workers?limit=1` | 401 | Same auth schemes |
| 3 | `GET /fscmRestApi/resources/11.13.18.05/` | 200 `application/vnd.oracle.adf.version+json` | Version `11.13.18.05` is the latest; framework versions 1–9 allowed (set with the `REST-Framework-Version` header) |
| 4 | `GET /fscmRestApi/resources/latest/invoices/describe` | 200 `application/vnd.oracle.adf.description+json` | Full field metadata for `invoices` (for example `InvoiceId` integer, mandatory, not updatable) |
| 5 | `GET /fscmService/InvoiceInterfaceService?WSDL` | 200 | Payables quick-invoice interface service |
| 6 | `GET /fscmService/ErpIntegrationService?WSDL` | 200 | Endpoint `https://…:443/fscmService/ErpIntegrationService`. Operations include `getESSJobStatus`, `downloadESSJobExecutionDetails`, `exportBulkData`, `getDocumentForDocumentId`, `getEntityList` (plus `importBulkData`, `uploadFileToUcm` and others) |
| 7 | `GET /fscmService/PurchaseOrderServiceV2?WSDL` | 200 | PO service |
| 8 | `GET /xmlpserver/services/ExternalReportWSSService?WSDL` | 200 | BI Publisher report service (`runReport`) |
| 9 | `GET https://idcs-dfd9d303fd844502b1bca6b30a13b968.identity.oraclecloud.com/.well-known/openid-configuration` | 200 | Token endpoint `https://idcs-dfd9d303fd844502b1bca6b30a13b968.identity.oraclecloud.com:443/oauth2/v1/token`; `client_credentials` grant supported |

---

## 3. Integration Service: how to call these

- Use the **HTTP connector** (`uipath-uipath-http`), one connection per credential type (§4). UiPath documents that this connector is currently available only in **API workflows**. The CLI (`uip is resources run …`) is used to probe it.
- Supported connection auth types (UiPath docs): UiPath User Access Token, OAuth 2.0 Authorization code (± PKCE), **OAuth 2.0 Client credentials**, OAuth 2.0 Password, **Basic Authentication**, API Key, OAuth 2.0 JWT Bearer, Personal Access Token. Fields can be filled from Orchestrator credential assets.
- **Body format:** UiPath documents JSON payloads only. Headers are free key/value pairs, but sending a `text/xml` SOAP envelope is **undocumented**. To be tested (§6, call S1). If Integration Service rejects XML, SOAP calls need a coded or XAML workflow with UiPath.WebAPI (`soap` service / HTTP Request with an XML body), reading a credential asset.
- **REST through Integration Service fits well:** JSON in and out, and with an OAuth client-credentials connection the token refresh is managed for you.

---

## 4. Credentials to create (human steps; the agent never sees passwords or secrets)

### 4.1 SOAP / REST integration user (Basic auth)

> **Decision (2026-11-23):** use the **existing user, Casey Brown**, through the Orchestrator credential asset **`Oracle_Fusion_P2P_Test`** (folder Shared/Testing-UBAPI), instead of creating a new integration user. In the HTTP connection, fill Username and Password with **Use credential asset > Oracle_Fusion_P2P_Test**, so no password is typed.
> - **Caveat:** Casey holds requester, buyer, AP and admin roles (Findings B4), so API calls run with broad access. Keep calls read-only unless announced.
> - **Caveat:** if her Oracle sign-in uses MFA or SSO, basic auth on the APIs may be refused. The first ping will show this.

The steps below are for creating a dedicated user later, if needed.

1. **Oracle (Security Console, as an admin):** Tools > Security Console > Users > Add User Account. Use a dedicated user (for example `UIPATH.INTEGRATION`) with only the roles needed for the services being called, for example *Accounts Payable Specialist* for invoices and *Buyer* for POs. Then run **Import User and Role Application Security Data** (Tools > Scheduled Processes).
   - If you'd rather reuse an existing user (for example Casey), say which.
2. **Store it in UiPath (you type the password):** Orchestrator > folder **Shared/Testing-UBAPI** > Connections > Add connection > **HTTP** > auth type **Basic Authentication**.
   - **Connection name:** `Oracle Fusion dev16 - Basic (integration user)`
   - **Base URL:** `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`
   - **Username / Password:** the integration user's
   - **Authentication validation API (optional):** `/fscmRestApi/resources/11.13.18.05/currencies?limit=1`
3. Optionally store the same pair as an Orchestrator **Credential asset** (for example `Oracle_Fusion_Integration_User`) so a workflow can sign SOAP envelopes if Integration Service can't send XML.

### 4.2 REST OAuth client (client credentials)

From Oracle's "Configure OAuth Using the Fusion Applications Identity Domain" ([docs](https://docs.oracle.com/en/cloud/saas/applications-common/26b/oaext/configure-oauth.html)):

1. Sign in to the **identity domain console** (`https://idcs-dfd9d303fd844502b1bca6b30a13b968.identity.oraclecloud.com/ui/v1/adminconsole`, or OCI Console > Identity & Security > Domains > the Fusion domain) as an identity domain administrator.
2. **Integrated applications > Add application > Confidential Application > Launch workflow.** Name it `UiPath Fusion REST (dev16)` > Next.
3. **Configure this application as a client now.** Under Authorization, tick **Client credentials** only.
4. **Token issuance policy:** set Authorized resources to *Specific*, tick **Add resources** > **Add scope** > select the **Fusion Applications** resource app > Add.
   - Note the full scope string it shows. It usually looks like `urn:opc:resource:fa:instanceid=<id>urn:opc:resource:consumer::all`, but copy the exact value from the console.
5. Finish > **Activate**. Copy the **Client ID** and **Client Secret** (don't paste them into chat).
6. **Oracle Security Console:** create a Fusion user whose **user name equals the Client ID** exactly, assign it the data roles it needs (as in §4.1), then run **Import User and Role Application Security Data**.
7. **Store it in UiPath:** Orchestrator > **Shared/Testing-UBAPI** > Connections > Add connection > **HTTP** > **OAuth 2.0 Client credentials**.
   - **Connection name:** `Oracle Fusion dev16 - OAuth client`
   - **Base URL:** `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`
   - **Client ID / Client secret:** from step 5
   - **Token URL:** `https://idcs-dfd9d303fd844502b1bca6b30a13b968.identity.oraclecloud.com/oauth2/v1/token`
   - **Scope:** the exact string from step 4
   - Tick **OAuth basic header**, so the client ID and secret go in the Basic header, which is how Oracle's token example sends them.

Tell the agent when each connection exists; it then pings it (`uip is connections ping`) and runs §6.

---

## 5. Things to know (Docs)

- Oracle has announced that Fusion Applications is moving **from password-based to OAuth token authentication for REST and SOAP**. Username/password connections are expected to need migrating before **31 March 2027** ([Oracle Integration blog](https://blogs.oracle.com/integration/?p=3120)). Prefer OAuth for anything long-lived; treat Basic as short-term.
- A token is accepted but calls return 401 → the client usually lacks a Fusion user or roles. Create the Client-ID user and assign roles (forum and A-Team guidance).
- REST tokens last 3600 s by default.
- Use `REST-Framework-Version` (for example `4`) for consistent response shapes; `describe` shows the fields per version.

---

## 6. Planned authenticated calls (read-only unless announced)

| # | Interface | Call | Purpose | Result |
|---|---|---|---|---|
| R1 | REST Basic | `GET /fscmRestApi/resources/11.13.18.05/invoices` with `q=InvoiceNumber='UIP-AP-231126-1013'` | Read AP-01's canceled invoice; check Approval Status | **Works** (§7) |
| R2 | REST Basic | `GET …/purchaseRequisitions` with `q=Requisition='204162'` | Read P2P-01 requisitions | **Works** |
| R3 | REST Basic | `GET …/suppliers` with `q=Supplier='ABC Consulting'`, `expand=sites` | Supplier and site data | **Works** |
| R4 | REST Basic | `GET …/invoices` with `q=ApprovalStatus='<status>'`, `totalResults=true` | Is invoice approval on? | **Works**: answered, off for US1 (§7) |
| O1 | REST OAuth | Same as R1–R3 through the OAuth connection | Confirm Bearer works and the client user's data access | Pending (§4.2) |
| S1 | SOAP Basic | `POST /fscmService/ErpIntegrationService` `getServiceLastUpdateTime` | Confirm SOAP auth and whether Integration Service can carry XML | **Works** (§7) |
| S2 | SOAP OAuth | Same with a Bearer header | Confirm SOAP accepts OAuth tokens | Pending |

No writes are planned. Any POST, PATCH or DELETE (create, update, delete, submit, cancel) will be announced first.

---

## Sources

- [Configure OAuth Using the Fusion Applications Identity Domain (26B)](https://docs.oracle.com/en/cloud/saas/applications-common/26b/oaext/configure-oauth.html)
- [Retrieve Bearer Token Using IDCS OAuth 2.0 REST API (Financials 26A)](https://docs.oracle.com/en/cloud/saas/financials/26a/farfa/Retrieving_Bearer_Token_Using_IDCS.html)
- [A-Team: Validating Fusion IAM trust for API integrations](https://blogs.oracle.com/coretec/validating-fusion-iam-trust-for-api-integrations)
- [Oracle Integration blog: password to OAuth transition](https://blogs.oracle.com/integration/?p=3120)
- [Create an Integration User (Fusion Service)](https://docs.oracle.com/en/cloud/saas/fusion-service/faiec/create-an-integration-user.html)
- [UiPath HTTP connector](https://docs.uipath.com/integration-service/automation-cloud/latest/user-guide/uipath-uipath-http) and [its authentication types](https://docs.uipath.com/integration-service/automation-cloud/latest/user-guide/uipath-uipath-http-authentication)

---

## 7. Authenticated results (Basic auth, Casey Brown, through Integration Service). Verified 2026-11-23.

Connection: **Oracle Fusion dev16 - Basic (integration user)**, HTTP connector, folder Testing-UBAPI, Basic Authentication (Casey's username and password entered by the user). Ping: Enabled. `base-url` = `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`.

| # | Call | HTTP | Result | Good for |
|---|---|---|---|---|
| R1 | GET `invoices`, q `InvoiceNumber='UIP-AP-231126-1013'` | 200 | 1 row: InvoiceId 300000342340067, ABC Consulting / ABC US1, InvoiceAmount 0, Source "Manual invoice entry", ValidationStatus **Canceled**, ApprovalStatus **Not required**, PaidStatus Unpaid, AccountingStatus Unaccounted, CanceledFlag true, CanceledBy/CreatedBy CASEY.BROWN, CanceledDate 2026-11-22 | **Test assertions and cleanup checks**: confirm the UI result without screen-scraping |
| R2 | GET `purchaseRequisitions`, q `Requisition='204162'` | 200 | 1 row: "Test UiPath P2P-01 R1 below 50K boundary", DocumentStatus **Canceled**, US1, preparer CASEY.BROWN, ApprovedDate 2026-11-22 | Verifying requisition status after UI steps; finding the session's documents |
| R3 | GET `suppliers`, q `Supplier='ABC Consulting'`, `expand=sites`, child `fields` (`fields=A,B;sites:C,D`) | 200 | SupplierId 300000075039541, number 1288, ACTIVE. Sites: **ABC US1 (US1 BU)**, ABC Norway / ABC Sweden (Sweden BU), ABC Healthcare, ABC Supremo US, ABC Consulting MISC (Progress CA)… | Picking valid supplier and site test data per BU |
| R4 | GET `invoices`, q `ApprovalStatus='<value>'`, `totalResults=true`, `limit=2` | 200 | Tenant totals: Workflow approved 1,542; Required 6,939; Initiated 22; Manually approved 26; Rejected 4. **Corrected 2026-11-23:** the original US1 check used ` and ` in `q`, which framework v1 silently ignores. With `;` it gives US1: Workflow approved **9** (newest 14/11/25), Rejected 2, Manually approved 1, Required 0, Initiated 0, Not required 15,782 | Invoice approval **has been used in US1 historically**, but new US1 invoices (889900, UIP-AP-231126-1013) come out *Not required*. Nothing is pending. |
| S1 | POST `/fscmService/ErpIntegrationService`, headers `Content-Type: text/xml; charset=utf-8`, `SOAPAction: …/erpIntegrationService/getServiceLastUpdateTime`, body = SOAP 1.1 envelope as a **string** | 200 | `<result>2026-10-20T15:42:42Z</result>`. Response is **MTOM multipart** (`application/xop+xml`, MIME boundary `------=_Part_…`), so extract the `<env:Envelope>` before parsing the XML | SOAP calls work through Integration Service with HTTP Basic (no WS-Security header needed): ESS jobs, UCM files, bulk import/export, BI reports |

### 7.1 How to call these through the Integration Service HTTP connection (gotchas)

- **Put query parameters in the request's `query` object**, not in the `url`:
  - `{"method":"GET","url":"/fscmRestApi/resources/11.13.18.05/invoices","query":{"q":"InvoiceNumber='X'","onlyData":"true","fields":"…"}}`
  - A `q=…'…'` written inline in the URL was **silently dropped**, and the call returned unfiltered rows (other teams' data).
  - URL-encoding it inline gave a 400 ("parameter q … is not valid").
- **`fields` must use exact REST attribute names.** Unknown names give a 400 listing the whole value. Get the names from the public `GET /fscmRestApi/resources/latest/<resource>/describe` (for invoices: `InvoiceNumber`, `ValidationStatus`, `ApprovalStatus`, `PaidStatus`, `AccountingStatus`, `CanceledFlag`, `InvoiceStatus`, …).
- **Non-JSON bodies work:** the connection carried a `text/xml` SOAP envelope when `body` was a string and `headers` set `Content-Type` and `SOAPAction`. This goes beyond UiPath's documented "JSON only".
- **The `uip` CLI on Windows splits `--body` on spaces** through the npm launcher ("too many arguments") and mangles some escapes ("Invalid JSON"). Call `node …/@uipath/cli/dist/index.js` with an argument list instead. Helper: `P2PGuide/tools/ishttp.py` (`call(connId, request, show, raw)`).
- Response envelope: `Data.code` (vendor HTTP status), `Data.headers`, `Data.body` (parsed JSON or string), `Data.rawStringBody`. The CLI `Result` is "Success" even for a vendor 400/401, so **always check `Data.code`**.
- Oracle REST paging: `limit`, `offset`, `hasMore`, `totalResults=true` (gives a cheap count); `orderBy=CreationDate:desc`; `onlyData=true` drops links.
- Shared tenant: unfiltered list calls return other teams' records. Always filter by your own document number, and don't store others' data.

### 7.2 What each interface is good for in this project

| Need | Use |
|---|---|
| Assert a UI step's outcome (status, approval, holds, cancel) | REST GET by document number (R1, R2). Fast, no screenshots. |
| Choose valid test data (supplier site per BU, currencies, terms) | REST GET (R3) + `describe` for LOV and field rules |
| Check tenant configuration from data (for example invoice approval per BU) | REST GET with `totalResults=true` counts (R4) |
| Bulk loads, ESS jobs, scheduled processes, BI reports | SOAP `ErpIntegrationService` / `ExternalReportWSSService` (S1 pattern). Parse MTOM. |
| Test-data setup and cleanup (create or cancel invoices, requisitions) | REST POST/PATCH or actions. **Not yet exercised; each write will be announced.** |

### 7.3 Approvers for a document: BPM worklist REST (verified 2026-11-23, requisition 204169)

The Fusion `purchaseRequisitions` resource has no approvers child. Use the **BPM tasks REST API** through the same connection; it returns only tasks the connection user can see.

| # | Call | Result | Good for |
|---|---|---|---|
| B1 | GET `/bpm/api/4.0/tasks`, query `keyword=<doc number>`, `assignment=ALL`, `status=ASSIGNED` | 200. Two tasks "Approve Requisition 204169": the root task 2484220 (Submitted) and **2484221 (Action Required, assignees `casey.brown`)**. `taskDefinitionName` ReqApproval, `identificationKey` `REQ_<headerId>_1`. | Who must act now; task number for the next calls |
| B2 | GET `/bpm/api/4.0/tasks/<number>/history` | 200. Each step's `reason` gives the **rule**: `HeaderHierarchyRules_RequsitionSelfApprovalunder50K` → auto-approved by workflowsystem; `HeaderHierarchyRules_RequisitionApprovalCaseyBrown` → assigned to Casey; `HeaderStageConsensusRules_CategoryHierarchyLevel1isnotblank` → auto-approved | **Routing assertions**: which rules fired, in order, and the outcome |
| B3 | GET `/bpm/api/4.0/tasks/<number>` | 200. Detail plus `actionList` (Approve/Reject plus system actions: WITHDRAW, ESCALATE, SKIP_CURRENT_ASSIGNMENT, …) and links to payload, comments and attachments | Seeing what an approval API call could do. **Any action is a write: announce it first.** |

Finding: for under-50K requisitions, the self-approval rule **does** auto-approve. The catch-all `RequisitionApprovalCaseyBrown` rule then adds Casey as a sequential approver, which is why they stay "Pending approval". A category consensus stage also fires and auto-approves.

### 7.4 Purchase order US165366 (from requisition 204169). Verified 2026-11-23.

| # | Call | Result |
|---|---|---|
| P1 | GET `/fscmRestApi/resources/11.13.18.05/purchaseOrders`, q `OrderNumber='US165366'`, `expand=lines` | First read: Pending Approval. Seconds later: **Open**. Buyer Casey Brown, Dell Inc. / Dell US1, US1 BU, 1 × 2,000 (206.61 Monitors), TotalTax 190 (**9.5%**), Total 2,190 USD, Requisition 204169, SupplierCommunicationMethod None |
| P2 | GET `/bpm/api/4.0/tasks`, `keyword=US165366`, `assignment=ALL`, `status=COMPLETED` | Approve Purchase Order tasks 2484226 and 2484227 (COMPLETED) + FYI 2483238/2483239 "Document (Purchase Order) US165366 (Requisition 204169) Implemented" (Casey) |
| P3 | GET `/bpm/api/4.0/tasks/2484227/history` | Only rule fired: **`TermsApprovalHierarchyRules_POSelfApproval`** → auto-approved by workflowsystem at 00:47:22, so **no human PO approval** for a 2,190 USD US1 PO by Casey |

Notes:
- BPM task search: `status` must be a valid value (`ASSIGNED`, `COMPLETED`, …). `ANY` gives a 400 "Invalid status filter". The default (no status) returns only open tasks, so search `COMPLETED` as well.
- PO attribute names (from `purchaseOrders/describe`): `OrderNumber`, `Status`, `Buyer`, `Supplier`, `SupplierSite`, `Ordered`, `TotalTax`, `Total`, `Requisition`, `FundsStatus`, `SupplierCommunicationMethod`. Lines: `LineNumber`, `Description`, `Category`, `Quantity`, `UOM`, `Price`, `Ordered`, `Status`.

### 7.5 Receipt status for a PO. Verified 2026-11-23 (US165366).

| # | Call | Result | Good for |
|---|---|---|---|
| RC1 | GET `purchaseOrders`, q `OrderNumber='US165366'`, `expand=lines,lines.schedules`, schedule fields `ReceivedQuantity,QuantityAccepted,QuantityRejected,BilledQuantity,InvoiceMatchOption,ReceiptRouting,OverReceiptTolerancePercent,OverReceiptAction,MatchApprovalLevelCode,…` | Header, line and schedule **Closed for Receiving**; received 1 of 1, accepted 0 / rejected 0 (Direct delivery), billed 0. Controls: over-receipt 50% / action None, early/late 60 days / None, close tolerance 0%, match option **Order**, **2-Way**, accrue at receipt No | **Receipt and billing progress per PO schedule**, and the tolerances that decide whether an over-receipt warns or blocks (here: never) |
| RC2 | GET `receivingReceiptRequests` (q `VendorName`, `CreationDate`) | 0 rows for today's Dell receipt. This is the **receipt interface** (receipts created by API or import), so receipts entered in the UI don't appear | Reading receipts created through the API only |

- `receipts` and `receivingTransactions` describe as action resources (`ReturnStatus`, `ErrorUniqueTransactionId`, children `receiptHeaders` / `transactionLines`). They're for **creating** receipts, not querying them.
- No REST resource returned the UI receipt number. Use the UI (My Receipts / Manage Receipts) or a BI Publisher report through SOAP (`ExternalReportWSSService.runReport`).


### 7.6 Invoice 889900 (PO US165366): validation and payment readiness. Verified 2026-11-23.

| # | Call | Result |
|---|---|---|
| I1 | GET `invoices`, q `PurchaseOrderNumber='US165366'` | InvoiceId 300000342340095, number **889900**, Dell Inc. / Dell US1, 2,190.00 USD, Standard, Manual invoice entry, **Validated**, approval **Not required**, Unpaid, Unaccounted, InvoiceStatus Completed, created 23/11/26 00:49 by CASEY.BROWN |
| I2 | GET `invoices/{InvoiceId}/child/invoiceInstallments` | Installment 1: Unpaid 2,190, DueDate 2026-12-23, **HoldFlag false**, PaymentMethod Electronic (EFT), bank account XXXXX1255, priority 99 |
| I3 | GET `invoiceHolds`, q `InvoiceNumber='889900'` | 0 holds |
| I4 | GET `invoices/{InvoiceId}` (fields) | PaymentTerms Net 30, TermsDate 2026-11-22, AmountPaid 0 |

**Ready for payment = Validated + approval Not required/approved + no holds + installment HoldFlag false + UnpaidAmount > 0.** For 889900, all are true.

### 7.7 Filter syntax gotcha (important)

- With the default **REST-Framework-Version 1**, `q` combines conditions with **`;`** (`BusinessUnit='US1 Business Unit';ApprovalStatus='Required'`). Using ` and ` returns **0 rows silently** (no error).
- With header `REST-Framework-Version: 2` (or higher), ` and ` / `or` / `LIKE` row-match expressions work.
- Single-condition queries work either way.
- Control test: `Supplier='Dell Inc.' and CreatedBy='CASEY.BROWN'` gave 0 on v1 and 265 on v2; with `;` on v1 it gave 265.

### 7.8 Side effect found: withholding-tax invoices from AP-01

`q` `InvoiceNumber LIKE 'Withholding tax-300000342340067%'` (300000342340067 = AP-01 invoice UIP-AP-231126-1013):

| InvoiceId | Number | Supplier / site | Amount | Status |
|---|---|---|---|---|
| 1581378 | Withholding tax-300000342340067-4 | Internal Revenue Service / TAX PAYMENTS | 54.50 | Not validated, Pending control check, not canceled |
| 1581379 | Withholding tax-300000342340067-4-Canceled | Internal Revenue Service / TAX PAYMENTS | -54.50 | Not validated, Pending control check, not canceled |

- Validating the ABC Consulting invoice applied **10% withholding** and auto-created an IRS withholding invoice (23:26).
- Cancelling the invoice auto-created the reversing one (23:29).
- They net to zero. The AP-01 UI Totals showed Withholding 0.00, which was misleading.
- Cleanup decision pending with the user.

---

## 8. Re-probe for the DNZTRAIN setup (org `deloivqbaydk`). 2026-11-26

**Context:** the project moved to UiPath org `deloivqbaydk` (Test Manager DNZTRAIN, folder Shared/OracleFusion). The Oracle tenant is the same. The Basic connection in §7 lives in the old org (`salesyuhwlxy`, Testing-UBAPI), so it can't be used from here.

**Blocker (authenticated calls), resolved the same day:** at first this org had **no Integration Service connections**, and no Oracle credential environment variables were set on this machine, so the calls in §8.1 were made **without credentials**. The user then created the HTTP connection, and the authenticated results are in **§9**. Nothing was written.

### 8.1 Auth methods (verified without credentials, 2026-11-26)

| Interface | Call | Result | Auth it accepts |
|---|---|---|---|
| FSCM REST | GET `/fscmRestApi/resources/11.13.18.05/purchaseOrders?limit=1` | 401 | `Basic`, `Bearer`, `oit` (realm owsm) |
| HCM REST | GET `/hcmRestApi/resources/11.13.18.05/workers`, `organizations`, `departmentsLov` | 401 | Same: `Basic`, `Bearer`, `oit` |
| BPM tasks REST | GET `/bpm/api/4.0/tasks` | **500** (JSON), not 401 | Unknown without credentials; worked with Basic in §7.3 |
| SOAP WSDLs | `fscmService/ErpIntegrationService`, `hcmService/WorkerServiceV2`, `hcmService/OrganizationServiceV2` | 200 (public) | Per-port OWSM policies (`…SoapHttpPort_Input_Policy`). §7 S1 showed **HTTP Basic** works for SOAP. |
| IDCS OAuth | `/.well-known/openid-configuration` | 200 | Grants: `client_credentials`, **`password`**, `refresh_token`, `authorization_code`, `jwt-bearer`, `tls_cert_auth` |

**Conclusion:**
- **Username and password (Casey) work today** as HTTP Basic on REST and SOAP (verified in §7).
- OAuth also offers a **password grant**, which is still username and password, but it needs a confidential application (client ID and secret, §4.2) first.
- Oracle is moving Fusion from passwords to OAuth before **31 March 2027** (§5), so Basic is a short-term choice.

### 8.2 The requested Workday operations, mapped to Oracle

The request named Workday operations (`Get_Workers`, `Get_Organizations`, `Get_Event_Detail`, `Get_Worker_Event_History`) and a Workday "HR Partner" OAuth login. Oracle has none of these by name. The equivalents:

| Requested (Workday) | Oracle SOAP | Oracle REST | Good for (P2P) | Status |
|---|---|---|---|---|
| Get_Workers | `WorkerServiceV2`: `findWorker`, `getWorkerInformationByUserName`, `getWorkerInformationByPersonNumber` | `hcmRestApi/…/workers` (expand assignments, manager) | **Finding test subjects**: personas, each requester's manager (supervisor approver), BU | WSDL verified; call **Pending** (no connection) |
| Get_Organizations | `OrganizationServiceV2`: `findOrganization`, `findOrganizationByIdAndClassification` | `hcmRestApi/…/organizations`, `departmentsLov` | **Checking preconditions**: BU and department IDs (closes Findings §6.3 "US1 BU ID") | WSDL verified; call **Pending** |
| Get_Event_Detail | none | BPM `/bpm/api/4.0/tasks/<number>` (§7.3 B3) | **Verifying results**: who must act now; available actions | Verified 2026-11-23 (old org) |
| Get_Worker_Event_History | none | BPM `/bpm/api/4.0/tasks/<number>/history` (§7.3 B2); document status by number (§7 R1, R2) | **Verifying results**: which rules fired, in order | Verified 2026-11-23 (old org) |
| Cancel / rescind | none for P2P | REST actions: `purchaseRequisitions/{id}/action/cancel`, `purchaseOrders/{id}/action/cancel` or `close`, `invoices/action/cancelInvoice` (Playbook §7.1) | **Cancelling and rescinding** test documents | Verified 24/11 through a workflow; **writes, announce first** |
| HR Partner via OAuth | n/a | Any of the above with a Bearer token | Same calls under a client identity | **Pending**: needs a confidential app (§4.2); no P2P "HR Partner" persona exists |

`WorkerServiceV2` also exposes write operations (`terminateWorkRelationship`, `updatePerson`, `mergePerson`, …). These are not used here: they are HR writes outside P2P.

### 8.3 To unblock

1. Set the real password in credential asset `Oracle_Fusion_P2P_Test` (Shared/OracleFusion). It holds a placeholder.
2. In Shared/OracleFusion, create an **HTTP** connection with **Basic Authentication**. Name it `Oracle Fusion dev16 - Basic (Casey)`, base URL `https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com`, and fill the username and password from the asset, or type them yourself.
3. The agent then pings it and runs the read-only calls in §8.2, starting with `getWorkerInformationByUserName` for CASEY.BROWN and `findOrganization` for US1.

---

## 9. Authenticated results (Basic auth, Casey Brown, org `deloivqbaydk`). Verified 2026-11-26.

**Connection:** **Oracle Fusion dev16 - Basic (Casey)**, HTTP connector (`uipath-uipath-http`), id `febfd95a-2028-4496-8c33-7e7567b95602`, folder **Shared** (not Shared/OracleFusion), ping Enabled. The user entered the credentials; the agent never saw them. No environment-variable integration user exists, so SOAP went through this same connection.

**Auth verdict:**
- **HTTP Basic with Casey's username and password works on everything tried:**
  - FSCM REST
  - HCM REST
  - SCIM (`/hcmRestApi/scim`)
  - BPM tasks REST
  - SOAP (`hcmService`, `fscmService`); no WS-Security header is needed
- **Exception:** `/bpm/api/4.0/identities/…` redirects to the IDCS sign-in page (an HTML form with HTTP 200), so it can't be used with Basic.
- **OAuth** (client credentials, or the password grant) still needs a confidential app (§4.2).

**Safety:** every call was a GET, a read-only SOAP `get*`/`find*` operation, or a read-only REST action (announced first). Queries were filtered to Casey's own records or limited to one row.

### 9.1 What each API is good for

| Purpose | Call | HTTP | What it returned / showed |
|---|---|---|---|
| **Users** | REST `hcmRestApi/…/userAccounts` `q=Username='CASEY.BROWN'` | 200 | UserId, SuspendedFlag false, PersonNumber 4. `expand=userAccountRoles` gives **RoleCode only**, first 25 |
| Users | REST `hcmRestApi/…/publicWorkers` `q=DisplayName='Casey Brown'` | 200 | PersonNumber, DisplayName, WorkEmail, Username. **Find test subjects by name without HR-sensitive data.** |
| Users | REST `hcmRestApi/…/workers` `q=PersonNumber='4'`, `expand=workRelationships.assignments.managers` | 200 | Assignment Director, US1 Business Unit, Finance US, JOB003, ACTIVE; manager type LINE_MANAGER. **Also returns DateOfBirth**, so don't log raw responses. |
| Users | SOAP `WorkerServiceV2.getWorkerInformationByUserName` (userName, effectiveDate) | 200 (MTOM) | Full worker: assignment, BU, job, department, location, legal employer. **It also returns the national identifier (SSN) and date of birth.** Raw responses were deleted and no values are recorded here. Prefer `publicWorkers`. |
| **Roles** | SCIM `GET /hcmRestApi/scim/Users?filter=userName eq "CASEY.BROWN"` | 200 | active true, **131 roles** in one call (Findings §5 counted 130). **Best way to check a test user's roles before a run.** |
| Roles | SCIM `GET /hcmRestApi/scim/Roles?filter=displayName co "Buyer"` | 200 | Role id, name, category (JOB) and `members`. Answers "who holds role X?" |
| Roles | REST `fscmRestApi/…/procurementAgents` `q=Agent='Brown, Casey'` | 200 | Procurement BU **US1 (300000046987012)**, Active, default requisitioning BU US1, manage requisitions and orders **with Full access to other agents' documents**, and flags for agreements, negotiations, suppliers, catalog and so on. **This answers the Findings §6.3 "procurement BU access" item.** |
| Roles | REST `fscmRestApi/…/dataSecurities` `q=UserName='CASEY.BROWN'` | 200 | 0 rows (her data access doesn't come from this resource) |
| **BPM** | `GET /bpm/api/4.0/tasks?keyword=204162&assignment=ALL&status=COMPLETED` | 200 | 7 tasks for requisition 204162 (6 "Approve Requisition", 1 FYI), with taskDefinitionName ReqApproval / ReqStatusFYI |
| BPM | `GET /bpm/api/4.0/tasks/2481236/history` | 200 | Each step's rule in `reason`: `RequsitionSelfApprovalunder50K` auto-approved → `RequisitionApprovalCaseyBrown` assigned to casey.brown → category rules auto-approved → withdrawn. **Routing assertions without the UI.** |
| BPM | `GET /bpm/api/4.0/tasks/2481236` | 200 | outcome APPROVE, assignees, payload/comments/attachments links; `actionList` only offers VIEW_* actions on a completed task |
| BPM | REST action `purchaseRequisitions/{id}/action/retrieveCurrentApprovers` (POST, body `"{}"`) | 200 | `NO_APPROVERS_FOUND` for the canceled requisition 204162. **On a pending requisition, this is the quickest "who must approve now?" check.** |
| BPM | REST action `purchaseRequisitions/{id}/action/getApprovalWorkflowStatus` | 200 | For 204162: STATUS ERROR, POR-2011611 "Ruleset did not return any results" (expected for a canceled document). Use it on pending documents. |
| **Preconditions** | REST `fscmRestApi/…/finBusinessUnitsLOV` `q=BusinessUnitName='US1 Business Unit'` | 200 | **US1 BU ID 300000046987012**, ledger 300000046975971, legal entity 300000046973970, location 300000047013170. **Closes Findings §6.3 "ID for US1".** |
| Preconditions | REST `hcmRestApi/…/hcmBusinessUnitsLOV`, `hcmRestApi/…/organizations` | 200 | Same ID; classification FUN_BUSINESS_UNIT; Active |
| Preconditions | SOAP `OrganizationServiceV2.findOrganizationByIdAndClassification` (300000046987012, FUN_BUSINESS_UNIT) | 200 | US1 Business Unit and its classifications. REST is simpler for the same data. |
| Preconditions | REST `fscmRestApi/…/suppliers` `q=Supplier='Dell Inc.'`, `expand=sites` | 200 | Dell Inc. 1255 ACTIVE; site **Dell US1 → US1 Business Unit** (plus UK, France, China, Australia, Japan, Italy, Germany sites) |
| Preconditions | REST `fscmRestApi/…/currenciesLOV` `q=CurrencyCode='USD'` | 200 | USD, enabled, precision |
| Preconditions | SOAP `ErpIntegrationService.getServiceLastUpdateTime` | 200 (MTOM) | 2026-10-20T15:42:42Z. **A cheap SOAP health check.** |
| Preconditions | REST `fscmRestApi/…/erpintegrations` | 200 | Reachable, 0 rows. The REST front door for ESS jobs and file loads. |
| **Verifying results** | REST `purchaseRequisitions` `q=Requisition='204162'` | 200 | DocumentStatus Canceled, description, preparer |
| Verifying results | REST `purchaseOrders` `q=OrderNumber='US165366'` | 200 | **Closed**, buyer Casey, Dell Inc., total 2,190, requisition 204169 |
| Verifying results | REST `invoices` / `invoiceHolds` `q=InvoiceNumber='889900'` | 200 | **Validated, Not required, Unpaid, not canceled**; 0 holds. *Leftover test data from 23 Nov.* |
| Verifying results | REST `payablesPayments` `q=BusinessUnit='US1 Business Unit'`, `limit=1`, `totalResults=true` | 200 | 3,669 US1 payments. Filter by PaymentNumber or invoice in tests. The sample row belonged to another team and was discarded. |

### 9.2 Cancelling and rescinding (from public `describe`, **not called**: each is a write and would be announced)

| Document | REST actions available | Notes |
|---|---|---|
| Requisition (`purchaseRequisitions`) | `cancel`, `returnLines`, `reassignRequisitions`, `submitRequisition`, plus read-only `retrieveCurrentApprovers`, `getApprovalWorkflowStatus`, `checkActionEligibility` | There is no withdraw action. Withdraw is UI Edit (Playbook §5.6). Incomplete requisitions: `DELETE` (§7.1 of Playbook) |
| Draft PO / change order (`draftPurchaseOrders`) | `withdraw`, `cancelChangeOrder`, `deleteChangeOrder`, `submit`, `processRequesterChanges` | **Rescinding a pending change order** |
| PO (`purchaseOrders`) | `cancel`, `close`, `reopen`, `hold` / `removeHold`, `freeze` / `unfreeze`, `submit`, `communicate` | Cancel if nothing is received or invoiced, otherwise close (Playbook §7.1) |
| Receipt (`receivingReceiptRequests`) | `upsert`, `submitForApproval` | No cancel or correct action. **Corrections and returns are UI-only** (or go through the receipt interface). |
| Invoice (`invoices`) | `cancelInvoice`, `cancelLine`, `validateInvoice`, `calculateTax`, `reverseDistributions` | `cancelInvoice` was verified on 24 Nov |
| Payment (`payablesPayments`) | `initiateStopPayment`, `initiateEscheat`, `upsert` | **No void action in REST.** Voiding a payment is UI-only (and needs the owner's approval). |

### 9.3 Gotchas (new)

- **Read-only REST actions:** POST with `Content-Type: application/vnd.oracle.adf.action+json` and the body as the **string** `"{}"`. An empty JSON object fails inside Integration Service ("Could not serialize … body"), with `Data.code` missing and only `Message: "400 "`.
- **Resource catalogs** (`/fscmRestApi/resources/11.13.18.05/`, `/hcmRestApi/…`) return 200 but **list no resources**, even when signed in. Use the documented names, `describe` per resource, or try a name and read the 404.
- **Names that 404:** `currencies` (use `currenciesLOV`), `roles` (use SCIM Roles), `receivingReceiptTransactions`, and `userAccounts/{id}/child/userAccountRoles` addressed by UserId. Use SCIM for roles.
- **`fields` on nested expands** (`a;b:c;b.c:d`) was rejected for `workers`, so expand without `fields`. A `q` with nested names (`names.LastName`) is not valid either; use `PersonNumber`.
- **SCIM `attributes=`** with `roles` gave 400 "Attribute name is not a valid attribute". Call without `attributes`.
- **PII:** `WorkerServiceV2` (SSN, DOB) and REST `workers` (DOB). Never store raw responses; extract only the fields needed.
- **Shared tenant:** `payablesPayments` and BPM lists return other teams' records unless filtered. Always filter by your own document number or user.
- **Shell gotcha:** in bash, `UID` is a read-only built-in, so a variable called `UID` silently holds the Linux user id. Use another name.

### 9.4 Recommended use in tests

| Step | API |
|---|---|
| Before a run: is the login active, and does it have the roles? | SCIM `Users?filter=userName eq "<USER>"` (active, roles), `procurementAgents` (BU and actions) |
| Before a run: valid BU, supplier site, currency | `finBusinessUnitsLOV`, `suppliers?expand=sites`, `currenciesLOV` |
| After submit: who must approve? | `purchaseRequisitions/{id}/action/retrieveCurrentApprovers`, or BPM `tasks?keyword=<number>&status=ASSIGNED` |
| After approval: which rules fired? | BPM `tasks/{number}/history` (`reason` = rule name) |
| After each step: did it work? | REST GET by document number (`purchaseRequisitions`, `purchaseOrders`, `invoices`, `invoiceHolds`, `payablesPayments`) |
| Cleanup | §9.2 actions (announced). Payment void and receipt correction are UI-only. |

**Open items:**
- An OAuth client (§4.2).
- Move the connection to Shared/OracleFusion if test runs should use that folder.
- Leftover invoice **889900** (Validated, Unpaid) and its closed PO US165366 from the 23 Nov end-to-end run: decide whether to cancel the invoice.

### 9.5 Create and cancel a requisition through REST (experiment, 2026-11-26)

| Step | Call | Result |
|---|---|---|
| Create | `POST purchaseRequisitions`, `Content-Type: application/json` | **201**: requisition **204188**, status **Incomplete** (it is not submitted for approval) |
| Cancel | `POST purchaseRequisitions/{id}/action/cancel` `{"cancelReason": "..."}` | **400 POR-2010919** "You can't cancel a requisition … if it's incomplete. You must delete it." |
| Clean up | `DELETE purchaseRequisitions/{id}` | **204**; a search by number then returns 0 rows |

**Minimum create body** (US1, Casey). The first attempt without the two marked fields gave 400 POR-2010313:
```json
{"RequisitioningBU": "US1 Business Unit", "PreparerEmail": "CASEY.BROWN_eqjz-dev16@oraclepdemos.com",
 "ExternallyManagedFlag": false,                       // required
 "Description": "UIP-TEST-API-<ts> ...",
 "lines": [{"LineNumber": 1, "LineTypeCode": "Goods", "CategoryName": "206.61 Monitors",
   "ItemDescription": "UIP-TEST-API-<ts> ...", "Quantity": 1, "UOM": "Ea", "Price": 10, "CurrencyCode": "USD",
   "RequesterEmail": "CASEY.BROWN_eqjz-dev16@oraclepdemos.com", "DestinationTypeCode": "EXPENSE",
   "DestinationOrganizationId": 300000047274444,       // required (org code 001)
   "DeliverToLocationCode": "Seattle", "Supplier": "Dell Inc.", "SupplierSite": "Dell US1"}]}
```

**Implication:**
- REST is a fast way to create test data, but the requisition stays Incomplete.
- To get a requisition that can be canceled, submit it first (`action/submitRequisition`, not tried yet), which starts approval. Under 50K, Casey's catch-all step still applies.
- An Incomplete requisition is cleaned up with `DELETE`.
