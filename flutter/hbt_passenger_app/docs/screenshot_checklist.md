# Passenger App — Screenshot Checklist

**App:** hbt_passenger_app
**Date:** 2026-07-30
**Status:** ✅ All 7 MVP screens implemented

---

## Screen Inventory

| # | Screen | File | Route | Status |
|---|--------|------|-------|--------|
| 1 | Splash | `features/splash/presentation/splash_screen.dart` | `/splash` | ✅ New |
| 2 | Login | `features/auth/presentation/login_screen.dart` | `/login` | ✅ Existing |
| 3 | Registration | `features/auth/presentation/registration_screen.dart` | `/register` | ✅ Existing |
| 4 | Trip Search | `features/trip/presentation/trip_search_screen.dart` | Embedded in Home tab 0 | ✅ Enhanced |
| 5 | Trip Detail | `features/trip/presentation/trip_detail_screen.dart` | `/trip-detail` | ✅ New |
| 6 | Seat Selection | `features/booking/presentation/booking_screen.dart` | `/booking` | ✅ Enhanced |
| 7 | Booking Confirmation | `features/booking/presentation/booking_screen.dart` | Embedded in Booking flow | ✅ Enhanced |
| 8 | My Tickets | `features/ticket/presentation/ticket_list_screen.dart` | Embedded in Home tab 1 | ✅ Existing |
| — | Home (shell) | `features/home/presentation/home_screen.dart` | `/home` | ✅ Existing |

---

## Screenshot Checklist

### 1. Splash Screen (`/splash`)
- [ ] HBT branded bus icon in primary-colour container
- [ ] "HBT Passenger" title in primary colour
- [ ] "Bus ticketing made simple" subtitle
- [ ] CircularProgressIndicator spinner
- [ ] Auto-routes to `/home` if authenticated, `/register` if not
- [ ] Brief delay (600ms) to show branding before routing

### 2. Login Screen (`/login`)
- [ ] "Welcome Back" heading
- [ ] Phone number field with `+95 ` prefix
- [ ] Password field with visibility toggle
- [ ] "Sign In" button (BusyButton with spinner when loading)
- [ ] "New here? Create an account" link → `/register`
- [ ] Error text in red when auth fails
- [ ] Validates phone is non-empty
- [ ] Validates password is non-empty
- [ ] On success: redirects to `/home`

### 3. Registration Screen (`/register`)
- [ ] "Join HBT" heading
- [ ] Phone number field with `+95 ` prefix
- [ ] Password field (min 8 chars validation)
- [ ] First Name (optional)
- [ ] Last Name (optional)
- [ ] "Create Account" button (BusyButton with spinner)
- [ ] "Already have an account? Sign in" link → `/login`
- [ ] On success: auto-login and redirect to `/home`

### 4. Trip Search (Home tab 0)
- [ ] "Where are you going?" heading
- [ ] "From" dropdown (terminals grouped by city)
- [ ] "To" dropdown (terminals grouped by city)
- [ ] "Find Routes" button (appears after both terminals selected)
- [ ] Route dropdown (appears after routes loaded)
- [ ] Pickup Stop dropdown
- [ ] Dropoff Stop dropdown
- [ ] Date picker (tappable, shows calendar)
- [ ] "Search Trips" button
- [ ] Results list: trip number, operator name, departure time
- [ ] Each result tappable → `/trip-detail`
- [ ] "No trips found" empty state with "Back to Search" link
- [ ] Error handling with retry
- [ ] Pull-to-refresh

### 5. Trip Detail Screen (`/trip-detail`)
- [ ] AppBar with trip number
- [ ] Header card: bus icon, trip number, StatusChip
- [ ] Trip Information card:
  - [ ] Operator name
  - [ ] Route name
  - [ ] Service date
  - [ ] Departure time
  - [ ] Arrival time
  - [ ] Duration (if available)
  - [ ] Distance (if available)
- [ ] Route Stops card with visual timeline:
  - [ ] Vertical line connecting stops
  - [ ] Green dot for pickup stop with "PICKUP" badge
  - [ ] Red dot for dropoff stop with "DROPOFF" badge
  - [ ] Grey dots for intermediate stops
- [ ] "Select Seat & Book" button → `/booking`
- [ ] Pull-to-refresh

### 6. Seat Selection (`/booking` — seat grid section)
- [ ] AppBar with trip reference
- [ ] Trip summary card: bus icon, trip number, StatusChip, operator, date, departure
- [ ] "Select Your Seat" section header
- [ ] Seat grid:
  - [ ] Available seats (green tint, selectable)
  - [ ] Booked seats (grey, non-selectable)
  - [ ] Selected seat (primary colour, highlighted)
  - [ ] Front indicator label
  - [ ] Row layout with aisle gap
- [ ] Legend: Available / Booked / Selected
- [ ] "Confirm Booking" button (disabled until seat selected)
- [ ] Error card for API failures

### 7. Booking Confirmation (success view in Booking flow)
- [ ] Green check icon in circular background
- [ ] "Booking Confirmed!" heading
- [ ] Truncated booking ID (#xxxxxxxx)
- [ ] Trip summary card with checkmarks:
  - [ ] Trip number
  - [ ] Date
  - [ ] Departure time
  - [ ] Seat number
- [ ] "Home" secondary button → pop to root
- [ ] "My Tickets" primary button → `/tickets`

### 8. My Tickets (Home tab 1)
- [ ] Tappable ticket cards with:
  - [ ] Ticket number (bold)
  - [ ] StatusChip (coloured by status)
  - [ ] Trip number
  - [ ] Passenger name
  - [ ] Seat identifier
  - [ ] Departure time
  - [ ] Fare amount + currency
- [ ] Pull-to-refresh
- [ ] Empty state with icon + "No tickets yet." + hint text
- [ ] Loading state (LoadingView)
- [ ] Error state (ErrorView with retry)

### 9. Home Shell (`/home`)
- [ ] AppBar with "Search Trips" / "My Tickets"
- [ ] PopupMenuButton: Profile, Sign Out
- [ ] Bottom NavigationBar: Search, My Tickets
- [ ] Profile dialog shows user info
- [ ] Sign Out → `/login`

---

## App-level features
- [ ] Material 3 theme (seed colour `#00695c`)
- [ ] Splash screen on cold start (session restore)
- [ ] Token refresh on expired session
- [ ] Secure token storage (flutter_secure_storage)

## Navigation map

```
/splash → /register (unauthenticated)
        → /home (authenticated)

/register → /home (after successful registration)
/login → /home (after login)

/home
  ├── Tab 0: TripSearchScreen
  │     └── result tap → /trip-detail
  │                       └── "Select Seat & Book" → /booking
  │                                                   ├── confirm → success view
  │                                                   └── "My Tickets" → /tickets
  └── Tab 1: TicketListScreen
```

---

## Shared widgets reused

| Widget | Used in |
|--------|---------|
| `BusyButton` | Login, Registration, Booking |
| `BusyButtonIcon` | — (available) |
| `ActionButtonRow` | Booking (success view) |
| `ActionChipButton` | — (available) |
| `LoadingView` | Booking, Ticket List, Trip Detail |
| `ErrorView` | Booking, Ticket List |
| `ErrorCard` | Booking, Trip Detail |
| `EmptyView` | — (available; Ticket List uses inline empty) |
| `EmptyListTileCard` | — (available) |
| `AppDialog.showInfo` | Home (profile dialog) |
| `AsyncState` | Trip Search, Booking, Ticket List, Trip Detail |
| `StatusChip` | Home (AppBar), Ticket List, Trip Detail, Booking |
| `StatusAvatar` | — (available) |
