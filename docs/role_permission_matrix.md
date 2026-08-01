# HBT Transport Platform — Role & Permission Matrix

**Version:** 1.0 · **Date:** 2026-08-01
**Author:** CPO / Enterprise Solution Architect
**Purpose:** Definitive role hierarchy, permission matrix, and approval hierarchy.
All roles and permissions are **configurable by the Owner** — this document is the
**default seed**, not a hard-coded contract.

---

## 1. Role hierarchy

```
PLATFORM (Owner-created, tenant-scoped)
│
├── OWNER (org owner — full org scope)
│   ├── MANAGER (branch/terminal ops)
│   │   ├── COUNTER
│   │   ├── CONDUCTOR
│   │   ├── DRIVER
│   │   ├── GATE
│   │   └── CARGO_STAFF
│   ├── FINANCE
│   │   ├── CASHIER
│   │   └── ACCOUNTANT
│   ├── FLEET_MANAGER
│   ├── HR
│   └── MECHANIC
│
└── PLATFORM_ROLES (created by Owner): SUPPORT (read-only), AUDITOR (read-only + export)
```

- **Owner** (platform-level) creates Organizations, Users, Roles, Permissions.
- **Organization Owner** is appointed per org; can create sub-roles within their org.
- Everything below is seeded defaults; Owner may edit any role's permission set or create
  new roles.

---

## 2. Permission catalog (atomic capabilities)

### 2.1 Identity & tenancy
| Code | Description |
|------|-------------|
| org.manage | Create/edit org settings |
| user.manage | Create/edit users |
| role.manage | Create/edit roles & permission bundles |
| permission.view | View permission catalog |
| membership.manage | Assign users to orgs/roles |
| subscription.manage | Change plan, suspend |

### 2.2 Scheduling & network
| Code | Description |
|------|-------------|
| schedule.manage | CRUD schedules, generate trips |
| trip.manage | CRUD trips, lifecycle transitions |
| trip.assign | Assign vehicle/driver/conductor |
| route.manage | CRUD routes/stops/segments |
| fare.manage | CRUD fare rules/promotions |

### 2.3 Booking & ticketing
| Code | Description |
|------|-------------|
| booking.view | View bookings |
| booking.create | Create bookings |
| booking.cancel | Cancel bookings |
| ticket.sell | Sell tickets (counter/passenger) |
| ticket.issue | Issue tickets |
| ticket.validate | Validate at gate/scanner |
| ticket.reissue | Reissue/reprint tickets |
| ticket.void | Void tickets (with approval) |
| seatlock.acquire | Acquire/release seat locks |
| price.override | Apply discounted price (with approval + reason) |
| group.booking | Multi-passenger bookings |

### 2.4 Cargo
| Code | Description |
|------|-------------|
| cargo.accept | Accept shipments |
| cargo.price | Price shipments (rules/overrides) |
| cargo.assign | Assign to trip/vehicle |
| cargo.transition | Move status (load/transit/arrive) |
| cargo.handover | Hand over with ID/signature |
| cargo.manage | CRUD categories/pricing rules |
| claim.manage | Create/process claims |
| claim.approve | Approve claim payouts |

### 2.5 Finance & cash
| Code | Description |
|------|-------------|
| payment.record | Record payments |
| payment.verify | Verify payment evidence |
| payment.approve | Approve payments (above limits) |
| refund.request | Request refunds |
| refund.approve | Approve refunds |
| refund.pay | Mark refunds paid |
| settlement.submit | Submit trip/counter settlement |
| settlement.verify | Verify settlement |
| settlement.approve | Approve settlement |
| expense.create | Create expenses |
| expense.approve | Approve expenses |
| bank.reconcile | Bank deposit reconciliation |
| cash.handover | Till/float handover |
| payroll.run | Run payroll |
| gl.export | Export GL/journal |
| report.finance | Finance reports |

### 2.6 Fleet & maintenance
| Code | Description |
|------|-------------|
| vehicle.manage | CRUD vehicles |
| layout.manage | Seat layouts |
| maintenance.manage | Work orders |
| inspection.perform | Pre-trip inspections |
| fuel.log | Record fuel |
| parts.log | Record parts |
| assignment.manage | Vehicle/crew assignments |

### 2.7 HR
| Code | Description |
|------|-------------|
| staff.manage | CRUD staff |
| roster.manage | Rosters |
| attendance.manage | Attendance |
| doc.manage | Staff documents/expiry |
| payroll.input | Payroll input |

### 2.8 Operations & gate
| Code | Description |
|------|-------------|
| manifest.view | View manifests |
| boarding.mark | Mark boarded |
| dispatch.confirm | Confirm dispatch/headcount |
| incident.log | Operational incident register |
| monitoring.view | Dashboards/alerts |
| print.manage | Printers/templates |

### 2.9 Reporting & audit
| Code | Description |
|------|-------------|
| report.owner | Owner reports |
| report.ops | Operations reports |
| audit.view | Audit trail |
| data.export | Export data |

---

## 3. Default role → permission matrix

Legend: ● full · ◐ limited/own-scope · ○ none

| Permission | OWNER | MGR | COUNTER | CONDUCTOR | DRIVER | GATE | CARGO | FINANCE | FLEET | HR | MECHANIC |
|------------|:-----:|:---:|:-------:|:---------:|:-----:|:----:|:-----:|:-------:|:----:|:--:|:--------:|
| org.manage | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| user.manage | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| role.manage | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| subscription.manage | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| schedule.manage | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| trip.manage | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| trip.assign | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ |
| route.manage | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| fare.manage | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| booking.view | ● | ● | ● | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| booking.create | ● | ◐ | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| booking.cancel | ● | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| ticket.sell | ● | ◐ | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| ticket.issue | ● | ◐ | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| ticket.validate | ● | ● | ● | ● | ○ | ● | ○ | ○ | ○ | ○ | ○ |
| ticket.reissue | ● | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| ticket.void | ● | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| seatlock.acquire | ● | ● | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| price.override | ● | ● | ◐ | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| group.booking | ● | ● | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| cargo.accept | ● | ● | ● | ● | ○ | ○ | ● | ○ | ○ | ○ | ○ |
| cargo.price | ● | ● | ◐ | ◐ | ○ | ○ | ● | ○ | ○ | ○ | ○ |
| cargo.assign | ● | ● | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ | ○ |
| cargo.transition | ● | ● | ◐ | ◐ | ○ | ○ | ● | ○ | ○ | ○ | ○ |
| cargo.handover | ● | ● | ○ | ◐ | ○ | ○ | ● | ○ | ○ | ○ | ○ |
| cargo.manage | ● | ◐ | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ | ○ |
| claim.manage | ● | ◐ | ○ | ◐ | ○ | ○ | ● | ◐ | ○ | ○ | ○ |
| claim.approve | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| payment.record | ● | ◐ | ● | ● | ○ | ○ | ◐ | ● | ○ | ○ | ○ |
| payment.verify | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| payment.approve | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| refund.request | ● | ◐ | ● | ◐ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| refund.approve | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| refund.pay | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| settlement.submit | ● | ◐ | ● | ● | ○ | ○ | ◐ | ○ | ○ | ○ | ○ |
| settlement.verify | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| settlement.approve | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| expense.create | ● | ● | ● | ● | ● | ◐ | ◐ | ● | ● | ◐ | ● |
| expense.approve | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| bank.reconcile | ● | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| cash.handover | ● | ● | ● | ● | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| payroll.run | ● | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ◐ | ○ |
| gl.export | ● | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| report.finance | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| vehicle.manage | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ |
| layout.manage | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ |
| maintenance.manage | ● | ◐ | ○ | ○ | ○ | ◐ | ○ | ○ | ● | ○ | ● |
| inspection.perform | ● | ◐ | ○ | ○ | ● | ○ | ○ | ○ | ◐ | ○ | ● |
| fuel.log | ● | ◐ | ○ | ○ | ● | ○ | ○ | ○ | ● | ○ | ○ |
| parts.log | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ● |
| staff.manage | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ |
| roster.manage | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ |
| attendance.manage | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ |
| doc.manage | ● | ◐ | ○ | ○ | ◐ | ○ | ○ | ○ | ◐ | ● | ○ |
| manifest.view | ● | ● | ◐ | ● | ○ | ● | ◐ | ○ | ○ | ○ | ○ |
| boarding.mark | ● | ◐ | ○ | ○ | ○ | ● | ○ | ○ | ○ | ○ | ○ |
| dispatch.confirm | ● | ● | ○ | ○ | ◐ | ● | ○ | ○ | ○ | ○ | ○ |
| incident.log | ● | ● | ○ | ◐ | ● | ◐ | ◐ | ○ | ◐ | ◐ | ● |
| monitoring.view | ● | ● | ◐ | ○ | ○ | ◐ | ○ | ◐ | ◐ | ○ | ○ |
| report.owner | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| report.ops | ● | ● | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ |
| audit.view | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ◐ | ○ | ○ | ○ |
| data.export | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ◐ |

---

## 4. Approval hierarchy (money & risk actions)

| Action | Request | Verify | Approve | Over-limit → | SLA |
|--------|---------|--------|---------|--------------|-----|
| Refund ≤ threshold | Counter | Finance | Manager | Owner | 24h |
| Refund > threshold | Counter | Finance | Manager | Owner | 24h |
| Trip settlement | Conductor/Counter | Finance | Manager | Owner | 24h |
| Expense ≤ threshold | Any | Finance | Manager | Owner | 48h |
| Price override | Counter | — | Manager | Owner | 4h |
| Ticket void | Counter | — | Manager | — | 4h |
| Cargo claim ≤ threshold | Cargo | Finance | Manager | Owner | 72h |
| Corporate credit line | Sales | Finance | Owner | — | 48h |
| Payment account change | Finance | Manager | Owner | — | 48h |
| Payroll run | HR | Finance | Owner | — | 7d |
| Subscription change | — | — | Owner | — | — |

**Rules:**
1. **Separation of duties:** requester ≠ verifier ≠ approver (enforced).
2. **Escalation:** any item past SLA auto-escalates one level + notifies.
3. **No self-approval** ever.
4. Thresholds and chains are Owner-configurable per org.

---

## 5. Scope model

- **Global scope:** platform roles (support, auditor).
- **Org scope:** owner, manager, finance, fleet, hr.
- **Branch scope:** manager/counter/gate assigned to branch.
- **Counter scope:** counter login binds to a counter device/till.
- **Trip scope:** conductor/driver bind to assigned trip.

---

## 6. Role → screen → report → notification summary

See docs/business_operation_blueprint.md §4 (per-role: responsibilities, daily/weekly/
monthly workflow, permissions, screens, reports, notifications, offline behaviour, cash
flow, approval chain, fraud prevention, KPIs).

---

*All rows are defaults seeded by the Owner; every permission is configurable.*
