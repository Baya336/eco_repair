
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_db, get_current_user
from app.models import Reservation, ReservationItem, Announcement, User
from app.schemas import ReservationCreate


router = APIRouter(
    prefix="/reservations",
    tags=["Reservations"]
)


# =====================================================
# CREER UNE RESERVATION
# =====================================================

@router.post("/")
def create_reservation(
    data: ReservationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    announcement = db.query(Announcement).filter(
        Announcement.id == data.announcement_id
    ).with_for_update().first()

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable."
        )

    if announcement.statut != "disponible":
        raise HTTPException(
            status_code=400,
            detail="Cette annonce n'est plus disponible."
        )

    if announcement.type_offre != "don":
        raise HTTPException(
            status_code=400,
            detail="Seuls les dons peuvent faire l'objet d'une réservation."
        )

    if announcement.user_id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="Vous ne pouvez pas réserver votre propre annonce."
        )

    telephone = data.telephone_contact or current_user.telephone
    email = data.email_contact or current_user.email
    

    reservation = Reservation(
        user_id=current_user.id,
        date_retrait_souhaitee=data.date_retrait_souhaitee,
        creneau_retrait=data.creneau_retrait,
        telephone_contact=telephone,
        email_contact=email,
        commentaire=data.commentaire,
        statut="en_attente",
        confirmation_donneur=False,
        confirmation_beneficiaire=False
    )

    db.add(reservation)
    db.flush()

    reservation_item = ReservationItem(
        reservation_id=reservation.id,
        announcement_id=announcement.id,
        quantite=1
    )

    db.add(reservation_item)
    db.commit()
    db.refresh(reservation)

    return {
        "message": "Demande de réservation envoyée avec succès.",
        "reservation_id": reservation.id,
        "statut": reservation.statut
    }


# =====================================================
# MES RESERVATIONS (COTE BENEFICIAIRE)
# =====================================================

@router.get("/mes-reservations")
def get_my_reservations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reservations = db.query(Reservation).filter(
        Reservation.user_id == current_user.id
    ).order_by(
        Reservation.date_reservation.desc()
    ).all()

    result = []

    for reservation in reservations:
        articles = []

        for item in reservation.items:
            announcement = item.announcement

            articles.append({
                "announcement_id": announcement.id,
                "titre": announcement.titre,
                "nom_materiel": announcement.nom_materiel,
                "quantite": item.quantite
            })

        result.append({
            "id": reservation.id,
            "date_reservation": reservation.date_reservation,
            "date_retrait_souhaitee": reservation.date_retrait_souhaitee,
            "creneau_retrait": reservation.creneau_retrait,
            "telephone_contact": reservation.telephone_contact,
            "email_contact": reservation.email_contact,
            "statut": reservation.statut,
            "commentaire": reservation.commentaire,
            "confirmation_donneur": reservation.confirmation_donneur,
            "confirmation_beneficiaire": reservation.confirmation_beneficiaire,
            "articles": articles
        })

    return result


# =====================================================
# RESERVATIONS RECUES (COTE DONNEUR)
# =====================================================

@router.get("/recues")
def get_received_reservations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reservations = (
        db.query(Reservation)
        .join(ReservationItem)
        .join(Announcement)
        .filter(Announcement.user_id == current_user.id)
        .order_by(Reservation.date_reservation.desc())
        .all()
    )

    result = []

    for reservation in reservations:
        articles = []

        for item in reservation.items:
            announcement = item.announcement

            if announcement.user_id == current_user.id:
                articles.append({
                    "announcement_id": announcement.id,
                    "titre": announcement.titre,
                    "nom_materiel": announcement.nom_materiel,
                    "quantite": item.quantite
                })

        if articles:
            result.append({
                "id": reservation.id,
                "date_reservation": reservation.date_reservation,
                "date_retrait_souhaitee": reservation.date_retrait_souhaitee,
                "creneau_retrait": reservation.creneau_retrait,
                "telephone_contact": reservation.telephone_contact,
                "email_contact": reservation.email_contact,
                "statut": reservation.statut,
                "commentaire": reservation.commentaire,
                "confirmation_donneur": reservation.confirmation_donneur,
                "confirmation_beneficiaire": reservation.confirmation_beneficiaire,
                "beneficiaire": reservation.user.nom,
                "articles": articles
            })

    return result


# =====================================================
# ACCEPTER UNE RESERVATION
# =====================================================

@router.put("/{reservation_id}/accepter")
def accept_reservation(
    reservation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reservation = db.query(Reservation).filter(
        Reservation.id == reservation_id
    ).with_for_update().first()

    if reservation is None:
        raise HTTPException(
            status_code=404,
            detail="Réservation introuvable."
        )

    if reservation.statut != "en_attente":
        raise HTTPException(
            status_code=400,
            detail="Cette réservation ne peut plus être acceptée."
        )

    if len(reservation.items) != 1:
        raise HTTPException(
            status_code=400,
            detail="Cette réservation doit contenir un seul article."
        )

    item = reservation.items[0]

    announcement = db.query(Announcement).filter(
        Announcement.id == item.announcement_id
    ).with_for_update().first()

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable."
        )

    if announcement.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Vous n'êtes pas propriétaire de cette annonce."
        )

    if announcement.statut != "disponible":
        raise HTTPException(
            status_code=400,
            detail="Cette annonce n'est plus disponible."
        )

    if announcement.type_offre != "don":
        raise HTTPException(
            status_code=400,
            detail="Cette réservation ne concerne pas un don."
        )

    reservation.statut = "acceptee"
    announcement.statut = "reserve"

    # Refuser les autres demandes en attente pour cette annonce
    other_reservations = (
        db.query(Reservation)
        .join(ReservationItem)
        .filter(
            ReservationItem.announcement_id == announcement.id,
            Reservation.id != reservation.id,
            Reservation.statut == "en_attente"
        )
        .all()
    )

    for other in other_reservations:
        other.statut = "refusee"

    db.commit()

    return {
        "message": "Réservation acceptée avec succès.",
        "reservation_id": reservation.id,
        "statut": reservation.statut
    }


# =====================================================
# REFUSER UNE RESERVATION
# =====================================================

@router.put("/{reservation_id}/refuser")
def refuse_reservation(
    reservation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reservation = db.query(Reservation).filter(
        Reservation.id == reservation_id
    ).with_for_update().first()

    if reservation is None:
        raise HTTPException(
            status_code=404,
            detail="Réservation introuvable."
        )

    if reservation.statut != "en_attente":
        raise HTTPException(
            status_code=400,
            detail="Cette réservation ne peut plus être refusée."
        )

    if len(reservation.items) != 1:
        raise HTTPException(
            status_code=400,
            detail="Cette réservation doit contenir un seul article."
        )

    item = reservation.items[0]

    announcement = db.query(Announcement).filter(
        Announcement.id == item.announcement_id
    ).first()

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable."
        )

    if announcement.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Vous n'êtes pas propriétaire de cette annonce."
        )

    reservation.statut = "refusee"

    db.commit()

    return {
        "message": "Réservation refusée.",
        "reservation_id": reservation.id,
        "statut": reservation.statut
    }


# =====================================================
# CONFIRMER LE RETRAIT D'UN DON
# =====================================================

@router.put("/{reservation_id}/confirmer-retrait")
def confirm_handover(
    reservation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reservation = db.query(Reservation).filter(
        Reservation.id == reservation_id
    ).with_for_update().first()

    if reservation is None:
        raise HTTPException(
            status_code=404,
            detail="Réservation introuvable."
        )

    if reservation.statut == "terminee":
        raise HTTPException(
            status_code=400,
            detail="Ce retrait a déjà été confirmé par les deux personnes."
        )

    if reservation.statut != "acceptee":
        raise HTTPException(
            status_code=400,
            detail="La réservation doit être acceptée avant de confirmer le retrait."
        )

    if len(reservation.items) != 1:
        raise HTTPException(
            status_code=400,
            detail="Cette réservation doit contenir un seul article."
        )

    item = reservation.items[0]

    announcement = db.query(Announcement).filter(
        Announcement.id == item.announcement_id
    ).with_for_update().first()

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable."
        )

    if announcement.type_offre != "don":
        raise HTTPException(
            status_code=400,
            detail="Cette confirmation concerne uniquement les dons."
        )

    if announcement.statut != "reserve":
        raise HTTPException(
            status_code=400,
            detail="Cette annonce n'est pas dans le statut réservé."
        )

    # Confirmation du donneur
    if current_user.id == announcement.user_id:

        if reservation.confirmation_donneur:
            raise HTTPException(
                status_code=400,
                detail="Vous avez déjà confirmé la remise."
            )

        reservation.confirmation_donneur = True

    # Confirmation du bénéficiaire
    elif current_user.id == reservation.user_id:

        if reservation.confirmation_beneficiaire:
            raise HTTPException(
                status_code=400,
                detail="Vous avez déjà confirmé la réception."
            )

        reservation.confirmation_beneficiaire = True

    else:
        raise HTTPException(
            status_code=403,
            detail="Vous ne participez pas à cette réservation."
        )

    # Terminer uniquement lorsque les deux personnes ont confirmé
    if (
        reservation.confirmation_donneur
        and reservation.confirmation_beneficiaire
    ):
        reservation.statut = "terminee"
        announcement.statut = "termine"

        message = (
            "Retrait confirmé par les deux personnes. "
            "Annonce terminée."
        )
    else:
        message = (
            "Votre confirmation a été enregistrée. "
            "En attente de l'autre personne."
        )

    db.commit()
    db.refresh(reservation)

    return {
        "message": message,
        "reservation_id": reservation.id,
        "announcement_id": announcement.id,
        "statut_reservation": reservation.statut,
        "statut_annonce": announcement.statut,
        "confirmation_donneur": reservation.confirmation_donneur,
        "confirmation_beneficiaire": reservation.confirmation_beneficiaire
    }
