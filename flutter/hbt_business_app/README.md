# HBT Business App

Flutter application for HBT operator owners, managers, counters, dispatchers,
cashiers, drivers and conductors. Every staff member uses an individual account;
the backend determines organization, role and permitted data scope.

## Run locally

From this directory:

```powershell
flutter pub get
flutter run -d windows --dart-define=HBT_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Supported development targets are Android, iOS, Windows and web. Examples:

```powershell
# Browser (Django must allow the displayed localhost origin through CORS)
flutter run -d chrome --dart-define=HBT_API_BASE_URL=http://127.0.0.1:8000/api/v1

# Android emulator
flutter run -d android --dart-define=HBT_API_BASE_URL=http://10.0.2.2:8000/api/v1

# A physical Android/iOS device on the same LAN
flutter run --dart-define=HBT_API_BASE_URL=http://192.168.1.20:8000/api/v1
```

For a physical Android device, replace `10.0.2.2` with the LAN address of the
computer running Django, for example `http://192.168.1.20:8000/api/v1`.
For a physical device Django must listen on the LAN interface and its hostname
must be included in `DJANGO_ALLOWED_HOSTS`.

## Initial scope

- JWT sign-in, secure token storage and restore/logout;
- Myanmar-first sign-in and role-aware business shell;
- API base URL supplied only by `--dart-define`, never hardcoded per build;
- foundations for ticket sales, cargo and pending/sync work.

## Current code structure

- `lib/main.dart` is the application entry point only.
- `lib/app/` owns app startup, theme and authenticated route selection.
- `lib/core/` owns environment configuration and the HTTP client.
- `lib/features/auth/` owns session restoration, sign-in and sign-out.
- `lib/features/business/` owns the authenticated shell and business screens.

The ticket tab is a permission-gated, online worklist for existing bookings
and issued tickets. Counter sale, cargo and sync mutations remain unimplemented
and must not be represented as completed workflows until each is connected to
its API contract and has the required role, offline and audit behavior.

The app loads the active organization and its server-calculated effective
permissions from `GET /api/v1/me/organizations/{organization_id}/context/`.
It stores only the selected organization ID locally; permissions are refreshed
from the API at sign-in and when the user changes organization. The next
payment-evidence upload and permission-gated payment decision/ticket result are
available after a locked fare quote. The counter-sale booking flow covers
passenger and trip/seat selection plus a server fare quote.
Offline outbox/local encrypted database is a release-critical follow-up: this
app does not claim that the placeholder Sync screen provides offline
transaction support.

The first counter-sale increment ends at a locked server fare quote. Payment
confirmation and ticket issue are separate increments, so the client must not
calculate fares, mark a booking paid, or issue a ticket locally.
The counter seat picker must use the counter-authorized, segment-aware
`GET /organizations/{org}/trips/{trip}/seats/` contract with pickup/dropoff
parameters; layout positions alone must not be treated as availability.

The backend enforces `ticket.issue` in addition to `payment.confirm` when a
payment decision includes ticket allocations. The Business app still has no
payment-decision or ticket-issue UI; it must not expose those actions until the
complete client workflow and its tests are delivered.

## Backend contract

See `../../backend/README.md` for endpoint setup and
`../../docs/implementation/07-notification-offline-sync.md` for the required
sync contract. Never store passwords, wallet PINs, OTPs or payment-provider
secrets on the device.
