
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.dependencies import get_db
from app.models import Fault, FaultCause

router = APIRouter(prefix="/faults", tags=["Faults"])


@router.get("/")
def get_faults(db: Session = Depends(get_db)):
    faults = db.query(Fault).all()

    return [
        {
            "id": fault.id,
            "nom_panne": fault.nom_panne,
            "libelle_court": fault.libelle_court,
            "symptomes": fault.symptomes
        }
        for fault in faults
    ]


@router.get("/search")
def search_faults(q: str, db: Session = Depends(get_db)):
    faults = db.query(Fault).filter(
        Fault.nom_panne.ilike(f"%{q}%")
    ).all()

    return [
        {
            "id": fault.id,
            "nom_panne": fault.nom_panne,
            "libelle_court": fault.libelle_court,
            "symptomes": fault.symptomes
        }
        for fault in faults
    ]


@router.get("/{fault_id}")
def get_fault(fault_id: int, db: Session = Depends(get_db)):
    fault = db.query(Fault).filter(
        Fault.id == fault_id
    ).first()

    if not fault:
        raise HTTPException(status_code=404, detail="Panne introuvable")

    return {
        "id": fault.id,
        "nom_panne": fault.nom_panne,
        "libelle_court": fault.libelle_court,
        "symptomes": fault.symptomes
    }


@router.get("/{fault_id}/causes")
def get_fault_causes(fault_id: int, db: Session = Depends(get_db)):
    fault = (
        db.query(Fault)
        .options(
            joinedload(Fault.cause_associations)
            .joinedload(FaultCause.cause)
        )
        .filter(Fault.id == fault_id)
        .first()
    )

    if not fault:
        raise HTTPException(status_code=404, detail="Panne introuvable")

    return [
        {
            "id": association.cause.id,
            "nom_cause": association.cause.nom_cause,
            "description": association.cause.description
        }
        for association in fault.cause_associations
    ]
