
from sqlalchemy import inspect
from sqlalchemy.orm import configure_mappers

from app.database import Base, engine
from app import models

try:
    # Vérifier les relations entre les modèles
    configure_mappers()

    print("Relations SQLAlchemy : OK")

    # Vérifier les modèles déclarés
    print("\nTables déclarées dans models.py :")
    for table in Base.metadata.tables:
        print("-", table)

    # Vérifier les tables réellement présentes dans PostgreSQL
    inspector = inspect(engine)
    tables_postgres = set(inspector.get_table_names())

    print("\nTables présentes dans PostgreSQL :")
    for table in sorted(tables_postgres):
        print("-", table)

    # Comparer les deux listes
    tables_python = set(Base.metadata.tables.keys())

    print("\nTables manquantes dans PostgreSQL :",
          tables_python - tables_postgres)

    print("Tables supplémentaires dans PostgreSQL :",
          tables_postgres - tables_python)

    print("\nVérification terminée !")

except Exception as e:
    print("Une erreur est survenue :")
    print(e)
