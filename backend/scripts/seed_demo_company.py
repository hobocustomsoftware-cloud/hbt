"""Seed a realistic demo company for the runtime UI review.

Data-provisioning script only — does not modify application code.
Creates: tenant, org, users (owner/counter/conductor/driver/finance/manager),
memberships, routes (Yangon->Mandalay, Yangon->Taunggyi), terminals, stops,
seat layout + vehicle, schedules, trips (today/tomorrow), fare rules, cargo
categories/pricing.

Idempotent: safe to re-run (skips existing objects by unique code/phone).
"""

import os
import sys
import uuid
from datetime import date, time, timedelta

import django

# Make `config` importable when run as scripts/seed_demo_company.py
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.utils import timezone

from apps.identity.models import User
from apps.tenancy.models import Tenant, Organization, Membership
from apps.locations.models import PhysicalTerminal, OperationalStatus
from apps.network.models import Route, RouteStop
from apps.fleet.models import SeatLayout, LayoutPosition, Vehicle
from apps.scheduling.models import Schedule, Trip
from apps.fares.models import FareRule
from apps.cargo.models import CargoCategory, CargoPricingRule
from apps.workforce.models import StaffProfile, DriverProfile, ConductorProfile
from apps.passengers.models import Passenger

PASSWORD = "Demo-pass-123"


def get_or_create_user(phone, first_name, last_name):
    user, created = User.objects.get_or_create(
        phone_number=phone,
        defaults={
            "first_name": first_name,
            "last_name": last_name,
            "status": User.Status.ACTIVE,
        },
    )
    if created:
        user.set_password(PASSWORD)
        user.save()
        print(f"  + user {phone} ({first_name})")
    else:
        print(f"  = user {phone} exists")
    return user


def main():
    print("Seeding HBT demo company...")

    # 1. Tenant + organization
    tenant, _ = Tenant.objects.get_or_create(
        slug="demo-tenant", defaults={"name": "Demo Tenant"}
    )
    org, created = Organization.objects.get_or_create(
        tenant=tenant,
        legal_name="Shwe Yoke Lay Express Co., Ltd.",
        defaults={
            "display_name": "Shwe Yoke Lay Express",
            "status": Organization.Status.ACTIVE,
        },
    )
    print(f"{'  + created' if created else '  = existing'} org {org.display_name}")

    # 2. Users
    owner = get_or_create_user("+959751234561", "U", "Aung Owner")
    manager = get_or_create_user("+959751234562", "Daw", "Su Manager")
    counter = get_or_create_user("+959751234563", "Ko", "Min Counter")
    conductor = get_or_create_user("+959751234564", "Ko", "Zaw Conductor")
    driver = get_or_create_user("+959751234565", "U", "Tin Driver")
    finance = get_or_create_user("+959751234566", "Daw", "Hla Finance")

    # 3. Memberships (active)
    memberships = {}
    for user in (owner, manager, counter, conductor, driver, finance):
        membership, _ = Membership.objects.get_or_create(
            organization=org,
            user=user,
            defaults={"status": Membership.Status.ACTIVE, "joined_at": timezone.now()},
        )
        memberships[user.phone_number] = membership
        if _:
            print(f"  + membership {user.phone_number}")

    # 3b. Role assignments (RBAC) — owner assigns roles to staff.
    from apps.tenancy.models import Role, MembershipRole
    from apps.tenancy.services import assign_role

    role_codes = {
        owner.phone_number: "company-owner",
        manager.phone_number: "operations-manager",
        counter.phone_number: "counter-sales",
        conductor.phone_number: "conductor",
        driver.phone_number: "driver",
        finance.phone_number: "finance",
    }
    owner_membership = memberships[owner.phone_number]
    owner_role = Role.objects.get(code="company-owner")

    # Bootstrap: the org owner cannot assign themselves (no actor above them),
    # so create the owner assignment directly. This mirrors platform seeding.
    if not MembershipRole.objects.filter(
        membership=owner_membership, role=owner_role
    ).exists():
        MembershipRole.objects.create(
            membership=owner_membership,
            role=owner_role,
            scope_type="company",
        )
        print(f"  + role company-owner -> {owner.phone_number} (bootstrap)")

    for phone, role_code in role_codes.items():
        role = Role.objects.get(code=role_code)
        target = memberships[phone]
        existing = MembershipRole.objects.filter(membership=target, role=role).exists()
        if existing:
            print(f"  = role {role_code} already on {phone}")
            continue
        try:
            assign_role(
                actor_membership=owner_membership,
                target_membership=target,
                role=role,
                scope_type="company",
            )
            print(f"  + role {role_code} -> {phone}")
        except Exception as exc:
            print(f"  ! role assign {role_code} -> {phone} failed: {exc}")

    # 4. Terminals
    terminals = {}
    for code, name, city in [
        ("yangon-aa", "Aung Mingalar Highway Terminal", "Yangon"),
        ("mandalay-ky", "Kyaw Zay Terminal", "Mandalay"),
        ("taunggyi", "Taunggyi Main Terminal", "Taunggyi"),
        ("naypyidaw", "Naypyidaw Highway Terminal", "Naypyidaw"),
    ]:
        terminal, _ = PhysicalTerminal.objects.get_or_create(
            code=code,
            defaults={"name": name, "city": city, "status": OperationalStatus.ACTIVE},
        )
        terminals[code] = terminal
        print(f"  + terminal {name}")

    # 5. Routes + stops
    def create_route(code, name, stop_specs):
        route, _ = Route.objects.get_or_create(
            organization=org, code=code, defaults={"name": name, "status": Route.Status.ACTIVE}
        )
        for seq, (terminal_key, stop_code, stop_name, stop_type) in enumerate(stop_specs, start=1):
            RouteStop.objects.get_or_create(
                route=route,
                code=stop_code,
                defaults={
                    "terminal": terminals[terminal_key],
                    "name": stop_name,
                    "sequence": seq,
                    "stop_type": stop_type,
                    "status": RouteStop.Status.ACTIVE,
                },
            )
        return route

    create_route(
        "yangon-mandalay",
        "Yangon - Mandalay Express",
        [
            ("yangon-aa", "ym-1", "Aung Mingalar Terminal", RouteStop.Type.TERMINAL),
            ("naypyidaw", "ym-2", "Naypyidaw Stop", RouteStop.Type.MAJOR),
            ("mandalay-ky", "ym-3", "Kyaw Zay Terminal", RouteStop.Type.TERMINAL),
        ],
    )
    create_route(
        "yangon-taunggyi",
        "Yangon - Taunggyi Express",
        [
            ("yangon-aa", "yt-1", "Aung Mingalar Terminal", RouteStop.Type.TERMINAL),
            ("taunggyi", "yt-2", "Taunggyi Main Terminal", RouteStop.Type.TERMINAL),
        ],
    )
    print("  + routes yangon-mandalay, yangon-taunggyi")

    # 6. Branch (required by vehicle) + seat layout + vehicle
    from apps.locations.models import Branch

    branch, _ = Branch.objects.get_or_create(
        organization=org,
        code="yangon-main",
        defaults={
            "name": "Yangon Main Branch",
            "status": OperationalStatus.ACTIVE,
        },
    )
    print("  + branch yangon-main")
    layout, _ = SeatLayout.objects.get_or_create(
        organization=org,
        code="vip-2x2",
        defaults={
            "name": "VIP 2x2 (29 seats)",
            "layout_type": SeatLayout.Type.CUSTOM,
            "status": SeatLayout.Status.APPROVED,
            "row_count": 8,
            "column_count": 4,
        },
    )
    if _:
        for row in range(1, 9):
            for col in range(1, 5):
                LayoutPosition.objects.create(
                    layout=layout,
                    identifier=f"{row}{chr(64 + col)}",
                    position_type=LayoutPosition.Type.STANDARD,
                    row=row,
                    column=col,
                )
        print("  + seat layout vip-2x2 (32 positions)")
    vehicle, _ = Vehicle.objects.get_or_create(
        organization=org,
        code="bus-001",
        defaults={
            "branch": branch,
            "registration_number": "YGN 2K-1234",
            "fleet_number": "SYL-001",
            "category": Vehicle.Category.SHUTTLE,
            "passenger_capacity": 32,
            "cargo_supported": True,
            "cargo_weight_capacity_kg": 1500,
            "air_conditioned": True,
            "status": Vehicle.Status.AVAILABLE,
        },
    )
    print("  + vehicle bus-001")

    # 7. Schedules + trips
    today = timezone.localdate()
    routes = {
        "ym": Route.objects.get(organization=org, code="yangon-mandalay"),
        "yt": Route.objects.get(organization=org, code="yangon-taunggyi"),
    }
    schedules = {}
    for key, route, dep, arr, days in [
        ("ym-morning", routes["ym"], time(7, 0), time(15, 0), [0, 1, 2, 3, 4, 5, 6]),
        ("ym-night", routes["ym"], time(21, 0), time(5, 0), [0, 1, 2, 3, 4, 5, 6]),
        ("yt-morning", routes["yt"], time(8, 0), time(18, 0), [0, 1, 2, 3, 4, 5, 6]),
    ]:
        schedule, _ = Schedule.objects.get_or_create(
            organization=org,
            route=route,
            code=key,
            defaults={
                "name": f"{route.name} ({dep.strftime('%H:%M')})",
                "planned_departure_time": dep,
                "planned_arrival_time": arr,
                "arrival_day_offset": 1 if dep > arr and key == "ym-night" else 0,
                "operating_days": days,
                "effective_from": today - timedelta(days=30),
                "status": Schedule.Status.OPERATIONAL,
            },
        )
        schedules[key] = schedule
    print("  + schedules ym-morning, ym-night, yt-morning")

    trip_count = 0
    for day_offset in (0, 1):
        d = today + timedelta(days=day_offset)
        for key, schedule in schedules.items():
            departure = timezone.make_aware(
                timezone.datetime.combine(d, schedule.planned_departure_time)
            )
            arrival = departure + timedelta(hours=8)
            _, created = Trip.objects.get_or_create(
                organization=org,
                schedule=schedule,
                service_date=d,
                defaults={
                    "trip_number": f"{schedule.code.upper()}-{d.strftime('%m%d')}",
                    "planned_departure_at": departure,
                    "planned_arrival_at": arrival,
                    "route": schedule.route,
                    "seat_layout": layout,
                    "seat_layout_snapshot": {"id": str(layout.id), "version": 1},
                    "status": Trip.Status.PLANNED,
                },
            )
            if created:
                trip_count += 1
    print(f"  + {trip_count} trips generated (today + tomorrow)")

    # 8. Fare rules (Yangon-Mandalay base)
    ym_route = routes["ym"]
    ym_pickup = ym_route.stops.get(code="ym-1")
    ym_dropoff = ym_route.stops.get(code="ym-3")
    FareRule.objects.get_or_create(
        organization=org,
        route=ym_route,
        defaults={
            "code": "ym-base",
            "name": "Yangon-Mandalay Base Fare",
            "pickup_stop": ym_pickup,
            "dropoff_stop": ym_dropoff,
            "base_fare": 25000,
            "currency": "MMK",
            "active": True,
            "created_by": owner,
            "effective_from": timezone.now() - timedelta(days=30),
        },
    )
    print("  + fare rule yangon-mandalay 25,000 MMK")

    # 9. Cargo
    category, _ = CargoCategory.objects.get_or_create(
        organization=org,
        code="parcel",
        defaults={
            "name": "Parcel",
            "default_pricing_method": "per_kg",
            "default_rate": 3000,
            "active": True,
        },
    )
    CargoPricingRule.objects.get_or_create(
        organization=org,
        code="parcel-per-kg",
        defaults={
            "name": "Parcel per kg",
            "category": category,
            "method": CargoPricingRule.Method.TIERED_KG,
            "base_weight_kg": 1,
            "base_price": 3000,
            "excess_rate_per_kg": 3000,
            "active": True,
            "created_by": owner,
        },
    )
    print("  + cargo category + pricing rule")

    # 10. A demo passenger
    Passenger.objects.get_or_create(
        organization=org,
        passenger_code="PASS-DEMO-001",
        defaults={"full_name": "Ma Mya Passenger", "phone_number": "+959751234567"},
    )
    print("  + demo passenger PASS-DEMO-001")

    print("\n=== SEED COMPLETE ===")
    print(f"Login (password: {PASSWORD}):")
    print(f"  Owner:      +959751234561")
    print(f"  Manager:    +959751234562")
    print(f"  Counter:    +959751234563")
    print(f"  Conductor:  +959751234564")
    print(f"  Driver:     +959751234565")
    print(f"  Finance:    +959751234566")
    print(f"  Superuser:  +959757393574 (existing, unknown password)")


if __name__ == "__main__":
    main()
