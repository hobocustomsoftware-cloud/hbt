import base64
import hashlib
import hmac

from cryptography.fernet import Fernet, InvalidToken
from django.conf import settings


def _fernet():
    configured = getattr(settings, "NRC_ENCRYPTION_KEY", "")
    if configured:
        key = configured.encode("ascii")
    else:
        digest = hashlib.sha256(
            f"hbt-nrc-encryption:{settings.SECRET_KEY}".encode("utf-8")
        ).digest()
        key = base64.urlsafe_b64encode(digest)
    return Fernet(key)


def encrypt_nrc(value):
    if not value:
        return ""
    return _fernet().encrypt(value.encode("utf-8")).decode("ascii")


def decrypt_nrc(value):
    if not value:
        return ""
    try:
        return _fernet().decrypt(value.encode("ascii")).decode("utf-8")
    except InvalidToken:
        return ""


def nrc_blind_index(value):
    if not value:
        return ""
    key = getattr(settings, "NRC_BLIND_INDEX_KEY", "") or settings.SECRET_KEY
    return hmac.new(
        key.encode("utf-8"),
        value.upper().encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def _secret_fernet():
    configured = getattr(settings, "PAYMENT_CREDENTIAL_ENCRYPTION_KEY", "")
    if configured:
        key = configured.encode("ascii")
    else:
        digest = hashlib.sha256(
            f"hbt-payment-credentials:{settings.SECRET_KEY}".encode("utf-8")
        ).digest()
        key = base64.urlsafe_b64encode(digest)
    return Fernet(key)


def encrypt_secret(value):
    if not value:
        return ""
    return _secret_fernet().encrypt(value.encode("utf-8")).decode("ascii")


def decrypt_secret(value):
    if not value:
        return ""
    try:
        return _secret_fernet().decrypt(value.encode("ascii")).decode("utf-8")
    except InvalidToken:
        return ""


def _push_fernet():
    configured = getattr(settings, "PUSH_TOKEN_ENCRYPTION_KEY", "")
    if configured:
        key = configured.encode("ascii")
    else:
        digest = hashlib.sha256(
            f"hbt-push-token:{settings.SECRET_KEY}".encode("utf-8")
        ).digest()
        key = base64.urlsafe_b64encode(digest)
    return Fernet(key)


def encrypt_push_token(value):
    if not value:
        return ""
    return _push_fernet().encrypt(value.encode("utf-8")).decode("ascii")


def decrypt_push_token(value):
    if not value:
        return ""
    try:
        return _push_fernet().decrypt(value.encode("ascii")).decode("utf-8")
    except InvalidToken:
        return ""
