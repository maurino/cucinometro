from typing import List, Dict, Set

from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.orm import Session, joinedload

from db import Base, engine, get_db
from models import (
    FamilyMember,
    Meal,
    MealParticipant,
    DishwashingAssignment,
    MealKind,
)
from schemas import (
    MemberCreate,
    MemberRead,
    MealCreate,
    MealRead,
    DecideDishwasherRequest,
    DecideDishwasherResponse,
    DecideDishwasherExplanation,
)

app = FastAPI(title="Cucinometro API", version="0.1.0")


@app.on_event("startup")
def on_startup():
    # Lo schema è gestito via SQL, non creiamo tabelle da qui.
    Base.metadata.bind = engine


@app.get("/internal/health")
def health():
    return {"status": "ok"}


# ---------- Helpers ----------


def get_or_create_member_by_name(db: Session, name: str) -> FamilyMember:
    name = name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Member name cannot be empty")

    member = db.execute(
        select(FamilyMember).where(FamilyMember.name == name)
    ).scalar_one_or_none()

    if member is None:
        member = FamilyMember(name=name)
        db.add(member)
        db.commit()
        db.refresh(member)

    return member


def get_or_create_meal(
    db: Session,
    date,
    kind: MealKind,
) -> Meal:
    meal = db.execute(
        select(Meal).where(Meal.date == date, Meal.kind == kind)
    ).scalar_one_or_none()

    if meal is None:
        meal = Meal(date=date, kind=kind)
        db.add(meal)
        db.commit()
        db.refresh(meal)

    return meal


def set_meal_participants(
    db: Session,
    meal: Meal,
    participant_names: List[str],
) -> List[FamilyMember]:
    # Normalizza e rimuove duplicati mantenendo l'ordine
    seen: Set[str] = set()
    cleaned: List[str] = []
    for n in participant_names:
        n = n.strip()
        if n and n not in seen:
            seen.add(n)
            cleaned.append(n)

    if not cleaned:
        raise HTTPException(status_code=400, detail="At least one participant is required")

    members: List[FamilyMember] = [
        get_or_create_member_by_name(db, name) for name in cleaned
    ]

    # Cancella i partecipanti esistenti e ricrea
    db.query(MealParticipant).filter(MealParticipant.meal_id == meal.id).delete()
    for m in members:
        db.add(MealParticipant(meal_id=meal.id, member_id=m.id))

    db.commit()
    db.refresh(meal)

    return members


def meal_to_read(meal: Meal, members_by_id: Dict[int, FamilyMember]) -> MealRead:
    participant_names = [
        members_by_id[mp.member_id].name for mp in meal.participants
    ]

    dishwasher_name = None
    if meal.dishwashing_assignment is not None:
        dishwasher_member = members_by_id.get(meal.dishwashing_assignment.member_id)
        if dishwasher_member is not None:
            dishwasher_name = dishwasher_member.name

    return MealRead(
        id=meal.id,
        date=meal.date,
        kind=meal.kind,
        participants=participant_names,
        dishwasher=dishwasher_name,
    )


# ---------- Membri ----------


@app.get("/internal/members", response_model=List[MemberRead])
def list_members(db: Session = Depends(get_db)):
    members = db.execute(select(FamilyMember).order_by(FamilyMember.name)).scalars().all()
    return members


@app.post("/internal/members", response_model=MemberRead, status_code=201)
def create_member(payload: MemberCreate, db: Session = Depends(get_db)):
    existing = db.execute(
        select(FamilyMember).where(FamilyMember.name == payload.name.strip())
    ).scalar_one_or_none()

    if existing is not None:
        raise HTTPException(status_code=400, detail="Member with this name already exists")

    member = FamilyMember(name=payload.name.strip())
    db.add(member)
    db.commit()
    db.refresh(member)
    return member


# ---------- Pasti ----------


@app.post("/internal/meals", response_model=MealRead, status_code=201)
def create_or_update_meal(payload: MealCreate, db: Session = Depends(get_db)):
    meal = get_or_create_meal(db, payload.date, payload.kind)
    members = set_meal_participants(db, meal, payload.participants)

    members_by_id = {m.id: m for m in members}
    # Ricarica il meal con partecipanti e assegnazione
    meal = (
        db.execute(
            select(Meal)
            .options(
                joinedload(Meal.participants),
                joinedload(Meal.dishwashing_assignment),
            )
            .where(Meal.id == meal.id)
        )
        .unique()
        .scalar_one()
    )

    # Assicura che tutti i membri coinvolti siano nel dizionario
    for mp in meal.participants:
        if mp.member_id not in members_by_id:
            members_by_id[mp.member_id] = db.get(FamilyMember, mp.member_id)

    return meal_to_read(meal, members_by_id)


@app.get("/internal/meals", response_model=List[MealRead])
def list_meals(
    date_from: str | None = None,
    date_to: str | None = None,
    kind: MealKind | None = None,
    db: Session = Depends(get_db),
):
    stmt = select(Meal).options(
        joinedload(Meal.participants),
        joinedload(Meal.dishwashing_assignment),
    )

    if kind is not None:
        stmt = stmt.where(Meal.kind == kind)

    from datetime import date as _date

    if date_from is not None:
        stmt = stmt.where(Meal.date >= _date.fromisoformat(date_from))
    if date_to is not None:
        stmt = stmt.where(Meal.date <= _date.fromisoformat(date_to))

    stmt = stmt.order_by(Meal.date.desc(), Meal.kind)

    meals = db.execute(stmt).unique().scalars().all()

    # Precarica tutti i membri usati in una sola query
    member_ids: Set[int] = set()
    for meal in meals:
        for mp in meal.participants:
            member_ids.add(mp.member_id)
        if meal.dishwashing_assignment is not None:
            member_ids.add(meal.dishwashing_assignment.member_id)

    members = db.execute(
        select(FamilyMember).where(FamilyMember.id.in_(member_ids))
    ).scalars().all()
    members_by_id = {m.id: m for m in members}

    return [meal_to_read(m, members_by_id) for m in meals]


@app.get("/internal/meals/{meal_id}", response_model=MealRead)
def get_meal(meal_id: int, db: Session = Depends(get_db)):
    meal = (
        db.execute(
            select(Meal)
            .options(
                joinedload(Meal.participants),
                joinedload(Meal.dishwashing_assignment),
            )
            .where(Meal.id == meal_id)
        )
        .unique()
        .scalar_one_or_none()
    )

    if meal is None:
        raise HTTPException(status_code=404, detail="Meal not found")

    member_ids: Set[int] = set()
    for mp in meal.participants:
        member_ids.add(mp.member_id)
    if meal.dishwashing_assignment is not None:
        member_ids.add(meal.dishwashing_assignment.member_id)

    members = (
        db.execute(
            select(FamilyMember).where(FamilyMember.id.in_(member_ids))
        )
        .scalars()
        .all()
    )
    members_by_id = {m.id: m for m in members}

    return meal_to_read(meal, members_by_id)
# ---------- Decide dishwasher ----------


@app.post(
    "/internal/meals/decide-dishwasher",
    response_model=DecideDishwasherResponse,
)
def decide_dishwasher(payload: DecideDishwasherRequest, db: Session = Depends(get_db)):
    if not payload.participants:
        raise HTTPException(status_code=400, detail="At least one participant is required")

    # 1. Normalizza/crea membri
    members = [
        get_or_create_member_by_name(db, name) for name in payload.participants
    ]
    members_by_id = {m.id: m for m in members}
    participant_ids: Set[int] = {m.id for m in members}

    # 2. Trova o crea il pasto corrente
    meal = get_or_create_meal(db, payload.date, payload.kind)

    # 3. Imposta i partecipanti del pasto corrente
    set_meal_participants(db, meal, payload.participants)

    # 4. Ricarica meal con relazioni
    meal = (
        db.execute(
            select(Meal)
            .options(
                joinedload(Meal.participants),
                joinedload(Meal.dishwashing_assignment),
            )
            .where(Meal.id == meal.id)
        )
        .unique()
        .scalar_one()
    )

    # 5. Trova i pasti storici con esattamente gli stessi partecipanti
    # Nota: consideriamo TUTTI i pasti passati, non solo dello stesso tipo (lunch/dinner)
    # perché l'importante è contare i lavaggi quando erano presenti gli stessi membri
    candidate_meals = (
        db.execute(
            select(Meal)
            .options(
                joinedload(Meal.participants),
                joinedload(Meal.dishwashing_assignment),
            )
            .where(Meal.id != meal.id)
        )
        .unique()
        .scalars()
        .all()
    )

    considered: List[Meal] = []
    for m in candidate_meals:
        ids = {mp.member_id for mp in m.participants}
        if ids == participant_ids:
            considered.append(m)

    # 6. Calcola quante volte ognuno ha lavato tra i pasti considerati
    stats: Dict[str, int] = {m.name: 0 for m in members}
    for m in considered:
        if m.dishwashing_assignment is not None:
            dw_member = members_by_id.get(m.dishwashing_assignment.member_id)
            if dw_member is not None:
                stats[dw_member.name] += 1

    # 7. Scegli il partecipante con il conteggio minimo
    #    In caso di pareggio, usa il conteggio globale (tutte le combinazioni) come spareggio
    min_count = min(stats.values()) if stats else 0
    candidates = [name for name, cnt in stats.items() if cnt == min_count]

    global_stats: Dict[str, int] = {}
    if len(candidates) > 1:
        # Calcola il conteggio globale di lavaggi per i candidati in pareggio
        global_rows = db.execute(
            select(FamilyMember.name, func.count(DishwashingAssignment.id))
            .join(DishwashingAssignment, DishwashingAssignment.member_id == FamilyMember.id)
            .where(FamilyMember.name.in_(candidates))
            .group_by(FamilyMember.name)
        ).all()
        global_stats = {row[0]: row[1] for row in global_rows}
        # Assicura che tutti i candidati abbiano un valore (anche 0)
        for name in candidates:
            global_stats.setdefault(name, 0)

        min_global = min(global_stats[n] for n in candidates)
        candidates = [n for n in candidates if global_stats[n] == min_global]

    chosen_name = sorted(candidates)[0]
    chosen_member = next(m for m in members if m.name == chosen_name)

    # 8. Crea/aggiorna l'assegnazione per il pasto corrente
    assignment = db.execute(
        select(DishwashingAssignment).where(DishwashingAssignment.meal_id == meal.id)
    ).scalar_one_or_none()

    if assignment is None:
        assignment = DishwashingAssignment(meal_id=meal.id, member_id=chosen_member.id)
        db.add(assignment)
    else:
        assignment.member_id = chosen_member.id

    db.commit()
    db.refresh(assignment)

    # Collega l'assegnazione al meal in memoria
    meal.dishwashing_assignment = assignment

    # 9. Costruisci spiegazione (se richiesta)
    explanation = None
    if payload.explain:
        num_considered = len(considered)

        explanation_text = f"Ho considerato {num_considered} pasti passati con esattamente gli stessi partecipanti."

        if num_considered > 0:
            explanation_text += "\n\n**Conteggio lavaggi per partecipante (stessa combinazione):**\n\n"
            explanation_text += "| Partecipante | Lavaggi |\n"
            explanation_text += "|-------------|--------|\n"
            for name, count in sorted(stats.items()):
                explanation_text += f"| {name} | {count} |\n"

            min_count_local = min(stats.values())
            candidates_local = [name for name, cnt in stats.items() if cnt == min_count_local]

            explanation_text += f"\nIl membro scelto è quello con il minor numero di lavaggi in questa combinazione ({min_count_local})."
            if len(candidates_local) == 1:
                explanation_text += f" Ho scelto **{candidates_local[0]}**."
            else:
                explanation_text += f" Pareggio tra: {', '.join(sorted(candidates_local))}."
                explanation_text += "\n\n**Spareggio: conteggio globale lavaggi (tutte le combinazioni):**\n\n"
                explanation_text += "| Partecipante | Lavaggi totali |\n"
                explanation_text += "|-------------|---------------|\n"
                for name in sorted(candidates_local):
                    explanation_text += f"| {name} | {global_stats.get(name, 0)} |\n"
                min_global = min(global_stats.get(n, 0) for n in candidates_local)
                winners = [n for n in candidates_local if global_stats.get(n, 0) == min_global]
                if len(winners) == 1:
                    explanation_text += f"\nHo scelto **{winners[0]}** (meno lavaggi in assoluto: {min_global})."
                else:
                    explanation_text += f"\nAncora pareggio tra {', '.join(sorted(winners))}: ho scelto **{sorted(winners)[0]}** (ordine alfabetico)."
        else:
            explanation_text += " Non ci sono pasti passati con esattamente questi partecipanti."
            if global_stats:
                explanation_text += "\n\n**Spareggio: conteggio globale lavaggi (tutte le combinazioni):**\n\n"
                explanation_text += "| Partecipante | Lavaggi totali |\n"
                explanation_text += "|-------------|---------------|\n"
                for name in sorted(global_stats.keys()):
                    explanation_text += f"| {name} | {global_stats[name]} |\n"
                explanation_text += f"\nHo scelto **{chosen_name}** (meno lavaggi in assoluto)."
            else:
                explanation_text += f" Ho scelto **{chosen_name}** (ordine alfabetico)."

        explanation = DecideDishwasherExplanation(
            explanation=explanation_text
        )

    # 10. Assicura che tutti i membri siano nel dizionario
    for mp in meal.participants:
        if mp.member_id not in members_by_id:
            members_by_id[mp.member_id] = db.get(FamilyMember, mp.member_id)
    if meal.dishwashing_assignment is not None:
        if meal.dishwashing_assignment.member_id not in members_by_id:
            members_by_id[meal.dishwashing_assignment.member_id] = db.get(
                FamilyMember,
                meal.dishwashing_assignment.member_id,
            )

    meal_read = meal_to_read(meal, members_by_id)

    return DecideDishwasherResponse(
        meal=meal_read,
        dishwasher=chosen_member.name,
        stats=stats,
        explanation=explanation,
    )