# UAT Screenshot Findings — 2026-08-23

| Screenshot | Finding | UAT status |
|---|---|---|
| `screenshots/api-ready.png` | Django REST readiness page loaded with HTTP 200 and JSON showing `status: ready`, `database: ok`. This confirms API container, PostgreSQL and Redis are healthy at capture time. | PASS |
| `screenshots/api-schema.png` | Requested `/api/schema/swagger-ui/` returned Django 404 Page Not Found. The URL is not registered in the current route configuration; this is an API documentation route/configuration gap, not a service-down result. | FAIL |

The screenshots were captured from the Docker host at `127.0.0.1:8000` using a headless browser. They are UAT evidence for API reachability only; they do not prove authenticated Dashboard, Business App, Passenger App, printer, camera, offline-sync or real-payment workflow completion.

| `screenshots/public-home.png` | Public passenger landing page rendered with Myanmar branding, route/date search controls, operator card, footer links and demo operator content. Visual layout is available, but interactive search was not submitted with a validated dataset in this capture. | PARTIAL |
| `screenshots/admin-entry.png` | `/admin/` entry page rendered with login fields, but the screenshot shows unstyled/incomplete admin presentation and no authenticated Super Admin dashboard session. | BLOCKED / UI GAP |

The API readiness capture confirms the repaired Docker stack is healthy. The Swagger URL and authenticated dashboard remain open UAT defects. Business/Passenger mobile device workflows were not captured because the attached environment does not provide an emulator/device session connected to the running API.


## UAT gateway v2 findings — 2026-08-23

| Screenshot | Finding | UAT status |
|---|---|---|
| `screenshots-v2/admin-entry.png` | Through the HTTP-only UAT gateway, admin CSS/static assets now load correctly. The login card is rendered with HBT branding, Myanmar text, phone/password fields and sign-in button. Authentication was not submitted because no approved UAT credentials were provided. | PASS — visual entry; AUTH BLOCKED |
| `screenshots-v2/swagger-ui.png` | `/api/docs/` no longer returns 404, but the page remains on a `LOADING` state in headless capture. This indicates the route is reachable while the Swagger client/schema asset loading is not yet proven complete. | PARTIAL / OPEN |
| `screenshots-v2/api-ready.png` | UAT gateway readiness remains healthy through Nginx. | PASS |
| `screenshots-v2/public-home.png` | Public landing page remains rendered through the UAT gateway. | PARTIAL PASS |

The UAT gateway is HTTP-only and intended for local UAT only. Production must continue using `tenant.conf` with valid TLS certificates; the UAT gateway must not be used as a production TLS substitute.


| `screenshots-v2/swagger-ui-wait.png` | After rebuilding the API image with `drf_spectacular_sidecar` and WhiteNoise, and waiting for the schema request, Swagger UI renders the HBT API title, version, Authorize button and endpoint groups. | PASS — visual rendering |


## Business/Passenger web UAT findings — 2026-08-23

| Screenshot | Finding | UAT status |
|---|---|---|
| `screenshots-v2/business-web.png` | Business App Flutter web build loads its branded login screen with phone/password fields, Myanmar localization text and sign-in action. No approved UAT account was submitted, so authenticated operational workflows remain unverified. | PASS — launch/login visual; AUTH BLOCKED |
| `screenshots-v2/passenger-web.png` | Passenger App web screenshot captured `ERR_CONNECTION_REFUSED` because the Passenger web server was not reachable at capture time. The Flutter web build itself completed, but runtime launch evidence failed. | FAIL / BLOCKED |

The Business and Passenger screenshots are browser launch evidence only. They do not represent real-data booking, payment confirmation, ticket issue, boarding, cargo, offline sync or device tests.


| `screenshots-v2/passenger-web-retry.png` | Passenger web server responded with HTTP 200, but the Flutter shell remained visually blank after the configured wait. This is a runtime/rendering blocker for Passenger web UAT; native Android/iOS device UAT is still not covered. | FAIL / OPEN |


## Passenger web runtime fix — 2026-08-23

| Screenshot | Finding | UAT status |
|---|---|---|
| `screenshots-v2/passenger-web-fixed.png` | After adding a `kIsWeb` guard around `flutter_foreground_task` and using the existing `NotificationSocket` directly in browser mode, the Passenger App renders its registration/login screen instead of a blank shell. | PASS — web launch |

Root cause was confirmed through CDP diagnostics: `flutter_foreground_task` attempted to use `ReceivePort.sendPort` in the browser, producing `Unsupported operation: ReceivePort.sendPort` during app startup. The native foreground-isolate notification path remains unchanged for Android/iOS; web uses a reconnecting authenticated WebSocket on the main browser isolate.
