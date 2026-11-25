
from decimal import Decimal, InvalidOperation
from pathlib import Path
from uuid import uuid4

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    UploadFile,
    File,
)
from pydantic import ValidationError
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.schemas import (
    AnnouncementCreate,
    AnnouncementResponse,
    AnnouncementUpdate,
)
from app.dependencies import get_db, get_current_user
from app.models import Announcement, User


router = APIRouter(
    prefix="/announcements",
    tags=["Annonces"]
)


# ============================================================
# FONCTIONS UTILITAIRES
# ============================================================

def announcement_to_dict(a: Announcement):
    """Prépare les données d'une annonce pour la réponse API."""

    return {
        "id": a.id,
        "user_id": a.user_id,
        "type_materiel": a.type_materiel,
        "titre": a.titre,
        "nom_materiel": a.nom_materiel,
        "marque": a.marque,
        "modele": a.modele,
        "reference": a.reference,
        "description": a.description,
        "etat_objet": a.etat_objet,
        "photo": a.photo,
        "sous_type": a.sous_type,
        "indice_reparabilite": a.indice_reparabilite,
        "etat_piece": a.etat_piece,
        "co2_economise_kg": a.co2_economise_kg,
        "poids_kg": a.poids_kg,
        "lieu_retrait": a.lieu_retrait,
        "type_offre": a.type_offre,
        "quantite": a.quantite,
        "statut": a.statut,
        "date_publication": a.date_publication,
        "utilisateur": {
            "nom": a.user.nom
        }
    }


def convert_decimal(value, field_name):
    """Convertit une valeur en Decimal et vérifie qu'elle est valide."""

    if value is None or value == "":
        return None

    if isinstance(value, str):
        value = value.lower().replace("kg", "").strip()

    try:
        result = Decimal(str(value))

        if not result.is_finite():
            raise InvalidOperation

        return result

    except (InvalidOperation, ValueError, TypeError):
        raise HTTPException(
            status_code=422,
            detail=f"La valeur du champ {field_name} est invalide."
        )


    
def convert_flutter_data(data: dict):
    """
    Convertit les données Flutter vers AnnouncementCreate.
    Le CO2 est calculé côté serveur selon le sous-type.
    """

    if not isinstance(data, dict):
        raise HTTPException(
            status_code=422,
            detail="Les données de l'annonce doivent être un objet JSON."
        )

    if "name" in data:

        # 1. Conversion de la catégorie
        category = data.get("category")

        if category == 0:
            type_materiel = "equipement"
        elif category == 1:
            type_materiel = "piece"
        else:
            raise HTTPException(
                status_code=422,
                detail="La catégorie doit être 0 (équipement) ou 1 (pièce)."
            )

        # 2. Conversion du type d'offre
        type_flutter = data.get("type")

        if type_flutter == "Don":
            type_offre = "don"
        elif type_flutter == "Prêt":
            type_offre = "pret"
        else:
            raise HTTPException(
                status_code=422,
                detail="Le type d'offre doit être Don ou Prêt."
            )

        # Une pièce détachée ne peut être proposée qu'en don
        if type_materiel == "piece" and type_offre == "pret":
            raise HTTPException(
                status_code=400,
                detail="Une pièce détachée peut uniquement être proposée en don."
            )

        # 3. Vérification du nom
        name = data.get("name")

        if not isinstance(name, str) or not name.strip():
            raise HTTPException(
                status_code=422,
                detail="Le nom de l'annonce est obligatoire."
            )

        # 4. Récupération du sous-type
        sub_type = data.get("subType")

        if not isinstance(sub_type, str) or not sub_type.strip():
            raise HTTPException(
                status_code=422,
                detail="Le sous-type du matériel est obligatoire."
            )

        # 5. Calcul du CO2 côté serveur
        co2_by_sub_type = {
            "PC Portable": Decimal("156"),
            "PC Fixe / Tour": Decimal("220"),
            "Écran / Moniteur": Decimal("85"),
            "Barrette de RAM": Decimal("14"),
            "Disque SSD / HDD": Decimal("28"),
            "Batterie / Chargeur": Decimal("18"),
            "Autre composant": Decimal("15"),
        }

        if sub_type not in co2_by_sub_type:
            raise HTTPException(
                status_code=422,
                detail="Le sous-type sélectionné n'est pas reconnu."
            )

        co2_value = co2_by_sub_type[sub_type]

        # 6. Conversion de l'indice de réparabilité
        repair_score = convert_decimal(
            data.get("repairScore"),
            "repairScore"
        )

        # 7. Conversion du poids
        weight = convert_decimal(
            data.get("poids_kg"),
            "poids_kg"
        )

        # 8. Récupération de la quantité
        quantity = data.get("quantite", 1)

        # 9. Construction des données Backend
        mapped_data = {
            "type_materiel": type_materiel,
            "titre": name.strip(),
            "nom_materiel": name.strip(),
            "type_offre": type_offre,

            "sous_type": sub_type,

            "indice_reparabilite": (
                repair_score
                if type_materiel == "equipement"
                else None
            ),

            "etat_piece": (
                data.get("partCondition")
                if type_materiel == "piece"
                else None
            ),

            "etat_objet": None,

            # Valeur calculée par le serveur
            "co2_economise_kg": co2_value,

            "poids_kg": weight,
            "quantite": quantity,

            "lieu_retrait": data.get("location"),
            "description": data.get("description"),
            "photo": data.get("image"),
        }

    else:
        # Format Backend classique
        mapped_data = data

    try:
        return AnnouncementCreate.model_validate(mapped_data)

    except ValidationError as e:
        raise HTTPException(
            status_code=422,
            detail=e.errors()
        )


# ============================================================
# UPLOADER UNE PHOTO
# ============================================================

@router.post("/upload-photo")
async def upload_announcement_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Enregistre la photo d'une annonce sur le serveur."""

    # Formats autorisés
    allowed_types = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
    }

    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Format non autorisé. Utilisez JPG, PNG ou WEBP."
        )

    # Lire le fichier et limiter sa taille à 5 Mo
    photo_content = await file.read()

    if not photo_content:
        raise HTTPException(
            status_code=400,
            detail="Le fichier envoyé est vide."
        )

    max_size = 5 * 1024 * 1024

    if len(photo_content) > max_size:
        raise HTTPException(
            status_code=400,
            detail="La photo ne doit pas dépasser 5 Mo."
        )

    # Dossier de stockage : app/uploads/announcements
    upload_dir = (
    Path(__file__).resolve().parent.parent.parent
    / "uploads"
    / "announcements"
)

    upload_dir.mkdir(parents=True, exist_ok=True)

    # Générer un nom de fichier unique
    extension = allowed_types[file.content_type]
    filename = f"{uuid4().hex}{extension}"

    photo_path = upload_dir / filename

    try:
        photo_path.write_bytes(photo_content)

        print("PHOTO ENREGISTRÉE :", photo_path.resolve())
        print("FICHIER EXISTE :", photo_path.exists())


    except OSError:
        raise HTTPException(
            status_code=500,
            detail="Impossible d'enregistrer la photo sur le serveur."
        )

    return {
        "photo": f"/uploads/announcements/{filename}"
    }



# ============================================================
# CREER UNE ANNONCE
# ============================================================

@router.post(
    "/",
    response_model=AnnouncementResponse,
    status_code=201
)
def create_announcement(
    data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Convertir les données envoyées par Flutter
    announcement_data = convert_flutter_data(data)

    # Vérifier la règle des pièces détachées
    if (
        announcement_data.type_materiel == "piece"
        and announcement_data.type_offre == "pret"
    ):
        raise HTTPException(
            status_code=400,
            detail="Une pièce détachée peut uniquement être proposée en don."
        )

    # Créer l'annonce
    new_announcement = Announcement(
        **announcement_data.model_dump(),
        user_id=current_user.id
    )

    try:
        db.add(new_announcement)
        db.commit()
        db.refresh(new_announcement)

    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la création de l'annonce : {str(e)}"
        )

    return announcement_to_dict(new_announcement)

    


# ============================================================
# AFFICHER TOUTES LES ANNONCES DISPONIBLES
# ============================================================

@router.get("/", response_model=list[AnnouncementResponse])
def get_announcements(
    db: Session = Depends(get_db)
):

    announcements = (
        db.query(Announcement)
        .filter(Announcement.statut == "disponible")
        .order_by(Announcement.date_publication.desc())
        .all()
    )

    return [announcement_to_dict(a) for a in announcements]


# ============================================================
# AFFICHER MES ANNONCES
# ============================================================

@router.get(
    "/mes-annonces",
    response_model=list[AnnouncementResponse]
)
def get_my_announcements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    announcements = (
        db.query(Announcement)
        .filter(Announcement.user_id == current_user.id)
        .order_by(Announcement.date_publication.desc())
        .all()
    )

    return [announcement_to_dict(a) for a in announcements]


# ============================================================
# AFFICHER LES ANNONCES D'EQUIPEMENTS
# ============================================================

@router.get(
    "/equipements",
    response_model=list[AnnouncementResponse]
)
def get_equipment_announcements(
    db: Session = Depends(get_db)
):

    announcements = (
        db.query(Announcement)
        .filter(
            Announcement.type_materiel == "equipement",
            Announcement.statut == "disponible"
        )
        .order_by(Announcement.date_publication.desc())
        .all()
    )

    return [announcement_to_dict(a) for a in announcements]


# ============================================================
# AFFICHER LES ANNONCES DE PIECES
# ============================================================

@router.get(
    "/pieces",
    response_model=list[AnnouncementResponse]
)
def get_parts_announcements(
    db: Session = Depends(get_db)
):

    announcements = (
        db.query(Announcement)
        .filter(
            Announcement.type_materiel == "piece",
            Announcement.type_offre == "don",
            Announcement.statut == "disponible"
        )
        .order_by(Announcement.date_publication.desc())
        .all()
    )

    return [announcement_to_dict(a) for a in announcements]


# ============================================================
# RECHERCHER DES ANNONCES
# ============================================================

@router.get(
    "/search",
    response_model=list[AnnouncementResponse]
)
def search_announcements(
    q: str = Query(min_length=1),
    type_materiel: str | None = None,
    db: Session = Depends(get_db)
):

    if type_materiel not in (None, "equipement", "piece"):
        raise HTTPException(
            status_code=400,
            detail="Le type doit être 'equipement' ou 'piece'."
        )

    query = db.query(Announcement).filter(
        Announcement.statut == "disponible"
    )

    if type_materiel is not None:
        query = query.filter(
            Announcement.type_materiel == type_materiel
        )

    recherche = f"%{q}%"

    announcements = query.filter(
        or_(
            Announcement.titre.ilike(recherche),
            Announcement.nom_materiel.ilike(recherche),
            Announcement.marque.ilike(recherche),
            Announcement.modele.ilike(recherche),
            Announcement.reference.ilike(recherche),
            Announcement.description.ilike(recherche),
            Announcement.sous_type.ilike(recherche),
            Announcement.lieu_retrait.ilike(recherche)
        )
    ).order_by(
        Announcement.date_publication.desc()
    ).all()

    return [announcement_to_dict(a) for a in announcements]


# ============================================================
# AFFICHER UNE ANNONCE PAR SON IDENTIFIANT
# ============================================================

@router.get(
    "/{announcement_id}",
    response_model=AnnouncementResponse
)
def get_announcement(
    announcement_id: int,
    db: Session = Depends(get_db)
):

    announcement = (
        db.query(Announcement)
        .filter(
            Announcement.id == announcement_id,
            Announcement.statut == "disponible"
        )
        .first()
    )

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable."
        )

    return announcement_to_dict(announcement)


# ============================================================
# MODIFIER UNE ANNONCE
# ============================================================

@router.put(
    "/{announcement_id}",
    response_model=AnnouncementResponse
)
def update_announcement(
    announcement_id: int,
    announcement_data: AnnouncementUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    announcement = (
        db.query(Announcement)
        .filter(Announcement.id == announcement_id)
        .first()
    )

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable."
        )

    if announcement.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Vous ne pouvez pas modifier cette annonce."
        )

    update_data = announcement_data.model_dump(
        exclude_unset=True
    )

    nouveau_type = update_data.get(
        "type_materiel",
        announcement.type_materiel
    )

    nouvelle_offre = update_data.get(
        "type_offre",
        announcement.type_offre
    )

    if nouveau_type == "piece" and nouvelle_offre == "pret":
        raise HTTPException(
            status_code=400,
            detail="Une pièce détachée peut uniquement être proposée en don."
        )

    for key, value in update_data.items():
        setattr(announcement, key, value)

    try:
        db.commit()
        db.refresh(announcement)

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Une erreur est survenue lors de la modification de l'annonce."
        )

    return announcement_to_dict(announcement)


# ============================================================
# DESACTIVER UNE ANNONCE
# ============================================================

@router.delete("/{announcement_id}")
def deactivate_announcement(
    announcement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    announcement = (
        db.query(Announcement)
        .filter(Announcement.id == announcement_id)
        .first()
    )

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable."
        )

    if announcement.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Vous ne pouvez pas désactiver cette annonce."
        )

    announcement.statut = "desactive"

    try:
        db.commit()
        db.refresh(announcement)

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Une erreur est survenue lors de la désactivation de l'annonce."
        )

    return {
        "message": "Annonce désactivée avec succès.",
        "id": announcement.id,
        "statut": announcement.statut
    }
