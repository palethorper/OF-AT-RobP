Use the uipath-test skill for the charter and Test Manager, and the uipath-rpa skill to drive the
browser (`uip rpa uia`).

Run an exploratory testing session on Oracle Fusion ERP, procure to pay, from an approved requisition
through to payment. This is charter **P2P-02**: it continues P2P-01, which only covered the requisition.

## Read first

- `run-config.json`: Test Manager project, folder and login. Stop if `status` is `not-ready`.
- `specs/OracleFusion_Tenant_Findings.md`: routing, rules, personas and blockers.
- `OracleFusion_Automation_Playbook.md`: URLs, ready text, input methods, LOV recipe, cleanup, traps.
- `specs/charter-p2p-requisition-to-payment.md`: P2P-01 session notes and its follow-up list.

Build the charter on what these say. Where they disagree with the screen, the screen wins; record it
as a surprise.

## People

I'm signed in to Oracle as Casey Brown (requester, buyer, receiver, Payables). Check her roles on
screen rather than assuming them.

The approver is Anita Kennedy, Casey's manager. When a step needs her:
1. Sign out.
2. Open the sign-in page and type her username.
3. Stop. I type the password.

Switch back to Casey the same way. Never type, read or store a password.

## Charter

Write `specs/charter-p2p-02-approval-to-payment.md` in the same shape as the P2P-01 charter:
mission, expected behaviour (from the findings), areas, test data, risks, and empty session notes.
Cover these areas:

1. **Approval (Anita)**
   - Create three requisitions at or above 50,000 approval amount. Approval amount includes 9.5%
     tax; use the price table in the playbook.
   - On these, try Approve, Reject and Request More Information.
   - For the information request, answer it as Casey.
   - Compare who each one routes to with the findings, including Casey's catch-all step.
2. **Purchase order (Casey as buyer)**
   - Process the approved requisition into an order and submit it.
   - Record which approval stages fire. Only the self-approval rule fired via the API before.
   - Try a change order on quantity and on price, and note whether it re-routes.
3. **Receipt**
   - Receive part of the quantity, then the rest.
   - Try receiving more than ordered: does it warn or block?
   - Try correcting a receipt.
4. **Supplier invoice**
   - Create invoices matched to the PO for three cases: at the received quantity, above the received
     quantity, and at a price above the PO price.
   - Validate each and record the holds and their reasons.
   - Find out whether invoice approval is switched on (view the setting only).
5. **Payment**
   - Pay one clean, validated invoice in full.
   - Record whether it routes to AP Payment Approvers (Matthew Schnieder, Kerry Lane).

Test data:
- US1 Business Unit only, small quantities.
- The supplier and category used in P2P-01 (Dell Inc., Desktops).
- Every description and comment starts with "Test UiPath P2P-02".

Timebox: 120 minutes. If one area takes more than half the time, stop it and move the rest to
P2P-03.

**Show me a short summary of the charter and wait for my go before you start the session.**

## Running the session

- Follow the playbook's input methods: DebuggerApi in the background by default, with clear mode
  Empty field (single line). Navigate by direct URL where the playbook gives one.
- Wait on ready text, polling every 5 s, with a timeout of at least 180 s. A blank Redwood page is
  normal at first.
- Steps that need the browser in front (hardware clicks such as BPM Approve, screenshots):
  - Do everything else first, then group them.
  - Before each group, tell me "Focus batch: about N seconds" and I'll leave the PC alone.
  - If focus is refused, don't retry in a loop. Keep the page text and mark the screenshot pending.
- Evidence for every screen: a page-text capture in `P2PGuide/text` and a screenshot in
  `P2PGuide/shots`, with the same numbered name, for example `p2p02_01_requisitions`.
- Keep `P2PGuide/documents.txt` (every document number and action, with time) and
  `P2PGuide/surprises.txt` up to date as you go, not at the end.
- Note every surprise:
  - required fields
  - warnings compared with blockers
  - holds and their reasons
  - approval steps that did or didn't fire against the documented rules
  - fields that default from the requester or the PO
  - actions that aren't where you'd expect
  - pages that take more than 30 s to load

## Rules

- Announce every write before you make it: create, submit, approve, reject, request information,
  withdraw, cancel, receive, correct, validate, pay, void.
- Only act on documents created in this session, and identify each one by its number. Casey's and
  Anita's worklists hold other teams' items, so don't open or touch those.
- Never click anything on the playbook's never-click list (BPM admin edits, Security Console edits,
  synchronisation).
- Settings pages are view only.

## Capture in Test Manager

Use the project and folder from `run-config.json` (DNZTRAIN, Shared/OracleFusion). The CLI can't
start an exploratory-type execution, so:

1. Create a test case named "Exploratory charter: P2P-02 approval to payment (US1, Casey Brown)".
   - Give it one manual step per area, with the expected behaviour as each step's expected result.
   - Add the labels Exploratory, P2P and Charter.
2. Run it as a manual execution named "Exploratory session <date> - P2P-02 approval to payment".
   Save the ids to `P2PGuide/session-ids.txt`.
3. At the end, finish the test case log with one result and comment per area. Each comment gives
   the surprises and the document numbers.
4. Attach the filled-in charter and a zip of this session's evidence to the test case log.
5. Raise defects only for real problems, such as routing that contradicts the rules or an
   unexpected blocker. A finding about unread rules is not a defect.

## Cleanup and finish

Before you finish, clean up everything created in this session, using the playbook's cleanup
recipes:
- invoices: cancel
- POs: cancel, or close if they have receipts
- requisitions: withdraw, then cancel

Ask me before voiding a payment.

Then:
- Record every document number and its final status in the charter's session notes.
- Update the playbook with anything newly verified (PO, receipt, invoice and payment sections).
- Update the findings where the screen contradicted them.
- Finish with a short report: what was covered, the top surprises, the defects raised, what's left
  for P2P-03, and any cleanup that is still pending.

Don't publish anything.
