-- Script per cancellare tutti i dati dal database Cucinometro
-- Ordine importante per rispettare i vincoli di foreign key

-- Cancella assegnazioni lavapiatti
DELETE FROM dishwashing_assignment;

-- Cancella partecipanti ai pasti
DELETE FROM meal_participant;

-- Cancella pasti
DELETE FROM meal;

-- Cancella membri di test (quelli che non sono nella famiglia originale)
DELETE FROM family_member
WHERE name NOT IN ('mauro', 'daniela', 'silvia', 'claudia', 'alessandra', 'giulia', 'francesco');

-- Reset delle sequenze auto-increment
SELECT setval('family_member_id_seq', COALESCE((SELECT MAX(id) FROM family_member), 0) + 1);
SELECT setval('meal_id_seq', 1);
SELECT setval('dishwashing_assignment_id_seq', 1);