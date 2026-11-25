
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.dependencies import get_db, get_current_user
from app.models import Diagnostic, Fault
from app.schemas import DiagnosticCreate

router = APIRouter(prefix="/diagnostics", tags=["Diagnostics"])


@router.post("/")
def create_diagnostic(
    data: DiagnosticCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    if data.fault_id is not None:
        fault = db.query(Fault).filter(
            Fault.id == data.fault_id
        ).first()

        if not fault:
            raise HTTPException(
                status_code=404,
                detail="Panne introuvable"
            )

    diagnostic = Diagnostic(
        user_id=current_user.id,
        fault_id=data.fault_id,
        description_observee=data.description_observee
    )

    db.add(diagnostic)
    db.commit()
    db.refresh(diagnostic)

    return {
        "id": diagnostic.id,
        "user_id": diagnostic.user_id,
        "fault_id": diagnostic.fault_id,
        "description_observee": diagnostic.description_observee,
        "date_diagnostic": diagnostic.date_diagnostic
    }


@router.get("/mes-diagnostics")
def get_my_diagnostics(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    diagnostics = (
        db.query(Diagnostic)
        .options(joinedload(Diagnostic.fault))
        .filter(Diagnostic.user_id == current_user.id)
        .order_by(Diagnostic.date_diagnostic.desc())
        .all()
    )

    return [
        {
            "id": diagnostic.id,
            "fault_id": diagnostic.fault_id,
            "nom_panne": (
                diagnostic.fault.nom_panne
                if diagnostic.fault else None
            ),
            "description_observee": diagnostic.description_observee,
            "date_diagnostic": diagnostic.date_diagnostic
        }
        for diagnostic in diagnostics
    ]
