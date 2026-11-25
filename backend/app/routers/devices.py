from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.dependencies import get_db
from app.models import Device
from app.schemas import DeviceResponse

router = APIRouter(
    prefix="/devices",
    tags=["Appareils"]
)


# Consulter tous les appareils
@router.get("/", response_model=list[DeviceResponse])
def get_devices(db: Session = Depends(get_db)):

    return (
        db.query(Device)
        .options(joinedload(Device.category))
        .all()
    )


# Rechercher un appareil
@router.get("/search", response_model=list[DeviceResponse])
def search_devices(q: str, db: Session = Depends(get_db)):

    return (
        db.query(Device)
        .filter(
            (Device.nom.ilike(f"%{q}%")) |
            (Device.marque.ilike(f"%{q}%")) |
            (Device.modele.ilike(f"%{q}%"))
        )
        .all()
    )


# Consulter un appareil par identifiant
@router.get("/{device_id}", response_model=DeviceResponse)
def get_device(device_id: int, db: Session = Depends(get_db)):

    device = db.query(Device).filter(
        Device.id == device_id
    ).first()

    if device is None:
        raise HTTPException(
            status_code=404,
            detail="Appareil introuvable."
        )

    return device