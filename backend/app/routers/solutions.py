
from fastapi import APIRouter, Depends, HTTPException
from app.dependencies import get_db
import re
import unicodedata

from sqlalchemy.orm import Session, joinedload

from app.models import (
    Fault,
    FaultSolution,
    Solution,
    Announcement
)


router = APIRouter(prefix="/solutions", tags=["Solutions"])


def solution_to_dict(solution):
    return {
        "id": solution.id,
        "titre": solution.titre,
        "description": solution.description,
        "difficulte": solution.difficulte,
        "duree_minutes": solution.duree_minutes,
        "co2_economise_kg": (
            float(solution.co2_economise_kg)
            if solution.co2_economise_kg is not None else None
        ),
        "outils": solution.outils or [],
        "etapes_reparation": solution.etapes_reparation or [],
        "precautions": solution.precautions,
        "pieces_necessaires": solution.pieces_necessaires or []
    }


def normalize_piece_name(value):
    value = unicodedata.normalize("NFKD", str(value))
    value = value.encode("ascii", "ignore").decode("ascii")
    value = value.lower()

    stopwords = {
        "avec", "pour", "dans", "sur", "les", "des",
        "une", "un", "du", "de", "la", "le", "ou",
        "et", "compatible", "modele", "telephone"
    }

    words = set(re.findall(r"[a-z0-9]+", value))

    return {
        word for word in words
        if len(word) > 2 and word not in stopwords
    }


def piece_matches(required_name, announcement):
    required_words = normalize_piece_name(required_name)

    candidate_names = [
        announcement.nom_materiel,
        announcement.titre
    ]

    for candidate_name in candidate_names:
        candidate_words = normalize_piece_name(candidate_name or "")

        if not required_words or not candidate_words:
            continue

        common_words = required_words & candidate_words

        coverage = len(common_words) / len(required_words)
        precision = len(common_words) / len(candidate_words)

        if coverage >= 0.5 and precision >= 0.5:
            return True

    return False


@router.get("/")
def get_solutions(db: Session = Depends(get_db)):
    solutions = db.query(Solution).all()
    return [solution_to_dict(s) for s in solutions]




@router.get("/{solution_id}/available-parts")
def get_available_parts(
    solution_id: int,
    db: Session = Depends(get_db)
):
    solution = db.query(Solution).filter(
        Solution.id == solution_id
    ).first()

    if not solution:
        raise HTTPException(
            status_code=404,
            detail="Solution introuvable"
        )

    required_parts = solution.pieces_necessaires or []

    if not isinstance(required_parts, list):
        required_parts = [required_parts]

    announcements = (
        db.query(Announcement)
        .filter(
            Announcement.type_materiel == "piece",
            Announcement.type_offre == "don",
            Announcement.statut == "disponible",
            Announcement.quantite > 0
        )
        .all()
    )

    pieces = []

    for required_name in required_parts:
        matches = [
            announcement
            for announcement in announcements
            if piece_matches(required_name, announcement)
        ]

        pieces.append({
            "nom": required_name,
            "statut": (
                "disponible" if matches else "non_disponible"
            ),
            "annonces": [
                {
                    "announcement_id": a.id,
                    "titre": a.titre,
                    "nom_materiel": a.nom_materiel,
                    "marque": a.marque,
                    "modele": a.modele,
                    "photo": a.photo,
                    "description": a.description,
                    "etat_piece": a.etat_piece,
                    "lieu_retrait": a.lieu_retrait,
                    "quantite": a.quantite
                }
                for a in matches
            ]
        })

    return {
        "solution_id": solution.id,
        "pieces": pieces
    }


@router.get("/{solution_id}")
def get_solution(solution_id: int, db: Session = Depends(get_db)):
    solution = db.query(Solution).filter(
        Solution.id == solution_id
    ).first()

    if not solution:
        raise HTTPException(status_code=404, detail="Solution introuvable")

    return solution_to_dict(solution)


@router.get("/fault/{fault_id}")
def get_solutions_by_fault(
    fault_id: int,
    db: Session = Depends(get_db)
):
    fault = db.query(Fault).filter(Fault.id == fault_id).first()

    if not fault:
        raise HTTPException(status_code=404, detail="Panne introuvable")

    associations = (
        db.query(FaultSolution)
        .options(joinedload(FaultSolution.solution))
        .filter(FaultSolution.fault_id == fault_id)
        .all()
    )

    return [
        solution_to_dict(association.solution)
        for association in associations
    ]
