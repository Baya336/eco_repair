from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date

from app.dependencies import get_db, get_current_user
from app.models import LoanRequest, Announcement, User
from app.schemas import LoanRequestCreate

router = APIRouter(
    prefix="/loan-requests",
    tags=["Demandes de prêt"]
)



@router.post("/", status_code=201)
def create_loan_request(
    request_data: LoanRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Vérifier que l'annonce existe et concerne un équipement proposé en prêt
    announcement = db.query(Announcement).filter(
        Announcement.id == request_data.announcement_id,
        Announcement.type_materiel == "equipement",
        Announcement.type_offre == "pret",
        Announcement.statut == "disponible"
    ).first()

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Équipement introuvable ou prêt indisponible."
        )

    # Empêcher l'utilisateur de demander son propre équipement
    if announcement.user_id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="Vous ne pouvez pas demander votre propre équipement."
        )

    # Vérifier les dates
    if request_data.date_debut_souhaitee < date.today():
        raise HTTPException(
            status_code=400,
            detail="La date de début doit être aujourd'hui ou ultérieure."
        )

    if request_data.date_fin_souhaitee <= request_data.date_debut_souhaitee:
        raise HTTPException(
            status_code=400,
            detail="La date de fin doit être après la date de début."
        )

    # Récupérer les coordonnées du profil si elles ne sont pas fournies
    telephone = request_data.telephone_contact or current_user.telephone
    email = request_data.email_contact or current_user.email

    if not telephone and not email:
        raise HTTPException(
            status_code=400,
            detail="Un téléphone ou un e-mail est nécessaire."
        )

    # Créer la demande
    new_request = LoanRequest(
        user_id=current_user.id,
        announcement_id=announcement.id,
        date_debut_souhaitee=request_data.date_debut_souhaitee,
        date_fin_souhaitee=request_data.date_fin_souhaitee,
        motif=request_data.motif,
        telephone_contact=telephone,
        email_contact=email,
        statut="en_attente"
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    return {
        "message": "Votre demande de prêt a été envoyée.",
        "loan_request_id": new_request.id,
        "announcement_id": announcement.id,
        "statut": new_request.statut,
        "date_debut_souhaitee": new_request.date_debut_souhaitee,
        "date_fin_souhaitee": new_request.date_fin_souhaitee
    }