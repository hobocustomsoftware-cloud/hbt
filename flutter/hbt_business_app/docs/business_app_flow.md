# Business App — Screen Inventory

**App:** hbt_business_app
**Source files:** 44 Dart files (14 screens, 3 controllers, 3 services, 2 models, 14 widgets, 4 infra, 4 config/routing/app)
**Date:** 2026-07-30

---

## 1. Complete Screen Inventory

| # | Screen | File | Feature | Type | Permissions |
|---|--------|------|---------|------|-------------|
| S1 | Loading | inline in `app.dart` | Auth | Splash | None |
| S2 | SignIn | `auth/screens/sign_in_screen.dart` | Auth | Form | None |
| S3 | BusinessHome | `business/screens/business_home.dart` | Shell | Shell + Nav | None (shell) |
| S4 | DashboardPage | inline in `business_home.dart` | Shell | Dashboard | None (shell) |
| S5 | TicketSalesPage | `ticket_sales/screens/ticket_sales_page.dart` | Ticket Sales | List | `booking.view` \| `ticket.view` |
| S6 | CounterBookingPage | `ticket_sales/screens/counter_booking_page.dart` | Ticket Sales | Form (multi-step) | `booking.manage`, `passenger.*`, `trip.view`, `fare.quote` |
| S7 | PaymentDecisionPage | `ticket_sales/screens/payment_decision_page.dart` | Ticket Sales | Form | `payment.record`, `payment.confirm`, `ticket.issue` |
| S8 | TicketScannerScreen | `ticket_sales/screens/ticket_scanner_screen.dart` | Ticket Sales | Scanner | None (hardware) |
| S9 | TripListPage | `trip/screens/trip_list_page.dart` | Trip | List | `trip.view` |
| S10 | TripDetailPage | `trip/screens/trip_detail_page.dart` | Trip | Detail + Actions | `trip.view` |
| S11 | RouteListPage | `routes/screens/route_list_page.dart` | Routes | List + CRUD | `route.view` |
| S12 | RouteDetailPage | `routes/screens/route_detail_page.dart` | Routes | Form (create/edit) | `route.manage` |
| S13 | CargoWorklistPage | `cargo/screens/cargo_worklist_page.dart` | Cargo | List + Actions | `cargo.view` |
| S14 | CargoAcceptancePage | `cargo/screens/cargo_acceptance_page.dart` | Cargo | Form | `cargo.accept` |
| S15 | RefundListPage | `refund/screens/refund_list_page.dart` | Refund | List + Filter | `refund.view` |
| S16 | RefundCreatePage | `refund/screens/refund_create_page.dart` | Refund | Form | `refund.request` |
| S17 | RefundDetailPage | `refund/screens/refund_detail_page.dart` | Refund | Detail + Actions | `refund.view` |
| — | SyncPage | Placeholder in business_home.dart | Sync | — | Not implemented |

### 1.1 Screen classification

| Type | Count | Screens |
|------|-------|---------|
| List (read-only) | 5 | TicketSales, TripList, RouteList, CargoWorklist, RefundList |
| Form (create/edit) | 5 | SignIn, CounterBooking, PaymentDecision, RouteDetail, CargoAcceptance, RefundCreate |
| Detail + actions | 3 | TripDetail, RefundDetail, PaymentDecision (after submit) |
| Scanner | 1 | TicketScanner |
| Shell/Dashboard | 2 | BusinessHome, DashboardPage (inline) |
| Splash | 1 | Loading (inline in app.dart) |
| **Total unique** | **17** | |

---

## 2. Widget Trees (Page-level)

### 2.1 SignIn screen tree

```
SignInScreen (StatefulWidget)
 ├── Scaffold
 │    ├── SafeArea
 │    ├── SingleChildScrollView
 │    │    └── ConstrainedBox (maxWidth: 420)
 │    │         └── Form
 │    │              ├── Icon (directions_bus_rounded, hardcoded Color(0xff00695c))
 │    │              ├── Text("HBT Business") — headlineMedium
 │    │              ├── Text("ကားဂိတ်လုပ်ငန်း စီမံခန့်ခွဲမှု")
 │    │              ├── TextFormField (phone) — 'ဖုန်းနံပါတ်'
 │    │              ├── TextFormField (password) — 'စကားဝှက်'
 │    │              ├── BusyButton ('ဝင်မည်')
 │    │              └── Text('Server: ${apiBaseUrl}') — bodySmall
```

### 2.2 BusinessHome shell tree

```
BusinessHome (StatefulWidget) → SessionController
 ├── Scaffold
 │    ├── AppBar
 │    │    ├── Title ← current tab name
 │    │    ├── PopupMenuButton (org switcher)
 │    │    ├── IconButton → TripListPage
 │    │    ├── IconButton → RouteListPage
 │    │    ├── IconButton → TicketScannerScreen
 │    │    ├── IconButton → RefundListPage (conditional: refund.view)
 │    │    └── IconButton (sign out)
 │    ├── Body: _BusinessContextBody
 │    │    ├── [loading] → CircularProgressIndicator
 │    │    ├── [error] → Icon + Text + Retry
 │    │    ├── [no org] → Text("No organization available.")
 │    │    └── [ready] → Tab content:
 │    │         ├── Tab 0: _DashboardPage
 │    │         ├── Tab 1: TicketSalesPage
 │    │         ├── Tab 2: CargoWorklistPage
 │    │         └── Tab 3: _PlaceholderPage (Sync)
 │    └── BottomNavigationBar
 │         ├── Home (tab 0)
 │         ├── Ticket (tab 1)
 │         ├── Cargo (tab 2)
 │         └── Sync (tab 3)
```

### 2.3 DashboardPage tree

```
_DashboardPage (StatelessWidget) — housed in Tab 0
 └── ListView
      ├── Card (Online/Offline status — static text)
      ├── Text("Quick Actions")
      ├── _QuickAction → TripListPage
      ├── _QuickAction → RouteListPage
      ├── _QuickAction → TicketScannerScreen
      ├── _QuickAction → CounterBookingPage
      ├── _QuickAction → RefundListPage (conditional)
      └── _QuickAction → Pending Payments (switchTab to Tab 1)
```

### 2.4 Ticket sales flow tree

```
TicketSalesPage (Tab 1)
 ├── [loading] → LoadingView
 ├── [error] → ErrorView + retry
 ├── [no permission] → Text("လက်မှတ်နှင့် booking records ကြည့်ခွင့်မရှိပါ။")
 └── [data] → RefreshIndicator > ListView
      ├── AppListTileCard (counter ticket sale) → CounterBookingPage
      │                                        (conditional: 5 permissions)
      ├── Text("လတ်တလော Booking များ")
      ├── [bookings list] → AppListTileCard per booking
      ├── Text("ထုတ်ပေးထားသော လက်မှတ်များ")
      └── [tickets list] → AppListTileCard per ticket

CounterBookingPage (push from TicketSalesPage or Dashboard)
 ├── [loading] → LoadingView
 ├── ErrorCard
 ├── Section: Passenger dropdown + add button
 ├── Section: Trip dropdown
 ├── Section: Pickup stop dropdown (conditional on trip)
 ├── Section: Dropoff stop dropdown (conditional on trip)
 ├── Section: Seat ChoiceChip grid (conditional on stops)
 ├── Contact name text field
 ├── Contact phone text field
 ├── BusyButton → create booking + fare quote + lock
 └── If quote created: AppListTileCard → PaymentDecisionPage

PaymentDecisionPage (push from CounterBookingPage)
 ├── AppListTileCard (fare quote summary)
 ├── ErrorCard
 ├── [pre-payment] →
 │    ├── Payment method dropdown
 │    ├── Account version dropdown
 │    ├── File picker button (evidence upload)
 │    ├── Payment reference text field
 │    └── BusyButton → upload evidence + record payment
 ├── [post-payment, pre-decision] →
 │    ├── AppListTileCard (payment summary)
 │    ├── Approval note text field
 │    └── ActionButtonRow (Reject / Confirm + Issue)
 └── [post-decision] →
      ├── Text("Issued Tickets")
      └── AppListTileCard per issued ticket
```

### 2.5 Trip flow tree

```
TripListPage (push from AppBar or Dashboard)
 ├── [loading] → LoadingView
 ├── [error] → ErrorView + retry
 ├── [empty] → RefreshIndicator > ListView
 │    └── Icon + Text("No trips found.")
 └── [data] → RefreshIndicator > ListView.separated
      ├── Filter chip (conditional)
      └── Card > ListTile per trip → TripDetailPage

TripDetailPage (push from TripListPage)
 ├── RefreshIndicator > ListView
 │    ├── InfoCard (trip header: number, status chip)
 │    ├── _buildTripInfo()
 │    │    └── InfoCard (trip info: route, date, departure, arrival, vehicle, driver, conductor)
 │    ├── _buildStatusActions()
 │    │    └── Column: TextField (notes) + ActionChips per status transition
 │    ├── FilledButton → CounterBookingPage (preselected trip)
 │    └── ErrorCard (conditional)
```

### 2.6 Route flow tree

```
RouteListPage (push from AppBar or Dashboard)
 ├── [loading] → LoadingView
 ├── [error] → ErrorView + retry
 ├── [empty] → EmptyView + "Create Route" button
 └── [data] → RefreshIndicator > ListView.separated
      └── ListTile per route → RouteDetailPage (edit mode)

RouteDetailPage (push from RouteListPage — create or edit)
 └── Form
      ├── TextFormField (code)
      ├── TextFormField (name)
      ├── TextFormField (operating region)
      ├── Row: Distance + Duration
      └── DropdownButtonFormField (status: draft/approved/active)
```

### 2.7 Cargo flow tree

```
CargoWorklistPage (Tab 2)
 ├── [no permission: cargo.view] → Text("Cargo records ကြည့်ခွင့်မရှိပါ။")
 ├── [loading] → LoadingView
 ├── RefreshIndicator > ListView
 │    ├── FilledButton → CargoAcceptancePage (conditional: cargo.accept)
 │    ├── ErrorCard
 │    ├── EmptyListTileCard or shipment cards
 │    └── Per shipment: Card > ListTile
 │         ├── Title: shipment_number
 │         ├── Subtitle: status + payment_status
 │         └── Trailing action button:
 │              ├── "Trip သတ်မှတ်" (accepted)
 │              ├── "အပ်နှံ" (ready_pickup)
 │              └── Status-named button (other active statuses)

CargoAcceptancePage (push from CargoWorklistPage)
 ├── [loading] → LoadingView
 └── ListView
      ├── ErrorCard
      ├── TextField (shipment number)
      ├── ContactPickerRow (sender) → create contact dialog
      ├── ContactPickerRow (receiver) → create contact dialog
      ├── DropdownButtonFormField (origin terminal)
      ├── DropdownButtonFormField (destination terminal)
      ├── TextField (item category)
      ├── TextField (description)
      ├── TextField (piece count)
      ├── TextField (manual charge)
      └── BusyButton → 'Cargo လက်ခံမည်'
```

### 2.8 Refund flow tree

```
RefundListPage (push from AppBar or Dashboard)
 ├── [loading] → LoadingView
 ├── [error] → ErrorView + retry
 ├── [empty] → EmptyView + "Request Refund" button
 └── [data]
      ├── _StatusFilterBar (horizontal FilterChip row)
      └── RefreshIndicator > ListView.builder
           └── _RefundListItem > Card > ListTile → RefundDetailPage

RefundCreatePage (push from RefundListPage)
 ├── [loading] → LoadingView
 ├── [success] → Card with check icon + "Back to List"
 └── [form]
      ├── ErrorCard
      ├── DropdownButtonFormField (payment)
      ├── DropdownButtonFormField (ticket — optional)
      ├── TextField (refund amount)
      ├── TextField (reason, multiline)
      └── BusyButton → submit refund request

RefundDetailPage (push from RefundListPage)
 ├── RefreshIndicator > ListView
 │    ├── Card (status banner with colour)
 │    ├── ErrorCard
 │    ├── _InfoRow list (refund number, payment, amount, reason, ticket, decision note)
 │    ├── Divider + Text("Timeline")
 │    ├── _TimelineItem list (created, decided, paid, completed)
 │    ├── Divider
 │    └── Action button row (conditional on status):
 │         ├── [requested] → Reject / Approve (refund.approve)
 │         ├── [approved] → Mark Paid (refund.pay)
 │         └── [paid] → Complete (refund.complete)
```

---

## 3. Permission Mapping

| Screen | Required permissions | Gated element |
|--------|---------------------|---------------|
| TripListPage | `trip.view` (implied — no explicit gate) | — |
| TripDetailPage | `trip.view` (implied) | — |
| RouteListPage | `route.view` (implied) | — |
| RouteDetailPage | — (no explicit gate) | — |
| TicketSalesPage | `booking.view` OR `ticket.view` | Entire screen; booking list; ticket list |
| CounterBookingPage | `booking.manage`, `passenger.view`, `passenger.manage`, `trip.view`, `fare.quote` | Entry card in TicketSalesPage |
| PaymentDecisionPage | `payment.record`, `payment.confirm`, `ticket.issue` | Buttons disabled when missing |
| CargoWorklistPage | `cargo.view` | Entire screen |
| CargoAcceptancePage | `cargo.accept` | Entry button in CargoWorklistPage |
| TicketScannerScreen | — (no gate) | — |
| RefundListPage | `refund.view` | AppBar icon + screen content |
| RefundCreatePage | `refund.request` | "+" button in RefundListPage app bar |
| RefundDetailPage | `refund.approve`, `refund.pay`, `refund.complete` | Action buttons per status |

### Permission gaps

- **TripListPage**: No `trip.view` permission gate on the page itself. Only the AppBar icon is shown unconditionally. A user without `trip.view` can reach a broken page.
- **RouteListPage**: Same issue — no `route.view` gate.
- **RouteDetailPage**: Create/edit button has no `route.manage` gate.
- **TripDetailPage** status actions (`ready`, `boarding`, `depart`, etc.): No permission gate. Any user who can see the trip can advance its status.
