# Myanmar NRC Reference, Validation and Privacy

**Implemented:** 2026-07-26  
**Dataset version:** `mm-nrc-2021-hbt-v1`  
**Status:** Community-derived reference with HBT-reviewed critical examples

## 1. Canonical format

HBT accepts Myanmar and English NRC input:

- `၁၂/ကမရ(နိုင်)၁၂၃၄၅၆`
- `12/KaMaYa(N)123456`

The canonical comparison form is:

- `12/KAMAYA(N)123456`

The stored identity is decomposed into state/region, township, citizenship
type and six-digit serial components. State/township combinations are validated
against versioned reference data.

## 2. Approved examples

| English | Myanmar |
|---|---|
| `12/KaMaYa(N)123456` | `၁၂/ကမရ(နိုင်)၁၂၃၄၅၆` |
| `9/PaMaNa(N)123456` | `၉/ပမန(နိုင်)၁၂၃၄၅၆` |

The first example is Kamayut under NRC state code 12. Nay Pyi Taw `9*`
reference records are merged into NRC input state code 9.

## 3. Reference data

The bundled source is the MIT-licensed `wai-lin/mm-nrc` dataset. HBT preserves
its license, source identifiers and source version. The importer:

- merges `9*` into NRC input code `9`
- collapses duplicate state/short-code rows into aliases
- excludes rows without usable NRC short codes
- normalizes Myanmar zero accidentally used in alphabetic short codes
- marks community-derived and HBT-reviewed records separately

The seed currently produces 14 state/region records, 446 deduplicated township
short-code records and six citizenship-type records.

The Shweyokelay JSON was reviewed as a secondary source but is not copied as
the HBT authority because it contains inconsistent mappings and Unicode/key
quality issues. In particular, HBT corrects `12/KaMaYa` to `၁၂/ကမရ`.

## 4. Public reference APIs

| Method | Endpoint |
|---|---|
| GET | `/api/v1/public/nrc/states/` |
| GET | `/api/v1/public/nrc/townships/?state_code=12` |
| GET | `/api/v1/public/nrc/citizenship-types/` |
| POST | `/api/v1/public/nrc/validate/` |

Clients SHOULD implement State/Region → Township → Citizenship Type → Serial
as four short controls. Free-text input MAY be accepted only through the same
backend validation.

## 5. Privacy storage

Passenger and Cargo NRC values are not returned in full and are not retained
in legacy plaintext columns. HBT stores:

- reference foreign keys for state, township and citizenship type
- six-digit serial component
- authenticated encrypted canonical NRC
- keyed HMAC blind index for duplicate detection
- validation or manual-review status

API responses return strong masked representations such as:

- `12/KaMaYa(N)••••56`
- `၁၂/ကမရ(နိုင်)••••၅၆`

Production MUST configure independent `NRC_ENCRYPTION_KEY` and
`NRC_BLIND_INDEX_KEY` secrets. Key rotation MUST be designed and rehearsed
before production rotation.

## 6. Migration behavior

Existing valid NRC values are parsed, encrypted and backfilled into reference
components. Invalid or unknown values are encrypted, removed from plaintext
columns and marked `needs_review`. Duplicate passenger NRC values within an
operator are marked for manual review rather than silently merged.

## 7. Known limitations

- The source is community-maintained, not a confirmed official immigration
  registry export.
- Records marked `community` require continued field validation.
- Only `N`, `E` and `P` are marked HBT-reviewed citizenship types; other types
  remain community-derived.
- OCR/card scanning and full-NRC privileged reveal workflows are not included.
- Encryption key rotation tooling and privacy-retention commands remain
  production closure work.

