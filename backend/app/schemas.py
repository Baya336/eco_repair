
from datetime import date, datetime
from decimal import Decimal
from typing import Literal




from pydantic import BaseModel, ConfigDict , Field , EmailStr


# Configuration commune
class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)



# -------------------------
# UTILISATEURS
# -------------------------



class UserCreate(BaseModel):
    nom: str
    email: EmailStr
    password: str

    adresse: str
    role: Literal[
        "Étudiant / Particulier",
        "Réparateur / FabLab",
        "Donateur / Service IT"
    ]

    telephone: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseSchema):
    id: int
    nom: str
    email: EmailStr
    telephone: str | None = None
    adresse: str | None = None
    role: str
    date_creation: datetime | None = None


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetVerify(BaseModel):
    email: EmailStr
    code: str = Field(
        min_length=6,
        max_length=6,
        pattern=r"^[0-9]{6}$"
    )
    new_password: str = Field(min_length=8)


# -------------------------
# CATEGORIES
# -------------------------

class CategoryCreate(BaseModel):
    nom: str


class CategoryResponse(BaseSchema):
    id: int
    nom: str


# -------------------------
# EQUIPEMENTS
# -------------------------

class DeviceCreate(BaseModel):
    category_id: int
    nom: str
    marque: str | None = None
    modele: str | None = None
    description: str | None = None
    
    photo: str | None = None
    indice_reparabilite: Decimal | None = None
    
    
    date_sortie: date | None = None
    outils: str | None = None
    etapes_reparation: list[str] | None = None

    manual_titre: str | None = None
    
    manual_pdf: str | None = None



class DeviceResponse(BaseSchema):
    id: int
    category_id: int
    nom: str
    marque: str | None = None
    modele: str | None = None
    description: str | None = None
    
    photo: str | None = None
    indice_reparabilite: Decimal | None = None
    
    
    date_sortie: date | None = None
    outils: str | None = None
    etapes_reparation: list[str] | None = None

    manual_titre: str | None = None
    
    manual_pdf: str | None = None


# -------------------------
# PIECES DETACHEES
# -------------------------

class PartCreate(BaseModel):
    nom: str
    categorie: str | None = None
    marque: str | None = None
    modele_compatible: str | None = None
    reference: str | None = None
    etat: str | None = None
    description: str | None = None
    photo: str | None = None


class PartResponse(BaseSchema):
    id: int
    nom: str
    categorie: str | None = None
    marque: str | None = None
    modele_compatible: str | None = None
    reference: str | None = None
    etat: str | None = None
    description: str | None = None
    photo: str | None = None


# -------------------------
# ANNONCES
# -------------------------




class AnnouncementCreate(BaseModel):
    type_materiel: Literal["equipement", "piece"]
    titre: str
    nom_materiel: str

    marque: str | None = None
    modele: str | None = None
    reference: str | None = None

    description: str | None = None
    etat_objet: str | None = None
    photo: str | None = None

    sous_type: str | None = None
    indice_reparabilite: Decimal | None = Field(default=None, ge=0, le=10)
    etat_piece: str | None = None
    co2_economise_kg: Decimal | None = Field(default=None, ge=0)
    lieu_retrait: str | None = None

    type_offre: Literal["don", "pret"]
    quantite: int = Field(default=1, ge=1)
    poids_kg: Decimal | None = Field(default=None, gt=0)

class AnnouncementUser(BaseModel):
    nom: str


class AnnouncementResponse(BaseSchema):
    id: int
    user_id: int
    type_materiel: str
    titre: str
    nom_materiel: str

    marque: str | None = None
    modele: str | None = None
    reference: str | None = None

    description: str | None = None
    etat_objet: str | None = None
    photo: str | None = None

    sous_type: str | None = None
    indice_reparabilite: Decimal | None = None
    etat_piece: str | None = None
    co2_economise_kg: Decimal | None = None
    lieu_retrait: str | None = None

    type_offre: str
    quantite: int
    statut: str
    date_publication: datetime | None = None
    utilisateur: AnnouncementUser
    poids_kg: Decimal | None = Field(default=None, gt=0)

class AnnouncementUpdate(BaseModel):
    type_materiel: Literal["equipement", "piece"] | None = None
    titre: str | None = None
    nom_materiel: str | None = None

    marque: str | None = None
    modele: str | None = None
    reference: str | None = None

    description: str | None = None
    etat_objet: str | None = None
    photo: str | None = None

    sous_type: str | None = None
    indice_reparabilite: Decimal | None = Field(default=None, ge=0, le=10)
    etat_piece: str | None = None
    co2_economise_kg: Decimal | None = Field(default=None, ge=0)
    lieu_retrait: str | None = None

    type_offre: Literal["don", "pret"] | None = None
    quantite: int | None = Field(default=None, ge=1)
    poids_kg: Decimal | None = Field(default=None, gt=0)
 








class ReservationCreate(BaseModel):
    announcement_id: int

    # Créneau de retrait
    creneau_retrait: str | None = None

    # Informations de contact
    telephone_contact: str | None = None
    email_contact: EmailStr | None = None

    # Date de retrait souhaitée
    date_retrait_souhaitee: datetime | None = None

    # Commentaire facultatif
    commentaire: str | None = None



class LoanRequestCreate(BaseModel):
    announcement_id: int
    date_debut_souhaitee: date
    date_fin_souhaitee: date
    motif: str = Field(min_length=1)
    telephone_contact: str | None = None
    email_contact: EmailStr | None = None




# -------------------------
# PANIER
# -------------------------

class CartItemResponse(BaseModel):
    id: int
    announcement_id: int

    # Informations affichées dans le panier Flutter
    name: str
    type: str
    location: str | None = None
    icon: str | None = None

    # Informations nécessaires à DetailProduitPage
    category: int
    subType: str | None = None
    description: str | None = None
    image: str | None = None
    co2Saved: str | None = None
    repairScore: float | None = None
    partCondition: str | None = None
    condition: str | None = None



# -------------------------
# DIAGNOSTIC DES PANNES
# -------------------------


# -------------------------
# SOLUTIONS DE REPARATION
# -------------------------

class SolutionCreate(BaseModel):
    titre: str
    description: str | None = None
    etapes_reparation: list[str] | None = None
    difficulte: str | None = None
    precautions: str | None = None
    duree_minutes: int | None = None
    co2_economise_kg: Decimal | None = None
    outils: list[str] | None = None
    pieces_necessaires: list[str] = Field(default_factory=list)


class SolutionUpdate(BaseModel):
    titre: str | None = None
    description: str | None = None
    etapes_reparation: list[str] | None = None
    difficulte: str | None = None
    precautions: str | None = None
    duree_minutes: int | None = None
    co2_economise_kg: Decimal | None = None
    outils: list[str] | None = None
    pieces_necessaires: list[str] | None = None


class SolutionResponse(BaseSchema):
    id: int
    titre: str
    description: str | None = None
    etapes_reparation: list[str] | None = None
    difficulte: str | None = None
    precautions: str | None = None
    duree_minutes: int | None = None
    co2_economise_kg: Decimal | None = None
    outils: list[str] | None = None
    pieces_necessaires: list[str] = Field(default_factory=list)






class CompatiblePartResponse(BaseModel):
    announcement_id: int
    name: str
    type: Literal["Don", "Prêt"]
    condition: str | None = None
    location: str | None = None
    co2: str | None = None
    photo: str | None = None
    quantity: int | None = None
    statut: str | None = None
    available: bool = False


class PanneDiagnosticResponse(BaseModel):
    id: int
    symptom: str
    shortLabel: str | None = None
    cause: str | None = None

    difficulty: str | None = None
    time: str | None = None
    co2Saved: str | None = None

    # Accepte une liste ou un texte selon le format attendu
    # par ta PannePage actuelle.
    tools: list[str] | str | None = None
    steps: list[str] | None = None

    compatibleParts: list[CompatiblePartResponse] = Field(default_factory=list)


class DiagnosticCreate(BaseModel):
    fault_id: int | None = None
    description_observee: str = Field(min_length=1)


class DiagnosticResponse(BaseSchema):
    id: int
    user_id: int
    fault_id: int | None = None
    description_observee: str
    date_diagnostic: datetime | None = None
