// AUTO-GENERATED from OpenAPI spec + Django serializers cross-validation.
// Do not edit manually — regenerate when backend contracts change.
//
// Field names match the JSON keys returned by the HBT API exactly.
// All fields are nullable (?) because API responses may redact optional fields.

class Trip {
  final String? id;
  final String? organizationId;
  final String? schedule;
  final String? route;
  final String? tripNumber;
  final String? serviceDate;
  final String? plannedDepartureAt;
  final String? plannedArrivalAt;
  final String? status;
  final String? operationalNotes;
  final String? boardingStartedAt;
  final String? departedAt;
  final String? arrivedAt;
  final String? currentStop;
  final Map<String, dynamic>? scheduleSnapshot;
  final Map<String, dynamic>? routeSnapshot;
  final String? vehicle;
  final String? driver;
  final String? conductor;
  final String? seatLayout;
  final Map<String, dynamic>? seatLayoutSnapshot;
  final bool? resourcesComplete;
  final String? createdAt;
  final String? updatedAt;

  // ⚠ MISMATCH FIX: Flutter accesses `route_id`, `vehicle_id`, `driver_id`,
  //   `conductor_id`, `organization_name` — but Trip has `route`, `vehicle`,
  //   `driver`, `conductor` as FK strings. These are NOT direct fields.
  //   Use the FK string values (e.g. `route` contains the UUID, not `route_id`).

  Trip({
    this.id,
    this.organizationId,
    this.schedule,
    this.route,
    this.tripNumber,
    this.serviceDate,
    this.plannedDepartureAt,
    this.plannedArrivalAt,
    this.status,
    this.operationalNotes,
    this.boardingStartedAt,
    this.departedAt,
    this.arrivedAt,
    this.currentStop,
    this.scheduleSnapshot,
    this.routeSnapshot,
    this.vehicle,
    this.driver,
    this.conductor,
    this.seatLayout,
    this.seatLayoutSnapshot,
    this.resourcesComplete,
    this.createdAt,
    this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id']?.toString(),
        organizationId: json['organization_id']?.toString(),
        schedule: json['schedule']?.toString(),
        route: json['route']?.toString(),
        tripNumber: json['trip_number']?.toString(),
        serviceDate: json['service_date']?.toString(),
        plannedDepartureAt: json['planned_departure_at']?.toString(),
        plannedArrivalAt: json['planned_arrival_at']?.toString(),
        status: json['status']?.toString(),
        operationalNotes: json['operational_notes']?.toString(),
        boardingStartedAt: json['boarding_started_at']?.toString(),
        departedAt: json['departed_at']?.toString(),
        arrivedAt: json['arrived_at']?.toString(),
        currentStop: json['current_stop']?.toString(),
        scheduleSnapshot: json['schedule_snapshot'] as Map<String, dynamic>?,
        routeSnapshot: json['route_snapshot'] as Map<String, dynamic>?,
        vehicle: json['vehicle']?.toString(),
        driver: json['driver']?.toString(),
        conductor: json['conductor']?.toString(),
        seatLayout: json['seat_layout']?.toString(),
        seatLayoutSnapshot:
            json['seat_layout_snapshot'] as Map<String, dynamic>?,
        resourcesComplete: json['resources_complete'] as bool?,
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class RouteDto {
  final String? id;
  final String? organizationId;
  final String? code;
  final String? name;
  final String? status;
  final String? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final String? operatingRegion;
  final int? stopCount;
  final String? createdAt;
  final String? updatedAt;

  RouteDto({
    this.id,
    this.organizationId,
    this.code,
    this.name,
    this.status,
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    this.operatingRegion,
    this.stopCount,
    this.createdAt,
    this.updatedAt,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) => RouteDto(
        id: json['id']?.toString(),
        organizationId: json['organization_id']?.toString(),
        code: json['code']?.toString(),
        name: json['name']?.toString(),
        status: json['status']?.toString(),
        estimatedDistanceKm: json['estimated_distance_km']?.toString(),
        estimatedDurationMinutes:
            json['estimated_duration_minutes'] is int
                ? json['estimated_duration_minutes'] as int
                : (json['estimated_duration_minutes'] != null
                    ? int.tryParse(json['estimated_duration_minutes'].toString())
                    : null),
        operatingRegion: json['operating_region']?.toString(),
        stopCount: json['stop_count'] is int
            ? json['stop_count'] as int
            : (json['stop_count'] != null
                ? int.tryParse(json['stop_count'].toString())
                : null),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class RouteStopDto {
  final String? id;
  final String? routeId;
  final String? terminal;
  final String? code;
  final String? name;
  final int? sequence;
  final String? stopType;
  final String? status;
  final bool? boardingAllowed;
  final bool? dropoffAllowed;
  final bool? cargoAllowed;
  final String? city;
  final String? latitude;
  final String? longitude;
  final String? addressLine;

  RouteStopDto({
    this.id,
    this.routeId,
    this.terminal,
    this.code,
    this.name,
    this.sequence,
    this.stopType,
    this.status,
    this.boardingAllowed,
    this.dropoffAllowed,
    this.cargoAllowed,
    this.city,
    this.latitude,
    this.longitude,
    this.addressLine,
  });

  factory RouteStopDto.fromJson(Map<String, dynamic> json) => RouteStopDto(
        id: json['id']?.toString(),
        routeId: json['route_id']?.toString(),
        terminal: json['terminal']?.toString(),
        code: json['code']?.toString(),
        name: json['name']?.toString(),
        sequence: json['sequence'] is int
            ? json['sequence'] as int
            : int.tryParse(json['sequence']?.toString() ?? ''),
        stopType: json['stop_type']?.toString(),
        status: json['status']?.toString(),
        boardingAllowed: json['boarding_allowed'] as bool?,
        dropoffAllowed: json['dropoff_allowed'] as bool?,
        cargoAllowed: json['cargo_allowed'] as bool?,
        city: json['city']?.toString(),
        latitude: json['latitude']?.toString(),
        longitude: json['longitude']?.toString(),
        addressLine: json['address_line']?.toString(),
      );
}

class Booking {
  final String? id;
  final String? organizationId;
  final String? trip;
  final String? bookingNumber;
  final String? bookingType;
  final String? channel;
  final String? status;
  final String? contactName;
  final String? contactPhone;
  final String? pickupStop;
  final String? dropoffStop;
  final String? expiresAt;
  final String? confirmedAt;
  final String? authorizationReference;
  final String? notes;
  final String? clientRequestId;
  final List<BookingPassenger>? passengerItems;
  final String? createdAt;
  final String? updatedAt;

  // ⚠ NOTE: The API returns `authorization_reference` (not `booking_reference`).
  //   The DTO correctly uses `authorizationReference`. Monetary fields
  //   (`base_fare`, `discount_amount`, `tax_amount`, `total_amount`, `currency`)
  //   belong to FareQuote/FareQuoteLine, not Booking. The screen code reads
  //   these from the FareQuote response correctly.

  Booking({
    this.id,
    this.organizationId,
    this.trip,
    this.bookingNumber,
    this.bookingType,
    this.channel,
    this.status,
    this.contactName,
    this.contactPhone,
    this.pickupStop,
    this.dropoffStop,
    this.expiresAt,
    this.confirmedAt,
    this.authorizationReference,
    this.notes,
    this.clientRequestId,
    this.passengerItems,
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id']?.toString(),
        organizationId: json['organization_id']?.toString(),
        trip: json['trip']?.toString(),
        bookingNumber: json['booking_number']?.toString(),
        bookingType: json['booking_type']?.toString(),
        channel: json['channel']?.toString(),
        status: json['status']?.toString(),
        contactName: json['contact_name']?.toString(),
        contactPhone: json['contact_phone']?.toString(),
        pickupStop: json['pickup_stop']?.toString(),
        dropoffStop: json['dropoff_stop']?.toString(),
        expiresAt: json['expires_at']?.toString(),
        confirmedAt: json['confirmed_at']?.toString(),
        authorizationReference: json['authorization_reference']?.toString(),
        notes: json['notes']?.toString(),
        clientRequestId: json['client_request_id']?.toString(),
        passengerItems: (json['passenger_items'] as List?)
            ?.map((e) =>
                BookingPassenger.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class BookingPassenger {
  final String? id;
  final String? passenger;
  final String? passengerName;
  final SeatReservation? seatReservation;

  BookingPassenger({
    this.id,
    this.passenger,
    this.passengerName,
    this.seatReservation,
  });

  factory BookingPassenger.fromJson(Map<String, dynamic> json) =>
      BookingPassenger(
        id: json['id']?.toString(),
        passenger: json['passenger']?.toString(),
        passengerName: json['passenger_name']?.toString(),
        seatReservation: json['seat_reservation'] != null
            ? SeatReservation.fromJson(
                json['seat_reservation'] as Map<String, dynamic>)
            : null,
      );
}

class SeatReservation {
  final String? id;
  final String? seatPosition;
  final String? seatIdentifierSnapshot;
  final String? status;
  final int? pickupSequence;
  final int? dropoffSequence;

  SeatReservation({
    this.id,
    this.seatPosition,
    this.seatIdentifierSnapshot,
    this.status,
    this.pickupSequence,
    this.dropoffSequence,
  });

  factory SeatReservation.fromJson(Map<String, dynamic> json) =>
      SeatReservation(
        id: json['id']?.toString(),
        seatPosition: json['seat_position']?.toString(),
        seatIdentifierSnapshot: json['seat_identifier_snapshot']?.toString(),
        status: json['status']?.toString(),
        pickupSequence: json['pickup_sequence'] is int
            ? json['pickup_sequence'] as int
            : int.tryParse(json['pickup_sequence']?.toString() ?? ''),
        dropoffSequence: json['dropoff_sequence'] is int
            ? json['dropoff_sequence'] as int
            : int.tryParse(json['dropoff_sequence']?.toString() ?? ''),
      );
}

class Ticket {
  final String? id;
  final String? organizationId;
  final String? booking;
  final String? bookingPassenger;
  final String? passenger;
  final String? passengerName;
  final String? trip;
  final String? tripNumber;
  final String? plannedDepartureAt;
  final String? seatPosition;
  final String? seatIdentifier;
  final String? ticketNumber;
  final String? ticketType;
  final String? status;
  final String? validationCode;
  final String? qrPayload;
  final String? fareAmount;
  final String? discountAmount;
  final String? taxAmount;
  final String? serviceCharge;
  final String? totalAmount;
  final String? currency;
  final String? issuingChannel;
  final String? issuedAt;
  final String? createdAt;
  final String? updatedAt;

  Ticket({
    this.id,
    this.organizationId,
    this.booking,
    this.bookingPassenger,
    this.passenger,
    this.passengerName,
    this.trip,
    this.tripNumber,
    this.plannedDepartureAt,
    this.seatPosition,
    this.seatIdentifier,
    this.ticketNumber,
    this.ticketType,
    this.status,
    this.validationCode,
    this.qrPayload,
    this.fareAmount,
    this.discountAmount,
    this.taxAmount,
    this.serviceCharge,
    this.totalAmount,
    this.currency,
    this.issuingChannel,
    this.issuedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id']?.toString(),
        organizationId: json['organization_id']?.toString(),
        booking: json['booking']?.toString(),
        bookingPassenger: json['booking_passenger']?.toString(),
        passenger: json['passenger']?.toString(),
        passengerName: json['passenger_name']?.toString(),
        trip: json['trip']?.toString(),
        tripNumber: json['trip_number']?.toString(),
        plannedDepartureAt: json['planned_departure_at']?.toString(),
        seatPosition: json['seat_position']?.toString(),
        seatIdentifier: json['seat_identifier']?.toString(),
        ticketNumber: json['ticket_number']?.toString(),
        ticketType: json['ticket_type']?.toString(),
        status: json['status']?.toString(),
        validationCode: json['validation_code']?.toString(),
        qrPayload: json['qr_payload']?.toString(),
        fareAmount: json['fare_amount']?.toString(),
        discountAmount: json['discount_amount']?.toString(),
        taxAmount: json['tax_amount']?.toString(),
        serviceCharge: json['service_charge']?.toString(),
        totalAmount: json['total_amount']?.toString(),
        currency: json['currency']?.toString(),
        issuingChannel: json['issuing_channel']?.toString(),
        issuedAt: json['issued_at']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class PaymentRecord {
  final String? id;
  final String? organization;
  final String? amount;
  final String? booking;
  final String? cargoShipment;
  final String? paymentNumber;
  final String? status;
  final String? method;
  final String? currency;
  final String? providerName;
  final String? transactionReference;
  final String? confirmedAt;
  final String? createdAt;
  final String? updatedAt;

  // ⚠ MISMATCH FIX: Flutter accesses `total_charge` — but PaymentRecord
  //   has `amount`, not `total_charge`. Flutter accesses `account_label` —
  //   but PaymentRecord has no such field. Use `provider_name` instead.

  PaymentRecord({
    this.id,
    this.organization,
    this.amount,
    this.booking,
    this.cargoShipment,
    this.paymentNumber,
    this.status,
    this.method,
    this.currency,
    this.providerName,
    this.transactionReference,
    this.confirmedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: json['id']?.toString(),
        organization: json['organization']?.toString(),
        amount: json['amount']?.toString(),
        booking: json['booking']?.toString(),
        cargoShipment: json['cargo_shipment']?.toString(),
        paymentNumber: json['payment_number']?.toString(),
        status: json['status']?.toString(),
        method: json['method']?.toString(),
        currency: json['currency']?.toString(),
        providerName: json['provider_name']?.toString(),
        transactionReference: json['transaction_reference']?.toString(),
        confirmedAt: json['confirmed_at']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class FareQuote {
  final String? id;
  final String? booking;
  final int? version;
  final String? status;
  final String? currency;
  final String? subtotal;
  final String? discountAmount;
  final String? taxAmount;
  final String? totalAmount;
  final String? expiresAt;
  final String? lockedAt;
  final List<FareQuoteLine>? lines;
  final String? createdAt;
  final String? updatedAt;

  FareQuote({
    this.id,
    this.booking,
    this.version,
    this.status,
    this.currency,
    this.subtotal,
    this.discountAmount,
    this.taxAmount,
    this.totalAmount,
    this.expiresAt,
    this.lockedAt,
    this.lines,
    this.createdAt,
    this.updatedAt,
  });

  factory FareQuote.fromJson(Map<String, dynamic> json) => FareQuote(
        id: json['id']?.toString(),
        booking: json['booking']?.toString(),
        version: json['version'] is int
            ? json['version'] as int
            : int.tryParse(json['version']?.toString() ?? ''),
        status: json['status']?.toString(),
        currency: json['currency']?.toString(),
        subtotal: json['subtotal']?.toString(),
        discountAmount: json['discount_amount']?.toString(),
        taxAmount: json['tax_amount']?.toString(),
        totalAmount: json['total_amount']?.toString(),
        expiresAt: json['expires_at']?.toString(),
        lockedAt: json['locked_at']?.toString(),
        lines: (json['lines'] as List?)
            ?.map((e) =>
                FareQuoteLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class FareQuoteLine {
  final String? id;
  final String? bookingPassenger;
  final String? fareRule;
  final String? baseFare;
  final String? discountAmount;
  final String? taxAmount;
  final String? totalAmount;
  final bool? overridden;

  FareQuoteLine({
    this.id,
    this.bookingPassenger,
    this.fareRule,
    this.baseFare,
    this.discountAmount,
    this.taxAmount,
    this.totalAmount,
    this.overridden,
  });

  factory FareQuoteLine.fromJson(Map<String, dynamic> json) => FareQuoteLine(
        id: json['id']?.toString(),
        bookingPassenger: json['booking_passenger']?.toString(),
        fareRule: json['fare_rule']?.toString(),
        baseFare: json['base_fare']?.toString(),
        discountAmount: json['discount_amount']?.toString(),
        taxAmount: json['tax_amount']?.toString(),
        totalAmount: json['total_amount']?.toString(),
        overridden: json['overridden'] as bool?,
      );
}

class Passenger {
  final String? id;
  final String? organizationId;
  final String? passengerCode;
  final String? fullName;
  final String? phoneNumber;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  // ⚠ MISMATCH FIX: Flutter accesses `code` (should be `passenger_code`),
  //   `first_name` + `last_name` (should be `full_name`), `email` (backend
  //   doesn't have an email field on Passenger).

  Passenger({
    this.id,
    this.organizationId,
    this.passengerCode,
    this.fullName,
    this.phoneNumber,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        id: json['id']?.toString(),
        organizationId: json['organization_id']?.toString(),
        passengerCode: json['passenger_code']?.toString(),
        fullName: json['full_name']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        status: json['status']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class CargoShipment {
  final String? id;
  final String? organization;
  final String? shipmentNumber;
  final String? trackingCode;
  final String? qrPayload;
  final String? sender;
  final String? receiver;
  final String? originTerminal;
  final String? destinationTerminal;
  final String? assignedTrip;
  final String? status;
  final String? itemCategory;
  final String? description;
  final int? pieceCount;
  final String? weightKg;
  final String? totalCharge;
  final String? currency;
  final String? acceptedAt;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  // ⚠ MISMATCH FIX: Flutter accesses `contact_name` — cargo has `sender`
  //   and `receiver` (UUIDs), not a string contact name. Flutter accesses
  //   `pickup_stop` and `dropoff_stop` — cargo has `origin_terminal` and
  //   `destination_terminal`.

  CargoShipment({
    this.id,
    this.organization,
    this.shipmentNumber,
    this.trackingCode,
    this.qrPayload,
    this.sender,
    this.receiver,
    this.originTerminal,
    this.destinationTerminal,
    this.assignedTrip,
    this.status,
    this.itemCategory,
    this.description,
    this.pieceCount,
    this.weightKg,
    this.totalCharge,
    this.currency,
    this.acceptedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CargoShipment.fromJson(Map<String, dynamic> json) => CargoShipment(
        id: json['id']?.toString(),
        organization: json['organization']?.toString(),
        shipmentNumber: json['shipment_number']?.toString(),
        trackingCode: json['tracking_code']?.toString(),
        qrPayload: json['qr_payload']?.toString(),
        sender: json['sender']?.toString(),
        receiver: json['receiver']?.toString(),
        originTerminal: json['origin_terminal']?.toString(),
        destinationTerminal: json['destination_terminal']?.toString(),
        assignedTrip: json['assigned_trip']?.toString(),
        status: json['status']?.toString(),
        itemCategory: json['item_category']?.toString(),
        description: json['description']?.toString(),
        pieceCount: json['piece_count'] is int
            ? json['piece_count'] as int
            : int.tryParse(json['piece_count']?.toString() ?? ''),
        weightKg: json['weight_kg']?.toString(),
        totalCharge: json['total_charge']?.toString(),
        currency: json['currency']?.toString(),
        acceptedAt: json['accepted_at']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

class VehicleDto {
  final String? id;
  final String? organization;
  final String? code;
  final String? fleetNumber;
  final String? registrationNumber;
  final String? brand;
  final String? model;
  final int? passengerCapacity;
  final String? status;

  VehicleDto({
    this.id,
    this.organization,
    this.code,
    this.fleetNumber,
    this.registrationNumber,
    this.brand,
    this.model,
    this.passengerCapacity,
    this.status,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) => VehicleDto(
        id: json['id']?.toString(),
        organization: json['organization']?.toString(),
        code: json['code']?.toString(),
        fleetNumber: json['fleet_number']?.toString(),
        registrationNumber: json['registration_number']?.toString(),
        brand: json['brand']?.toString(),
        model: json['model']?.toString(),
        passengerCapacity: json['passenger_capacity'] is int
            ? json['passenger_capacity'] as int
            : int.tryParse(json['passenger_capacity']?.toString() ?? ''),
        status: json['status']?.toString(),
      );
}

class OrganizationDto {
  final String? id;
  final String? displayName;
  final String? legalName;
  final String? tenantId;

  OrganizationDto({
    this.id,
    this.displayName,
    this.legalName,
    this.tenantId,
  });

  factory OrganizationDto.fromJson(Map<String, dynamic> json) =>
      OrganizationDto(
        id: json['id']?.toString(),
        displayName: json['display_name']?.toString(),
        legalName: json['legal_name']?.toString(),
        tenantId: json['tenant_id']?.toString(),
      );
}
