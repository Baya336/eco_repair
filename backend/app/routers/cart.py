
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_db, get_current_user
from app.models import Cart, CartItem, Announcement, User
from app.schemas import CartItemResponse


router = APIRouter(prefix="/cart", tags=["Panier"])


# ---------------------------------
# Récupérer ou créer le panier actif
# ---------------------------------

def get_or_create_cart(db: Session, user: User):
    cart = db.query(Cart).filter(
        Cart.user_id == user.id,
        Cart.statut == "actif"
    ).first()

    if cart is None:
        cart = Cart(
            user_id=user.id,
            statut="actif"
        )
        db.add(cart)
        db.commit()
        db.refresh(cart)

    return cart


# ---------------------------------
# Convertir un article pour Flutter
# ---------------------------------

def cart_item_to_dict(item: CartItem):
    announcement = item.announcement

    if announcement is None:
        return None

    category = 0 if announcement.type_materiel == "equipement" else 1

    co2 = announcement.co2_economise_kg
    co2_text = f"{co2} kg" if co2 is not None else None

    repair_score = announcement.indice_reparabilite

    return {
        "id": item.id,
        "announcement_id": announcement.id,
        "name": announcement.nom_materiel,
        "type": "Don" if announcement.type_offre == "don" else "Prêt",
        "location": announcement.lieu_retrait,
        "icon": "💻" if category == 0 else "🔧",
        "category": category,
        "subType": announcement.sous_type,
        "description": announcement.description,
        "image": announcement.photo,
        "co2Saved": co2_text,
        "repairScore": float(repair_score) if repair_score is not None else None,
        "partCondition": announcement.etat_piece,
        "condition": announcement.etat_objet or announcement.etat_piece
    }


# ---------------------------------
# Ajouter une annonce au panier
# ---------------------------------

@router.post("/add/{announcement_id}")
def add_to_cart(
    announcement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    announcement = db.query(Announcement).filter(
        Announcement.id == announcement_id,
        Announcement.statut == "disponible"
    ).first()

    if announcement is None:
        raise HTTPException(
            status_code=404,
            detail="Annonce introuvable ou indisponible."
        )

    if announcement.user_id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="Tu ne peux pas ajouter ta propre annonce au panier."
        )

    cart = get_or_create_cart(db, current_user)

    existing_item = db.query(CartItem).filter(
        CartItem.cart_id == cart.id,
        CartItem.announcement_id == announcement.id
    ).first()

    if existing_item:
        return {
            "message": "Cette annonce est déjà dans ton panier.",
            "cart_item_id": existing_item.id,
            "announcement_id": announcement.id
        }

    new_item = CartItem(
        cart_id=cart.id,
        announcement_id=announcement.id,
        quantite=1
    )

    db.add(new_item)
    db.commit()
    db.refresh(new_item)

    return {
        "message": "Annonce ajoutée au panier avec succès.",
        "cart_item_id": new_item.id,
        "announcement_id": announcement.id
    }


# ---------------------------------
# Afficher le panier
# ---------------------------------

@router.get("/", response_model=list[CartItemResponse])
def get_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, current_user)

    items = db.query(CartItem).join(
        Announcement,
        CartItem.announcement_id == Announcement.id
    ).filter(
        CartItem.cart_id == cart.id,
        Announcement.statut == "disponible"
    ).all()

    result = []

    for item in items:
        article = cart_item_to_dict(item)

        if article is not None:
            result.append(article)

    return result


# ---------------------------------
# Retirer une annonce du panier
# ---------------------------------

@router.delete("/remove/{announcement_id}")
def remove_from_cart(
    announcement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, current_user)

    item = db.query(CartItem).filter(
        CartItem.cart_id == cart.id,
        CartItem.announcement_id == announcement_id
    ).first()

    if item is None:
        raise HTTPException(
            status_code=404,
            detail="Cette annonce n'existe pas dans ton panier."
        )

    db.delete(item)
    db.commit()

    return {
        "message": "Annonce retirée du panier.",
        "announcement_id": announcement_id
    }


# ---------------------------------
# Vider le panier
# ---------------------------------

@router.delete("/clear")
def clear_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, current_user)

    db.query(CartItem).filter(
        CartItem.cart_id == cart.id
    ).delete(synchronize_session=False)

    db.commit()

    return {
        "message": "Panier vidé avec succès."
    }
