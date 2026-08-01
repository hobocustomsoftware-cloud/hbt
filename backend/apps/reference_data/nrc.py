import re
from dataclasses import dataclass

from .models import NRCCitizenshipType, NRCStateRegion, NRCTownship

MYANMAR_DIGITS_TO_ASCII = str.maketrans("၀၁၂၃၄၅၆၇၈၉", "0123456789")
ASCII_DIGITS_TO_MYANMAR = str.maketrans("0123456789", "၀၁၂၃၄၅၆၇၈၉")
NRC_INPUT_PATTERN = re.compile(
    r"^(?P<state>\d{1,2})/"
    r"(?P<township>[A-Za-z]+|[က-အ]+)"
    r"\((?P<citizenship>[A-Za-z]+|[က-အဧည့်နိုင်ပြုသာသနာယာယီ]+)\)"
    r"(?P<serial>\d{6})$",
    re.UNICODE,
)

ROMANIZATION_TOKENS = (
    "HTA", "KHA", "PHA", "THA", "HSA", "NGA", "NYA",
    "AHA", "AH", "AA", "BA", "DA", "GA", "HA", "KA", "LA", "MA",
    "NA", "OO", "OU", "PA", "SA", "TA", "WA", "YA", "ZA",
)


@dataclass(frozen=True)
class ParsedNRC:
    state_region: NRCStateRegion
    township: NRCTownship
    citizenship_type: NRCCitizenshipType
    serial_ascii: str

    @property
    def canonical_en(self):
        return (
            f"{self.state_region.code}/{self.township.code_en}"
            f"({self.citizenship_type.code_en}){self.serial_ascii}"
        )

    @property
    def display_en(self):
        return (
            f"{self.state_region.code}/{display_english_code(self.township.code_en)}"
            f"({self.citizenship_type.code_en}){self.serial_ascii}"
        )

    @property
    def display_mm(self):
        return (
            f"{str(self.state_region.code).translate(ASCII_DIGITS_TO_MYANMAR)}/"
            f"{self.township.code_mm}({self.citizenship_type.code_mm})"
            f"{self.serial_ascii.translate(ASCII_DIGITS_TO_MYANMAR)}"
        )


def compact_nrc(value):
    return "".join(
        (value or "").translate(MYANMAR_DIGITS_TO_ASCII).split()
    )


def display_english_code(code):
    remaining = code.upper()
    parts = []
    while remaining:
        token = next(
            (item for item in ROMANIZATION_TOKENS if remaining.startswith(item)),
            None,
        )
        if token is None:
            parts.append(remaining[0].upper())
            remaining = remaining[1:]
        else:
            parts.append(token[0] + token[1:].lower())
            remaining = remaining[len(token):]
    return "".join(parts)


def parse_nrc(value):
    compact = compact_nrc(value)
    match = NRC_INPUT_PATTERN.fullmatch(compact)
    if not match:
        raise ValueError(
            "NRC must use 12/KaMaYa(N)123456 or "
            "၁၂/ကမရ(နိုင်)၁၂၃၄၅၆ format."
        )
    parts = match.groupdict()
    try:
        state = NRCStateRegion.objects.get(
            code=int(parts["state"]), active=True
        )
    except NRCStateRegion.DoesNotExist as exc:
        raise ValueError("Unknown NRC state/region code.") from exc

    township_input = parts["township"]
    township_query = (
        {"code_en__iexact": township_input}
        if township_input.isascii()
        else {"code_mm": township_input}
    )
    try:
        township = NRCTownship.objects.get(
            state_region=state, active=True, **township_query
        )
    except NRCTownship.DoesNotExist as exc:
        raise ValueError(
            "Township code does not belong to the selected NRC state/region."
        ) from exc

    citizenship_input = parts["citizenship"]
    citizenship_query = (
        {"code_en__iexact": citizenship_input}
        if citizenship_input.isascii()
        else {"code_mm": citizenship_input}
    )
    try:
        citizenship = NRCCitizenshipType.objects.get(
            active=True, **citizenship_query
        )
    except NRCCitizenshipType.DoesNotExist as exc:
        raise ValueError("Unknown NRC citizenship type.") from exc
    return ParsedNRC(state, township, citizenship, parts["serial"])


def render_nrc_from_components(
    state_region, township, citizenship_type, serial_ascii
):
    if not all((state_region, township, citizenship_type, serial_ascii)):
        return None
    return ParsedNRC(
        state_region, township, citizenship_type, serial_ascii
    )


def mask_rendered_nrc(parsed, language="mm"):
    if not parsed:
        return ""
    serial = f"••••{parsed.serial_ascii[-2:]}"
    if language == "en":
        return (
            f"{parsed.state_region.code}/"
            f"{display_english_code(parsed.township.code_en)}"
            f"({parsed.citizenship_type.code_en}){serial}"
        )
    state_mm = str(parsed.state_region.code).translate(ASCII_DIGITS_TO_MYANMAR)
    serial_mm = serial[:-2] + serial[-2:].translate(ASCII_DIGITS_TO_MYANMAR)
    return (
        f"{state_mm}/{parsed.township.code_mm}"
        f"({parsed.citizenship_type.code_mm}){serial_mm}"
    )

