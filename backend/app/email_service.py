
import os
import smtplib

from email.message import EmailMessage
from dotenv import load_dotenv


# Charger les variables du fichier .env
load_dotenv()

SMTP_EMAIL = os.getenv("SMTP_EMAIL")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")

SMTP_PORT = 465


def send_password_reset_code(to_email: str, code: str):
    """
    Envoie un code de récupération du mot de passe
    à l'adresse e-mail de l'utilisateur.
    """

    if not SMTP_EMAIL or not SMTP_PASSWORD:
        raise RuntimeError(
            "La configuration Gmail est incomplète dans le fichier .env."
        )

    message = EmailMessage()

    message["Subject"] = "RE-TECH 360 - Code de récupération"
    message["From"] = SMTP_EMAIL
    message["To"] = to_email

    message.set_content(
        f"""
Bonjour,

Tu as demandé à réinitialiser ton mot de passe RE-TECH 360.

Voici ton code de vérification :

{code}

Ce code est valable pendant 10 minutes et ne peut être utilisé qu'une seule fois.

Si tu n'es pas à l'origine de cette demande, ignore cet e-mail.

L'équipe RE-TECH 360
"""
    )

    # Connexion sécurisée à Gmail et envoi du message
    with smtplib.SMTP_SSL(
        SMTP_SERVER,
        SMTP_PORT,
        timeout=20
    ) as server:
        server.login(SMTP_EMAIL, SMTP_PASSWORD)
        server.send_message(message)
