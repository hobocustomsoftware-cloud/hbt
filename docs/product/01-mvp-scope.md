# AI Prompt — MVP Scope and Release Boundary

Act as a Chief Product Officer, transportation-domain product manager, business analyst, and principal software architect.

Create the authoritative **MVP Scope and Release Boundary** for the HoBo Transport Platform (HBT).

Use the existing files under `architecture/`, `docs/business/`, `docs/modules/`, and `docs/workflows/` as source material. Do not merely repeat their instructions. Resolve them into concrete product decisions.

## Confirmed product context

Treat the following as confirmed stakeholder inputs:

- Initial target country: Myanmar
- Initial transport segment: intercity express bus transportation
- Product model: multi-tenant SaaS business platform
- Product approach: offline-first
- The platform must make intercity bus ticket discovery, booking, and purchasing easier for passengers.
- Bus operators, terminals, and their authorized staff must be able to replace paper-based operational records with digital records that can also be viewed and managed from phones.
- Authorized vehicle assistants/conductors must be able to sell or issue tickets for passengers within their permitted operational scope.
- Counter-operated and authorized crew-operated cargo/parcel handling is included in the initial MVP as Cargo Lite within HBT Business.
- Cargo functionality is not included in HBT Passenger for the MVP. Senders and receivers interact with the bus company/counter or authorized crew; passenger self-service cargo booking is deferred.
- Passenger self-service must be available through both a mobile application and a responsive public website.
- Passengers must create and use an account to purchase tickets; guest checkout is not part of the initial scope.
- One account holder must be able to purchase multiple tickets in one booking for other travelers, such as two or three passengers.
- Organization/company customers must be able to make group purchases for multiple travelers, such as five or ten passengers. The specification must distinguish an individual account making a multi-passenger booking from an organization-managed purchase.
- A normal individual account must be able to link to one or more organizations when authorized.
- The platform must also support organization/company accounts and organization-managed users. The specification must define the relationship between the company account, linked individual accounts, membership, roles, and data ownership.
- Company group bookings must support an approval workflow and invoice generation.
- The payment architecture must be provider-neutral and designed for later integration with Myanmar payment methods and providers, including MMQR, KBZPay, AYA Pay, and bank-based payments.
- External/online payment-provider integration is deferred from the initial implementation. The MVP scope must define how payment status is recorded or confirmed before those integrations exist, without falsely representing an unverified payment as paid.
- The HBT commercial model must not charge transaction fees on passenger-ticket or cargo transactions. Platform revenue must come from bus-operator monthly and annual SaaS subscriptions.
- SaaS subscription billing is separate from passenger-ticket and cargo payment collection. MVP subscription invoices and subscription-payment confirmation may be handled manually until provider integrations are introduced.
- MVP passenger-ticket and cargo payments must support manually recorded cash, wallet-QR, and bank-transfer methods. Automatic wallet/bank verification, gateway settlement, and webhook processing are deferred.
- A tenant may register approved payment-receiving accounts and QR images. An account may be a merchant account or, where the operator still relies on it, an explicitly approved personal wallet account.
- Merchant payment accounts should be preferred. A personal wallet must require company-owner approval, named ownership, business justification, permitted branch/counter scope, activation period, reconciliation responsibility, and audit history.
- HBT must never collect or store wallet PINs, passwords, OTP secrets, private banking credentials, or credentials used to operate a merchant/personal account.
- Displaying or scanning a static wallet QR does not prove payment. Until an official provider integration verifies payment, wallet and bank payments must follow submitted-for-verification and authorized-manual-confirmation states.
- Customers may submit a provider name, payer/reference information, transaction reference, payment time, amount, and receipt screenshot where company policy permits. An authorized counter/finance user must verify the evidence against the receiving account before marking payment confirmed.
- Payment-account and QR changes must require explicit authority and audit. Existing bookings and payment records must preserve which account/version was presented at payment time.
- Payment accounts and QR selection must support tenant-wide, branch, terminal-operation, and counter scopes with deterministic priority and must not expose one tenant's payment destination to another tenant.
- Later wallet, MMQR, online bank, and payment-gateway integrations must plug into the same payment-state model without rewriting booking, ticket, cargo, invoice, or reconciliation ownership.
- Myanmar-first, low-digital-literacy usability is a mandatory MVP requirement for both HBT Passenger and HBT Business. A user who can read basic Myanmar text must be able to complete their permitted primary tasks without understanding technical or financial-system jargon.
- Critical payment and operational state changes must support push notifications with an audible notification channel when the user grants permission and the operating system allows it. This includes at minimum payment submitted, payment awaiting staff verification, payment confirmed/rejected, booking expiry warning, ticket issued, trip change, cargo exception, and staff action required.
- When a passenger payment is confirmed or rejected while HBT Passenger is backgrounded or closed, the backend must send a push notification through the supported mobile notification service. HBT Business must similarly notify authorized counter/finance users when manual payment verification is awaiting action.
- Notifications must remain visible in an in-app notification inbox and the related task must remain visible in a pending-work queue; sound alone must never be the only evidence or workflow trigger.
- Notification delivery is best effort and must account for disabled permissions, no connectivity, operating-system battery controls, Do Not Disturb, device force-stop, invalid device tokens, and provider failure. The system must track delivery attempts without claiming that a notification was heard or read.
- Lock-screen notification text must minimize personal, payment, ticket, and cargo information. Sensitive details must require authenticated app access.
- HBT Business must use distinct, configurable notification categories for informational events, action-required events, payment verification, trip operations, and urgent exceptions. Users may configure sound within policy, but high-risk operational alerts must remain clearly distinguishable.
- Primary workflows must use short Myanmar labels, large touch targets, clear icons paired with text, step-by-step screens, obvious back/cancel/retry actions, plain-language errors, and confirmation before irreversible actions.
- Color must not be the only indication of status. Statuses must include Myanmar text and recognizable symbols. Critical amounts, dates, trip references, ticket references, passenger/cargo counts, and payment states must be visually prominent.
- Optional audio guidance may be provided for selected high-value actions, but it must not expose passenger or payment-sensitive information aloud by default. The design must remain fully usable without text-to-speech availability.
- Myanmar-language usability must be tested with representative counter staff, conductors, owners, and passengers who have limited digital experience before MVP release.
- MVP notifications must use ordinary alert sound and/or vibration as an attention cue; spoken notification content and text-to-speech are not required.
- HBT Passenger and HBT Business must minimize taps, typing, navigation depth, and repeated choices for high-frequency tasks. “One click” means the shortest safe path, not removal of required business information or security controls.
- After login, HBT Business must open directly to a role- and context-specific work dashboard. It must remember the last permitted organization, branch, terminal, counter, shift, or assigned trip where safe, while making the active context unmistakably visible.
- A notification tap must deep-link directly to the relevant payment, booking, trip, cargo, or approval task after authentication rather than opening a generic home screen.
- High-frequency safe actions should use prominent quick actions, smart defaults, recent items, scanner-first entry, saved filters, and automatic context. Examples include search trip, sell ticket, scan ticket, accept cargo, print/reprint, view assigned trip, and view pending payments.
- The primary navigation should expose only the small set of work areas permitted for the active role. Rare configuration and administrative actions must not clutter counter, driver, or conductor workflows.
- Forms must progressively disclose optional or exceptional fields. Required fields should be prefilled from the active trip, counter, organization, customer history, or scanned reference when safe and accurate.
- The system must not sacrifice integrity for fewer taps. Payment confirmation, refund, cancellation, role/permission changes, trip closing/reopening, cargo handover, and other irreversible or high-risk actions must use a concise confirmation, hold/swipe confirmation, approval, or re-authentication appropriate to risk.
- Repeated/batch workflows should support scan-and-continue, print-all/print-selected, multi-passenger ticket separation, pending-payment queues, and bulk-safe actions so staff do not repeatedly return through menus.
- Authorized vehicle assistants/conductors must be able to create walk-up bookings, sell or issue tickets, and validate/check passenger tickets for their assigned operational scope.
- Tickets must be electronic tickets that a customer can retain and retrieve after purchase.
- Every traveler in a multi-passenger booking must receive a distinct passenger-specific e-ticket. The purchasing account holder must be able to separate and distribute the relevant e-ticket to each traveler.
- Each e-ticket must include both a QR code and a human-readable booking/ticket reference.
- A customer must be able to save an e-ticket as an image to the device gallery and share that image with the relevant traveler through ordinary device sharing mechanisms.
- Authorized terminal or operator staff must be able to print a paper representation of the e-ticket before boarding. The printed ticket must remain usable for authorized roadside or journey checkpoint inspection.
- Myanmar language is the primary product language for the initial market.
- Every human user must have an individual login account. Shared counter, manager, owner, driver, or conductor credentials must not be treated as an acceptable operating model.
- A single individual account may act as a passenger and may also hold one or more authorized workforce roles in one or more organizations.
- A company/organization is a tenant workspace, not a shared human login. Organization membership assigns roles and operating scopes to individual accounts.
- The initial workforce role model must cover at least:
  - Company Owner: controls company-level ownership, administrators, subscription, high-risk policy, and company-wide oversight.
  - Company Administrator: manages organization configuration, branches, terminals/counters, users, roles, and master data as delegated by the owner.
  - Company/Operations Manager: oversees schedules, trips, operational staff, exceptions, approvals, and company or assigned-area reporting.
  - Branch or Terminal Manager: manages an assigned branch/terminal operation, counter staff, local trips, local exceptions, and approvals within delegated limits.
  - Counter Sales Staff: searches trips, creates and updates permitted bookings, records permitted payments, issues/reissues and prints tickets, and assists passengers at assigned counters.
  - Dispatcher/Operations Staff: manages assigned-trip readiness, manifests, vehicle and crew assignment, departure, arrival, and operational exceptions.
  - Vehicle Assistant/Conductor: for assigned trips, views the permitted passenger manifest, creates walk-up bookings, sells/issues tickets, validates tickets, records boarding, and works offline where allowed.
  - Driver: views assigned trip, route, schedule, vehicle, and essential operational information, without receiving unnecessary passenger or financial access.
  - Cashier/Finance Staff: verifies permitted payments, handles reconciliation, invoices, refunds, and settlements according to approval limits.
  - Inspector: validates tickets and views only the minimum journey and passenger evidence required for authorized inspection.
- Permissions must combine role and scope. Required scopes include tenant/company-wide, branch, terminal, counter, assigned trip, and self-only.
- A physical terminal may serve multiple bus companies. The domain model must distinguish the shared physical terminal from a specific company's branch, operating presence, and sales counter at that terminal.
- Counter devices may be shared operational devices, but every transaction must remain attributable to the individual staff member who authenticated or unlocked the working session.
- High-risk actions such as role changes, price overrides, exceptional discounts, payment confirmation, refund, ticket cancellation/reissue, trip reopening, and settlement adjustment must use explicit permissions, approval limits, and audit records.
- The SaaS platform must support separately authenticated platform administrators. A platform administrator is not a tenant owner and must not receive unrestricted routine access to tenant business data merely because of the platform role.
- Platform administration must distinguish platform operations from tenant support access. Tenant support access must be purpose-bound, time-limited, least-privileged, explicitly reasoned, and fully audited; sensitive access should require approval and stronger authentication.
- Tenant owners and authorized tenant administrators must be able to create custom organization roles, select allowed permissions, and assign those roles to organization members.
- Managers may create or assign custom roles only when explicitly delegated by the owner or tenant administrator.
- A user must never be able to grant a permission, scope, approval limit, or role that exceeds the authority they currently hold and are permitted to delegate.
- Platform-provided system role templates must remain protected from tenant modification. Tenants may copy a template into a custom role and adjust only permissions they are authorized to delegate.
- Role creation, permission changes, role assignment/removal, scope changes, privileged access, platform support access, and access denials must be auditable.
- Android and iOS applications must support self-service account registration without requiring platform staff to manually create ordinary accounts.
- After identity registration, onboarding must clearly separate three user intents:
  - Passenger: create a personal account for searching, booking, purchasing, and retaining tickets.
  - Start a transport business: create a tenant/company onboarding request and become the initial company owner through an atomic, auditable provisioning workflow.
  - Join an existing company: accept a verified invitation or organization join request; the user must not self-assign a workforce role.
- Creating a transport business must provision the tenant, organization, initial owner membership, company-owner role, and safe initial configuration as one recoverable workflow. The company may remain pending or trial-limited until required verification is complete.
- A company owner or explicitly authorized administrator/manager must invite staff and assign roles, scopes, and approval limits. Drivers, conductors, counter staff, finance staff, and managers must not be able to claim those roles merely by registering.
- An invited user must explicitly accept organization membership before workforce access becomes active.
- One individual account may simultaneously remain a passenger and hold different workforce roles in multiple organizations.
- Mobile and web clients must derive menus, actions, and protected screens from effective permissions and scopes returned by the backend; clients must not treat a role name alone as proof of authority.
- Workforce permissions must be evaluated by action and scope. At minimum:
  - Counter sales staff may manage permitted bookings, ticket issue/reissue/printing, permitted payment recording, and passenger assistance at assigned counters.
  - Drivers may access assigned trip, route, schedule, vehicle, operational instructions, and only the minimum passenger information necessary for safe operations; they must not receive ticket-sales, refund, pricing, or role-management authority by default.
  - Conductors/vehicle assistants may access assigned-trip manifests, create permitted walk-up bookings, sell/issue and validate tickets, record boarding and trip events, and perform assigned cash handover; they must not manage organization configuration, pricing policy, refunds, or roles by default.
- Offline workforce access must use a time-bounded cached authorization snapshot tied to the user, device, organization, role assignment, and trip/counter scope. Revocation and permission changes must take effect on synchronization and high-risk actions must not rely indefinitely on stale offline authority.
- The SaaS operator experience must be phone-first. A bus company branch or terminal counter without a computer must be able to perform its permitted daily operations from an Android or iOS phone.
- The business mobile application must support Bluetooth thermal printing so an authorized counter or conductor user with a supported phone and printer can issue passenger tickets and sales/payment slips.
- Printing must remain available for permitted offline transactions. Print jobs must be queued locally, retriable, attributable to the authenticated staff member and device, and synchronized into the audit history when connectivity returns.
- Each passenger-specific ticket must be independently printable and must include the human-readable ticket reference and QR code. A multi-passenger booking must support printing all tickets or selected passenger tickets.
- Reprints must not create a new sale or a second ticket. Every reprint must reference the original ticket, be marked as a copy/reprint where appropriate, record the reason and staff member, and create an audit event.
- Payment/sales slips must clearly distinguish recorded, pending verification, confirmed, refunded, voided, and unpaid states. A manual record must never be presented as externally verified electronic payment.
- Printing must use configurable organization templates and printer profiles, including common thermal paper widths, while preserving mandatory identifiers, QR readability, Myanmar text legibility, and audit references.
- The printing architecture must be document-type neutral. Ticket, payment slip, invoice summary, manifest, cash handover, cargo receipt, and cargo label documents must use a shared rendering, print-queue, retry, reprint, and audit foundation.
- Cargo Lite must support terminal-to-terminal parcel acceptance, trip assignment, loading, in-transit custody, destination-terminal arrival, receiver notification/lookup, verified handover, receipt/label printing, cash recording, and reconciliation.
- Authorized conductors/vehicle assistants may accept permitted cargo for their assigned trip at company-approved intermediate pickup points, similarly to permitted walk-up passenger sales. They must not accept arbitrary cargo outside the assigned route, trip, capacity, item policy, or delegated limits.
- Every cargo consignment must have a unique reference and QR code and must record at minimum sender and receiver contact details, origin/pickup point, destination terminal, item category, piece count, measured or declared weight, declared value where required, charge, payment status, accepting staff/device, assigned trip, custody status, and timestamps.
- Roadside/intermediate cargo acceptance must record the pickup location, evidence required by company policy, accepting crew member, device, cash/payment record, and a digital or printed sender receipt. Where a scale or other verification is unavailable, declared values must remain clearly distinguished from verified values.
- Cargo custody events must be append-only and auditable. At minimum they must distinguish accepted, assigned, loaded, in transit, arrived, ready for pickup, handed over, refused, cancelled, lost/damaged exception, and returned.
- Cargo handover must verify the receiver using company-approved evidence such as a reference/QR, phone/OTP, identification check, or delegated pickup authorization, while minimizing stored personal information.
- Company policy must define prohibited/restricted goods, maximum size/weight/value, packaging requirements, liability acknowledgement, pricing, discounts, refunds, claims, retention, and incident escalation. Cargo must not be accepted when required policy checks cannot be satisfied.
- Cargo cash and charges collected by counter or crew must participate in shift/trip cash handover, reconciliation, approval, and audit alongside ticket sales while remaining separately reportable.
- The MVP monetization focus is the bus-operator SaaS business. Passenger access remains free, while bus companies pay monthly or annual SaaS subscriptions. Transaction fees and per-ticket/per-cargo commissions are explicitly excluded.
- The MVP must ship exactly two customer-facing applications:
  - HBT Passenger for passenger registration, trip discovery, booking, purchase, and e-ticket management.
  - HBT Business for company owners, administrators, managers, terminal/counter staff, dispatchers, finance staff, drivers, conductors/vehicle assistants, and inspectors.
- A separate crew application is not part of the MVP. Driver, conductor, inspector, counter, manager, finance, and owner experiences must be permission-adaptive workspaces within HBT Business.
- After HBT Business login, the backend must return the user's active organizations, effective permissions, delegated scopes, current assignments, and time bounds. The application must build navigation, dashboards, screens, buttons, and offline capabilities from that effective access context.
- HBT Business must support users who belong to multiple organizations or hold multiple roles. The user must explicitly select or switch the active organization and, where applicable, the active operational context such as branch, terminal, counter, shift, or assigned trip.
- Hiding a screen or button in HBT Business is not authorization. Every backend request must independently enforce identity, active membership, tenant boundary, permission, scope, assignment, approval limit, account status, and applicable offline-authority rules.
- A trip must remain operationally active from preparation and departure through intermediate stops to final arrival and formal trip closing.
- The platform must maintain an offline-capable chronological trip event log. Authorized staff must be able to record scheduled and actual arrival/departure times, location or stop, event type, responsible staff member, passenger impact, and notes.
- Trip operations must distinguish:
  - passenger boarding/alighting stops;
  - rest/toilet breaks;
  - meal breaks;
  - fuel or vehicle-service stops;
  - authorized roadside/journey inspection checkpoints;
  - traffic, weather, breakdown, incident, or other unscheduled stops.
- Intermediate passenger boarding must be supported at company-approved stops or pickup points. The platform must record each passenger's origin and destination, verify seat availability for the relevant route segments, update the manifest, record payment status, and issue a passenger-specific ticket.
- Seat inventory must be segment-aware so that a seat used on one portion of a route may be sold for a later non-overlapping portion when company policy permits.
- Authorized conductor/counter staff must be able to record permitted intermediate walk-up passengers while offline, subject to duplicate-sale and synchronization-conflict controls.
- Scheduled rest and meal stops should be part of the trip plan. Actual arrival, departure, delay, skipped-stop, changed-location, and unscheduled-stop events must be recordable during operation.
- Final arrival must not by itself finalize financial and operational records. An authorized user must perform Trip Closing after reconciling passengers, tickets, payments, cash, refunds/adjustments, operational events, and unresolved exceptions.
- A closed trip must become read-only for ordinary users. Reopening or post-close adjustment must require explicit authority, reason, approval where required, and a complete audit trail.
- The MVP reporting scope must include pre-departure, live/in-progress, and post-trip reports, with phone-friendly views and printable/exportable versions where operationally required.
- The post-trip summary must consolidate at least planned versus actual timings, boarding and alighting by stop, passenger/ticket totals, segment occupancy, intermediate sales, payment and cash totals, discounts/refunds/voids, staff and vehicle assignments, rest/meal/inspection/incident events, unresolved exceptions, and closing approvals.

Do not reinterpret “offline-first” as “offline-only.” Define which passenger and staff journeys require connectivity, which can continue without connectivity, and how later synchronization should behave.

## Stakeholder decisions still requiring clarification

Do not silently decide the following. Provide recommendations and record them as open questions until approved:

- Whether terminal, branch, and third-party agent sales are all included initially
- The exact data a conductor may access and modify
- Organization membership invitation, verification, removal, and multi-organization rules
- Company booking approval levels, approvers, rejection behavior, invoice numbering, tax fields, payment terms, and cancellation behavior
- Exact delegation and approval limits for company owner, company administrator, operations manager, terminal manager, counter staff, finance staff, and conductor
- Whether a company may operate multiple counters at one physical terminal and whether counters require separate cash shifts/registers
- Staff onboarding, identity verification, device enrollment, shift handover, temporary replacement, suspension, and emergency access rules
- Company policy for permitted intermediate pickup/drop-off points, unscheduled roadside pickup, seat reuse by route segment, and required approvals
- Which operational events require passenger notification and which delay thresholds trigger escalation
- Whether GPS/location capture is manual, device-assisted, or deferred, and what location privacy rules apply
- Trip closing responsibility, required reconciliation tolerances, approval thresholds, and maximum time allowed after final arrival
- Required report formats, recipients, retention, exports, and scheduled delivery
- The MVP payment-recording and manual-confirmation workflow before payment-provider integration
- E-ticket security and lifecycle rules: QR contents, signature, expiry, revocation, reissue, duplicate copies, and screenshot/share handling
- Separate validation events and states for boarding, conductor inspection, and roadside/journey checkpoint inspection so that an inspection does not incorrectly consume or invalidate a valid ticket
- Printer types, paper sizes, layouts, and offline printing requirements at terminals
- Whether English is included as a secondary MVP language or deferred

## Required outcomes

Define:

1. Product problem and target market
2. Primary MVP users and operating context
3. MVP business outcomes and measurable success criteria
4. Modules included in MVP
5. Modules deferred from MVP
6. Must-have, should-have, could-have, and explicitly excluded capabilities
7. End-to-end MVP journeys
8. Online and offline boundaries
9. Single-tenant versus multi-tenant MVP expectations
10. Reporting, notification, payment, cargo, subscription, and AI boundaries
11. Required integrations and integrations deferred
12. Data migration and initial onboarding boundaries
13. MVP operational and support expectations
14. Release assumptions, constraints, dependencies, and risks
15. Exit criteria for beginning implementation
16. Exit criteria for MVP release

## Decision rules

- Distinguish confirmed decisions, recommended decisions, assumptions, and open questions.
- Do not invent legal, pricing, payment-provider, or country-specific requirements.
- Prefer the smallest coherent release that completes a real booking-to-trip journey.
- Every included capability must map to a module and workflow.
- Every deferred capability must include a reason and a future trigger.
- Identify conflicts found in existing documents.

## Required tables

- In-scope/out-of-scope matrix
- Module release matrix
- User journey coverage matrix
- Dependency matrix
- Assumption and open-question register
- MVP acceptance checklist

Do not include source code. Produce decisions specific enough to drive backlog creation.
