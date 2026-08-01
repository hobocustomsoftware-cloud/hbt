# Business App — User Journeys

---

## 1. Journey Inventory

| # | Journey | Role | Screens visited | API calls | Online? |
|---|---------|------|-----------------|-----------|---------|
| J1 | Sign in + org select | All | 2 | 3 | Required |
| J2 | Counter booking + payment + ticket | Counter | 4 | 6 | Required |
| J3 | Trip list → status transition | Dispatcher | 2 | 3 | Required |
| J4 | Route CRUD | Admin/Manager | 2 | 2-3 | Required |
| J5 | Cargo acceptance → transition → handover | Cargo staff | 2 | 5+ | Required |
| J6 | Refund request → approve → pay | Finance | 3 | 5 | Required |
| J7 | Ticket scanning | Conductor | 1 | 1 | Required |
| J8 | View dashboard | All | 1 | 0 | N/A |

---

## 2. Journey J1: Sign In + Org Select (Happy Path)

**Role:** All users
**Online:** Required (cannot work offline)

```mermaid
sequenceDiagram
    actor User
    participant App as HbtBusinessApp
    participant Auth as AuthController
    participant Org as OrgController
    participant API

    App->>App: Launch
    Auth->>API: GET /auth/me/ (restore token)
    alt Token valid
        API-->>Auth: {user data}
        Auth-->>App: authenticated=true
        Org->>API: GET /me/organizations/
        API-->>Org: [{ orgs }]
        Org->>API: GET /me/organizations/{id}/context/
        API-->>Org: {permissions, ...}
        Org-->>App: activeOrganization set
        App-->>User: BusinessHome with org context
    else No token
        App-->>User: SignInScreen
        User->>App: Enter phone + password
        App->>Auth: signIn(phone, password)
        Auth->>API: POST /auth/login/
        API-->>Auth: {access, refresh}
        Auth->>API: GET /auth/me/
        API-->>Auth: {user}
        Auth-->>App: authenticated=true
        Org->>API: POST /me/devices/ (register)
        Org->>API: GET /me/organizations/{id}/context/
        App-->>User: BusinessHome
    end
```

**Permission check points:**
- No permission gates at sign-in. Org context loads all permissions for the user.

**Error paths:**
- `E1`: Token expired: refresh attempt → fail → clear → show SignInScreen
- `E2`: Login wrong password: `ScaffoldMessenger.showSnackBar` with error
- `E3`: No organizations: Text("No organization available.") — dead end
- `E4`: Context load error: Error icon + retry button → `loadOrganizationContext()`

---

## 3. Journey J2: Counter Booking → Payment → Ticket Issue (Happy Path)

**Role:** Counter staff
**Online:** Required (all API calls are synchronous HTTP)

```mermaid
sequenceDiagram
    actor Counter
    participant DASH as DashboardPage
    participant CB as CounterBookingPage
    participant PD as PaymentDecisionPage
    participant API

    Counter->>DASH: Tap "New Booking"
    DASH->>CB: Navigator.push(CounterBookingPage)
    
    Note over CB: Initial load
    CB->>API: GET /orgs/{id}/passengers/
    CB->>API: GET /orgs/{id}/trips/
    API-->>CB: [passengers], [trips]
    
    Counter->>CB: Select passenger (or create new)
    Counter->>CB: Select trip
    Counter->>CB: Select pickup stop
    Counter->>CB: Select dropoff stop
    
    CB->>API: GET /orgs/{id}/trips/{id}/seats/?pickup=X&dropoff=Y
    API-->>CB: [{seat data}]
    
    Counter->>CB: Select seat
    Counter->>CB: Enter contact info
    
    Counter->>CB: Tap "Booking နှင့် Fare Quote ပြုလုပ်မည်"
    
    CB->>API: POST /orgs/{id}/bookings/
    API-->>CB: {booking}
    CB->>API: POST /orgs/{id}/bookings/{id}/fare-quotes/create/
    API-->>CB: {quote}
    CB->>API: POST /orgs/{id}/fare-quotes/{id}/lock/
    API-->>CB: {locked_quote}
    
    Counter->>CB: Tap fare quote card
    CB->>PD: Navigator.push(PaymentDecisionPage)

    Note over PD: Payment flow
    PD->>API: GET /orgs/{id}/payment-accounts/
    API-->>PD: [{accounts}]
    
    Counter->>PD: Select payment method
    Counter->>PD: Pick evidence file (cash/transfer)
    Counter->>PD: Enter payment reference
    
    PD->>API: POST /orgs/{id}/payment-uploads/ (multipart)
    API-->>PD: {upload}
    PD->>API: POST /orgs/{id}/payments/
    API-->>PD: {payment}
    
    Note over PD: Decision flow
    Counter->>PD: Enter approval note
    Counter->>PD: Tap "Confirm + Issue"
    
    PD->>API: POST /orgs/{id}/payments/{id}/decision/ {approve:true, tickets}
    API-->>PD: {confirmed}
    PD->>API: GET /orgs/{id}/tickets/
    API-->>PD: [{tickets}]
    
    Note over PD: Done. Tickets shown on screen.
```

**API call count:** 9 (minimum, excluding file upload bytes)

**Permission check points:**
- Entry to CounterBookingPage: requires 5 permissions (`passenger.view`, `passenger.manage`, `trip.view`, `booking.manage`, `fare.quote`)
- Create passenger dialog: `passenger.manage`
- Payment: `payment.record`
- Decision: `payment.confirm` + `ticket.issue`

**Error paths:**
- `E1`: Any API failure → `ErrorCard` at top of current screen → retry by user
- `E2`: Passenger not found → create passenger dialog → POST → error card
- `E3`: Seat double-booked by another counter → API returns error → ErrorCard
- `E4`: Fare quote lock fails → ErrorCard → booking abandoned mid-flow

**Offline path:** **None.** Every API call is synchronous HTTP. No offline queue. No local storage.

---

## 4. Journey J3: Trip → Status Transition (Happy Path)

**Role:** Dispatcher
**Online:** Required

```mermaid
sequenceDiagram
    actor Disp as Dispatcher
    participant TL as TripListPage
    participant TD as TripDetailPage
    participant API

    Disp->>TL: View trip list
    TL->>API: GET /orgs/{id}/trips/
    API-->>TL: {results: [{trips}]}
    
    Disp->>TL: Filter by status (optional)
    Disp->>TL: Tap trip
    
    TL->>TD: Navigator.push(TripDetailPage)
    TD->>API: GET /orgs/{id}/trips/{id}/
    API-->>TD: {trip details}

    alt Status = planned
        Disp->>TD: Tap "Mark Ready"
        TD->>API: POST /orgs/{id}/trips/{id}/ready/
        API-->>TD: {updated trip}
    else Status = ready
        Disp->>TD: Tap "Start Boarding"
        TD->>API: POST /orgs/{id}/trips/{id}/boarding/start/
        API-->>TD: {updated trip}
    else Status = boarding
        Disp->>TD: Tap "Depart"
        TD->>API: POST /orgs/{id}/trips/{id}/depart/
        API-->>TD: {updated trip}
    else Status = departed
        Disp->>TD: Tap "En Route"
        TD->>API: POST /orgs/{id}/trips/{id}/en-route/
        API-->>TD: {updated trip}
    else Status = in_progress
        Disp->>TD: Tap "Arrive"
        TD->>API: POST /orgs/{id}/trips/{id}/arrive/
        API-->>TD: {updated trip}
    end
```

**API call count:** 2 + N (N = number of transitions)

**Permission check points:** No permission gates on any status transition action.

**Error paths:**
- `E1`: Trip not found (refreshed state) → ErrorCard
- `E2`: Invalid transition (server rejects) → ErrorCard → snackbar

**Offline path:** **None.** No offline trip transition queue.

---

## 5. Journey J4: Route CRUD

**Role:** Admin / Manager
**Online:** Required

```mermaid
sequenceDiagram
    actor Admin
    participant RL as RouteListPage
    participant RD as RouteDetailPage
    participant API

    Admin->>RL: View route list
    RL->>API: GET /orgs/{id}/routes/
    API-->>RL: {results: [{routes}]}

    alt Create
        Admin->>RL: Tap + (AppBar)
        RL->>RD: Navigator.push(RouteDetailPage, create mode)
        Admin->>RD: Fill form (code, name, region, distance, duration, status)
        Admin->>RD: Tap Save
        RD->>API: POST /orgs/{id}/routes/
        API-->>RD: {created route}
        RD-->>RL: pop with result
    else Edit
        Admin->>RL: Tap route
        RL->>RD: Navigator.push(RouteDetailPage, edit mode)
        Admin->>RD: Modify fields
        Admin->>RD: Tap Save
        RD->>API: PATCH /orgs/{id}/routes/{id}/
        API-->>RD: {updated route}
        RD-->>RL: pop with result
    end
```

**API call count:** 2 (list + create/edit)

**Permission gaps:**
- No `route.view` gate on RouteListPage
- No `route.manage` gate on RouteDetailPage create/edit

---

## 6. Journey J5: Cargo Acceptance → Transition → Handover

**Role:** Cargo staff
**Online:** Required

```mermaid
sequenceDiagram
    actor Cargo
    participant CWP as CargoWorklistPage
    participant CAP as CargoAcceptancePage
    participant API

    Cargo->>CWP: View cargo worklist
    CWP->>API: GET /orgs/{id}/cargo/shipments/
    API-->>CWP: [{shipments}]

    alt Accept new cargo
        Cargo->>CWP: Tap "Cargo လက်ခံရန်"
        CWP->>CAP: Navigator.push(CargoAcceptancePage)
        Cargo->>CAP: Fill form (number, sender, receiver, terminals, category, pieces, charge)
        
        alt Create new contact
            Cargo->>CAP: Tap person_add icon
            CAP->>CAP: showDialog (code, name, phone)
            CAP->>API: POST /orgs/{id}/cargo/contacts/
            API-->>CAP: {created contact}
        end
        
        Cargo->>CAP: Tap "Cargo လက်ခံမည်"
        CAP->>API: POST /orgs/{id}/cargo/shipments/
        API-->>CAP: {created shipment}
        CAP-->>CWP: pop(true)
    end
    
    alt Trip assignment (status=accepted)
        Cargo->>CWP: Tap "Trip သတ်မှတ်"
        CWP->>API: GET /orgs/{id}/trips/
        API-->>CWP: [{trips}]
        CWP->>CWP: AppDialog.showPicker
        Cargo->>CWP: Select trip
        CWP->>API: POST /orgs/{id}/cargo/shipments/{id}/assign-trip/
    end
    
    alt Status transition (assigned→loaded→in_transit→arrived→ready_pickup)
        Cargo->>CWP: Tap status button
        CWP->>API: POST /orgs/{id}/cargo/shipments/{id}/transition/
    end
    
    alt Handover (ready_pickup)
        Cargo->>CWP: Tap "အပ်နှံ"
        CWP->>CWP: showDialog (recipient, reference)
        Cargo->>CWP: Enter recipient info
        CWP->>API: POST /orgs/{id}/cargo/shipments/{id}/transition/
    end
```

**API call count:** 2-6 per flow segment

**Permission check points:**
- `cargo.view` gates entire CargoWorklistPage
- `cargo.accept` gates the "Cargo လက်ခံရန်" button
- `cargo.manage` gates all action buttons (trip assignment, transition, handover)

---

## 7. Journey J6: Refund Request → Approve → Pay → Complete

**Role:** Finance staff
**Online:** Required

```mermaid
sequenceDiagram
    actor Finance
    participant RL as RefundListPage
    participant RC as RefundCreatePage
    participant RD as RefundDetailPage
    participant API
    participant SVC as RefundService

    Finance->>RL: View refund list
    RL->>SVC: list()
    SVC->>API: GET /orgs/{id}/refunds/
    API-->>SVC: [{refunds}]
    SVC-->>RL: data

    alt Create request
        Finance->>RL: Tap + (AppBar)
        RL->>RC: Navigator.push(RefundCreatePage)
        RC->>API: GET /orgs/{id}/payments/
        API-->>RC: [{payments}]
        Finance->>RC: Select payment
        RC->>API: GET /orgs/{id}/tickets/
        API-->>RC: [{tickets}]
        Finance->>RC: Select ticket (optional)
        Finance->>RC: Enter amount + reason
        RC->>SVC: request(paymentId, amount, reason)
        SVC->>API: POST /orgs/{id}/refunds/
        API-->>SVC: {refund}
        SVC-->>RC: success
        RC-->>RL: pop
    end
    
    alt Approve/Reject
        Finance->>RL: Tap refund
        RL->>RD: Navigator.push(RefundDetailPage)
        
        RD->>SVC: get(refundId)
        SVC->>API: GET /orgs/{id}/refunds/{id}/
        API-->>SVC: {detail}
        SVC-->>RD: data
        
        Note over RD,Finance: Status = 'requested'
        Finance->>RD: Tap "Approve"
        RD->>RD: showDialog (amount, note)
        Finance->>RD: Enter approved amount
        RD->>SVC: decide(refundId, approve=true, amount)
        SVC->>API: POST /orgs/{id}/refunds/{id}/decision/
    end
    
    alt Mark Paid
        Note over RD,Finance: Status = 'approved'
        Finance->>RD: Tap "Mark Paid"
        RD->>RD: showDialog (payout reference)
        RD->>SVC: markPaid(refundId, payoutRef)
        SVC->>API: POST /orgs/{id}/refunds/{id}/paid/
    end
    
    alt Complete
        Note over RD,Finance: Status = 'paid'
        Finance->>RD: Tap "Complete Refund"
        RD->>RD: Confirm dialog
        RD->>SVC: complete(refundId)
        SVC->>API: POST /orgs/{id}/refunds/{id}/complete/
    end
```

**API call count:** 2-5 per flow segment

**Permission check points:**
- `refund.view`: list page entry + AppBar icon
- `refund.request`: create button
- `refund.approve`: approve/reject buttons
- `refund.pay`: mark paid button
- `refund.complete`: complete button

---

## 8. Journey J7: Ticket Scanning

**Role:** Conductor
**Online:** Required

```mermaid
sequenceDiagram
    actor Cond as Conductor
    participant SC as TicketScannerScreen
    participant API

    Cond->>SC: Open scanner (AppBar or Dashboard)
    SC->>SC: Start camera, show viewfinder
    
    Cond->>SC: Scan QR code
    SC->>SC: Pause camera
    
    alt Ticket QR
        SC->>API: GET /orgs/{id}/tickets/validate/?code=***
        API-->>SC: {ticket data}
        SC-->>Cond: Show ticket result + status
    else Cargo QR
        SC->>API: POST /orgs/{id}/cargo/qr/resolve/
        API-->>SC: {cargo data}
        SC-->>Cond: Show cargo result
    end
    
    Cond->>SC: Tap "Scan Again"
    SC->>SC: Resume camera
```

**Note:** The ticket validation endpoint uses a hardcoded `?code=***` placeholder — this is a bug (see validation).

---

## 9. Offline Paths

**Current state:** No offline paths exist. The app is fully online-only.

### 9.1 What would change

```mermaid
flowchart TB
    subgraph Current [Current — All Online]
        SCREEN --> API1[HTTP Request]
        API1 -->|success| SCREEN_OK[Show data]
        API1 -->|failure| SCREEN_ERR[Show error]
    end

    subgraph Future [Future — Offline First]
        SCREEN2 --> LOCAL[Read from AppDatabase]
        LOCAL --> SCREEN_OK2[Show cached data immediately]
        SCREEN2 --> BACKGROUND[Fire background HTTP request]
        BACKGROUND -->|success| UPDATE[Update AppDatabase]
        BACKGROUND -->|failure| KEEP[Keep cached data + banner]
        UPDATE --> REBUILD[Rebuild UI with fresh data]
        
        WRITE[Create/edit] --> LOCAL_WRITE[Write to AppDatabase]
        LOCAL_WRITE --> ENQUEUE[Enqueue sync operation]
        ENQUEUE --> QUEUED[Show syncing indicator]
    end
```

### 9.2 Screens with offline entry points

| Screen | Read offline? | Write offline? | Sync status? |
|--------|--------------|----------------|--------------|
| SignInScreen | ❌ | ❌ | ❌ |
| DashboardPage | ❌ | N/A | ❌ |
| TicketSalesPage | ❌ | N/A | ❌ |
| CounterBookingPage | ❌ | ❌ | ❌ |
| PaymentDecisionPage | ❌ | ❌ | ❌ |
| TicketScannerScreen | ❌ | ❌ | ❌ |
| TripListPage | ❌ | N/A | ❌ |
| TripDetailPage | ❌ | ❌ | ❌ |
| RouteListPage | ❌ | N/A | ❌ |
| RouteDetailPage | ❌ | ❌ | ❌ |
| CargoWorklistPage | ❌ | N/A | ❌ |
| CargoAcceptancePage | ❌ | ❌ | ❌ |
| RefundListPage | ❌ | N/A | ❌ |
| RefundCreatePage | ❌ | ❌ | ❌ |
| RefundDetailPage | ❌ | ❌ | ❌ |
| SyncPlaceholder | N/A | N/A | N/A (placeholder) |

---

## 10. Role-Based Access Matrix

| Screen / Feature | Admin | Manager | Counter | Dispatcher | Cargo | Conductor | Finance |
|-----------------|-------|---------|---------|------------|-------|-----------|---------|
| **Dashboard** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Trips** (list) | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| **Trips** (status transition) | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Routes** (view) | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Routes** (create/edit) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Booking** (view) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Booking** (create) | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Payment** (record) | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Payment** (confirm) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Tickets** (issue) | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Tickets** (scan) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **Cargo** (view) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Cargo** (accept) | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Cargo** (manage transitions) | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Refund** (view) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Refund** (request) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Refund** (approve) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Refund** (pay) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Refund** (complete) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **QR Scanner** | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ |
| **Sync dashboard** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**Permission field mapping** (from backend access control matrix):

```
booking: [view, manage]
passenger: [view, manage]
trip: [view]
fare: [quote]
payment: [record, confirm]
ticket: [view, issue]
cargo: [view, accept, manage]
refund: [view, request, approve, pay, complete]
route: [view, manage]
```

---

## 11. Recommended Navigation Improvements

| Priority | Change | Rationale |
|----------|--------|-----------|
| **High** | Add permission gates to TripListPage (`trip.view`) and RouteListPage (`route.view`) | Currently all users see these screens even without permission |
| **High** | Add permission gate to RouteDetailPage create/edit (`route.manage`) | Admin data can be modified by any user |
| **High** | Add splash screen with branding | Currently shows blank `CircularProgressIndicator` |
| **Medium** | Move "Trips" and "Routes" from AppBar to Dashboard only | Reduces AppBar clutter; dashboard is the hub |
| **Medium** | Merge dashboard quick actions into a grid (not ListView) | Better use of space on larger screens |
| **Medium** | Add "Back to Home" to PaymentDecisionPage after ticket issue | Current dead end requires hardware back |
| **Medium** | Add booking detail screen | CounterBookingPage only shows summary card after booking |
| **Medium** | Add cargo detail screen | No detail view for cargo shipments |
| **Low** | Add ticket detail screen | Tickets shown as list items only |
| **Low** | Rename `features/business/` → `features/shell/` | It's not a feature, it's the app shell |
| **Low** | Consolidate AppBar + Dashboard duplicate navigation paths | Trips, Routes, Scanner, Refunds accessible from both |
