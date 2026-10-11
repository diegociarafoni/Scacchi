import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))

from cryptography.hazmat.primitives import hashes  # noqa: E402
from cryptography.hazmat.primitives.asymmetric import padding  # noqa: E402

import derive_keystore  # noqa: E402

SEED = "frase di prova per i test, non usarla"


class DeriveKeystoreTest(unittest.TestCase):
    def test_stessa_frase_stesso_certificato(self):
        a = derive_keystore.certificate(derive_keystore.derive_key(SEED))
        b = derive_keystore.certificate(derive_keystore.derive_key(SEED))
        self.assertEqual(a.fingerprint(hashes.SHA256()), b.fingerprint(hashes.SHA256()))

    def test_frase_diversa_chiave_diversa(self):
        a = derive_keystore.derive_key(SEED).public_key().public_numbers()
        b = derive_keystore.derive_key(SEED + "!").public_key().public_numbers()
        self.assertNotEqual(a.n, b.n)

    def test_chiave_rsa_3072_valida(self):
        key = derive_keystore.derive_key(SEED)
        self.assertEqual(key.key_size, 3072)
        signature = key.sign(b"apk", padding.PKCS1v15(), hashes.SHA256())
        key.public_key().verify(signature, b"apk", padding.PKCS1v15(), hashes.SHA256())

    def test_frase_corta_rifiutata(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                [sys.executable, derive_keystore.__file__, os.path.join(tmp, "k.p12")],
                env={**os.environ, "ANDROID_SIGNING_SEED": "corta"},
                capture_output=True,
            )
        self.assertEqual(result.returncode, 1)


if __name__ == "__main__":
    unittest.main()
