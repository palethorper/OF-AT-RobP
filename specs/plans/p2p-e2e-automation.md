# Plan: automate TM test case OFP2P:227 (Oracle P2P E2E, Deloitte script)

Execution autonomy: interactive
Source: specs/source/Oracle_P2P_E2E_Manual_Test_Script.docx (S0–S8), user decisions 2026-11-23
Test Manager: requirement OFP2P:226, test case OFP2P:227 (id ac19fd72-4a65-0300-b40d-0b4a6618d649), 35 parameters incl. `Oracle_Fusion_P2P_Test` (Asset)
Project: C:/UiPath/OracleFusion_AgenticTesting (Portable, VisualBasic, UIA 26.10.7 ≥ min 26.10.2)
Mode: XAML, modern UIA, ONE Edge `NApplicationCard` per stage (ByInstance, OpenMode=Always for S0 only / attach after, IsIncognito=True, InteractionMode=DebuggerApi, maximized) — AGENTS.md
UI capture: live, in **Edge** (selectors are browser-specific), user signs in (types password); robot types password from the asset at run time (user-approved)

## Decisions (user, 2026-11-23)
- New requirement (OFP2P:226) + new automated test case (OFP2P:227)
- Requisition uses the **newly registered supplier** (site = registration address name, e.g. HQ)
- Casey Brown self-approves supplier registration + requisition
- Cleanup included (S9, runs always when RunCleanup=True)
- Capture session approved; robot may type the password from the credential asset during runs

## Stop conditions
- User sign-in needed (password) — wait for user
- Oracle shows an unexpected blocker that needs a business decision
- UIA scan fails on an unlocked interactive session after retries

## Tasks
- [x] T1 Test Manager: requirement OFP2P:226 + attachments (docx, xlsx)
- [x] T2 Test Manager: test case OFP2P:227, 10 steps, 35 parameters, link, attachment
- [x] T3 Window baseline; open Fusion in Edge (tab "Cloud Sign In", Edge window "... - Work - Microsoft Edge")
- [x] T3b Packages upgraded (user-approved "All to latest"): UIA 26.10.9, System 26.10.1, Testing 26.10.0 (WebAPI 2.5.2 latest). Fixed the IDCS "Failed to serialize the target into XAML" error.
- [x] C0 Capture Sign-in (IDCS). App "Oracle Identity Cloud" uR7IZSwNKU6CNcqBhFFDJg/2h7x-nsyRUeidlwOxhSMVg; screen "Oracle Sign In" uR7IZSwNKU6CNcqBhFFDJg/HUBH5pJF9E2nxzkZHf7kdA (`<html app='msedge.exe' title='Cloud Sign In' url='https://idcs-…/ui*' />`); Username Input uR7IZSwNKU6CNcqBhFFDJg/YDnFuy1_RUqnH_bIk3_pbA; Password Input uR7IZSwNKU6CNcqBhFFDJg/i1IoElEXDES-dGxkgGnFtg; Next Button uR7IZSwNKU6CNcqBhFFDJg/KkDVWm5ktUaTcz5qwNuR8A. Input method on IDCS: **Simulate** (DebuggerApi attach fails; first DebuggerApi type kept only "C").
- [x] A0 Workflows/S0_SignIn.xaml authored, linked (card → screen "Oracle Sign In"; NTypeInto_1/2, NClick_1), validate+build clean; debug run 2026-11-23 signed in via asset Oracle_Fusion_P2P_Test (FolderPath Shared/Testing-UBAPI) after the user reset the password. Card InteractionMode must stay **Simulate** (link-screen resets it to DebuggerApi — re-set after any relink). Args: in_CredentialAssetName, in_CredentialFolderPath, in_FusionUrl, in_UseIncognito.
- [x] C1a Home (Sales default tab). App "Oracle Fusion Cloud" uR7IZSwNKU6CNcqBhFFDJg/11ObnoGS7kiAZkJIbZT0qw; screen "Fusion Home" uR7IZSwNKU6CNcqBhFFDJg/7TN2LWKdH0S2QSDE9rLCIg, window selector stabilized `<html app='msedge.exe' title='*Oracle Fusion Cloud Applications*' url='https://fa-eqjz-dev16-saasfademo1.ds-fa.oraclepdemos.com/fscmUI*' />` (dropped volatile htmlwindowname). Greeting Text …/1VHG3Jkrr0-d9MeaNIfe5Q; Procurement Tab …/eqmP1C81mEeMicK0YgrUDA; Payables Tab …/hXbByTQ_10iiLuzsNPUoIQ; Settings And Actions …/xJ3VCf-66UuVJwsZc1IINw; Navigator …/fBp0_Sx2FEuEmGhPn3NsNw (prefix uR7IZSwNKU6CNcqBhFFDJg/). NOTE: S0 sign-in by robot FAILED (password field likely not filled by Simulate) — user signed in manually; diagnose later (pause before Next).
- [x] C1b Home Procurement tab (same screen "Fusion Home"; tab switch needs **Simulate** click): Purchase Requisitions App …/U2aXeGgBQky-ybLHBtSGtw; Supplier Management App …/K1ILxNxhI0iD9a3jmXF8tw; Process Requisitions New Quick Action …/Tp6y-6Z-VUqTXLUch4t1oQ; Purchase Orders New Quick Action …/ca_5sQPq6E2i6m8iV3lwiQ; My Receipts App (= My Receipts (New), id itemNode_procurement_MyReceiptsNew_*) …/2nwjno-dHUKcvX3Hhq8cmw. Show More not needed.
- [ ] (old C1 list) Procurement tab, Supplier Management tile, Purchase Requisitions tile, Process Requisitions (New), Purchase Orders (New), Show More, Payables tab, Invoices tile, greeting, Settings and Actions / Sign Out
- [x] C2 Supplier Management (URL /fscmUI/redwood/suppliers/landing-page/overview): screen uR7IZSwNKU6CNcqBhFFDJg/jhDdmUjsI0m8-cSqmfsztg (`title='Supplier Management - Oracle Fusion Cloud Applications'`); Register Supplier Link …/MRNW5N07mEayizfB9qbRVg; Supplier Registrations Link …/gWKA2MM0kkyDqxxkTwZakQ. All Fusion window selectors: drop volatile htmlwindowname before create-screen.
- [x] C3 Wizard p1 Company Details: Company, Business Relationship, Procurement BU, Request Reason, Country, Taxpayer ID, Organization Type, Continue  (WRITE: draft registration)
- [x] C4 Wizard p2 Contacts: First/Last/Email, admin=Yes, user account=Yes, Continue
- [x] C5 Wizard p3 Addresses: Address Name, purposes, Enter Address + suggestion, contact checkbox, Continue
- [x] C6 Wizard p4 Business Classifications: Classification Dropdown …/SVSHEA0eikO2c_DUFsG5GA + Dropdown Option Cell (exact text), Continue
- [x] C7 Wizard p5 Bank Accounts: Bank Country …/7fKsQ611bUCDGBXuxYtI1A (defaults, not set), Branch Number …/JtD2S7TYZUS8dYxmPMaedA + Dropdown Table Option Row …/ikHptuRhXESEAoMnhF2BNA, Account Number …/xs-Pvw42OEaQW9SuUbQ3wA (UNIQUE per run), Account Holder …/q1j7AgLXUUOiIOFxds8fMQ, Account Suffix …/GHPmCwffVUWSv5C4ylmFQA
- [x] C8 Wizard p6 Products and Services: Category Checkbox …/HbiPWzI8vEu6lIZIb0OLGg (row text, parametrized)
- [x] C9 Wizard p7 Questionnaire (Questionnaire Answer Radio …/uagiHiqn9ECyCs_EwZKVYQ, Add Attachments Button …/Z1gWw-jUS0e9vFegn5TB-g, Add Files Drop Zone …/ERwkH74cR0yAAsbWzRC_qg via Browser File Picker Scope, Attachments Panel Close Button …/RdZ8D6OZckqXtsCRlYEVrg, Submit Button …/l49rTBLTF0WY9KscJtyLTg); submit exercised by the S1 debug run: Full Compliance radio, Add Attachments, file input, close panel, Submit  (WRITE: submit registration) + toast
- [~] S1 robot run (2026-11-23 19:25, run 4): pages 1–6 pass unattended (reg 300000342395635, UIPTST Supplier 2611231925). Fixes in S1: Company typed last; Get Attribute `url` instead of Get URL; Retry Scope on Register Supplier and Add Attachments; new draft-exists dialog check → Start Over (OR "Draft Exists Start Over Button" …/zIPAczD5IE6ZXQsB6Ds_mQ). **BLOCKED** at the questionnaire upload: Browser File Picker Scope needs "Allow access to file URLs" on the UiPath Chrome extension (off in every profile). The native Open-dialog fallback (OR screen "Chrome Open File Dialog" …/5m4VnW9Ej0CuRdRB58kbLQ, element "Open Dialog File Name Input" …/5XMBf2Ew4EKel2W7AcxB2w) was captured, but typing into it was refused by the agent permission check. Debug session left suspended at NBrowserFilePickerScope_1.
- [x] C10/C11 Registration approval (BPM task) — Workflows/Common_ApproveBpmTask.xaml (screens BPM Worklist, BPM Task Window)
- [ ] (old) C10 Supplier Registrations list: search, request link, status
- [ ] C11 Notifications / worklist: registration approval task, Approve, Comment, Submit (new tab)  (WRITE: approve)
- [x] C12–C19 captured live (req 204170, PO US165367, receipt 52957, invoice UIP-OFP2P-2611232030 Validated); workflows S3_CreateRequisition, S5_CreatePurchaseOrder, S6_ReceiveOrder, S7_CreateInvoice; TC extended with S2–S7 + 3 verifications; validate + build clean (2026-11-23 21:45)
- [ ] (old) C12 Requisitions: Create Noncatalog Request form (Item Description, Item Type, Category, Qty, UOM, Price, Supplier, Supplier Site, Add to Cart), confirmation
- [ ] C13 Cart: line checkbox, totals (Subtotal, Tax, Approval Amount), requisition number, Submit  (WRITE: submit req)
- [ ] C14 My Requisitions: row status, requisition detail status
- [ ] C15 Requisition approval task: Approve, Submit  (WRITE: approve)
- [ ] C16 Process Requisitions (New): search, line checkbox, Stage; Staged document: line checkbox, Publish, PO created message  (WRITE: create PO)
- [ ] C17 Purchase Orders (New): search, row, Edit, Submit, status  (WRITE: submit PO)
- [ ] C18 My Receipts (New): search, line checkbox, Receive Now, toast, My Receipts tab row  (WRITE: receipt)
- [ ] C19 Payables Invoices: Tasks, Create Invoice; header (Identifying PO, Number, Amount); Lines action Match Invoice Lines + Go; match dialog (checkbox, Apply, OK); self-billing warning OK; Invoice Actions > Validate; status; Save and Close  (WRITE: invoice)
- [ ] C20 Cleanup screens: Invoice Actions > Cancel Invoice + OK; PO Cancel; Requisition More Actions > Cancel (reason, Cancel Requisition); supplier deactivate (path TBD in capture)  (WRITE: cleanup)
- [~] A1 Author workflows (done: S0 v2 with out_Browser + already-signed-in branch + greeting check; S1_RegisterSupplier (in_Profile dictionary, ≤20 args); Tests/TC_P2P_E2E.xaml (20 args = TM params after link-automation sync) registered InProgress; Data/Questionnaire_Attachment.docx) —: Tests/TC_P2P_E2E.xaml + Workflows/S0..S9 + Common helpers; Data/Questionnaire_Attachment.docx; register test case in project.json fileInfoCollection (backup project.json first)
- [ ] A2 Gate: validate every file + build
- [ ] A3 Debug run (consent-gated) with window baseline/diff; recover selectors
- [ ] A4 Context files (.claude/rules/project-context.md, AGENTS.md block); playbook update
- [ ] A5 Publish + link-automation to OFP2P:227 — ONLY when the user says so

## Browser switch (user, 2026-11-23): Chrome + DebuggerApi only
- Edge unreliable (sleeping tabs, content unreachable, COM HRESULT). User: use **Chrome**, input **DebuggerApi** (no Simulate, never take over the screen). Deviates from AGENTS.md (Edge) — ask user before editing AGENTS.md.
- Re-point existing OR screens/elements with `replace-screens` / `replace-elements` (reference IDs kept), then relink workflows (relink resets card mode to DebuggerApi = desired).
- [x] Sign-in screen + 3 elements replaced with Chrome definitions; S0 relinked (card DebuggerApi), validate+build clean; **debug run signed in successfully** (greeting "Good afternoon, Casey Brown").
- [ ] Replace Fusion Home, Supplier Management, Supplier Registration Wizard screens + elements (C1a/C1b/C2/C3) with Chrome definitions
- [ ] Simulate does not commit JET values — page 1 values must be re-entered with DebuggerApi and verified by "Required" hint disappearing
- Note: draft registration 300000342326530 (Edge) left unsubmitted — cleanup.

## TM parameter change (at link-automation, A5)
Analyzer ST-DBP-002 (error in this tenant) caps workflows at 20 arguments, so TC_P2P_E2E exposes 20 arguments: Oracle_Fusion_P2P_Test, CredentialFolderPath, FusionUrl, UseIncognito, RunCleanup, SupplierName (prefix; RunId appended), TaxpayerId (AUTO = RunId), AccountNumber (AUTO = MMddHHmm), ProcurementBU, Country, OrganizationType, ContactEmail, AddressLookup, BusinessClassification, BranchNumber, ProductsCategory, ItemDescription, Category, Quantity, Price. Script constants (Spend Authorized, New Supply Source, Contact/1, HQ, Example Holder, 00, attachment path, UOM Ea, USD, approvers = Casey) are defaults inside the test case. link-automation re-syncs the OFP2P:227 parameters to this list.

## Element naming (OR)
App "Oracle Fusion Cloud" (Fusion pod host) and "Oracle Identity Cloud" (IDCS host); screens named after page titles (e.g. "Supplier Registration Company Details").

## Created records log
See P2PGuide/documents.txt (capture run) — clean up after capture (S9 path).
