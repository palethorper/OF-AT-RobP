Use the uipath-rpa skill to explore the browser.
I'm signed in to Oracle Fusion Cloud ERP as Casey Brown
(Procurement Agent , with requester, buyer, receiving, Payables and admin roles).
Explore the environment for a procure-to-pay test suite that covers Create Requisition, Purchase Order,
Receipt, Supplier Invoice and Payment.

For each business process, list its steps in order with the navigation path to each one, who each
approval routes to (approval group, supervisor hierarchy, position or named user), and the rule
conditions (for example "Approval by Procurement Manager if requisition amount is 10,000 USD or more",
or by business unit or category). Approval rules are in BPM setup (Manage Requisition Approvals, Manage
Purchasing Document Approvals, Manage Invoice Approvals) and approval group members are in BPM Worklist >
Administration > Approval Groups. Read them on view-only pages; don't use Edit Rules.

For each test login, say who the user is, their job and data roles, which business units they can act
in, and whether they're a good initiator or approver. Use Security Console read only.

Flag blockers: approvals that route to someone with no login, users who are inactive, locked or
end-dated, and business-unit, legal-entity or country-specific steps or rules.

This is read only, so don't save, submit, approve, add to cart or change anything, and don't open other
users' worklist items or transactions. Redwood pages can take up to 2 minutes to load, so wait rather
than treat a blank page as an error.

Write it all to OracleFusion_Tenant_Findings.md, including a personas table.

- **Input method.** Clicks and typing use the Chromium API (`DebuggerApi`), not hardware events, so the robot does not need window focus and the person at the PC can keep working. Typing relies on Empty field (single line) to clear: a Ctrl+A inside an ADF table selects every row and Oracle drops the typed value. The Invoice Type select still uses hardware events.
