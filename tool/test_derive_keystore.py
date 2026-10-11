import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))

from cryptography.hazmat.primitives import hashes  # noqa: E402
from cryptography.hazmat.primitives.asymmetric import padding  # noqa: E402

import derive_keystore  # noqa: E402

SEED = "frase di prova per i test, non usarla mai per firmare"


class DeriveKeystoreTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.master = derive_keystore.master_key(SEED)
        cls.key = derive_keystore.derive_key(cls.master)
        cls.cert = derive_keystore.certificate(cls.key)

    def test_certificato_fissato(self):
        # Se cambia, tutti gli APK futuri avrebbero un'altra firma: va cambiato solo di proposito.
        self.assertEqual(
            self.cert.fingerprint(hashes.SHA256()).hex(),
            FINGERPRINT,
        )

    def test_frase_normalizzata(self):
        self.assertEqual(derive_keystore.master_key(f"  {SEED}\n"), self.master)
        nfd = "café " * 8
        nfc = "café " * 8
        self.assertEqual(derive_keystore.master_key(nfd), derive_keystore.master_key(nfc))

    def test_frase_diversa_chiave_diversa(self):
        other = derive_keystore.derive_key(derive_keystore.master_key(SEED + "!"))
        self.assertNotEqual(other.public_key().public_numbers().n, self.key.public_key().public_numbers().n)

    def test_chiave_rsa_3072_valida(self):
        numbers = self.key.private_numbers()
        self.assertEqual(self.key.key_size, 3072)
        self.assertEqual(numbers.p * numbers.q, numbers.public_numbers.n)
        for prime in (numbers.p, numbers.q):
            for base in (2, 3, 5, 7, 11, 13):
                self.assertEqual(pow(base, prime - 1, prime), 1)
        signature = self.key.sign(b"apk", padding.PKCS1v15(), hashes.SHA256())
        self.key.public_key().verify(signature, b"apk", padding.PKCS1v15(), hashes.SHA256())

    def test_frase_corta_rifiutata(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                [sys.executable, derive_keystore.__file__, os.path.join(tmp, "k.p12")],
                env={**os.environ, "ANDROID_SIGNING_SEED": "  troppo corta  "},
                capture_output=True,
            )
        self.assertEqual(result.returncode, 1)


FINGERPRINT = "f7a210f9a2ae398b6198600b5bb0b8c95aed56b471729e8b3f10deca336ad87f"

if __name__ == "__main__":
    unittest.main()
