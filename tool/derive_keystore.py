"""Chiave di firma Android derivata in modo deterministico da una frase segreta.

Stessa frase, stesso certificato: ogni build firma con la stessa identità
senza dover conservare un keystore. Uso:

    ANDROID_SIGNING_SEED=... python3 tool/derive_keystore.py out.p12

Scrive il keystore PKCS12 (alias "scacchi") e stampa su stdout la sua password.
"""

import datetime
import hashlib
import os
import sys
import unicodedata

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

ALIAS = b"scacchi"
KEY_BITS = 3072
E = 65537
# Cambiare il sale cambia la chiave: è la versione dello schema di derivazione.
SALT = b"scacchi-android-signing-v1"


class Stream:
    """Flusso di byte deterministico (SHAKE-256 in modalità contatore)."""

    def __init__(self, key: bytes, label: bytes):
        self._key = key
        self._label = label
        self._counter = 0

    def read(self, n: int) -> bytes:
        self._counter += 1
        data = self._key + self._label + self._counter.to_bytes(8, "big")
        return hashlib.shake_256(data).digest(n)

    def below(self, limit: int) -> int:
        size = (limit.bit_length() + 7) // 8 + 8
        return int.from_bytes(self.read(size), "big") % limit


SMALL_PRIMES = [p for p in range(3, 2000) if all(p % d for d in range(2, int(p**0.5) + 1))]


def is_probable_prime(n: int, stream: Stream, rounds: int = 64) -> bool:
    if any(n % p == 0 for p in SMALL_PRIMES):
        return n in SMALL_PRIMES
    d, s = n - 1, 0
    while d % 2 == 0:
        d //= 2
        s += 1
    for _ in range(rounds):
        a = 2 + stream.below(n - 3)
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True


def prime(stream: Stream, bits: int) -> int:
    while True:
        candidate = int.from_bytes(stream.read(bits // 8), "big")
        # I due bit alti garantiscono un modulo di esattamente KEY_BITS bit.
        candidate |= (3 << (bits - 2)) | 1
        if (candidate - 1) % E and is_probable_prime(candidate, stream):
            return candidate


MIN_SEED_LENGTH = 32


def normalize(seed: str) -> str:
    """Stessa frase anche se incollata con spazi attorno o accenti in forma diversa."""
    return unicodedata.normalize("NFC", seed.strip())


def master_key(seed: str) -> bytes:
    return hashlib.scrypt(
        normalize(seed).encode(), salt=SALT, n=2**17, r=8, p=1, dklen=64, maxmem=2**28
    )


def store_password(master: bytes) -> str:
    return Stream(master, b"store").read(32).hex()


def derive_key(master: bytes) -> rsa.RSAPrivateKey:
    p = prime(Stream(master, b"p"), KEY_BITS // 2)
    q = prime(Stream(master, b"q"), KEY_BITS // 2)
    if p == q:
        raise ValueError("primi coincidenti")
    if p < q:
        p, q = q, p
    phi = (p - 1) * (q - 1)
    d = pow(E, -1, phi)
    numbers = rsa.RSAPrivateNumbers(
        p=p,
        q=q,
        d=d,
        dmp1=rsa.rsa_crt_dmp1(d, p),
        dmq1=rsa.rsa_crt_dmq1(d, q),
        iqmp=rsa.rsa_crt_iqmp(p, q),
        public_numbers=rsa.RSAPublicNumbers(E, p * q),
    )
    return numbers.private_key()


def certificate(key: rsa.RSAPrivateKey) -> x509.Certificate:
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Rokko")])
    utc = datetime.timezone.utc
    # Campi fissi e firma PKCS#1 v1.5 (deterministica): certificato identico a ogni build.
    return (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(1)
        .not_valid_before(datetime.datetime(2026, 1, 1, tzinfo=utc))
        .not_valid_after(datetime.datetime(2126, 1, 1, tzinfo=utc))
        .sign(key, hashes.SHA256())
    )


def main() -> int:
    seed = os.environ.get("ANDROID_SIGNING_SEED", "")
    if len(normalize(seed)) < MIN_SEED_LENGTH:
        print(
            f"ANDROID_SIGNING_SEED deve avere almeno {MIN_SEED_LENGTH} caratteri casuali",
            file=sys.stderr,
        )
        return 1
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    master = master_key(seed)
    key = derive_key(master)
    cert = certificate(key)
    password = store_password(master)
    encryption = (
        serialization.PrivateFormat.PKCS12.encryption_builder()
        .kdf_rounds(50000)
        .key_cert_algorithm(pkcs12.PBES.PBESv2SHA256AndAES256CBC)
        .hmac_hash(hashes.SHA256())
        .build(password.encode())
    )
    data = pkcs12.serialize_key_and_certificates(ALIAS, key, cert, None, encryption)
    with open(sys.argv[1], "wb") as out:
        out.write(data)
    fingerprint = cert.fingerprint(hashes.SHA256()).hex(":").upper()
    print(f"Certificato SHA-256: {fingerprint}", file=sys.stderr)
    print(password)
    return 0


if __name__ == "__main__":
    sys.exit(main())
