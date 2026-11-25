import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies import get_db, get_current_user
from app.models import User, PasswordResetCode
from app.schemas import (
    UserCreate,
    UserResponse,
    UserLogin,
    PasswordResetRequest,
    PasswordResetVerify
)
from app.security import hash_password, verify_password
from app.token import create_access_token
from app.email_service import send_password_reset_code


router = APIRouter(
    prefix="/users",
    tags=["Utilisateurs"]
)


# -------------------------
# INSCRIPTION
# -------------------------

@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED
)
def create_user(user: UserCreate, db: Session = Depends(get_db)):

    # Vérifier si l'adresse email existe déjà
    existing_user = db.query(User).filter(
        User.email == user.email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cette adresse email est déjà utilisée."
        )

    # Convertir le rôle reçu de Flutter en rôle PostgreSQL
    roles_mapping = {
        "Étudiant / Particulier": "particulier",
        "Réparateur / FabLab": "reparateur",
        "Donateur / Service IT": "donateur"
    }

    role_db = roles_mapping.get(user.role)

    if role_db is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rôle invalide."
        )

    # Sécuriser le mot de passe
    hashed_password = hash_password(user.password)

    # Créer le nouvel utilisateur
    new_user = User(
        nom=user.nom,
        email=user.email,
        password=hashed_password,
        telephone=user.telephone,
        adresse=user.adresse,
        role=role_db
    )

    # Enregistrer dans PostgreSQL
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


# -------------------------
# CONNEXION
# -------------------------

@router.post("/login")
def login_user(user: UserLogin, db: Session = Depends(get_db)):

    # Rechercher l'utilisateur avec son email
    existing_user = db.query(User).filter(
        User.email == user.email
    ).first()

    # Vérifier si l'utilisateur existe
    if not existing_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect."
        )

    # Vérifier le mot de passe
    password_correct = verify_password(
        user.password,
        existing_user.password
    )

    if not password_correct:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect."
        )

    # Générer un jeton JWT
    access_token = create_access_token(existing_user.id)

    return {
        "message": "Connexion réussie !",
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": existing_user.id,
            "nom": existing_user.nom,
            "email": existing_user.email,
            "role": existing_user.role
        }
    }


# -------------------------
# PROFIL DE L'UTILISATEUR CONNECTÉ
# -------------------------

@router.get("/me", response_model=UserResponse)
def get_my_profile(
    current_user: User = Depends(get_current_user)
):
    return current_user




@router.post("/forgot-password")
def forgot_password(
    request: PasswordResetRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == request.email).first()

    # Même réponse, que l'adresse existe ou non
    if not user:
        return {
            "message": "Si cette adresse existe, un code de récupération sera envoyé."
        }

    # Invalider les anciens codes non utilisés
    db.query(PasswordResetCode).filter(
        PasswordResetCode.user_id == user.id,
        PasswordResetCode.used == False
    ).update({"used": True})

    # Générer un code à 6 chiffres
    code = f"{secrets.randbelow(1000000):06d}"

    reset_code = PasswordResetCode(
        user_id=user.id,
        code_hash=hash_password(code),
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
        used=False
    )

    db.add(reset_code)
    db.commit()

    try:
        send_password_reset_code(user.email, code)
    except Exception:
        db.query(PasswordResetCode).filter(
            PasswordResetCode.id == reset_code.id
        ).update({"used": True})
        db.commit()

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Impossible d'envoyer l'e-mail pour le moment."
        )

    return {
        "message": "Si cette adresse existe, un code de récupération sera envoyé."
    }


@router.post("/reset-password")
def reset_password(
    request: PasswordResetVerify,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == request.email).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré."
        )

    reset_code = db.query(PasswordResetCode).filter(
        PasswordResetCode.user_id == user.id,
        PasswordResetCode.used == False
    ).order_by(
        PasswordResetCode.created_at.desc()
    ).first()

    if not reset_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré."
        )

    if reset_code.expires_at <= datetime.now(timezone.utc):
        reset_code.used = True
        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré."
        )

    if not verify_password(request.code, reset_code.code_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré."
        )

    # Modifier le mot de passe
    user.password = hash_password(request.new_password)

    # Rendre le code inutilisable
    reset_code.used = True

    db.commit()

    return {
        "message": "Ton mot de passe a été réinitialisé avec succès."
    }
