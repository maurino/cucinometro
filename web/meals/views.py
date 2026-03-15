import os
import requests
from django.shortcuts import render, redirect
from django.contrib import messages
from django.conf import settings


def get_api_base_url():
    """Ottiene l'URL base dell'API da settings o variabile d'ambiente"""
    return getattr(settings, 'API_BASE_URL', os.getenv('API_BASE_URL', 'http://localhost:8000/api'))


def home(request):
    """Vista principale - mostra lista pasti e membri"""
    try:
        # Ottieni lista pasti
        meals_response = requests.get(f"{get_api_base_url()}/meals")
        meals = meals_response.json() if meals_response.status_code == 200 else []

        # Ottieni lista membri
        members_response = requests.get(f"{get_api_base_url()}/members")
        members = members_response.json() if members_response.status_code == 200 else []

        return render(request, 'meals/home.html', {
            'meals': meals,
            'members': members,
        })
    except requests.RequestException as e:
        messages.error(request, f"Errore di connessione all'API: {e}")
        return render(request, 'meals/home.html', {
            'meals': [],
            'members': [],
        })


def create_meal(request):
    """Vista per creare un nuovo pasto"""
    if request.method == 'POST':
        date = request.POST.get('date')
        kind = request.POST.get('kind')
        participants = request.POST.getlist('participants')

        if not date or not kind or not participants:
            messages.error(request, "Tutti i campi sono obbligatori")
            return redirect('home')

        try:
            data = {
                'date': date,
                'kind': kind,
                'participants': participants
            }

            response = requests.post(f"{get_api_base_url()}/meals", json=data)

            if response.status_code == 201:
                messages.success(request, "Pasto creato con successo!")
            else:
                messages.error(request, f"Errore nella creazione del pasto: {response.text}")

        except requests.RequestException as e:
            messages.error(request, f"Errore di connessione: {e}")

        return redirect('meals:home')

    # GET request - mostra form
    try:
        members_response = requests.get(f"{get_api_base_url()}/members")
        members = members_response.json() if members_response.status_code == 200 else []
    except requests.RequestException:
        members = []

    return render(request, 'meals/create_meal.html', {
        'members': members,
    })


def decide_dishwasher(request):
    """Vista per decidere chi lava i piatti"""
    if request.method == 'POST':
        date = request.POST.get('date')
        kind = request.POST.get('kind')
        participants = request.POST.getlist('participants')

        if not date or not kind or not participants:
            messages.error(request, "Tutti i campi sono obbligatori")
            return redirect('meals:home')

        try:
            data = {
                'date': date,
                'kind': kind,
                'participants': participants
            }

            response = requests.post(f"{get_api_base_url()}/meals/decide-dishwasher", json=data)

            if response.status_code == 200:
                result = response.json()
                messages.success(request, f"Il lavapiatti designato è: {result.get('dishwasher', 'N/A')}")
                return render(request, 'meals/decide_result.html', {
                    'result': result,
                    'participants': participants,
                    'date': date,
                    'kind': kind,
                })
            else:
                messages.error(request, f"Errore nel decidere il lavapiatti: {response.text}")

        except requests.RequestException as e:
            messages.error(request, f"Errore di connessione: {e}")

        return redirect('meals:home')

    # GET request - mostra form
    try:
        members_response = requests.get(f"{get_api_base_url()}/members")
        members = members_response.json() if members_response.status_code == 200 else []
    except requests.RequestException:
        members = []

    return render(request, 'meals/decide_dishwasher.html', {
        'members': members,
    })


def create_member(request):
    """Vista per creare un nuovo membro"""
    if request.method == 'POST':
        name = request.POST.get('name')

        if not name:
            messages.error(request, "Il nome è obbligatorio")
            return redirect('meals:home')

        try:
            data = {'name': name.strip()}

            response = requests.post(f"{get_api_base_url()}/members", json=data)

            if response.status_code == 201:
                messages.success(request, f"Membro '{name}' creato con successo!")
            else:
                messages.error(request, f"Errore nella creazione del membro: {response.text}")

        except requests.RequestException as e:
            messages.error(request, f"Errore di connessione: {e}")

        return redirect('meals:home')

    return render(request, 'meals/create_member.html')


def statistics(request):
    """Vista per visualizzare statistiche per ogni combinazione di membri"""
    try:
        # Ottieni lista membri
        members_response = requests.get(f"{get_api_base_url()}/members")
        members = members_response.json() if members_response.status_code == 200 else []

        if not members:
            messages.error(request, "Impossibile caricare la lista membri")
            return redirect('meals:home')

        # Ottieni tutti i pasti con partecipanti e assegnazioni
        meals_response = requests.get(f"{get_api_base_url()}/meals")
        meals = meals_response.json() if meals_response.status_code == 200 else []

        # Crea un dizionario per lookup veloce dei nomi dei membri
        member_names = {member['id']: member['name'] for member in members}

        # Raggruppa i pasti per combinazione di partecipanti
        combinations_stats = {}

        for meal in meals:
            if not meal.get('participants'):
                continue

            # Crea una chiave unica per la combinazione (ordinata alfabeticamente)
            participants_sorted = sorted(meal['participants'])
            combo_key = tuple(participants_sorted)

            if combo_key not in combinations_stats:
                combinations_stats[combo_key] = {
                    'participants': participants_sorted,
                    'total_meals': 0,
                    'dishwashing_counts': {name: 0 for name in participants_sorted}
                }

            combinations_stats[combo_key]['total_meals'] += 1

            # Conta i lavaggi per questa combinazione
            if meal.get('dishwasher') and meal['dishwasher'] in participants_sorted:
                combinations_stats[combo_key]['dishwashing_counts'][meal['dishwasher']] += 1

        # Converti in lista e ordina per frequenza decrescente
        stats_list = list(combinations_stats.values())

        # Ordina per frequenza decrescente (total_meals), poi per numero di partecipanti
        stats_list.sort(key=lambda x: (-x['total_meals'], len(x['participants']), x['participants']))

        return render(request, 'meals/statistics.html', {
            'stats_list': stats_list,
            'total_members': len(members),
            'total_meals': len(meals),
            'members': members,
        })

    except requests.RequestException as e:
        messages.error(request, f"Errore di connessione all'API: {e}")
        return redirect('meals:home')