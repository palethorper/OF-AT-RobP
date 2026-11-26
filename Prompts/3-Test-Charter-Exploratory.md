Use the uipath-test skill. Write an exploratory testing charter for Oracle Fusion procure to pay . The requester and buyer is Casey Brown. Read OracleFusion_Tenant_Findings.md
first and build the charter on what it says about routing, rules, personas and blockers.

The flow: a requisition is approved, becomes a purchase order, is received, matched to a supplier
invoice, and paid.

Cover:
- **Requisition.** Create a noncatalog request and submit it.
  - Try the 50,000 USD approval boundary: 49,999.99, 50,000.00 and 50,000.01. Below 50,000 should
    auto-approve. At 50,000 or more it should go to Casey's manager, Anita Kennedy.
  - Expect the extra approval step from the "Requisition Approval - Casey Brown" rule on every
    requisition.
  - Try the Approver override field.
  - Try withdrawing a pending requisition, then editing and resubmitting it.
- **Approval.** For a requisition at 50,000 or more, approve it as Anita Kennedy. Also try Reject and
  Request More Information. Compare what the approver sees with the routing in the findings.
- **Purchase order.** As the buyer, process the approved requisition into an order and submit it. Note
  which approval stages fire; the PO rules were not read. Try a change order on an open PO.
- **Receipt.** Receive less than the ordered quantity, then the rest. Try receiving more than ordered,
  and note whether it warns or blocks. Try correcting a receipt.
- **Supplier invoice.** Create an invoice matched to the PO. The Invoice Type list needs hardware
  events. Try three cases:
  - matching the quantity received
  - more than the quantity received, to see the match hold
  - a price above the PO price

  Then validate, and initiate approval if the action is offered. Note whether invoice approval is
  switched on.
- **Payment.** Pay one validated invoice in full. Note whether it routes to AP Payment Approvers
  (Matthew Schnieder, Kerry Lane).

Suggested data:
- US1 Business Unit only
- a supplier and category from Casey's own recent POs (US165363 or US165364)
- small quantities
- descriptions and comments that start with "Test UiPath"

Timebox: 90-120 minutes. If one process eats the time, split the rest into a follow-up charter.
Save it as charter-p2p-requisition-to-payment.md.

Capture the session in Test Manager project OFP2P, following the earlier session (test case OFP2P:76
and its manual execution "Exploratory session 2026-11-20 - …"). The CLI can't start an
`exploratory`-type execution, so:
1. Create a charter test case, "Exploratory charter: P2P requisition to payment (US1, Casey Brown)".
   Give it one manual step per area, with the expected behaviour as each step's expected result, and
   labels Exploratory, P2P and Charter.
2. Run it as a manual execution named "Exploratory session <date> - P2P requisition to payment
   (Casey Brown, dev16)".
3. At the end, finish the test case log with step results and comments, one per area, giving the
   surprises and document numbers.
4. Attach the filled-in charter and a zip of the evidence to the test case log.
5. Raise defects only for real problems, such as routing mismatches or unexpected blockers.

Use the uipath-rpa skill to drive the browser. Run the charter now. I'll sign in as Casey. When an
approval step comes up for Anita Kennedy (or another approver), switch to that user: open the sign-in
page and type their username, and I'll type the password. Switch back to Casey afterwards the same
way.

Drive the browser in the background, without taking focus, whenever possible:
- Clicks and typing use `DebuggerApi`, with clear mode Empty field (single line).
- Reads use Get Text or page-text reads.
- Navigate by direct URL where the findings list one.
- I keep using the PC while it runs.

Only the Invoice Type list and screenshots need the browser in front. Do everything else first, then
group the focus steps into short batches. Tell me before each batch ("Focus batch: about N seconds")
and I'll leave the PC alone. If focus is refused, don't retry in a loop; keep the page-text capture
and mark the screenshot as pending.

Evidence for every screen:
- a page-text capture in P2PGuide/text
- a screenshot in P2PGuide/shots, taken in a focus batch, with a numbered name, for example
  p2p01_01_requisitions.jpg; the text capture uses the same name

Note every surprise:
- required fields
- warnings compared with blockers
- holds and why they were applied
- approval steps that did or didn't fire against the documented rules
- fields that default from the requester or the PO
- buttons and actions that aren't where you'd expect
- pages that take more than 30 seconds to load

Rules:
- Announce every write before you make it: submit, approve, reject, create, receive, validate, pay,
  cancel or withdraw.
- Only act on documents you created in this session, and identify them by number. Casey's worklist
  also holds other teams' requisitions, so don't open or touch those.
- Before you finish, clean up everything you created:
  - withdraw or cancel requisitions
  - cancel POs
  - cancel invoices
  - void payments

  Ask me before voiding a payment. List the document numbers and the final status of each in the
  charter's session notes.
