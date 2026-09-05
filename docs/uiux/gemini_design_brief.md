# HoBo Transport — Gemini UI/UX Design Brief

## Product

Design the production UI/UX for **HoBo Transport**, a Myanmar intercity bus transport platform with two surfaces:

1. **Passenger app** — search routes, choose seats, create bookings, submit manual payment evidence, receive tickets, view trip/boarding information and manage personal/corporate booking flows.
2. **Business operations app** — owner/company administration, branches, terminals/counters, trip scheduling, fleet/seat layouts, booking/ticket operations, conductor/agent workflows, cargo, payments, cashier settlement, boarding, reports and offline-first operation.

## UX principles

- Offline-first for operational users: every critical action must communicate local save, queued sync, synced, conflict and failed states.
- Role-aware navigation: users see only modules/actions they can use.
- Fast counter workflows: seat selection, passenger lookup, booking, payment verification and ticket printing should minimize taps.
- High information density for dispatch/operations without visual clutter.
- Strong destructive-action confirmation and clear status semantics.
- Mobile-first passenger experience; tablet/desktop-friendly operations console.
- Accessible typography, touch targets and contrast.
- Burmese + English localization readiness.

## Required operational screens

- Login / session recovery
- Owner dashboard
- Operations dashboard
- Branch / terminal / counter management
- Fleet and vehicle detail
- Seat-layout editor and seat map
- Route/stops management
- Trip list, trip detail and trip lifecycle
- Booking list/detail and booking action flow
- Counter seat availability with segment-aware seat map
- Ticket/payment verification
- Boarding scanner and duplicate/rejected scan states
- Cargo acceptance, assignment, loading, transit, unloading and handover
- Cash settlement and reconciliation
- Corporate customer/member/approval/invoice flows
- Reports and CSV export controls
- Offline sync queue/conflict center
- Notifications and alerts
- Audit/security event viewer for privileged users
- Profile, roles, permissions and session security

## Required passenger screens

- Onboarding
- Route search
- Trip results
- Trip detail
- Segment-aware seat map
- Passenger details
- Booking confirmation
- Manual payment evidence submission
- Ticket / QR
- My trips / booking detail
- Corporate booking and approval status
- Notifications
- Profile / privacy / active sessions

## Signature visual direction

Use a **Southeast Asian transit-control aesthetic**: practical transport signage, route-line geometry, ticket-stub/card motifs and restrained map-inspired visual cues. Avoid generic fintech dashboards. The product should feel dependable, operational and fast.

Use a restrained brand palette derived from the HoBo Transport identity; if no official palette is supplied, propose 2–3 alternatives and show light/dark variants.

## Deliverables

- Information architecture
- Role-based navigation map
- Design system: typography, spacing, colors, status tokens, buttons, forms, tables, cards, dialogs, banners and empty/error/loading states
- High-fidelity screens for the required flows
- Responsive desktop/tablet/mobile variants where applicable
- Offline/sync/conflict UX patterns
- Accessibility notes
- Burmese/English localization considerations
- Developer handoff annotations and reusable component inventory

## Important

Do not invent backend capabilities that are not represented by the product flows above. Where an interaction requires an API decision not yet finalized, mark it as an explicit UX dependency rather than silently inventing behavior.
