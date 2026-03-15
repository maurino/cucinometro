import enum

from sqlalchemy import (
    Column,
    Date,
    Enum,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from db import Base


class MealKind(str, enum.Enum):
    lunch = "lunch"
    dinner = "dinner"


class FamilyMember(Base):
    __tablename__ = "family_member"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True, index=True)

    dishwashings = relationship(
        "DishwashingAssignment",
        back_populates="member",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


class Meal(Base):
    __tablename__ = "meal"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(Date, nullable=False, index=True)
    kind = Column(Enum(MealKind, name="meal_kind"), nullable=False)

    participants = relationship(
        "MealParticipant",
        back_populates="meal",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    dishwashing_assignment = relationship(
        "DishwashingAssignment",
        back_populates="meal",
        uselist=False,
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    __table_args__ = (
        UniqueConstraint("date", "kind", name="meal_unique_per_day_kind"),
    )


class MealParticipant(Base):
    __tablename__ = "meal_participant"

    meal_id = Column(
        Integer,
        ForeignKey("meal.id", ondelete="CASCADE"),
        primary_key=True,
    )
    member_id = Column(
        Integer,
        ForeignKey("family_member.id", ondelete="RESTRICT"),
        primary_key=True,
    )

    meal = relationship("Meal", back_populates="participants")
    member = relationship("FamilyMember")


class DishwashingAssignment(Base):
    __tablename__ = "dishwashing_assignment"

    id = Column(Integer, primary_key=True, index=True)
    meal_id = Column(
        Integer,
        ForeignKey("meal.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    member_id = Column(
        Integer,
        ForeignKey("family_member.id", ondelete="RESTRICT"),
        nullable=False,
    )

    meal = relationship("Meal", back_populates="dishwashing_assignment")
    member = relationship("FamilyMember", back_populates="dishwashings")