# HBT Backend

Initial Django and Django REST Framework foundation for the HoBo Transport
Platform.

## Local setup (PowerShell)

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
docker compose up -d postgres
python manage.py migrate
python manage.py runserver
```

If PostgreSQL 17 is already installed as a Windows service, update the
`POSTGRES_*` values in `.env` for that local server and skip the Docker command.
The database and database role must already exist.

The initial public health endpoint is:

```text
GET /api/v1/health/
```

Authentication endpoints:

```text
POST  /api/v1/auth/register/
POST  /api/v1/auth/login/
POST  /api/v1/auth/token/refresh/
POST  /api/v1/auth/logout/
GET   /api/v1/auth/me/
PATCH /api/v1/auth/me/
```

Tenant authorization endpoints:

```text
GET  /api/v1/me/organizations/
GET  /api/v1/me/organizations/{organization_id}/context/
GET  /api/v1/organizations/{organization_id}/
GET  /api/v1/organizations/{organization_id}/memberships/
GET  /api/v1/organizations/{organization_id}/permissions/
GET  /api/v1/organizations/{organization_id}/roles/
POST /api/v1/organizations/{organization_id}/roles/
POST /api/v1/organizations/{organization_id}/role-assignments/
```

The organization-context endpoint is the authenticated user's current
organization and server-calculated effective permission codes. Clients must
use it for UI visibility and routing, but the API remains the authorization
source for every mutation.

Location endpoints:

```text
GET        /api/v1/terminals/
GET,POST   /api/v1/organizations/{organization_id}/branches/
GET,PATCH  /api/v1/organizations/{organization_id}/branches/{branch_id}/
GET,POST   /api/v1/organizations/{organization_id}/terminal-operations/
GET,PATCH  /api/v1/organizations/{organization_id}/terminal-operations/{operation_id}/
GET,POST   /api/v1/organizations/{organization_id}/terminal-operations/{operation_id}/counters/
```

Route-network endpoints:

```text
GET,POST   /api/v1/organizations/{organization_id}/routes/
GET,PATCH  /api/v1/organizations/{organization_id}/routes/{route_id}/
GET,POST   /api/v1/organizations/{organization_id}/routes/{route_id}/stops/
GET,PATCH  /api/v1/organizations/{organization_id}/routes/{route_id}/stops/{stop_id}/
GET,POST   /api/v1/organizations/{organization_id}/routes/{route_id}/segments/
```

Fleet and workforce endpoints:

```text
GET,POST /api/v1/organizations/{organization_id}/vehicles/
GET,POST /api/v1/organizations/{organization_id}/seat-layouts/
GET,POST /api/v1/organizations/{organization_id}/seat-layouts/{layout_id}/positions/
POST     /api/v1/organizations/{organization_id}/vehicles/{vehicle_id}/layout-assignments/
GET,POST /api/v1/organizations/{organization_id}/staff/
GET,POST /api/v1/organizations/{organization_id}/drivers/
GET,POST /api/v1/organizations/{organization_id}/conductors/
```

Schedule and trip assignment endpoints:

```text
GET,POST  /api/v1/organizations/{organization_id}/schedules/
GET,PATCH /api/v1/organizations/{organization_id}/schedules/{schedule_id}/
POST      /api/v1/organizations/{organization_id}/schedules/{schedule_id}/generate-trip/
GET,POST  /api/v1/organizations/{organization_id}/trips/
GET,PATCH /api/v1/organizations/{organization_id}/trips/{trip_id}/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/assign-vehicle/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/assign-driver/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/assign-conductor/
GET       /api/v1/organizations/{organization_id}/trips/{trip_id}/assignment-history/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/ready/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/boarding/start/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/depart/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/en-route/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/stops/{stop_id}/reach/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/arrive/
GET       /api/v1/organizations/{organization_id}/trips/{trip_id}/operational-events/
```

Passenger sales and boarding endpoints:

```text
GET,POST  /api/v1/organizations/{organization_id}/passengers/
GET,PATCH /api/v1/organizations/{organization_id}/passengers/{passenger_id}/
GET,POST  /api/v1/organizations/{organization_id}/bookings/
GET       /api/v1/organizations/{organization_id}/trips/{trip_id}/seats/?pickup_stop={id}&dropoff_stop={id}
GET        /api/v1/organizations/{organization_id}/bookings/{booking_id}/
POST       /api/v1/organizations/{organization_id}/bookings/{booking_id}/confirm/
POST       /api/v1/organizations/{organization_id}/bookings/{booking_id}/cancel/
GET        /api/v1/organizations/{organization_id}/tickets/
POST       /api/v1/organizations/{organization_id}/tickets/issue/
GET        /api/v1/organizations/{organization_id}/tickets/{ticket_id}/
GET        /api/v1/organizations/{organization_id}/boardings/
POST       /api/v1/organizations/{organization_id}/trips/{trip_id}/boarding/validate/
POST       /api/v1/organizations/{organization_id}/boardings/{boarding_id}/board/
```

Passenger-account self-service endpoints:

```text
GET,POST /api/v1/passenger/travelers/
GET       /api/v1/passenger/trips/search/?date={date}&pickup_stop={id}&dropoff_stop={id}
GET       /api/v1/passenger/trips/{trip_id}/seats/?pickup_stop={id}&dropoff_stop={id}
GET,POST /api/v1/passenger/bookings/
GET       /api/v1/passenger/tickets/
```

Seat availability is route-segment aware. A seat occupied from stop 1 to stop
2 may be sold again from stop 2 onward, while overlapping reservations are
serialized and rejected.

## Validation

```powershell
python manage.py check
python manage.py test
python manage.py makemigrations --check --dry-run
```

PostgreSQL is the default database. SQLite remains available only for isolated
local checks by setting `DJANGO_DB_ENGINE=sqlite`.

The current foundation includes:

- Phone-number-based custom users
- Tenant and organization boundaries
- Organization memberships
- Roles, permissions, and scoped membership-role assignments
- Protected platform administrator grants and time-limited tenant support access
- JWT access/refresh rotation and logout blacklisting
- Append-only audit events

Automatic payment-provider processing and refunds are not implemented.
Manual cash, wallet-QR, and bank-transfer records require an authorized
confirmation decision. Booking confirmation retains its manual or external
authorization reference for traceability.

Cargo, payment, printing, closing, reporting, and sync endpoints:

```text
GET,POST /api/v1/organizations/{organization_id}/cargo/contacts/
GET,POST /api/v1/organizations/{organization_id}/cargo/shipments/
GET       /api/v1/organizations/{organization_id}/cargo/shipments/{shipment_id}/
POST      /api/v1/organizations/{organization_id}/cargo/shipments/{shipment_id}/assign-trip/
POST      /api/v1/organizations/{organization_id}/cargo/shipments/{shipment_id}/transition/
GET,POST /api/v1/organizations/{organization_id}/payments/
POST      /api/v1/organizations/{organization_id}/payments/{payment_id}/decision/
GET,POST /api/v1/organizations/{organization_id}/print-documents/
POST      /api/v1/organizations/{organization_id}/print-documents/{document_id}/printed/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/close/
POST      /api/v1/organizations/{organization_id}/trips/{trip_id}/settlement/
POST      /api/v1/organizations/{organization_id}/settlements/{settlement_id}/action/
GET       /api/v1/organizations/{organization_id}/reports/owner-dashboard/
GET       /api/v1/organizations/{organization_id}/sync/bootstrap/?since={timestamp}
```

The print API returns immutable ticket/cargo payloads for a mobile device's
local Bluetooth print queue. The sync bootstrap is a bounded delta-download
contract; mobile clients must retain an encrypted local database, durable
upload queue, retry state, and last successful cursor.
