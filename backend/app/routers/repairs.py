
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.dependencies import get_db
from app.models import Fault, FaultSolution, Announcement

router = APIRouter(prefix="/repairs", tags=["Repairs"])


def normalize(value):
    return (value or "").strip().casefold()


def is_matching_part(part_name, announcement):
    search_name = normalize(part_name)

    announcement_names = [
        normalize(announcement.nom_materiel),
        normalize(announcement.titre),
        normalize(announcement.reference)
    ]

    return any(
        search_name == name
        or search_name in name
        for name in announcement_names
        if name
    )


@router.get("/fault/{fault_id}")
def get_repairs_by_fault(
    fault_id: int,
    db: Session = Depends(get_db)
):
    fault = db.query(Fault).filter(
        Fault.id == fault_id
    ).first()

    if not fault:
        raise HTTPException(
            status_code=404,
            detail="Panne introuvable"
        )

    associations = (
        db.query(FaultSolution)
        .options(joinedload(FaultSolution.solution))
        .filter(FaultSolution.fault_id == fault_id)
        .all()
    )

    announcements = (
        db.query(Announcement)
        .filter(
            Announcement.type_materiel == "piece",
            Announcement.type_offre == "don",
            Announcement.statut != "desactive"
        )
        .all()
    )

    results = []

    for association in associations:
        solution = association.solution

        if not solution:
            continue

        needed_parts = solution.pieces_necessaires or []
        compatible_parts = []

        for part_name in needed_parts:
            matching = [
                announcement
                for announcement in announcements
                if is_matching_part(part_name, announcement)
            ]

            compatible_parts.append({
                "name": part_name,
                "annonces": [
                    {
                        "announcement_id": announcement.id,
                        "name": announcement.nom_materiel,
                        "type": "Don",
                        "condition": announcement.etat_piece,
                        "location": announcement.lieu_retrait,
                        "co2": (
                            str(announcement.co2_economise_kg)
                            if announcement.co2_economise_kg is not None
                            else None
                        ),
                        "photo": announcement.photo,
                        "quantity": announcement.quantite,
                        "statut": announcement.statut,
                        "available": (
                            announcement.statut == "disponible"
                            and announcement.quantite > 0
                        )
                    }
                    for announcement in matching
                ]
            })

        results.append({
            "solution_id": solution.id,
            "title": solution.titre,
            "description": solution.description,
            "difficulty": solution.difficulte,
            "time": solution.duree_minutes,
            "co2Saved": (
                str(solution.co2_economise_kg)
                if solution.co2_economise_kg is not None
                else None
            ),
            "tools": solution.outils or [],
            "steps": solution.etapes_reparation or [],
            "precautions": solution.precautions,
            "piecesNecessaires": needed_parts,
            "compatibleParts": compatible_parts
        })

    return results
