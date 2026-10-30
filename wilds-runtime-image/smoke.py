"""Image runtime verification; never contacts the game or changes its files."""
import bz2
import ctypes
import dbm.gnu
import hashlib
import json
import lzma
import os
import readline
import sqlite3
import ssl
import sys
import tempfile
import zlib

if sys.version_info < (3, 12):
    raise SystemExit("Python 3.12+ required")

with tempfile.TemporaryDirectory(prefix="wilds-runtime-") as directory:
    database = sqlite3.connect(os.path.join(directory, "smoke.sqlite3"))
    try:
        database.execute("CREATE TABLE probe(value TEXT)")
        database.execute("INSERT INTO probe VALUES(?)", ("verified",))
        database.commit()
        if database.execute("SELECT value FROM probe").fetchone()[0] != "verified":
            raise SystemExit("SQLite read/write failed")
    finally:
        database.close()

for compress, decompress in ((bz2.compress, bz2.decompress),
                             (lzma.compress, lzma.decompress),
                             (zlib.compress, zlib.decompress)):
    if decompress(compress(b"wilds-runtime")) != b"wilds-runtime":
        raise SystemExit("Compression library failed")

print(json.dumps({"python": sys.version.split()[0], "sqlite": sqlite3.sqlite_version,
                  "openssl": ssl.OPENSSL_VERSION, "uid": os.getuid() if hasattr(os, "getuid") else None,
                  "runtime_checks": "passed", "game_compatibility": "not_tested"}))
