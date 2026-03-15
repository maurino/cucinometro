from datetime import date
from typing import List, Dict, Optional

from pydantic import BaseModel, ConfigDict

from models import MealKind


# -------- Membri --------

class MemberBase(BaseModel):
    name: str


class MemberCreate(MemberBase):
    pass


class MemberRead(MemberBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


# -------- Pasti --------

class MealBase(BaseModel):
    date: date
    kind: MealKind


class MealCreate(MealBase):
    participants: List[str]  # nomi dei membri


class MealRead(MealBase):
    id: int
    participants: List[str]
    dishwasher: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# -------- Decide dishwasher --------

class DecideDishwasherRequest(BaseModel):
    date: date
    kind: MealKind
    participants: List[str]
    explain: bool = True


class ConsideredMeal(BaseModel):
    id: int
    date: date
    kind: MealKind
    dishwasher: Optional[str] = None


class DecideDishwasherExplanation(BaseModel):
    explanation: str


class DecideDishwasherResponse(BaseModel):
    meal: MealRead
    dishwasher: str
    stats: Dict[str, int]
    explanation: Optional[DecideDishwasherExplanation] = None