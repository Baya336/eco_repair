
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from collections import defaultdict
from decimal import Decimal

from app.dependencies import get_db
from app.models import Announcement

router = APIRouter(
    prefix="/environmental",
    tags=["Environmental Dashboard"]
)


@router.get("/dashboard")
def get_environmental_dashboard(
    db: Session = Depends(get_db)
):
    # Seules les annonces dont le réemploi est terminé
    announcements = (
        db.query(Announcement)
        .filter(
            Announcement.statut == "termine",
            Announcement.type_materiel.in_(["equipement", "piece"])
        )
        .all()
    )

    co2_total = Decimal("0")
    weight_total = Decimal("0")

    equipment_count = 0
    component_counts = defaultdict(int)

    repairability_scores = []

    for announcement in announcements:

        quantity = announcement.quantite or 1

        # Nombre d'équipements réemployés
        if announcement.type_materiel == "equipement":
            equipment_count += quantity

        # Poids total réemployé
        if announcement.poids_kg is not None:
            weight_total += (
                Decimal(str(announcement.poids_kg)) * quantity
            )

        # CO2 économisé
        if announcement.co2_economise_kg is not None:
            co2_total += (
                Decimal(str(announcement.co2_economise_kg)) * quantity
            )

        # Score de réparabilité
        if announcement.indice_reparabilite is not None:
            repairability_scores.append(
                float(announcement.indice_reparabilite)
            )

        # Répartition des pièces réemployées
        if announcement.type_materiel == "piece":
            component_name = (
                announcement.sous_type
                or announcement.nom_materiel
                or "Autres composants"
            )

            component_counts[component_name] += quantity

    # Calcul du score moyen
    average_score = (
        round(sum(repairability_scores) / len(repairability_scores), 1)
        if repairability_scores
        else None
    )

    # Préparation de la répartition des composants
    total_components = sum(component_counts.values())

    components = []

    for name, count in sorted(
        component_counts.items(),
        key=lambda item: item[1],
        reverse=True
    ):
        percentage = (
            round((count / total_components) * 100, 1)
            if total_components > 0
            else 0
        )

        components.append({
            "name": name,
            "count": count,
            "percentage": percentage
        })

    return {
        "co2_saved_kg": float(co2_total),
        "co2_saved_tonnes": round(float(co2_total) / 1000, 3),

        "equipment_saved": equipment_count,

        "deee_avoided_kg": round(float(weight_total), 3),

        "average_repairability_score": average_score,

        "most_reused_components": components,

        # À renseigner après un véritable audit EcoIndex
        "ecoindex_score": None,
        "ecoindex_grade": None
    }
