
import os
import requests
from dotenv import load_dotenv

load_dotenv()

BREVO_API_KEY = os.getenv("BREVO_API_KEY")
BREVO_SENDER_EMAIL = os.getenv("BREVO_SENDER_EMAIL")
BREVO_SENDER_NAME = os.getenv("BREVO_SENDER_NAME", "RE-TECH 360")


def send_password_reset_code(to_email: str, code: str):
    """Envoie un code de récupération via l'API Brevo."""

    if not BREVO_API_KEY or not BREVO_SENDER_EMAIL:
        raise RuntimeError("La configuration Brevo est incomplète dans le fichier .env.")

    url = "https://api.brevo.com/v3/smtp/email"

    headers = {
        "accept": "application/json",
        "api-key": BREVO_API_KEY,
        "content-type": "application/json",
    }

    payload = {
        "sender": {
            "name": BREVO_SENDER_NAME,
            "email": BREVO_SENDER_EMAIL,
        },
        "to": [{"email": to_email}],
        "subject": "RE-TECH 360 - Code de récupération",
        "textContent": f"""Bonjour,

Tu as demandé à réinitialiser ton mot de passe RE-TECH 360.

Voici ton code de vérification :

{code}

Ce code est valable pendant 10 minutes et ne peut être utilisé qu'une seule fois.

Si tu n'es pas à l'origine de cette demande, ignore cet e-mail.

L'équipe RE-TECH 360
""",
    }

    response = requests.post(
        url,
        headers=headers,
        json=payload,
        timeout=20,
    )

    if not response.ok:
        raise RuntimeError(
            f"Erreur Brevo ({response.status_code}): {response.text}"
        )
