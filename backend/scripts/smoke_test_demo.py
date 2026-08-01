"""Smoke-test the seeded demo data via the live API (runtime review prep)."""

import requests

BASE = "http://127.0.0.1:8000/api/v1"
PASSWORD = "Demo-pass-123"

for phone in ["+959751234563", "+959751234561", "+959751234565", "+959751234566"]:
    r = requests.post(
        f"{BASE}/auth/login/",
        json={"phone_number": phone, "password": PASSWORD},
        timeout=20,
    )
    if r.status_code != 200:
        print(f"{phone}: LOGIN FAIL {r.status_code} {r.text[:120]}")
        continue
    tok = r.json()["access"]
    h = {"Authorization": "Bearer " + tok}
    orgs = requests.get(f"{BASE}/me/organizations/", headers=h, timeout=20).json()
    org_id = orgs["results"][0]["id"]
    ctx = requests.get(
        f"{BASE}/me/organizations/{org_id}/context/", headers=h, timeout=20
    ).json()
    perms = ctx.get("permissions", [])
    trips = requests.get(f"{BASE}/organizations/{org_id}/trips/", headers=h, timeout=20)
    trip_count = len(trips.json().get("results", [])) if trips.status_code == 200 else "ERR"
    print(f"{phone}: {len(perms)} perms | trips={trips.status_code} count={trip_count}")
    # One trip detail + seats if available
    if trips.status_code == 200 and trip_count:
        trip = trips.json()["results"][0]
        seats = requests.get(
            f"{BASE}/organizations/{org_id}/trips/{trip['id']}/seats/",
            headers=h,
            timeout=20,
        )
        print(f"   trip {trip['trip_number']} {trip['status']} | seats {seats.status_code}")
        if seats.status_code == 200:
            print("   seat payload keys:", list(seats.json().keys()))
        else:
            print("   seat body:", seats.text[:200])
