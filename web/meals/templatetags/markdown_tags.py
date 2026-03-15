import markdown
from django import template
from django.utils.safestring import mark_safe

register = template.Library()

@register.filter
def markdownify(text):
    """Converte markdown in HTML"""
    if not text:
        return ""
    return mark_safe(markdown.markdown(text, extensions=['tables']))


@register.filter
def meal_kind(kind: str) -> str:
    """Converte il tipo di pasto (lunch/dinner) in italiano"""
    if not kind:
        return ""
    mapping = {
        'lunch': 'Pranzo',
        'dinner': 'Cena',
    }
    return mapping.get(str(kind).lower(), str(kind).title())