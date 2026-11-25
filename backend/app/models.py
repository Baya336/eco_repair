
from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Date,
    DateTime,
    Numeric,
    ForeignKey,
    CheckConstraint,
    UniqueConstraint,
    Index,
    Boolean
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import JSONB


from app.database import Base


# ============================================================
# AXE 1 : CATALOGUE INFORMATIF DES EQUIPEMENTS
# ============================================================

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String(100), nullable=False, unique=True)

    devices = relationship(
        "Device",
        back_populates="category"
    )


class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)

    category_id = Column(
        Integer,
        ForeignKey("categories.id"),
        nullable=False
    )

    nom = Column(String(150), nullable=False)
    marque = Column(String(100))
    modele = Column(String(100))
    description = Column(Text)
    
    photo = Column(String(255))

    indice_reparabilite = Column(Numeric(3, 1))
    
    
    date_sortie = Column(Date)

    # Informations de réparation
    outils = Column(Text, nullable=True)
    etapes_reparation = Column(JSONB, nullable=True)

    # Informations du manuel PDF
    manual_titre = Column(String(200), nullable=True)
    
    manual_pdf = Column(String(255), nullable=True)

    category = relationship(
        "Category",
        back_populates="devices"
    )


# ============================================================
# AXE 2 : UTILISATEURS ET ANNONCES
# ============================================================


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    # Nom et prénom dans un seul champ
    nom = Column(String(100), nullable=False)

    email = Column(
        String(150),
        nullable=False,
        unique=True,
        index=True
    )

    # Mot de passe hashé
    password = Column(String(255), nullable=False)

    telephone = Column(String(20), nullable=True)
    adresse = Column(Text, nullable=True)

    # Trois rôles possibles
    role = Column(String(50), nullable=False)

    date_creation = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "role IN ('particulier', 'reparateur', 'donateur')",
            name="check_user_role"
        ),
    )

    announcements = relationship(
        "Announcement",
        back_populates="user"
    )

    carts = relationship(
        "Cart",
        back_populates="user"
    )

    reservations = relationship(
        "Reservation",
        back_populates="user"
    )

    diagnostics = relationship(
        "Diagnostic",
        back_populates="user"
    )



class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    # Nature du matériel proposé :
    # equipement ou piece
    type_materiel = Column(String(30), nullable=False)

    titre = Column(String(200), nullable=False)
    nom_materiel = Column(String(150), nullable=False)
    marque = Column(String(100))
    modele = Column(String(100))
    reference = Column(String(100))

    description = Column(Text)
    etat_objet = Column(String(100))
    photo = Column(String(255))


    # Informations supplémentaires provenant de PublierPage
    sous_type = Column(String(100), nullable=True)

    indice_reparabilite = Column(Numeric(3, 1), nullable=True)

    etat_piece = Column(String(100), nullable=True)

    co2_economise_kg = Column(Numeric(10, 2), nullable=True)

    lieu_retrait = Column(String(200), nullable=True)


    # Type d'offre : don ou pret
    type_offre = Column(String(20), nullable=False)

    quantite = Column(Integer, nullable=False, default=1)

    # disponible, reserve, termine, desactive
    statut = Column(
        String(30),
        nullable=False,
        default="disponible"
    )

    date_publication = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    poids_kg = Column(Numeric(10, 3), nullable=True)

    __table_args__ = (
        CheckConstraint(
            "type_materiel IN ('equipement', 'piece')",
            name="check_type_materiel"
        ),
        CheckConstraint(
            "type_offre IN ('don', 'pret')",
            name="check_type_offre"
        ),
        CheckConstraint(
            "statut IN ('disponible', 'reserve', "
            "'termine', 'desactive')",
            name="check_statut_annonce"
        ),
        CheckConstraint(
            "quantite > 0",
            name="check_quantite_annonce"
        ),
        # Une pièce détachée peut uniquement être donnée
        CheckConstraint(
            "type_materiel != 'piece' OR type_offre = 'don'",
            name="check_piece_don_uniquement"
        ),
    )

    user = relationship(
        "User",
        back_populates="announcements"
    )

    cart_items = relationship(
        "CartItem",
        back_populates="announcement"
    )

    reservation_items = relationship(
        "ReservationItem",
        back_populates="announcement"
    )


# ============================================================
# AXE 3 : DIAGNOSTIC ET ASSISTANCE
# ============================================================


class Fault(Base):
    __tablename__ = "faults"

    id = Column(Integer, primary_key=True, index=True)
    nom_panne = Column(String(200), nullable=False)
    libelle_court = Column(String(150), nullable=True)
    symptomes = Column(Text)

    cause_associations = relationship(
        "FaultCause",
        back_populates="fault",
        cascade="all, delete-orphan"
    )

    solution_associations = relationship(
        "FaultSolution",
        back_populates="fault",
        cascade="all, delete-orphan"
    )

    diagnostics = relationship(
        "Diagnostic",
        back_populates="fault"
    )

class Cause(Base):
    __tablename__ = "causes"

    id = Column(Integer, primary_key=True, index=True)

    nom_cause = Column(String(200), nullable=False)
    description = Column(Text)

    fault_associations = relationship(
        "FaultCause",
        back_populates="cause",
        cascade="all, delete-orphan"
    )


class FaultCause(Base):
    __tablename__ = "fault_causes"

    id = Column(Integer, primary_key=True, index=True)

    fault_id = Column(
        Integer,
        ForeignKey("faults.id", ondelete="CASCADE"),
        nullable=False
    )

    cause_id = Column(
        Integer,
        ForeignKey("causes.id", ondelete="CASCADE"),
        nullable=False
    )

    __table_args__ = (
        UniqueConstraint(
            "fault_id",
            "cause_id",
            name="unique_fault_cause"
        ),
    )

    fault = relationship(
        "Fault",
        back_populates="cause_associations"
    )

    cause = relationship(
        "Cause",
        back_populates="fault_associations"
    )






class Solution(Base):
    __tablename__ = "solutions"

    id = Column(Integer, primary_key=True, index=True)

    titre = Column(String(200), nullable=False)
    description = Column(Text)

    etapes_reparation = Column(JSONB, nullable=True)
    difficulte = Column(String(50))
    precautions = Column(Text)

    duree_minutes = Column(Integer, nullable=True)
    co2_economise_kg = Column(Numeric(10, 2), nullable=True)
    outils = Column(JSONB, nullable=True)

    # Liste des pièces nécessaires à la réparation
    pieces_necessaires = Column(JSONB, nullable=True)

    fault_associations = relationship(
        "FaultSolution",
        back_populates="solution",
        cascade="all, delete-orphan"
    )

    part_associations = relationship(
        "SolutionPart",
        back_populates="solution",
        cascade="all, delete-orphan"
    )


class FaultSolution(Base):
    __tablename__ = "fault_solutions"

    id = Column(Integer, primary_key=True, index=True)

    fault_id = Column(
        Integer,
        ForeignKey("faults.id", ondelete="CASCADE"),
        nullable=False
    )

    solution_id = Column(
        Integer,
        ForeignKey("solutions.id", ondelete="CASCADE"),
        nullable=False
    )

    __table_args__ = (
        UniqueConstraint(
            "fault_id",
            "solution_id",
            name="unique_fault_solution"
        ),
    )

    fault = relationship(
        "Fault",
        back_populates="solution_associations"
    )

    solution = relationship(
        "Solution",
        back_populates="fault_associations"
    )



class Part(Base):
    __tablename__ = "parts"

    id = Column(Integer, primary_key=True, index=True)

    nom = Column(String(150), nullable=False)
    categorie = Column(String(100))
    marque = Column(String(100))
    reference = Column(String(100))
    description = Column(Text)
    photo = Column(String(255))

    type_offre = Column(String(20))
    etat = Column(String(150))
    lieu_retrait = Column(String(200))
    co2_economise_kg = Column(Numeric(10, 2))

    solution_associations = relationship(
        "SolutionPart",
        back_populates="part",
        cascade="all, delete-orphan"
    )



class SolutionPart(Base):
    __tablename__ = "solution_parts"

    id = Column(Integer, primary_key=True, index=True)

    solution_id = Column(
        Integer,
        ForeignKey("solutions.id", ondelete="CASCADE"),
        nullable=False
    )

    part_id = Column(
        Integer,
        ForeignKey("parts.id", ondelete="CASCADE"),
        nullable=False
    )

    __table_args__ = (
        UniqueConstraint(
            "solution_id",
            "part_id",
            name="unique_solution_part"
        ),
    )

    solution = relationship(
        "Solution",
        back_populates="part_associations"
    )

    part = relationship(
        "Part",
        back_populates="solution_associations"
    )


class Diagnostic(Base):
    __tablename__ = "diagnostics"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    # La panne identifiée est facultative
    fault_id = Column(
        Integer,
        ForeignKey("faults.id"),
        nullable=True
    )

    description_observee = Column(Text, nullable=False)

    date_diagnostic = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    user = relationship(
        "User",
        back_populates="diagnostics"
    )

    fault = relationship(
        "Fault",
        back_populates="diagnostics"
    )


# ============================================================
# AXE 4 : PANIER ET RESERVATIONS
# ============================================================

class Cart(Base):
    __tablename__ = "carts"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    statut = Column(String(30), default="actif")

    date_creation = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    user = relationship(
        "User",
        back_populates="carts"
    )

    items = relationship(
        "CartItem",
        back_populates="cart",
        cascade="all, delete-orphan"
    )

    reservations = relationship(
        "Reservation",
        back_populates="cart"
    )


class CartItem(Base):
    __tablename__ = "cart_items"

    id = Column(Integer, primary_key=True, index=True)

    cart_id = Column(
        Integer,
        ForeignKey("carts.id", ondelete="CASCADE"),
        nullable=False
    )

    announcement_id = Column(
        Integer,
        ForeignKey("announcements.id"),
        nullable=False
    )

    quantite = Column(Integer, nullable=False, default=1)

    __table_args__ = (
        UniqueConstraint(
            "cart_id",
            "announcement_id",
            name="unique_cart_announcement"
        ),
        CheckConstraint(
            "quantite > 0",
            name="check_quantite_cart"
        ),
    )

    cart = relationship(
        "Cart",
        back_populates="items"
    )

    announcement = relationship(
        "Announcement",
        back_populates="cart_items"
    )


class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)
    date_retrait_souhaitee = Column(DateTime(timezone=True))
    creneau_retrait = Column(String(200), nullable=True)
    telephone_contact = Column(String(20))
    email_contact = Column(String(150))

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    cart_id = Column(
        Integer,
        ForeignKey("carts.id"),
        nullable=True
    )

    date_reservation = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    # en_attente, acceptee, refusee, annulee, terminee
    statut = Column(
        String(30),
        nullable=False,
        default="en_attente"
    )

    commentaire = Column(Text)
    confirmation_donneur = Column(
    Boolean,
    nullable=False,
    default=False,
    server_default="false"
)

    confirmation_beneficiaire = Column(
    Boolean,
    nullable=False,
    default=False,
    server_default="false"
    ) 

    __table_args__ = (
        CheckConstraint(
            "statut IN ('en_attente', 'acceptee', "
            "'refusee', 'annulee', 'terminee')",
            name="check_statut_reservation"
        ),
    )

    user = relationship(
        "User",
        back_populates="reservations"
    )

    cart = relationship(
        "Cart",
        back_populates="reservations"
    )

    items = relationship(
        "ReservationItem",
        back_populates="reservation",
        cascade="all, delete-orphan"
    )


class ReservationItem(Base):
    __tablename__ = "reservation_items"

    id = Column(Integer, primary_key=True, index=True)

    reservation_id = Column(
        Integer,
        ForeignKey("reservations.id", ondelete="CASCADE"),
        nullable=False
    )

    announcement_id = Column(
        Integer,
        ForeignKey("announcements.id"),
        nullable=False
    )

    quantite = Column(Integer, nullable=False, default=1)

    __table_args__ = (
        UniqueConstraint(
            "reservation_id",
            "announcement_id",
            name="unique_reservation_announcement"
        ),
        CheckConstraint(
            "quantite > 0",
            name="check_quantite_reservation"
        ),
    )

    reservation = relationship(
        "Reservation",
        back_populates="items"
    )

    announcement = relationship(
        "Announcement",
        back_populates="reservation_items"
    )

    loan = relationship(
        "Loan",
        back_populates="reservation_item",
        uselist=False,
        cascade="all, delete-orphan"
    )

    environmental_impact = relationship(
        "EnvironmentalImpact",
        back_populates="reservation_item",
        uselist=False,
        cascade="all, delete-orphan"
    )


# ============================================================
# AXE 5 : GESTION DES PRETS
# ============================================================

class LoanRequest(Base):
    __tablename__ = "loan_requests"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    announcement_id = Column(
        Integer,
        ForeignKey("announcements.id"),
        nullable=False
    )

    date_debut_souhaitee = Column(Date, nullable=False)
    date_fin_souhaitee = Column(Date, nullable=False)

    motif = Column(Text, nullable=False)

    telephone_contact = Column(String(20))
    email_contact = Column(String(150))

    statut = Column(
        String(30),
        nullable=False,
        default="en_attente"
    )

    date_demande = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "date_fin_souhaitee > date_debut_souhaitee",
            name="check_dates_loan_request"
        ),
        CheckConstraint(
            "statut IN ('en_attente', 'acceptee', 'refusee', 'annulee')",
            name="check_statut_loan_request"
        ),
    )

    user = relationship("User")
    announcement = relationship("Announcement")

class Loan(Base):
    __tablename__ = "loans"

    id = Column(Integer, primary_key=True, index=True)

    reservation_item_id = Column(
        Integer,
        ForeignKey("reservation_items.id", ondelete="CASCADE"),
        nullable=False,
        unique=True
    )

    date_debut = Column(Date, nullable=False)
    date_retour_prevue = Column(Date, nullable=False)
    date_retour_reelle = Column(Date)

    statut = Column(String(30), default="en_cours")

    __table_args__ = (
        CheckConstraint(
            "date_retour_prevue >= date_debut",
            name="check_dates_loan"
        ),
    )

    reservation_item = relationship(
        "ReservationItem",
        back_populates="loan"
    )


# ============================================================
# AXE 6 : IMPACT ENVIRONNEMENTAL
# ============================================================

class EnvironmentalImpact(Base):
    __tablename__ = "environmental_impacts"

    id = Column(Integer, primary_key=True, index=True)

    reservation_item_id = Column(
        Integer,
        ForeignKey("reservation_items.id", ondelete="CASCADE"),
        nullable=False,
        unique=True
    )

    equipements_sauves = Column(Integer, default=0)
    deee_evites_kg = Column(Numeric(10, 2), default=0)
    co2_evite_kg = Column(Numeric(10, 2), default=0)

    methode_calcul = Column(Text)

    date_calcul = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "equipements_sauves >= 0",
            name="check_equipements_sauves"
        ),
        CheckConstraint(
            "deee_evites_kg >= 0",
            name="check_deee_evites"
        ),
        CheckConstraint(
            "co2_evite_kg >= 0",
            name="check_co2_evite"
        ),
    )

    reservation_item = relationship(
        "ReservationItem",
        back_populates="environmental_impact"
    )


# ============================================================
# INDEX POUR AMELIORER LES RECHERCHES
# ============================================================

Index("idx_device_nom", Device.nom)
Index("idx_device_marque_modele", Device.marque, Device.modele)
Index("idx_fault_nom", Fault.nom_panne)
Index("idx_announcement_date", Announcement.date_publication)
Index("idx_announcement_statut", Announcement.statut)
Index("idx_part_reference", Part.reference)





class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    code_hash = Column(String(255), nullable=False)

    expires_at = Column(DateTime(timezone=True), nullable=False)

    used = Column(Boolean, default=False, nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

