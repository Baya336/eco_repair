
from pathlib import Path
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from difflib import SequenceMatcher
import unicodedata
import re

BASE_DIR = Path(__file__).resolve().parent

load_dotenv(BASE_DIR / ".env")

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL n'est pas configurée")

PHOTOS_DIR = BASE_DIR / "uploads" / "photos"

def normalize(value):
    value = unicodedata.normalize("NFKD", value.lower())
    value = "".join(c for c in value if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", value)

engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    rows = conn.execute(text("""
        SELECT id, nom, photo
        FROM devices
        WHERE photo IS NOT NULL
        ORDER BY id
    """)).fetchall()

files = [f for f in PHOTOS_DIR.iterdir() if f.is_file()]

print("\n=== PHOTOS MANQUANTES ET CORRESPONDANCES POSSIBLES ===\n")

for row in rows:
    if not (BASE_DIR / row.photo).is_file():
        target = normalize(Path(row.photo).stem)
        candidates = sorted(
            files,
            key=lambda f: SequenceMatcher(
                None, target, normalize(f.stem)
            ).ratio(),
            reverse=True
        )

        print(f"\nID {row.id} - {row.nom}")
        print(f"Nom demandé : {Path(row.photo).name}")
        print("Fichiers ressemblants :")

        for candidate in candidates[:3]:
            score = SequenceMatcher(
                None, target, normalize(candidate.stem)
            ).ratio()
            print(f"  {score:.0%} - {candidate.name}")
