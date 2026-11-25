from sqlalchemy import inspect
from app.database import engine
from app import models

inspector = inspect(engine)

for table_name in models.Base.metadata.tables:
    print(f"\nTable : {table_name}")

    columns_python = {
        column.name
        for column in models.Base.metadata.tables[table_name].columns
    }

    columns_postgres = {
        column["name"]
        for column in inspector.get_columns(table_name)
    }

    print("Colonnes manquantes dans PostgreSQL :",
          columns_python - columns_postgres)

    print("Colonnes supplémentaires dans PostgreSQL :",
          columns_postgres - columns_python)
