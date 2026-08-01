"""Parse OpenAPI spec and Django serializers, compare, generate Flutter DTOs."""
import yaml, json, os, re, ast, sys

# Fix encoding for Windows console
if hasattr(sys.stdout, 'buffer'):
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BACKEND = r"F:\hbt\backend"
OPENAPI = os.path.join(BACKEND, "openapi.yaml")
SERIALIZERS_DIR = os.path.join(BACKEND, "apps")
OUTPUT_DIR = r"F:\hbt\_dto_generated"

# ── 1. Parse OpenAPI schemas ──────────────────────────────────────
with open(OPENAPI, "r", encoding="utf-8") as f:
    spec = yaml.safe_load(f)

schemas = spec.get("components", {}).get("schemas", {})
print(f"OpenAPI schemas: {len(schemas)}")

# Map schema -> { field -> { type, required } }
openapi_schemas = {}
for name, schema in schemas.items():
    props = schema.get("properties", {})
    fields = {}
    required = set(schema.get("required", []))
    for pname, pinfo in props.items():
        ptype = pinfo.get("type", "")
        ref = pinfo.get("$ref", "")
        if ref:
            ptype = ref.split("/")[-1]
        elif "items" in pinfo:
            iref = pinfo["items"].get("$ref", "")
            ptype = f"List[{iref.split('/')[-1]}]" if iref else f"List[{pinfo['items'].get('type','?')}]"
        elif ptype == "array" and "items" in pinfo:
            iref = pinfo["items"].get("$ref", "")
            ptype = f"List[{iref.split('/')[-1]}]" if iref else "List[?]"
        fields[pname] = {"type": ptype, "required": pname in required}
    openapi_schemas[name] = fields

# Print key schemas for the Flutter domains
target_keywords = ["Trip", "Route", "Booking", "Ticket", "Payment", 
                   "Fare", "Quote", "Passenger", "Traveler", "Shipment",
                   "Cargo", "Stop", "Terminal", "Vehicle", "Bus", "Seat",
                   "Organization", "Device", "Sync", "CargoQr", "Scanner"]

for name, fields in sorted(openapi_schemas.items()):
    for kw in target_keywords:
        if kw.lower() in name.lower():
            print(f"\n=== OpenAPI: {name} ===")
            for pname, info in sorted(fields.items()):
                req = "REQ" if info["required"] else "opt"
                print(f"  {pname}: {info['type']} ({req})")
            break

# ── 2. Parse Django serializers ──────────────────────────────────
def parse_serializer_fields(content, filepath):
    """Extract field definitions from a serializer file."""
    fields = {}
    # Match: class XSerializer(...):  field = serializers.Y(...)
    # Match: field = serializers.YField(...)
    field_pattern = re.compile(
        r'^\s*(\w+)\s*=\s*serializers\.(\w+)\((.*)\)$', re.MULTILINE
    )
    for match in field_pattern.finditer(content):
        fname, ftype, fargs = match.groups()
        fields[fname] = {"type": ftype, "args": fargs}
    
    # Also match Meta class fields
    meta = re.search(r'class\s+Meta:.*?fields\s*=\s*\[(.*?)\]',
                     content, re.DOTALL)
    meta_fields = []
    if meta:
        meta_fields = [m.strip(" '\"") for m in meta.group(1).split(",") if m.strip()]
    
    # Get model name
    model_match = re.search(r'model\s*=\s*(\w+)', content)
    model_name = model_match.group(1) if model_match else None
    
    return fields, meta_fields, model_name

serializer_files = []
for root, dirs, files in os.walk(SERIALIZERS_DIR):
    for f in files:
        if f == "serializers.py":
            serializer_files.append(os.path.join(root, f))

all_serializer_data = []
print(f"\nDjango serializer files: {len(serializer_files)}")

for fpath in sorted(serializer_files):
    app_name = os.path.basename(os.path.dirname(fpath))
    with open(fpath, "r", encoding="utf-8") as f:
        content = f.read()
    
    fields, meta_fields, model_name = parse_serializer_fields(content, fpath)
    all_serializer_data.append({
        "app": app_name,
        "file": fpath,
        "model": model_name,
        "fields": fields,
        "meta_fields": meta_fields,
    })
    
    if fields:
        print(f"\n  {app_name}/{model_name or '?'} ({len(fields)} fields)")
        for fname, finfo in sorted(fields.items()):
            print(f"    {fname}: {finfo['type']}")

# ── 3. Compare ────────────────────────────────────────────────────
print("\n\n=== FIELD-BY-FIELD COMPARISON ===")
print("Comparing OpenAPI schemas vs Flutter field usage + Django serializers")

# Flutter field usage from grep earlier
flutter_fields_by_context = {
    "Trip": ["id", "trip_number", "planned_departure_at", "planned_arrival_at",
             "status", "route", "route_id", "route_snapshot", "vehicle", "vehicle_id",
             "driver", "driver_id", "conductor", "conductor_id", "organization",
             "organization_name", "service_date", "pickup_stop", "dropoff_stop",
             "stops", "stop_count", "seats", "operational_notes",
             "estimated_distance_km", "estimated_duration_minutes", "operating_region"],
    "Route": ["id", "name", "code", "status", "description", "terminal", "city", "stops", "color"],
    "Booking": ["id", "booking_number", "booking_reference", "status", "trip", "trip_id",
                "passenger_name", "seats", "seat_identifier", "pickup_stop", "dropoff_stop",
                "total_amount", "base_fare", "tax_amount", "discount_amount", "currency", "notes"],
    "Ticket": ["id", "ticket_number", "status", "booking", "booking_id", "passenger_name",
               "seat_identifier", "trip", "route"],
    "Payment": ["id", "payment_number", "status", "amount", "total_charge", "currency",
                "provider_name", "account_label"],
    "FareQuote": ["id", "base_fare", "total_amount", "tax_amount", "discount_amount", "currency", "seats"],
    "Passenger": ["id", "code", "first_name", "last_name", "full_name", "email", "phone_number"],
    "CargoShipment": ["id", "shipment_number", "status", "item_category", "piece_count",
                      "weight_kg", "description", "contact_name", "pickup_stop", "dropoff_stop"],
    "Stop": ["id", "name", "sequence", "city", "terminal"],
    "Vehicle": ["id", "name", "code", "capacity", "identifier"],
    "Seat": ["id", "identifier", "available"],
    "Organization": ["id", "name", "code"],
}

for context, flutter_fields in sorted(flutter_fields_by_context.items()):
    print(f"\n--- {context} ---")
    print(f"  Flutter uses: {', '.join(sorted(flutter_fields))}")
    
    # Find matching OpenAPI schemas
    matching_openapi = {}
    for sname, sfields in openapi_schemas.items():
        if context.lower().replace("farequote","fare") in sname.lower():
            matching_openapi[sname] = sfields
    
    if matching_openapi:
        for sname, sfields in matching_openapi.items():
            oapi_fields = set(sfields.keys())
            flutter_set = set(flutter_fields)
            missing_in_flutter = oapi_fields - flutter_set
            missing_in_oapi = flutter_set - oapi_fields
            if missing_in_flutter:
                print(f"  [OVERSIGHT-OpenAPI-has] OpenAPI [{sname}] has but Flutter lacks: {missing_in_flutter}")
            if missing_in_oapi:
                print(f"  [OVERSIGHT-Flutter-has] Flutter uses but not in OpenAPI [{sname}]: {missing_in_oapi}")
            if not missing_in_flutter and not missing_in_oapi:
                print(f"  ✅ Matches OpenAPI [{sname}]")
    else:
        print(f"  ⚠ No matching OpenAPI schema found")


# ── 4. Generate Flutter DTOs ──────────────────────────────────────
os.makedirs(OUTPUT_DIR, exist_ok=True)

DTO_TEMPLATE = """// AUTO-GENERATED from OpenAPI spec. Do not edit manually.
// Generated: {date}

import 'dart:convert';

{sections}
"""

CLASS_TEMPLATE = """
class {name} {{
  {constructor}

  factory {name}.fromJson(Map<String, dynamic> json) => _${name}FromJson(json);

  Map<String, dynamic> toJson() => _${name}ToJson(this);

{fields}
}}

{from_json_func}
{to_json_func}
"""

def openapi_type_to_dart(openapi_type, required):
    """Map OpenAPI type strings to Dart types."""
    base = openapi_type
    nullable = "?" if not required else ""
    
    mapping = {
        "string": f"String{nullable}",
        "integer": f"int{nullable}",
        "number": f"double{nullable}",
        "boolean": f"bool{nullable}",
        "object": f"Map<String, dynamic>{nullable}",
    }
    
    if base.startswith("List["):
        inner = base[5:-1]
        inner_dart = openapi_type_to_dart(inner, True)
        return f"List<{inner_dart}>{nullable}?" if not required else f"List<{inner_dart}>"
    
    return mapping.get(base, f"dynamic /* {base} */")

# Generate DTO for key Flutter domains
domain_to_openapi = {
    "Trip": "Trip", "TripDetail": "TripDetail", "Route": "Route",
    "Booking": "Booking", "Ticket": "Ticket",
    "Payment": "Payment", "FareQuote": "FareQuote",
    "Passenger": "Passenger", "CargoShipment": "CargoShipment",
    "Stop": "Stop", "Terminal": "Terminal", "Vehicle": "Vehicle",
    "Seat": "Seat", "Organization": "Organization",
}

generated = []

for dart_name, oapi_name in sorted(domain_to_openapi.items()):
    # Find best matching schema
    best = None
    best_score = 0
    for sname, sfields in openapi_schemas.items():
        if oapi_name.lower() in sname.lower():
            # Prefer exact match
            score = 10 if sname.lower() == oapi_name.lower() else 5
            if "List" not in sname and "Request" not in sname:
                score += 3
            if sname.lower().startswith(oapi_name.lower()):
                score += 2
            if score > best_score:
                best_score = score
                best = (sname, sfields)
    
    if not best:
        print(f"  ⚠ Cannot generate DTO for {dart_name}: no OpenAPI schema found")
        continue
    
    sname, sfields = best
    print(f"  Generating {dart_name}DTO from {sname} ({len(sfields)} fields)")
    
    # Build field list
    fields_code = []
    constructor_args = []
    constructor_assignments = []
    from_json_lines = []
    to_json_lines = []
    
    field_defs = []
    
    for pname, pinfo in sorted(sfields.items()):
        dart_type = openapi_type_to_dart(pinfo["type"], pinfo["required"])
        is_required = pinfo["required"]
        
        fields_code.append(f"  final {dart_type} {pname};")
        
        if is_required:
            constructor_args.append(f"required this.{pname}")
        else:
            constructor_args.append(f"this.{pname}")
        
        # fromJson
        json_key = pname
        mapping = {
            "String": "json['{key}']?.toString()",
            "int": "json['{key}'] is int ? json['{key}'] as int : (json['{key}'] != null ? int.tryParse(json['{key}'].toString()) : null)",
            "double": "json['{key}'] is double ? json['{key}'] as double : (json['{key}'] != null ? double.tryParse(json['{key}'].toString()) : null)",
            "bool": "json['{key}'] as bool?",
            "Map<String, dynamic>": "json['{key}'] as Map<String, dynamic>?",
        }
        
        base_dart_type = dart_type.replace("?", "").split("<")[0]
        
        if dart_type.startswith("List<"):
            inner_type = dart_type.split("<")[1].rstrip(">?").replace("?", "")
            if inner_type in ["String", "int", "double", "bool", "dynamic"]:
                from_json_lines.append(f"    {pname}: (json['{json_key}'] as List?)?.cast<{inner_type}>(),")
            else:
                from_json_lines.append(f"    {pname}: (json['{json_key}'] as List?)?.map((e) => {inner_type}.fromJson(e as Map<String, dynamic>)).toList(),")
            to_json_lines.append(f"    '{json_key}': {pname}?.map((e) => e is {inner_type} ? e.toJson() : e).toList(),")
        elif dart_type.startswith("Map<"):
            from_json_lines.append(f"    {pname}: json['{json_key}'] as Map<String, dynamic>?,")
            to_json_lines.append(f"    '{json_key}': {pname},")
        elif base_dart_type in mapping:
            template = mapping[base_dart_type]
            from_json_lines.append(f"    {pname}: {template.format(key=json_key)},")
            to_json_lines.append(f"    '{json_key}': {pname},")
        else:
            from_json_lines.append(f"    {pname}: json['{json_key}'] as {base_dart_type}?,")
            to_json_lines.append(f"    '{json_key}': {pname},")

    constructor = "{name}({{\n    {args},\n  }}) : super();".format(
        name=dart_name,
        args=",\n    ".join(constructor_args)
    )
    
    fields_str = "\n".join(fields_code)
    
    from_json_str = """
{dtype} _${name}FromJson(Map<String, dynamic> json) => {name}(
    {fields}
  );""".format(
        dtype=dart_name,
        name=dart_name,
        fields=",\n    ".join(from_json_lines)
    )
    
    to_json_str = """
Map<String, dynamic> _${name}ToJson({name} instance) => {{
    {fields}
  }};""".format(
        name=dart_name,
        fields=",\n    ".join(to_json_lines)
    )
    
    dto_class = f"""
class {dart_name} {{
  {constructor}

  factory {dart_name}.fromJson(Map<String, dynamic> json) => _${dart_name}FromJson(json);

  Map<String, dynamic> toJson() => _${dart_name}ToJson(this);

{fields_str}
}}
"""
    generated.append(dto_class)
    generated.append(from_json_str)
    generated.append(to_json_str)

# Write output
output = DTO_TEMPLATE.format(
    date="2026-07-29",
    sections="\n".join(generated)
)

out_path = os.path.join(OUTPUT_DIR, "hbt_models.dart")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(output)

print(f"\n\nGenerated DTOs: {len(generated)//3} classes")
print(f"Output: {out_path}")
