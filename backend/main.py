
from fastapi import FastAPI
from app.routers import users, devices, announcements, reservations, cart
from app.routers import loans
from app.routers import faults
from app.routers import solutions
from app.routers import repairs, diagnostics
from app.routers import environmental
from pathlib import Path
from fastapi.staticfiles import StaticFiles


app = FastAPI(
    title="RE-TECH 360",
    description="Backend de l'application mobile de réemploi des pièces électroniques",
    version="1.0.0"
)


# Rendre les photos et les manuels PDF accessibles
BASE_DIR = Path(__file__).resolve().parent
UPLOADS_DIR = BASE_DIR / "uploads"

# Créer automatiquement le dossier s'il n'existe pas
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
print("DOSSIER UPLOADS :", UPLOADS_DIR.resolve())
print("DOSSIER EXISTE :", UPLOADS_DIR.exists())

app.mount(
    "/uploads",
    StaticFiles(directory=str(UPLOADS_DIR)),
    name="uploads"
)


# Connecter les routes
app.include_router(users.router)
app.include_router(devices.router)
app.include_router(announcements.router)
app.include_router(reservations.router)

app.include_router(loans.router)
app.include_router(cart.router)

app.include_router(faults.router)
app.include_router(solutions.router)

app.include_router(repairs.router)
app.include_router(diagnostics.router)

app.include_router(environmental.router)


@app.get("/")
def accueil():
    return {
        "message": "Bienvenue sur le backend RE-TECH 360 !"
    }
