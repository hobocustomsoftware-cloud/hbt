# Feature Matrix — HBT MVP

**Last updated:** 2026-07-29

---

## Counter App (HBT Business)

| Feature | Status | Note |
|---------|--------|------|
| Login | ✅ | Phone + password, JWT, secure storage |
| Route Management | ✅ | Route list, create, edit screens. Quick action + app bar access. |
| Trip Management | ✅ | Trip list + detail + operational actions (ready→boarding→depart→en-route→arrive). Status filter. |
| Seat Layout | ✅ | Seat selection in counter booking flow. |
| Booking | 🔶 | Individual booking works. Corporate/approval/invoice P0. |
| Payment | 🔶 | Manual payment + evidence upload works. Online connector P1. |
| Refund | ✅ | Refund request, approve/reject, mark paid, complete. Full lifecycle (5 endpoints). |
| Passenger | ✅ | Create, search, select passengers. |
| Offline Mode | ✅ | Encrypted SQLite database (sqflite_sqlcipher), device registry, sync manager, upload queue. |
| Sync | ✅ | Sync pull with cursor + push upload queue. Full push/pull orchestration. |
| Bluetooth Print | ❌ | Not implemented. Backend API complete. |
| QR Validation | ✅ | Scanner screen + validate API endpoint. Supports ticket (`HBT:TICKET:*`) and cargo (`HBT:CARGO:V1:*`) QR codes. |

## Passenger App (HBT Passenger)

| Feature | Status | Note |
|---------|--------|------|
| Registration | ✅ | Phone + password + optional name fields. Auto-login after register. |
| Trip Search | ✅ | Terminal → route → stop → date wizard. Matches backend API. |
| Booking | ✅ | Seat selection with availability. Traveler auto-creation. |
| Wallet/Tickets | ✅ | Ticket list with status chips. Pull-to-refresh. |
| Profile | ✅ | Profile dialog with name, phone, email. Sign out. |
| Session | ✅ | Auto-restore on launch. Token refresh. |
| Notifications | ❌ | Not implemented. |

## Admin

| Feature | Status | Note |
|---------|--------|------|
| Reports | 🔶 | Backend CSV. Static Flutter placeholders. |
| Dashboard | 🔶 | Backend monitoring API. Static Flutter cards. |
| Company | 🔶 | Org switching works. Full management UI missing. |
| Branch | 🔶 | Backend complete. No Flutter UI. |
| Users | 🔶 | Backend complete. No Flutter UI. |
| Roles | 🔶 | Permission gating works. Role creation UI missing. |

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Complete and functional |
| 🔶 | Partial — works but has gaps |
| ❌ | Missing — not implemented |
