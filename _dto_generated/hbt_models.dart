// AUTO-GENERATED from OpenAPI spec. Do not edit manually.
// Generated: 2026-07-29

import 'dart:convert';


class Booking {
  Booking({
    required this.authorization_reference,
    required this.booking_number,
    required this.booking_type,
    required this.channel,
    this.client_request_id,
    required this.confirmed_at,
    required this.contact_name,
    required this.contact_phone,
    required this.created_at,
    required this.created_by,
    required this.customer_account,
    required this.dropoff_stop,
    this.expires_at,
    required this.id,
    this.notes,
    required this.organization_id,
    required this.passenger_items,
    required this.pickup_stop,
    required this.status,
    required this.trip,
    required this.updated_at,
  }) : super();

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingToJson(this);

  final String authorization_reference;
  final String booking_number;
  final dynamic /* BookingTypeEnum */ booking_type;
  final dynamic /* BookingChannel */ channel;
  final String? client_request_id;
  final String confirmed_at;
  final String contact_name;
  final String contact_phone;
  final String created_at;
  final String created_by;
  final String customer_account;
  final String dropoff_stop;
  final String? expires_at;
  final String id;
  final String? notes;
  final String organization_id;
  final List<dynamic /* BookingPassenger */> passenger_items;
  final String pickup_stop;
  final dynamic /*  */ status;
  final String trip;
  final String updated_at;
}


Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
        authorization_reference: json['authorization_reference']?.toString(),,
        booking_number: json['booking_number']?.toString(),,
        booking_type: json['booking_type'] as dynamic /* BookingTypeEnum */?,,
        channel: json['channel'] as dynamic /* BookingChannel */?,,
        client_request_id: json['client_request_id']?.toString(),,
        confirmed_at: json['confirmed_at']?.toString(),,
        contact_name: json['contact_name']?.toString(),,
        contact_phone: json['contact_phone']?.toString(),,
        created_at: json['created_at']?.toString(),,
        created_by: json['created_by']?.toString(),,
        customer_account: json['customer_account']?.toString(),,
        dropoff_stop: json['dropoff_stop']?.toString(),,
        expires_at: json['expires_at']?.toString(),,
        id: json['id']?.toString(),,
        notes: json['notes']?.toString(),,
        organization_id: json['organization_id']?.toString(),,
        passenger_items: (json['passenger_items'] as List?)?.map((e) => dynamic /* BookingPassenger */.fromJson(e as Map<String, dynamic>)).toList(),,
        pickup_stop: json['pickup_stop']?.toString(),,
        status: json['status'] as dynamic /*  */?,,
        trip: json['trip']?.toString(),,
        updated_at: json['updated_at']?.toString(),
  );

Map<String, dynamic> _$BookingToJson(Booking instance) => {
        'authorization_reference': authorization_reference,,
        'booking_number': booking_number,,
        'booking_type': booking_type,,
        'channel': channel,,
        'client_request_id': client_request_id,,
        'confirmed_at': confirmed_at,,
        'contact_name': contact_name,,
        'contact_phone': contact_phone,,
        'created_at': created_at,,
        'created_by': created_by,,
        'customer_account': customer_account,,
        'dropoff_stop': dropoff_stop,,
        'expires_at': expires_at,,
        'id': id,,
        'notes': notes,,
        'organization_id': organization_id,,
        'passenger_items': passenger_items?.map((e) => e is dynamic /* BookingPassenger */ ? e.toJson() : e).toList(),,
        'pickup_stop': pickup_stop,,
        'status': status,,
        'trip': trip,,
        'updated_at': updated_at,
  };

class CargoShipment {
  CargoShipment({
    this.acceptance_channel,
    this.acceptance_device_id,
    required this.accepted_at,
    required this.accepted_by,
    this.accepting_counter,
    required this.actual_delivery_at,
    this.additional_charge,
    required this.assigned_trip,
    this.charge_lines,
    this.client_request_id,
    required this.confirmed_paid_amount,
    required this.created_at,
    this.currency,
    required this.custody_events,
    this.declared_value,
    this.description,
    required this.destination_terminal,
    this.discount_amount,
    this.expected_pickup_date,
    this.height_cm,
    required this.id,
    this.inspection_notes,
    required this.item_category,
    this.items,
    this.length_cm,
    this.liability_acknowledged,
    this.manual_charge,
    this.manual_pricing_reason,
    this.notes,
    required this.organization,
    required this.origin_terminal,
    required this.outstanding_amount,
    this.packaging_condition,
    required this.payment_status,
    this.pickup_latitude,
    this.pickup_location_text,
    this.pickup_longitude,
    required this.piece_count,
    required this.pricing_breakdown,
    required this.pricing_method,
    required this.qr_payload,
    this.rate_per_kg,
    required this.receiver,
    required this.sender,
    required this.shipment_number,
    required this.status,
    required this.total_charge,
    required this.tracking_code,
    required this.updated_at,
    this.weight_kg,
    this.weight_source,
    this.width_cm,
  }) : super();

  factory CargoShipment.fromJson(Map<String, dynamic> json) => _$CargoShipmentFromJson(json);

  Map<String, dynamic> toJson() => _$CargoShipmentToJson(this);

  final dynamic /* AcceptanceChannelEnum */ acceptance_channel;
  final String? acceptance_device_id;
  final String accepted_at;
  final String accepted_by;
  final String? accepting_counter;
  final String actual_delivery_at;
  final String? additional_charge;
  final String assigned_trip;
  final List<dynamic /* CargoChargeLine */>?? charge_lines;
  final String? client_request_id;
  final String confirmed_paid_amount;
  final String created_at;
  final String? currency;
  final List<dynamic /* CargoCustodyEvent */> custody_events;
  final String? declared_value;
  final String? description;
  final String destination_terminal;
  final String? discount_amount;
  final String? expected_pickup_date;
  final String? height_cm;
  final String id;
  final String? inspection_notes;
  final String item_category;
  final List<dynamic /* CargoItem */>?? items;
  final String? length_cm;
  final bool? liability_acknowledged;
  final String? manual_charge;
  final String? manual_pricing_reason;
  final String? notes;
  final String organization;
  final String origin_terminal;
  final String outstanding_amount;
  final String? packaging_condition;
  final String payment_status;
  final String? pickup_latitude;
  final String? pickup_location_text;
  final String? pickup_longitude;
  final int piece_count;
  final Map<String, dynamic> pricing_breakdown;
  final dynamic /* PricingMethodEnum */ pricing_method;
  final String qr_payload;
  final String? rate_per_kg;
  final String receiver;
  final String sender;
  final String shipment_number;
  final dynamic /*  */ status;
  final String total_charge;
  final String tracking_code;
  final String updated_at;
  final String? weight_kg;
  final dynamic /*  */ weight_source;
  final String? width_cm;
}


CargoShipment _$CargoShipmentFromJson(Map<String, dynamic> json) => CargoShipment(
        acceptance_channel: json['acceptance_channel'] as dynamic /* AcceptanceChannelEnum */?,,
        acceptance_device_id: json['acceptance_device_id']?.toString(),,
        accepted_at: json['accepted_at']?.toString(),,
        accepted_by: json['accepted_by']?.toString(),,
        accepting_counter: json['accepting_counter']?.toString(),,
        actual_delivery_at: json['actual_delivery_at']?.toString(),,
        additional_charge: json['additional_charge']?.toString(),,
        assigned_trip: json['assigned_trip']?.toString(),,
        charge_lines: (json['charge_lines'] as List?)?.map((e) => dynamic /* CargoChargeLine */.fromJson(e as Map<String, dynamic>)).toList(),,
        client_request_id: json['client_request_id']?.toString(),,
        confirmed_paid_amount: json['confirmed_paid_amount']?.toString(),,
        created_at: json['created_at']?.toString(),,
        currency: json['currency']?.toString(),,
        custody_events: (json['custody_events'] as List?)?.map((e) => dynamic /* CargoCustodyEvent */.fromJson(e as Map<String, dynamic>)).toList(),,
        declared_value: json['declared_value']?.toString(),,
        description: json['description']?.toString(),,
        destination_terminal: json['destination_terminal']?.toString(),,
        discount_amount: json['discount_amount']?.toString(),,
        expected_pickup_date: json['expected_pickup_date']?.toString(),,
        height_cm: json['height_cm']?.toString(),,
        id: json['id']?.toString(),,
        inspection_notes: json['inspection_notes']?.toString(),,
        item_category: json['item_category']?.toString(),,
        items: (json['items'] as List?)?.map((e) => dynamic /* CargoItem */.fromJson(e as Map<String, dynamic>)).toList(),,
        length_cm: json['length_cm']?.toString(),,
        liability_acknowledged: json['liability_acknowledged'] as bool?,,
        manual_charge: json['manual_charge']?.toString(),,
        manual_pricing_reason: json['manual_pricing_reason']?.toString(),,
        notes: json['notes']?.toString(),,
        organization: json['organization']?.toString(),,
        origin_terminal: json['origin_terminal']?.toString(),,
        outstanding_amount: json['outstanding_amount']?.toString(),,
        packaging_condition: json['packaging_condition']?.toString(),,
        payment_status: json['payment_status']?.toString(),,
        pickup_latitude: json['pickup_latitude']?.toString(),,
        pickup_location_text: json['pickup_location_text']?.toString(),,
        pickup_longitude: json['pickup_longitude']?.toString(),,
        piece_count: json['piece_count'] is int ? json['piece_count'] as int : (json['piece_count'] != null ? int.tryParse(json['piece_count'].toString()) : null),,
        pricing_breakdown: json['pricing_breakdown'] as Map<String, dynamic>?,,
        pricing_method: json['pricing_method'] as dynamic /* PricingMethodEnum */?,,
        qr_payload: json['qr_payload']?.toString(),,
        rate_per_kg: json['rate_per_kg']?.toString(),,
        receiver: json['receiver']?.toString(),,
        sender: json['sender']?.toString(),,
        shipment_number: json['shipment_number']?.toString(),,
        status: json['status'] as dynamic /*  */?,,
        total_charge: json['total_charge']?.toString(),,
        tracking_code: json['tracking_code']?.toString(),,
        updated_at: json['updated_at']?.toString(),,
        weight_kg: json['weight_kg']?.toString(),,
        weight_source: json['weight_source'] as dynamic /*  */?,,
        width_cm: json['width_cm']?.toString(),
  );

Map<String, dynamic> _$CargoShipmentToJson(CargoShipment instance) => {
        'acceptance_channel': acceptance_channel,,
        'acceptance_device_id': acceptance_device_id,,
        'accepted_at': accepted_at,,
        'accepted_by': accepted_by,,
        'accepting_counter': accepting_counter,,
        'actual_delivery_at': actual_delivery_at,,
        'additional_charge': additional_charge,,
        'assigned_trip': assigned_trip,,
        'charge_lines': charge_lines?.map((e) => e is dynamic /* CargoChargeLine */ ? e.toJson() : e).toList(),,
        'client_request_id': client_request_id,,
        'confirmed_paid_amount': confirmed_paid_amount,,
        'created_at': created_at,,
        'currency': currency,,
        'custody_events': custody_events?.map((e) => e is dynamic /* CargoCustodyEvent */ ? e.toJson() : e).toList(),,
        'declared_value': declared_value,,
        'description': description,,
        'destination_terminal': destination_terminal,,
        'discount_amount': discount_amount,,
        'expected_pickup_date': expected_pickup_date,,
        'height_cm': height_cm,,
        'id': id,,
        'inspection_notes': inspection_notes,,
        'item_category': item_category,,
        'items': items?.map((e) => e is dynamic /* CargoItem */ ? e.toJson() : e).toList(),,
        'length_cm': length_cm,,
        'liability_acknowledged': liability_acknowledged,,
        'manual_charge': manual_charge,,
        'manual_pricing_reason': manual_pricing_reason,,
        'notes': notes,,
        'organization': organization,,
        'origin_terminal': origin_terminal,,
        'outstanding_amount': outstanding_amount,,
        'packaging_condition': packaging_condition,,
        'payment_status': payment_status,,
        'pickup_latitude': pickup_latitude,,
        'pickup_location_text': pickup_location_text,,
        'pickup_longitude': pickup_longitude,,
        'piece_count': piece_count,,
        'pricing_breakdown': pricing_breakdown,,
        'pricing_method': pricing_method,,
        'qr_payload': qr_payload,,
        'rate_per_kg': rate_per_kg,,
        'receiver': receiver,,
        'sender': sender,,
        'shipment_number': shipment_number,,
        'status': status,,
        'total_charge': total_charge,,
        'tracking_code': tracking_code,,
        'updated_at': updated_at,,
        'weight_kg': weight_kg,,
        'weight_source': weight_source,,
        'width_cm': width_cm,
  };

class FareQuote {
  FareQuote({
    this.applied_promotion,
    required this.booking,
    this.coupon_code,
    required this.created_at,
    required this.created_by,
    required this.currency,
    required this.discount_amount,
    required this.expires_at,
    required this.id,
    required this.lines,
    required this.locked_at,
    required this.snapshot,
    required this.status,
    required this.subtotal,
    required this.tax_amount,
    required this.total_amount,
    required this.updated_at,
    required this.version,
  }) : super();

  factory FareQuote.fromJson(Map<String, dynamic> json) => _$FareQuoteFromJson(json);

  Map<String, dynamic> toJson() => _$FareQuoteToJson(this);

  final String? applied_promotion;
  final String booking;
  final String? coupon_code;
  final String created_at;
  final String created_by;
  final String currency;
  final String discount_amount;
  final String expires_at;
  final String id;
  final List<dynamic /* FareQuoteLine */> lines;
  final String locked_at;
  final dynamic /*  */ snapshot;
  final dynamic /*  */ status;
  final String subtotal;
  final String tax_amount;
  final String total_amount;
  final String updated_at;
  final int version;
}


FareQuote _$FareQuoteFromJson(Map<String, dynamic> json) => FareQuote(
        applied_promotion: json['applied_promotion']?.toString(),,
        booking: json['booking']?.toString(),,
        coupon_code: json['coupon_code']?.toString(),,
        created_at: json['created_at']?.toString(),,
        created_by: json['created_by']?.toString(),,
        currency: json['currency']?.toString(),,
        discount_amount: json['discount_amount']?.toString(),,
        expires_at: json['expires_at']?.toString(),,
        id: json['id']?.toString(),,
        lines: (json['lines'] as List?)?.map((e) => dynamic /* FareQuoteLine */.fromJson(e as Map<String, dynamic>)).toList(),,
        locked_at: json['locked_at']?.toString(),,
        snapshot: json['snapshot'] as dynamic /*  */?,,
        status: json['status'] as dynamic /*  */?,,
        subtotal: json['subtotal']?.toString(),,
        tax_amount: json['tax_amount']?.toString(),,
        total_amount: json['total_amount']?.toString(),,
        updated_at: json['updated_at']?.toString(),,
        version: json['version'] is int ? json['version'] as int : (json['version'] != null ? int.tryParse(json['version'].toString()) : null),
  );

Map<String, dynamic> _$FareQuoteToJson(FareQuote instance) => {
        'applied_promotion': applied_promotion,,
        'booking': booking,,
        'coupon_code': coupon_code,,
        'created_at': created_at,,
        'created_by': created_by,,
        'currency': currency,,
        'discount_amount': discount_amount,,
        'expires_at': expires_at,,
        'id': id,,
        'lines': lines?.map((e) => e is dynamic /* FareQuoteLine */ ? e.toJson() : e).toList(),,
        'locked_at': locked_at,,
        'snapshot': snapshot,,
        'status': status,,
        'subtotal': subtotal,,
        'tax_amount': tax_amount,,
        'total_amount': total_amount,,
        'updated_at': updated_at,,
        'version': version,
  };

class Organization {
  Organization({
    this.contact_email,
    this.contact_phone,
    required this.display_name,
    required this.id,
    required this.legal_name,
    this.registration_number,
    this.status,
    required this.tenant_id,
  }) : super();

  factory Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizationToJson(this);

  final dynamic /*  */ contact_email;
  final String? contact_phone;
  final String display_name;
  final String id;
  final String legal_name;
  final String? registration_number;
  final dynamic /* OrganizationStatus */ status;
  final String tenant_id;
}


Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
        contact_email: json['contact_email'] as dynamic /*  */?,,
        contact_phone: json['contact_phone']?.toString(),,
        display_name: json['display_name']?.toString(),,
        id: json['id']?.toString(),,
        legal_name: json['legal_name']?.toString(),,
        registration_number: json['registration_number']?.toString(),,
        status: json['status'] as dynamic /* OrganizationStatus */?,,
        tenant_id: json['tenant_id']?.toString(),
  );

Map<String, dynamic> _$OrganizationToJson(Organization instance) => {
        'contact_email': contact_email,,
        'contact_phone': contact_phone,,
        'display_name': display_name,,
        'id': id,,
        'legal_name': legal_name,,
        'registration_number': registration_number,,
        'status': status,,
        'tenant_id': tenant_id,
  };

class Passenger {
  Passenger({
    this.account,
    this.category,
    required this.created_at,
    this.date_of_birth,
    this.emergency_contact_name,
    this.emergency_contact_phone,
    required this.full_name,
    this.full_name_myanmar,
    this.gender,
    required this.id,
    required this.managed_by,
    required this.masked_nrc,
    required this.masked_nrc_en,
    required this.nrc_verification_status,
    required this.organization_id,
    required this.passenger_code,
    this.passport_number,
    this.phone_number,
    this.special_assistance,
    this.status,
    this.travel_notes,
    required this.updated_at,
  }) : super();

  factory Passenger.fromJson(Map<String, dynamic> json) => _$PassengerFromJson(json);

  Map<String, dynamic> toJson() => _$PassengerToJson(this);

  final String? account;
  final dynamic /* PassengerCategory */ category;
  final String created_at;
  final String? date_of_birth;
  final String? emergency_contact_name;
  final String? emergency_contact_phone;
  final String full_name;
  final String? full_name_myanmar;
  final dynamic /* GenderEnum */ gender;
  final String id;
  final String managed_by;
  final String masked_nrc;
  final String masked_nrc_en;
  final String nrc_verification_status;
  final String organization_id;
  final String passenger_code;
  final String? passport_number;
  final String? phone_number;
  final dynamic /*  */ special_assistance;
  final dynamic /* PassengerStatus */ status;
  final String? travel_notes;
  final String updated_at;
}


Passenger _$PassengerFromJson(Map<String, dynamic> json) => Passenger(
        account: json['account']?.toString(),,
        category: json['category'] as dynamic /* PassengerCategory */?,,
        created_at: json['created_at']?.toString(),,
        date_of_birth: json['date_of_birth']?.toString(),,
        emergency_contact_name: json['emergency_contact_name']?.toString(),,
        emergency_contact_phone: json['emergency_contact_phone']?.toString(),,
        full_name: json['full_name']?.toString(),,
        full_name_myanmar: json['full_name_myanmar']?.toString(),,
        gender: json['gender'] as dynamic /* GenderEnum */?,,
        id: json['id']?.toString(),,
        managed_by: json['managed_by']?.toString(),,
        masked_nrc: json['masked_nrc']?.toString(),,
        masked_nrc_en: json['masked_nrc_en']?.toString(),,
        nrc_verification_status: json['nrc_verification_status']?.toString(),,
        organization_id: json['organization_id']?.toString(),,
        passenger_code: json['passenger_code']?.toString(),,
        passport_number: json['passport_number']?.toString(),,
        phone_number: json['phone_number']?.toString(),,
        special_assistance: json['special_assistance'] as dynamic /*  */?,,
        status: json['status'] as dynamic /* PassengerStatus */?,,
        travel_notes: json['travel_notes']?.toString(),,
        updated_at: json['updated_at']?.toString(),
  );

Map<String, dynamic> _$PassengerToJson(Passenger instance) => {
        'account': account,,
        'category': category,,
        'created_at': created_at,,
        'date_of_birth': date_of_birth,,
        'emergency_contact_name': emergency_contact_name,,
        'emergency_contact_phone': emergency_contact_phone,,
        'full_name': full_name,,
        'full_name_myanmar': full_name_myanmar,,
        'gender': gender,,
        'id': id,,
        'managed_by': managed_by,,
        'masked_nrc': masked_nrc,,
        'masked_nrc_en': masked_nrc_en,,
        'nrc_verification_status': nrc_verification_status,,
        'organization_id': organization_id,,
        'passenger_code': passenger_code,,
        'passport_number': passport_number,,
        'phone_number': phone_number,,
        'special_assistance': special_assistance,,
        'status': status,,
        'travel_notes': travel_notes,,
        'updated_at': updated_at,
  };

class Payment {
  Payment({
    required this.adapter,
    required this.code,
    required this.created_at,
    required this.created_by,
    this.credential_version,
    required this.environment,
    required this.id,
    required this.last_test_succeeded,
    required this.last_tested_at,
    required this.merchant_id,
    this.status,
    required this.updated_at,
  }) : super();

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  final String adapter;
  final String code;
  final String created_at;
  final String created_by;
  final int? credential_version;
  final dynamic /* EnvironmentEnum */ environment;
  final String id;
  final bool last_test_succeeded;
  final String last_tested_at;
  final String merchant_id;
  final dynamic /* PaymentConnectorStatusEnum */ status;
  final String updated_at;
}


Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
        adapter: json['adapter']?.toString(),,
        code: json['code']?.toString(),,
        created_at: json['created_at']?.toString(),,
        created_by: json['created_by']?.toString(),,
        credential_version: json['credential_version'] is int ? json['credential_version'] as int : (json['credential_version'] != null ? int.tryParse(json['credential_version'].toString()) : null),,
        environment: json['environment'] as dynamic /* EnvironmentEnum */?,,
        id: json['id']?.toString(),,
        last_test_succeeded: json['last_test_succeeded'] as bool?,,
        last_tested_at: json['last_tested_at']?.toString(),,
        merchant_id: json['merchant_id']?.toString(),,
        status: json['status'] as dynamic /* PaymentConnectorStatusEnum */?,,
        updated_at: json['updated_at']?.toString(),
  );

Map<String, dynamic> _$PaymentToJson(Payment instance) => {
        'adapter': adapter,,
        'code': code,,
        'created_at': created_at,,
        'created_by': created_by,,
        'credential_version': credential_version,,
        'environment': environment,,
        'id': id,,
        'last_test_succeeded': last_test_succeeded,,
        'last_tested_at': last_tested_at,,
        'merchant_id': merchant_id,,
        'status': status,,
        'updated_at': updated_at,
  };

class Route {
  Route({
    required this.code,
    required this.created_at,
    this.estimated_distance_km,
    this.estimated_duration_minutes,
    required this.id,
    required this.name,
    this.operating_region,
    required this.organization_id,
    this.status,
    required this.stop_count,
    required this.updated_at,
  }) : super();

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);

  Map<String, dynamic> toJson() => _$RouteToJson(this);

  final String code;
  final String created_at;
  final String? estimated_distance_km;
  final int? estimated_duration_minutes;
  final String id;
  final String name;
  final String? operating_region;
  final String organization_id;
  final dynamic /* RouteStatusEnum */ status;
  final int stop_count;
  final String updated_at;
}


Route _$RouteFromJson(Map<String, dynamic> json) => Route(
        code: json['code']?.toString(),,
        created_at: json['created_at']?.toString(),,
        estimated_distance_km: json['estimated_distance_km']?.toString(),,
        estimated_duration_minutes: json['estimated_duration_minutes'] is int ? json['estimated_duration_minutes'] as int : (json['estimated_duration_minutes'] != null ? int.tryParse(json['estimated_duration_minutes'].toString()) : null),,
        id: json['id']?.toString(),,
        name: json['name']?.toString(),,
        operating_region: json['operating_region']?.toString(),,
        organization_id: json['organization_id']?.toString(),,
        status: json['status'] as dynamic /* RouteStatusEnum */?,,
        stop_count: json['stop_count'] is int ? json['stop_count'] as int : (json['stop_count'] != null ? int.tryParse(json['stop_count'].toString()) : null),,
        updated_at: json['updated_at']?.toString(),
  );

Map<String, dynamic> _$RouteToJson(Route instance) => {
        'code': code,,
        'created_at': created_at,,
        'estimated_distance_km': estimated_distance_km,,
        'estimated_duration_minutes': estimated_duration_minutes,,
        'id': id,,
        'name': name,,
        'operating_region': operating_region,,
        'organization_id': organization_id,,
        'status': status,,
        'stop_count': stop_count,,
        'updated_at': updated_at,
  };

class Seat {
  Seat({
    required this.bookable_seat_count,
    required this.code,
    required this.column_count,
    required this.created_at,
    this.deck_count,
    required this.id,
    required this.layout_type,
    required this.name,
    required this.organization,
    required this.organization_id,
    required this.row_count,
    this.status,
    required this.updated_at,
    this.version,
  }) : super();

  factory Seat.fromJson(Map<String, dynamic> json) => _$SeatFromJson(json);

  Map<String, dynamic> toJson() => _$SeatToJson(this);

  final int bookable_seat_count;
  final String code;
  final int column_count;
  final String created_at;
  final int? deck_count;
  final String id;
  final dynamic /* LayoutTypeEnum */ layout_type;
  final String name;
  final String organization;
  final String organization_id;
  final int row_count;
  final dynamic /* SeatLayoutStatusEnum */ status;
  final String updated_at;
  final int? version;
}


Seat _$SeatFromJson(Map<String, dynamic> json) => Seat(
        bookable_seat_count: json['bookable_seat_count'] is int ? json['bookable_seat_count'] as int : (json['bookable_seat_count'] != null ? int.tryParse(json['bookable_seat_count'].toString()) : null),,
        code: json['code']?.toString(),,
        column_count: json['column_count'] is int ? json['column_count'] as int : (json['column_count'] != null ? int.tryParse(json['column_count'].toString()) : null),,
        created_at: json['created_at']?.toString(),,
        deck_count: json['deck_count'] is int ? json['deck_count'] as int : (json['deck_count'] != null ? int.tryParse(json['deck_count'].toString()) : null),,
        id: json['id']?.toString(),,
        layout_type: json['layout_type'] as dynamic /* LayoutTypeEnum */?,,
        name: json['name']?.toString(),,
        organization: json['organization']?.toString(),,
        organization_id: json['organization_id']?.toString(),,
        row_count: json['row_count'] is int ? json['row_count'] as int : (json['row_count'] != null ? int.tryParse(json['row_count'].toString()) : null),,
        status: json['status'] as dynamic /* SeatLayoutStatusEnum */?,,
        updated_at: json['updated_at']?.toString(),,
        version: json['version'] is int ? json['version'] as int : (json['version'] != null ? int.tryParse(json['version'].toString()) : null),
  );

Map<String, dynamic> _$SeatToJson(Seat instance) => {
        'bookable_seat_count': bookable_seat_count,,
        'code': code,,
        'column_count': column_count,,
        'created_at': created_at,,
        'deck_count': deck_count,,
        'id': id,,
        'layout_type': layout_type,,
        'name': name,,
        'organization': organization,,
        'organization_id': organization_id,,
        'row_count': row_count,,
        'status': status,,
        'updated_at': updated_at,,
        'version': version,
  };

class Stop {
  Stop({
    ,
  }) : super();

  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);

  Map<String, dynamic> toJson() => _$StopToJson(this);


}


Stop _$StopFromJson(Map<String, dynamic> json) => Stop(
    
  );

Map<String, dynamic> _$StopToJson(Stop instance) => {
    
  };

class Terminal {
  Terminal({
    required this.branch,
    required this.code,
    required this.created_at,
    required this.display_name,
    required this.id,
    this.local_contact_phone,
    this.operating_hours,
    required this.organization_id,
    this.status,
    required this.terminal,
    required this.terminal_detail,
    required this.updated_at,
  }) : super();

  factory Terminal.fromJson(Map<String, dynamic> json) => _$TerminalFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalToJson(this);

  final String branch;
  final String code;
  final String created_at;
  final String display_name;
  final String id;
  final String? local_contact_phone;
  final dynamic /*  */ operating_hours;
  final String organization_id;
  final dynamic /* LocationOperationalStatus */ status;
  final String terminal;
  final dynamic /*  */ terminal_detail;
  final String updated_at;
}


Terminal _$TerminalFromJson(Map<String, dynamic> json) => Terminal(
        branch: json['branch']?.toString(),,
        code: json['code']?.toString(),,
        created_at: json['created_at']?.toString(),,
        display_name: json['display_name']?.toString(),,
        id: json['id']?.toString(),,
        local_contact_phone: json['local_contact_phone']?.toString(),,
        operating_hours: json['operating_hours'] as dynamic /*  */?,,
        organization_id: json['organization_id']?.toString(),,
        status: json['status'] as dynamic /* LocationOperationalStatus */?,,
        terminal: json['terminal']?.toString(),,
        terminal_detail: json['terminal_detail'] as dynamic /*  */?,,
        updated_at: json['updated_at']?.toString(),
  );

Map<String, dynamic> _$TerminalToJson(Terminal instance) => {
        'branch': branch,,
        'code': code,,
        'created_at': created_at,,
        'display_name': display_name,,
        'id': id,,
        'local_contact_phone': local_contact_phone,,
        'operating_hours': operating_hours,,
        'organization_id': organization_id,,
        'status': status,,
        'terminal': terminal,,
        'terminal_detail': terminal_detail,,
        'updated_at': updated_at,
  };

class Ticket {
  Ticket({
    required this.booking,
    required this.booking_passenger,
    required this.created_at,
    required this.currency,
    required this.discount_amount,
    required this.fare_amount,
    required this.id,
    required this.issued_at,
    required this.issued_by,
    required this.issuing_channel,
    required this.organization_id,
    required this.passenger,
    required this.passenger_name,
    required this.planned_departure_at,
    required this.qr_payload,
    required this.replacement_of,
    required this.revocation_reason,
    required this.revoked_at,
    required this.revoked_by,
    required this.seat_identifier,
    required this.seat_position,
    required this.service_charge,
    required this.status,
    required this.tax_amount,
    required this.ticket_number,
    required this.ticket_type,
    required this.total_amount,
    required this.trip,
    required this.trip_number,
    required this.updated_at,
    required this.validation_code,
  }) : super();

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);

  Map<String, dynamic> toJson() => _$TicketToJson(this);

  final String booking;
  final String booking_passenger;
  final String created_at;
  final String currency;
  final String discount_amount;
  final String fare_amount;
  final String id;
  final String issued_at;
  final String issued_by;
  final String issuing_channel;
  final String organization_id;
  final String passenger;
  final String passenger_name;
  final String planned_departure_at;
  final String qr_payload;
  final String replacement_of;
  final String revocation_reason;
  final String revoked_at;
  final String revoked_by;
  final String seat_identifier;
  final String seat_position;
  final String service_charge;
  final dynamic /*  */ status;
  final String tax_amount;
  final String ticket_number;
  final dynamic /*  */ ticket_type;
  final String total_amount;
  final String trip;
  final String trip_number;
  final String updated_at;
  final String validation_code;
}


Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
        booking: json['booking']?.toString(),,
        booking_passenger: json['booking_passenger']?.toString(),,
        created_at: json['created_at']?.toString(),,
        currency: json['currency']?.toString(),,
        discount_amount: json['discount_amount']?.toString(),,
        fare_amount: json['fare_amount']?.toString(),,
        id: json['id']?.toString(),,
        issued_at: json['issued_at']?.toString(),,
        issued_by: json['issued_by']?.toString(),,
        issuing_channel: json['issuing_channel']?.toString(),,
        organization_id: json['organization_id']?.toString(),,
        passenger: json['passenger']?.toString(),,
        passenger_name: json['passenger_name']?.toString(),,
        planned_departure_at: json['planned_departure_at']?.toString(),,
        qr_payload: json['qr_payload']?.toString(),,
        replacement_of: json['replacement_of']?.toString(),,
        revocation_reason: json['revocation_reason']?.toString(),,
        revoked_at: json['revoked_at']?.toString(),,
        revoked_by: json['revoked_by']?.toString(),,
        seat_identifier: json['seat_identifier']?.toString(),,
        seat_position: json['seat_position']?.toString(),,
        service_charge: json['service_charge']?.toString(),,
        status: json['status'] as dynamic /*  */?,,
        tax_amount: json['tax_amount']?.toString(),,
        ticket_number: json['ticket_number']?.toString(),,
        ticket_type: json['ticket_type'] as dynamic /*  */?,,
        total_amount: json['total_amount']?.toString(),,
        trip: json['trip']?.toString(),,
        trip_number: json['trip_number']?.toString(),,
        updated_at: json['updated_at']?.toString(),,
        validation_code: json['validation_code']?.toString(),
  );

Map<String, dynamic> _$TicketToJson(Ticket instance) => {
        'booking': booking,,
        'booking_passenger': booking_passenger,,
        'created_at': created_at,,
        'currency': currency,,
        'discount_amount': discount_amount,,
        'fare_amount': fare_amount,,
        'id': id,,
        'issued_at': issued_at,,
        'issued_by': issued_by,,
        'issuing_channel': issuing_channel,,
        'organization_id': organization_id,,
        'passenger': passenger,,
        'passenger_name': passenger_name,,
        'planned_departure_at': planned_departure_at,,
        'qr_payload': qr_payload,,
        'replacement_of': replacement_of,,
        'revocation_reason': revocation_reason,,
        'revoked_at': revoked_at,,
        'revoked_by': revoked_by,,
        'seat_identifier': seat_identifier,,
        'seat_position': seat_position,,
        'service_charge': service_charge,,
        'status': status,,
        'tax_amount': tax_amount,,
        'ticket_number': ticket_number,,
        'ticket_type': ticket_type,,
        'total_amount': total_amount,,
        'trip': trip,,
        'trip_number': trip_number,,
        'updated_at': updated_at,,
        'validation_code': validation_code,
  };

class Trip {
  Trip({
    required this.arrived_at,
    required this.boarding_started_at,
    required this.conductor,
    required this.created_at,
    required this.current_stop,
    required this.departed_at,
    required this.driver,
    required this.id,
    this.operational_notes,
    required this.organization_id,
    required this.planned_arrival_at,
    required this.planned_departure_at,
    required this.resources_complete,
    required this.route,
    required this.route_snapshot,
    this.schedule,
    required this.schedule_snapshot,
    required this.seat_layout,
    required this.seat_layout_snapshot,
    required this.service_date,
    required this.status,
    required this.trip_number,
    required this.updated_at,
    required this.vehicle,
  }) : super();

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  Map<String, dynamic> toJson() => _$TripToJson(this);

  final String arrived_at;
  final String boarding_started_at;
  final String conductor;
  final String created_at;
  final String current_stop;
  final String departed_at;
  final String driver;
  final String id;
  final String? operational_notes;
  final String organization_id;
  final String planned_arrival_at;
  final String planned_departure_at;
  final bool resources_complete;
  final String route;
  final dynamic /*  */ route_snapshot;
  final String? schedule;
  final dynamic /*  */ schedule_snapshot;
  final String seat_layout;
  final dynamic /*  */ seat_layout_snapshot;
  final String service_date;
  final dynamic /*  */ status;
  final String trip_number;
  final String updated_at;
  final String vehicle;
}


Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
        arrived_at: json['arrived_at']?.toString(),,
        boarding_started_at: json['boarding_started_at']?.toString(),,
        conductor: json['conductor']?.toString(),,
        created_at: json['created_at']?.toString(),,
        current_stop: json['current_stop']?.toString(),,
        departed_at: json['departed_at']?.toString(),,
        driver: json['driver']?.toString(),,
        id: json['id']?.toString(),,
        operational_notes: json['operational_notes']?.toString(),,
        organization_id: json['organization_id']?.toString(),,
        planned_arrival_at: json['planned_arrival_at']?.toString(),,
        planned_departure_at: json['planned_departure_at']?.toString(),,
        resources_complete: json['resources_complete'] as bool?,,
        route: json['route']?.toString(),,
        route_snapshot: json['route_snapshot'] as dynamic /*  */?,,
        schedule: json['schedule']?.toString(),,
        schedule_snapshot: json['schedule_snapshot'] as dynamic /*  */?,,
        seat_layout: json['seat_layout']?.toString(),,
        seat_layout_snapshot: json['seat_layout_snapshot'] as dynamic /*  */?,,
        service_date: json['service_date']?.toString(),,
        status: json['status'] as dynamic /*  */?,,
        trip_number: json['trip_number']?.toString(),,
        updated_at: json['updated_at']?.toString(),,
        vehicle: json['vehicle']?.toString(),
  );

Map<String, dynamic> _$TripToJson(Trip instance) => {
        'arrived_at': arrived_at,,
        'boarding_started_at': boarding_started_at,,
        'conductor': conductor,,
        'created_at': created_at,,
        'current_stop': current_stop,,
        'departed_at': departed_at,,
        'driver': driver,,
        'id': id,,
        'operational_notes': operational_notes,,
        'organization_id': organization_id,,
        'planned_arrival_at': planned_arrival_at,,
        'planned_departure_at': planned_departure_at,,
        'resources_complete': resources_complete,,
        'route': route,,
        'route_snapshot': route_snapshot,,
        'schedule': schedule,,
        'schedule_snapshot': schedule_snapshot,,
        'seat_layout': seat_layout,,
        'seat_layout_snapshot': seat_layout_snapshot,,
        'service_date': service_date,,
        'status': status,,
        'trip_number': trip_number,,
        'updated_at': updated_at,,
        'vehicle': vehicle,
  };

class Vehicle {
  Vehicle({
    this.accessible,
    this.air_conditioned,
    required this.branch,
    this.brand,
    this.cargo_supported,
    this.cargo_weight_capacity_kg,
    required this.category,
    required this.code,
    this.color,
    required this.created_at,
    required this.fleet_number,
    this.fuel_type,
    this.gps_available,
    required this.id,
    this.manufacturing_year,
    this.model,
    required this.organization,
    required this.organization_id,
    this.passenger_capacity,
    required this.registration_number,
    this.status,
    required this.updated_at,
    this.wifi_available,
  }) : super();

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  final bool? accessible;
  final bool? air_conditioned;
  final String branch;
  final String? brand;
  final bool? cargo_supported;
  final String? cargo_weight_capacity_kg;
  final dynamic /* VehicleCategoryEnum */ category;
  final String code;
  final String? color;
  final String created_at;
  final String fleet_number;
  final String? fuel_type;
  final bool? gps_available;
  final String id;
  final int? manufacturing_year;
  final String? model;
  final String organization;
  final String organization_id;
  final int? passenger_capacity;
  final String registration_number;
  final dynamic /* VehicleStatusEnum */ status;
  final String updated_at;
  final bool? wifi_available;
}


Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
        accessible: json['accessible'] as bool?,,
        air_conditioned: json['air_conditioned'] as bool?,,
        branch: json['branch']?.toString(),,
        brand: json['brand']?.toString(),,
        cargo_supported: json['cargo_supported'] as bool?,,
        cargo_weight_capacity_kg: json['cargo_weight_capacity_kg']?.toString(),,
        category: json['category'] as dynamic /* VehicleCategoryEnum */?,,
        code: json['code']?.toString(),,
        color: json['color']?.toString(),,
        created_at: json['created_at']?.toString(),,
        fleet_number: json['fleet_number']?.toString(),,
        fuel_type: json['fuel_type']?.toString(),,
        gps_available: json['gps_available'] as bool?,,
        id: json['id']?.toString(),,
        manufacturing_year: json['manufacturing_year'] is int ? json['manufacturing_year'] as int : (json['manufacturing_year'] != null ? int.tryParse(json['manufacturing_year'].toString()) : null),,
        model: json['model']?.toString(),,
        organization: json['organization']?.toString(),,
        organization_id: json['organization_id']?.toString(),,
        passenger_capacity: json['passenger_capacity'] is int ? json['passenger_capacity'] as int : (json['passenger_capacity'] != null ? int.tryParse(json['passenger_capacity'].toString()) : null),,
        registration_number: json['registration_number']?.toString(),,
        status: json['status'] as dynamic /* VehicleStatusEnum */?,,
        updated_at: json['updated_at']?.toString(),,
        wifi_available: json['wifi_available'] as bool?,
  );

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => {
        'accessible': accessible,,
        'air_conditioned': air_conditioned,,
        'branch': branch,,
        'brand': brand,,
        'cargo_supported': cargo_supported,,
        'cargo_weight_capacity_kg': cargo_weight_capacity_kg,,
        'category': category,,
        'code': code,,
        'color': color,,
        'created_at': created_at,,
        'fleet_number': fleet_number,,
        'fuel_type': fuel_type,,
        'gps_available': gps_available,,
        'id': id,,
        'manufacturing_year': manufacturing_year,,
        'model': model,,
        'organization': organization,,
        'organization_id': organization_id,,
        'passenger_capacity': passenger_capacity,,
        'registration_number': registration_number,,
        'status': status,,
        'updated_at': updated_at,,
        'wifi_available': wifi_available,
  };
