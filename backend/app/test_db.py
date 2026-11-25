
from sqlalchemy import text
from app.database import engine

try:
    with engine.connect() as connection:
        result = connection.execute(text("SELECT version()"))
        print("Connexion réussie à PostgreSQL !")
        print(result.fetchone()[0])

except Exception as e:
    print("Erreur de connexion :")
    print(e)
