import random
from datetime import date, timedelta

from db import SessionLocal
from models import (
    FamilyMember,
    Meal,
    MealParticipant,
    DishwashingAssignment,
    MealKind,
)


FAMILY_NAMES = [
    "mauro",
    "daniela",
    "silvia",
    "claudia",
    "alessandra",
    "giulia",
    "francesco",
]


def ensure_members(session):
    """Crea i membri se non esistono e restituisce lista di oggetti."""
    members_by_name = {}

    for name in FAMILY_NAMES:
        name = name.strip()
        existing = (
            session.query(FamilyMember)
            .filter(FamilyMember.name == name)
            .one_or_none()
        )
        if existing is None:
            existing = FamilyMember(name=name)
            session.add(existing)
            session.flush()
        members_by_name[name] = existing

    session.commit()
    return members_by_name


def get_or_create_meal(session, day: date, kind: MealKind) -> Meal:
    meal = (
        session.query(Meal)
        .filter(Meal.date == day, Meal.kind == kind)
        .one_or_none()
    )
    if meal is None:
        meal = Meal(date=day, kind=kind)
        session.add(meal)
        session.flush()
    return meal


def set_random_participants_and_dishwasher(
    session,
    meal: Meal,
    members_by_name: dict[str, FamilyMember],
):
    # Cancella eventuali partecipanti e assegnazioni esistenti
    session.query(MealParticipant).filter(
        MealParticipant.meal_id == meal.id
    ).delete()
    session.query(DishwashingAssignment).filter(
        DishwashingAssignment.meal_id == meal.id
    ).delete()

    # Scegli numero random di partecipanti (1..7)
    all_members = list(members_by_name.values())
    n_participants = random.randint(1, len(all_members))
    participants = random.sample(all_members, n_participants)

    for m in participants:
        session.add(MealParticipant(meal_id=meal.id, member_id=m.id))

    # Scegli un lavapiatti random tra i partecipanti
    chosen = random.choice(participants)
    assignment = DishwashingAssignment(meal_id=meal.id, member_id=chosen.id)
    session.add(assignment)

    session.commit()


def clear_all(session):
    """Cancella tutti i dati dal database."""
    session.query(DishwashingAssignment).delete()
    session.query(MealParticipant).delete()
    session.query(Meal).delete()
    session.query(FamilyMember).delete()
    session.commit()


def seed_one_year():
    session = SessionLocal()
    try:
        clear_all(session)
        members_by_name = ensure_members(session)

        start_day = date(2025, 1, 1)
        today = date.today()

        current = start_day
        created_meals = 0

        while current <= today:
            # Crea sempre pranzo e cena per ogni giorno
            meal_lunch = get_or_create_meal(session, current, MealKind.lunch)
            set_random_participants_and_dishwasher(
                session, meal_lunch, members_by_name
            )
            created_meals += 1

            meal_dinner = get_or_create_meal(session, current, MealKind.dinner)
            set_random_participants_and_dishwasher(
                session, meal_dinner, members_by_name
            )
            created_meals += 1

            current += timedelta(days=1)

        print(f"Seed completato: creati/aggiornati {created_meals} pasti.")
    finally:
        session.close()


if __name__ == "__main__":
    seed_one_year()