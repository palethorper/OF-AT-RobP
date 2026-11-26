Use the uipath-platform skill for Data Fabric. Design a Data Fabric entity for the Oracle Fusion Procure to
Pay chain (the OFP2P test cases: requisition, PO, receipt, invoice, payment; see
OracleFusion_Tenant_Findings.md and OracleFusion_Exploratory_Session.md). There is one record per run, and
it must carry everything a later test case needs from an earlier one: run ID and test marker, business unit,
requester and buyer, supplier and site, item, quantity, unit price and amount, charge account, the
requisition number and status, the PO number and status, the receipt number, the invoice number, ID and
validation status, the payment number, and how to clean up.
Every record we create in Oracle must have a description that starts with "UIP-TEST-<RunId>", so we can
find our own data.
Use a Stage choice set (Requisition, Approved, PO, Received, Invoiced, Validated, Paid, CleanedUp, Failed)
and a CleanupAction choice set (None, CancelRequisition, CancelPOLine, CancelInvoice, VoidPayment,
ManualReview). Oracle can't delete approved documents, only cancel or void them. Use DECIMAL for numbers and
tenant scope. Write the schema to OracleP2PRun.schema.json and show it to me before you create anything.

Use the uipath-platform skill for Data Fabric. Design a second, read-mostly entity for master and common
data: one row per reference item the tests use, with the type (Persona, BusinessUnit, Supplier, SupplierSite,
CatalogItem, ChargeAccount, PaymentTerms, BankAccount), the key, the display value, the BU, an
IsActive flag and the date we last checked it. Use a ReferenceType choice set and tenant scope. Seed it only
with data that already exists on dev16 and that we've confirmed read only: Casey Brown (requester, receiver,
AP, payments), Calvin Roth (buyer), Anita Kennedy (approver for 1,000+), US1 Business Unit, supplier ABC
Consulting, catalog item LAP-BBAG (Laptop Carrycase Black, $25.00), payment terms Immediate.
Don't create or change suppliers, items or accounts in Oracle; they're shared. Mark anything unconfirmed
(ABC Consulting's site and number, the US1 charge account) as IsActive = false until it's checked. Write
OracleP2PReference.schema.json and show it to me before you create anything.

Use the uipath-platform skill. Create both entities and their choice sets in Data Fabric with the uip df
commands. Then write a create script and a seed script; seed only with the reference rows above and with
P2P run records marked UIP-TEST. Save the entity and choice set IDs to df-p2p-ids.json. Read both entities
back and show me their fields.

Use the uipath-platform skill for the Data Fabric entity and the uipath-rpa skill for the workflow. The
receipt, invoice and payment tests must be able to run independently and in parallel without receiving or
invoicing the same PO. Design a reservation entity: which PO and schedule, reserved by which test set, run
ID, expiry, status, and a short snapshot (PO number, supplier, site, item, ordered quantity, received
quantity, unit price, amount, currency) that tests can use to work out their expected values. Then write
GetP2PAssignment.xaml in the Studio project. It reads the test's reservation and falls back to the latest
UIP-TEST run record at the right stage when there isn't one.