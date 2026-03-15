import requests
import json
from datetime import date

# Test dell'endpoint decide-dishwasher
url = 'http://localhost:8000/api/meals/decide-dishwasher'
data = {
    'date': '2026-03-16',
    'kind': 'lunch',
    'participants': ['mauro', 'daniela', 'silvia'],
    'explain': True
}

try:
    response = requests.post(url, json=data)
    if response.status_code == 200:
        result = response.json()
        print('SUCCESS: API responded')
        if 'explanation' in result and result['explanation']:
            print('Explanation:')
            print(result['explanation']['explanation'])
        else:
            print('No explanation in response')
    else:
        print(f'ERROR: {response.status_code} - {response.text}')
except Exception as e:
    print(f'Exception: {e}')